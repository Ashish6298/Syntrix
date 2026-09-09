/// Domain models and structured results for the Plugin Execution Runtime.
library;

/// Status outcome of an isolated plugin invocation.
enum PluginExecutionStatus {
  success,
  failed,
  timedOut,
  rejectedNotActive,
  unsupportedContribution,
  permissionDenied,
}

/// Structured outcome of a single plugin invocation.
class PluginExecutionResult<T> {
  final String pluginId;
  final String operation;
  final PluginExecutionStatus status;
  final T? value;
  final String? errorMessage;
  final String? stackTrace;
  final int durationMs;
  final DateTime timestamp;

  PluginExecutionResult({
    required this.pluginId,
    required this.operation,
    required this.status,
    this.value,
    this.errorMessage,
    this.stackTrace,
    required this.durationMs,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isSuccess => status == PluginExecutionStatus.success;

  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'operation': operation,
        'status': status.name,
        'value': value,
        'errorMessage': errorMessage,
        'stackTrace': stackTrace,
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Aggregated result of running a batch of plugins.
class PluginBatchExecutionResult {
  final String capabilityName;
  final List<PluginExecutionResult<dynamic>> results;
  final int totalDurationMs;

  const PluginBatchExecutionResult({
    required this.capabilityName,
    required this.results,
    required this.totalDurationMs,
  });

  int get totalCount => results.length;
  int get successCount =>
      results.where((r) => r.status == PluginExecutionStatus.success).length;
  int get failureCount =>
      results.where((r) => r.status == PluginExecutionStatus.failed).length;
  int get timeoutCount =>
      results.where((r) => r.status == PluginExecutionStatus.timedOut).length;
  int get rejectedCount => results
      .where((r) =>
          r.status == PluginExecutionStatus.rejectedNotActive ||
          r.status == PluginExecutionStatus.unsupportedContribution ||
          r.status == PluginExecutionStatus.permissionDenied)
      .length;

  bool get isAllSuccessful => successCount == totalCount && totalCount > 0;

  Map<String, dynamic> toJson() => {
        'capabilityName': capabilityName,
        'totalCount': totalCount,
        'successCount': successCount,
        'failureCount': failureCount,
        'timeoutCount': timeoutCount,
        'rejectedCount': rejectedCount,
        'totalDurationMs': totalDurationMs,
        'results': results.map((r) => r.toJson()).toList(),
      };
}

/// Immutable audit record capturing a plugin execution event.
class ExecutionAuditRecord {
  final String pluginId;
  final String operation;
  final PluginExecutionStatus status;
  final int durationMs;
  final String? details;
  final DateTime timestamp;

  ExecutionAuditRecord({
    required this.pluginId,
    required this.operation,
    required this.status,
    required this.durationMs,
    this.details,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'operation': operation,
        'status': status.name,
        'durationMs': durationMs,
        'details': details,
        'timestamp': timestamp.toIso8601String(),
      };
}
