import 'dart:async';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_models.dart';
import 'package:flutter_package_studio_core/src/plugin/interface/plugin_registry.dart';
import 'package:flutter_package_studio_core/src/plugin/lifecycle/plugin_lifecycle_manager.dart';
import 'package:flutter_package_studio_core/src/plugin/permission/plugin_permission_gate.dart';
import 'package:flutter_package_studio_core/src/plugin/runtime/plugin_execution_context.dart';
import 'package:flutter_package_studio_core/src/plugin/runtime/plugin_execution_models.dart';

/// Single authority for controlled, fault-isolated, timeout-bounded execution of active plugin contributions.
class PluginExecutionRuntime {
  final Logger _logger = Logger('PluginExecutionRuntime');
  final PluginLifecycleManager _lifecycleManager;
  final PluginPermissionGate _permissionGate;
  final PluginRegistry _registry;

  final List<ExecutionAuditRecord> _auditLog = [];
  final Map<String, int> _consecutiveFailures = {};
  final int maxConsecutiveFailures;

  PluginExecutionRuntime({
    required PluginLifecycleManager lifecycleManager,
    required PluginPermissionGate permissionGate,
    required PluginRegistry registry,
    this.maxConsecutiveFailures = 3,
  })  : _lifecycleManager = lifecycleManager,
        _permissionGate = permissionGate,
        _registry = registry;

  PluginRegistry get registry => _registry;
  List<ExecutionAuditRecord> get auditLog => List.unmodifiable(_auditLog);

  /// Executes a single contribution operation on an [PluginLifecycleState.active] plugin with error isolation and timeout bounding.
  Future<PluginExecutionResult<T>> executeContribution<T>({
    required String instanceId,
    required String operation,
    required FutureOr<T> Function(PluginExecutionContext context) action,
    Duration timeout = const Duration(seconds: 10),
    Map<String, dynamic>? metadata,
  }) async {
    final sw = Stopwatch()..start();
    _logger.info(
        'Executing "$operation" for plugin instance "$instanceId" (timeout: ${timeout.inMilliseconds}ms)');

    // 1. Check if plugin instance is tracked
    final instanceRecord = _lifecycleManager.getInstance(instanceId);
    if (instanceRecord == null) {
      sw.stop();
      final result = PluginExecutionResult<T>(
        pluginId: instanceId,
        operation: operation,
        status: PluginExecutionStatus.failed,
        errorMessage:
            'Plugin instance "$instanceId" is not tracked by lifecycle manager.',
        durationMs: sw.elapsedMilliseconds,
      );
      _recordAudit(instanceId, operation, PluginExecutionStatus.failed,
          sw.elapsedMilliseconds, result.errorMessage);
      return result;
    }

    final manifest = instanceRecord.manifest;
    final pluginId = manifest.id.value;

    // 2. Lifecycle State Gate: Plugin MUST be in `active` state
    if (instanceRecord.state != PluginLifecycleState.active) {
      sw.stop();
      final errorMsg =
          'Refused execution: Plugin "$pluginId" is in state "${instanceRecord.state.name}", expected "active".';
      _logger.warning(errorMsg);
      final result = PluginExecutionResult<T>(
        pluginId: pluginId,
        operation: operation,
        status: PluginExecutionStatus.rejectedNotActive,
        errorMessage: errorMsg,
        durationMs: sw.elapsedMilliseconds,
      );
      _recordAudit(pluginId, operation, PluginExecutionStatus.rejectedNotActive,
          sw.elapsedMilliseconds, errorMsg);
      return result;
    }

    // 3. Create scoped execution context
    final context = PluginExecutionContext(
      pluginId: pluginId,
      manifest: manifest,
      permissionGate: _permissionGate,
      metadata: metadata,
      rawPluginInstance: instanceRecord.instance,
    );

    // 4. Execute with timeout racing and error isolation
    final pluginFuture = Future<T>.sync(() => action(context));
    try {
      final value = await pluginFuture.timeout(
        timeout,
        onTimeout: () {
          // Explicitly absorb any delayed error/rejection from the abandoned future
          // so it never surfaces as an unhandled asynchronous error in the Dart zone.
          unawaited(pluginFuture.then<void>(
            (_) {},
            onError: (Object error, StackTrace stackTrace) {
              _logger.info(
                  'Safely absorbed delayed post-timeout failure for plugin "$pluginId": $error');
            },
          ));
          throw PluginTimeoutException(
              'Invocation of "$operation" on plugin "$pluginId" timed out after ${timeout.inMilliseconds}ms.');
        },
      );

      sw.stop();
      _consecutiveFailures[instanceId] =
          0; // Reset consecutive failures on success
      final result = PluginExecutionResult<T>(
        pluginId: pluginId,
        operation: operation,
        status: PluginExecutionStatus.success,
        value: value,
        durationMs: sw.elapsedMilliseconds,
      );
      _recordAudit(pluginId, operation, PluginExecutionStatus.success,
          sw.elapsedMilliseconds, 'SUCCESS');
      return result;
    } on PluginTimeoutException catch (e, st) {
      sw.stop();
      await _handleFailure(instanceId, 'Timeout during execution');
      final result = PluginExecutionResult<T>(
        pluginId: pluginId,
        operation: operation,
        status: PluginExecutionStatus.timedOut,
        errorMessage: e.message,
        stackTrace: st.toString(),
        durationMs: sw.elapsedMilliseconds,
      );
      _recordAudit(pluginId, operation, PluginExecutionStatus.timedOut,
          sw.elapsedMilliseconds, e.message);
      return result;
    } on PluginPermissionException catch (e, st) {
      sw.stop();
      final result = PluginExecutionResult<T>(
        pluginId: pluginId,
        operation: operation,
        status: PluginExecutionStatus.permissionDenied,
        errorMessage: e.message,
        stackTrace: st.toString(),
        durationMs: sw.elapsedMilliseconds,
      );
      _recordAudit(pluginId, operation, PluginExecutionStatus.permissionDenied,
          sw.elapsedMilliseconds, e.message);
      return result;
    } catch (e, st) {
      sw.stop();
      await _handleFailure(instanceId, 'Exception during execution: $e');
      final result = PluginExecutionResult<T>(
        pluginId: pluginId,
        operation: operation,
        status: PluginExecutionStatus.failed,
        errorMessage: e.toString(),
        stackTrace: st.toString(),
        durationMs: sw.elapsedMilliseconds,
      );
      _recordAudit(pluginId, operation, PluginExecutionStatus.failed,
          sw.elapsedMilliseconds, e.toString());
      return result;
    }
  }

