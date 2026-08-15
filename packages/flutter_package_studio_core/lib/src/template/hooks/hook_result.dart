/// Result and diagnostic models for template hooks.
library;

import 'package:flutter_package_studio_core/src/template/hooks/hook_action.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_context.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_phase.dart';

/// Diagnostic level for hook execution logs.
enum TemplateHookDiagnosticLevel {
  /// Informational log level.
  info,

  /// Warning log level.
  warning,

  /// Error log level.
  error;
}

/// Represents an individual diagnostic entry logged during hook execution.
class TemplateHookDiagnostic {
  /// Level of severity.
  final TemplateHookDiagnosticLevel level;

  /// Human-readable log message (secrets automatically redacted).
  final String message;

  /// Hook ID associated with this diagnostic entry.
  final String hookId;

  /// Lifecycle phase during which the entry was logged.
  final TemplateHookPhase phase;

  /// Timestamp when diagnostic was created.
  final DateTime timestamp;

  /// Creates a [TemplateHookDiagnostic].
  TemplateHookDiagnostic({
    required this.level,
    required String message,
    required this.hookId,
    required this.phase,
    DateTime? timestamp,
  })  : message = TemplateHookContext.redactSecrets(message),
        timestamp = timestamp ?? DateTime.now();

  /// Serializes diagnostic entry to JSON.
  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'hookId': hookId,
      'phase': phase.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Execution status of a single hook.
enum TemplateHookStatus {
  /// Hook completed execution successfully.
  success,

  /// Hook failed during execution.
  failed,

  /// Hook was skipped (e.g. disabled or un-met condition).
  skipped,

  /// Hook finished with warnings.
  warning;
}

/// Structured outcome of executing a single [TemplateHook].
class TemplateHookResult {
  /// Unique identifier of the hook.
  final String hookId;

  /// Target lifecycle phase.
  final TemplateHookPhase phase;

  /// Final execution status.
  final TemplateHookStatus status;

  /// Execution duration.
  final Duration duration;

  /// List of diagnostic entries emitted during hook execution.
  final List<TemplateHookDiagnostic> diagnostics;

  /// List of proposed declarative actions returned by the hook.
  final List<TemplateHookAction> proposedActions;

  /// Error details if the hook failed.
  final String? errorMessage;

  /// Creates a [TemplateHookResult].
  const TemplateHookResult({
    required this.hookId,
    required this.phase,
    required this.status,
    required this.duration,
    this.diagnostics = const [],
    this.proposedActions = const [],
    this.errorMessage,
  });

  /// Factory constructor for successful execution.
  factory TemplateHookResult.success({
    required String hookId,
    required TemplateHookPhase phase,
    required Duration duration,
    List<TemplateHookDiagnostic> diagnostics = const [],
    List<TemplateHookAction> proposedActions = const [],
  }) {
    return TemplateHookResult(
      hookId: hookId,
      phase: phase,
      status: TemplateHookStatus.success,
      duration: duration,
      diagnostics: diagnostics,
      proposedActions: proposedActions,
    );
  }

  /// Factory constructor for failed execution.
  factory TemplateHookResult.failure({
    required String hookId,
    required TemplateHookPhase phase,
    required Duration duration,
    required String error,
    List<TemplateHookDiagnostic> diagnostics = const [],
  }) {
    final redactedErr = TemplateHookContext.redactSecrets(error);
    return TemplateHookResult(
      hookId: hookId,
      phase: phase,
      status: TemplateHookStatus.failed,
      duration: duration,
      errorMessage: redactedErr,
      diagnostics: diagnostics,
    );
  }

  /// Factory constructor for skipped execution.
  factory TemplateHookResult.skipped({
    required String hookId,
    required TemplateHookPhase phase,
    String reason = 'Hook disabled or skipped',
  }) {
    return TemplateHookResult(
      hookId: hookId,
      phase: phase,
      status: TemplateHookStatus.skipped,
      duration: Duration.zero,
      diagnostics: [
        TemplateHookDiagnostic(
          level: TemplateHookDiagnosticLevel.info,
          message: reason,
          hookId: hookId,
          phase: phase,
        ),
      ],
    );
  }

  /// Indicates if this result represents a success or warning status.
  bool get isSuccessful =>
      status == TemplateHookStatus.success ||
      status == TemplateHookStatus.warning ||
      status == TemplateHookStatus.skipped;

  /// Serializes result to JSON.
  Map<String, dynamic> toJson() {
    return {
      'hookId': hookId,
      'phase': phase.name,
      'status': status.name,
      'durationMs': duration.inMilliseconds,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'diagnostics': diagnostics.map((d) => d.toJson()).toList(),
      'proposedActions': proposedActions.map((a) => a.toJson()).toList(),
    };
  }
}

/// Aggregated report of running the lifecycle hook engine for a template target.
class TemplateHookLifecycleReport {
  /// Target template identifier.
  final String templateId;

  /// Overall success flag of the lifecycle execution.
  final bool isSuccess;

  /// Flag indicating if execution was performed in dry-run mode.
  final bool isDryRun;

  /// Execution results per executed hook.
  final List<TemplateHookResult> results;

  /// Aggregated proposed actions from all executed hooks.
  final List<TemplateHookAction> aggregatedActions;

  /// Total duration of all hook executions.
  final Duration totalDuration;

  /// Creates a [TemplateHookLifecycleReport].
  const TemplateHookLifecycleReport({
    required this.templateId,
    required this.isSuccess,
    required this.isDryRun,
    required this.results,
    required this.aggregatedActions,
    required this.totalDuration,
  });

  /// Serializes report to JSON.
  Map<String, dynamic> toJson() {
    return {
      'templateId': templateId,
      'isSuccess': isSuccess,
      'isDryRun': isDryRun,
      'totalDurationMs': totalDuration.inMilliseconds,
      'hookCount': results.length,
      'actionCount': aggregatedActions.length,
      'results': results.map((r) => r.toJson()).toList(),
      'aggregatedActions': aggregatedActions.map((a) => a.toJson()).toList(),
    };
  }
}
