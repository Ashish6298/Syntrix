/// Core execution engine for template hooks.
library;

import 'dart:async';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_action.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_context.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_phase.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_policy.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_registry.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_result.dart';
import 'package:flutter_package_studio_core/src/template/hooks/template_hook.dart';

/// Orchestrates execution of registered hooks across lifecycle phases.
class TemplateHookEngine {
  final TemplateHookRegistry registry;
  final Logger _logger = Logger('TemplateHookEngine');

  /// Creates a [TemplateHookEngine] using [registry].
  TemplateHookEngine({
    TemplateHookRegistry? registry,
  }) : registry = registry ?? TemplateHookRegistry();

  /// Executes hooks registered for [phase] within [context].
  ///
  /// Returns [TemplateHookLifecycleReport] summarizing execution results.
  Future<TemplateHookLifecycleReport> executePhase({
    required TemplateHookPhase phase,
    required TemplateHookContext context,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final stopwatch = Stopwatch()..start();
    _logger.info(
        'Executing hook lifecycle phase: ${phase.displayName} (dryRun: ${context.dryRun})');

    final hooks = registry.resolveHooksForPhase(phase);
    final results = <TemplateHookResult>[];
    final aggregatedActions = <TemplateHookAction>[];
    var overallSuccess = true;

    for (final hook in hooks) {
      if (!hook.enabled) {
        results.add(TemplateHookResult.skipped(
          hookId: hook.id,
          phase: phase,
          reason: 'Hook disabled',
        ));
        continue;
      }

      final hookStopwatch = Stopwatch()..start();

      try {
        final Future<TemplateHookResult> execFuture =
            Future.sync(() => hook.execute(context));

        final result = await execFuture.timeout(
          timeout,
          onTimeout: () {
            throw TemplateHookTimeoutException(
                'Hook "${hook.id}" timed out after ${timeout.inMilliseconds}ms during phase ${phase.name}.');
          },
        );

        hookStopwatch.stop();

        final finalResult = TemplateHookResult(
          hookId: hook.id,
          phase: phase,
          status: result.status,
          duration: hookStopwatch.elapsed,
          diagnostics: result.diagnostics,
          proposedActions: result.proposedActions,
          errorMessage: result.errorMessage,
        );

        results.add(finalResult);

        if (finalResult.isSuccessful) {
          aggregatedActions.addAll(finalResult.proposedActions);
        } else {
          overallSuccess = false;
          _handlePolicyFailure(hook, finalResult.errorMessage ?? 'Hook failed',
              phase: phase);
        }
      } catch (e, st) {
        hookStopwatch.stop();
        final redactedErrMsg = TemplateHookContext.redactSecrets(e.toString());

        _logger.error(
            'Error executing hook "${hook.id}" in phase ${phase.name}: $redactedErrMsg',
            e,
            st);

        final failedResult = TemplateHookResult.failure(
          hookId: hook.id,
          phase: phase,
          duration: hookStopwatch.elapsed,
          error: redactedErrMsg,
        );

        results.add(failedResult);

        if (hook.failurePolicy == TemplateHookPolicy.warningOnly) {
          // Converted to warning
          final warnResult = TemplateHookResult(
            hookId: hook.id,
            phase: phase,
            status: TemplateHookStatus.warning,
            duration: hookStopwatch.elapsed,
            errorMessage: 'Warning: $redactedErrMsg',
          );
          results[results.length - 1] = warnResult;
        } else if (hook.failurePolicy == TemplateHookPolicy.failFast) {
          overallSuccess = false;
          if (e is TemplateHookException) {
            rethrow;
          }
          throw TemplateHookExecutionException(
            'Hook "${hook.id}" failed in phase ${phase.name}: $redactedErrMsg',
            e,
            st,
          );
        } else {
          // continueOnError
          overallSuccess = false;
        }
      }
    }

    stopwatch.stop();

    return TemplateHookLifecycleReport(
      templateId: context.metadata['templateId'] as String? ?? 'unknown',
      isSuccess: overallSuccess,
      isDryRun: context.dryRun,
      results: results,
      aggregatedActions: aggregatedActions,
      totalDuration: stopwatch.elapsed,
    );
  }

  void _handlePolicyFailure(TemplateHook hook, String error,
      {required TemplateHookPhase phase}) {
    switch (hook.failurePolicy) {
      case TemplateHookPolicy.failFast:
        throw TemplateHookExecutionException(
          'Hook "${hook.id}" failed in phase ${phase.name}: $error',
        );
      case TemplateHookPolicy.continueOnError:
      case TemplateHookPolicy.warningOnly:
        _logger.warning(
            'Hook "${hook.id}" failed with non-fatal policy (${hook.failurePolicy.name}): $error');
        break;
    }
  }
}