  /// Executes a batch across multiple plugin instances providing a capability in full isolation.
  Future<PluginBatchExecutionResult> executeBatch<T>({
    required List<String> instanceIds,
    required String capabilityName,
    required FutureOr<T> Function(
            String instanceId, PluginExecutionContext context)
        action,
    Duration timeout = const Duration(seconds: 10),
    Map<String, dynamic>? metadata,
  }) async {
    final batchSw = Stopwatch()..start();
    final results = <PluginExecutionResult<dynamic>>[];

    for (final instanceId in instanceIds) {
      // Isolate each invocation so one failure cannot interrupt the loop
      final res = await executeContribution<T>(
        instanceId: instanceId,
        operation: '$capabilityName.batchExecute',
        action: (ctx) => action(instanceId, ctx),
        timeout: timeout,
        metadata: metadata,
      );
      results.add(res);
    }

    batchSw.stop();
    return PluginBatchExecutionResult(
      capabilityName: capabilityName,
      results: List.unmodifiable(results),
      totalDurationMs: batchSw.elapsedMilliseconds,
    );
  }

  /// Safely executes analysis contributions using checked proxy.
  Future<PluginExecutionResult<List<String>>> executePackageAnalysis({
    required String instanceId,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return executeContribution<List<String>>(
      instanceId: instanceId,
      operation: 'PackageAnalysisContribution.getAnalyzers',
      timeout: timeout,
      action: (ctx) {
        final proxy = ctx.analysisContribution;
        if (proxy == null) {
          throw PluginExecutionException(
              'Plugin "$instanceId" does not implement PackageAnalysisContribution.');
        }
        return proxy.getAnalyzers();
      },
    );
  }

  /// Safely executes release workflow contributions using checked proxy.
  Future<PluginExecutionResult<List<String>>> executeReleaseWorkflow({
    required String instanceId,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return executeContribution<List<String>>(
      instanceId: instanceId,
      operation: 'ReleaseWorkflowContribution.getWorkflowHooks',
      timeout: timeout,
      action: (ctx) {
        final proxy = ctx.releaseWorkflowContribution;
        if (proxy == null) {
          throw PluginExecutionException(
              'Plugin "$instanceId" does not implement ReleaseWorkflowContribution.');
        }
        return proxy.getWorkflowHooks();
      },
    );
  }

  /// Safely executes command contributions using checked proxy.
  Future<PluginExecutionResult<List<String>>> executeCommandContribution({
    required String instanceId,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return executeContribution<List<String>>(
      instanceId: instanceId,
      operation: 'CommandContribution.getCommands',
      timeout: timeout,
      action: (ctx) {
        final proxy = ctx.commandContribution;
        if (proxy == null) {
          throw PluginExecutionException(
              'Plugin "$instanceId" does not implement CommandContribution.');
        }
        return proxy.getCommands();
      },
    );
  }

  Future<void> _handleFailure(String instanceId, String reason) async {
    final count = (_consecutiveFailures[instanceId] ?? 0) + 1;
    _consecutiveFailures[instanceId] = count;

    if (count >= maxConsecutiveFailures) {
      _logger.warning(
          'Plugin "$instanceId" exceeded max consecutive failures ($count >= $maxConsecutiveFailures). Disabling plugin instance.');
      try {
        await _lifecycleManager.transitionTo(
          instanceId: instanceId,
          targetState: PluginLifecycleState.disabled,
          reason:
              'Auto-disabled by runtime after $count consecutive execution failures: $reason',
        );
      } catch (e) {
        _logger.error(
            'Failed to transition broken plugin "$instanceId" to disabled: $e');
      }
    }
  }

  void _recordAudit(
    String pluginId,
    String operation,
    PluginExecutionStatus status,
    int durationMs,
    String? details,
  ) {
    _auditLog.add(ExecutionAuditRecord(
      pluginId: pluginId,
      operation: operation,
      status: status,
      durationMs: durationMs,
      details: details,
    ));
  }
}
