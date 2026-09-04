/// Domain models and abstractions for Phase 9.10: Enterprise Remote Execution & Controlled Workers.
library;

import 'dart:convert';

/// Status of a worker machine or process.
enum WorkerHealthStatus {
  healthy,
  busy,
  degraded,
  unhealthy,
  offline;

  String get label => name.toUpperCase();
}

/// Execution status of a remote/worker job.
enum WorkerExecutionStatus {
  queued,
  running,
  completed,
  failed,
  cancelled,
  timedOut;

  String get label => name.toUpperCase();

  bool get isTerminal =>
      this == WorkerExecutionStatus.completed ||
      this == WorkerExecutionStatus.failed ||
      this == WorkerExecutionStatus.cancelled ||
      this == WorkerExecutionStatus.timedOut;
}

/// Capability tags supported by a worker.
enum WorkerCapability {
  buildArtifacts,
  runTestSuite,
  runSecurityAudit,
  aiAnalysis,
  packagePublishing,
  codeFormatting,
  analyzerCheck;

  String get id => name;

  static WorkerCapability fromString(String? val) {
    if (val == null) return WorkerCapability.buildArtifacts;
    return WorkerCapability.values.firstWhere(
      (c) => c.name.toLowerCase() == val.toLowerCase(),
      orElse: () => WorkerCapability.buildArtifacts,
    );
  }
}

/// Resource limits applied to worker executions.
class WorkerResourceLimits {
  final int maxMemoryMb;
  final int maxCpuCores;
  final Duration timeout;
  final int maxDiskSpaceMb;

  const WorkerResourceLimits({
    this.maxMemoryMb = 2048,
    this.maxCpuCores = 2,
    this.timeout = const Duration(minutes: 10),
    this.maxDiskSpaceMb = 4096,
  });

  Map<String, dynamic> toJson() => {
        'max_memory_mb': maxMemoryMb,
        'max_cpu_cores': maxCpuCores,
        'timeout_seconds': timeout.inSeconds,
        'max_disk_space_mb': maxDiskSpaceMb,
      };

  factory WorkerResourceLimits.fromJson(Map<String, dynamic> json) {
    return WorkerResourceLimits(
      maxMemoryMb: json['max_memory_mb'] as int? ?? 2048,
      maxCpuCores: json['max_cpu_cores'] as int? ?? 2,
      timeout: Duration(seconds: json['timeout_seconds'] as int? ?? 600),
      maxDiskSpaceMb: json['max_disk_space_mb'] as int? ?? 4096,
    );
  }
}

/// Information and metadata regarding a registered worker instance.
class ControlledWorkerInfo {
  final String workerId;
  final String displayName;
  final String host;
  final List<WorkerCapability> capabilities;
  final WorkerHealthStatus healthStatus;
  final WorkerResourceLimits capacity;
  final int activeTaskCount;
  final DateTime registeredAt;
  final DateTime lastHeartbeat;
  final Map<String, dynamic> metadata;

  const ControlledWorkerInfo({
    required this.workerId,
    required this.displayName,
    this.host = 'localhost',
    required this.capabilities,
    this.healthStatus = WorkerHealthStatus.healthy,
    this.capacity = const WorkerResourceLimits(),
    this.activeTaskCount = 0,
    required this.registeredAt,
    required this.lastHeartbeat,
    this.metadata = const {},
  });

  bool get isAvailable =>
      healthStatus == WorkerHealthStatus.healthy && activeTaskCount < capacity.maxCpuCores;

  Map<String, dynamic> toJson() => {
        'worker_id': workerId,
        'display_name': displayName,
        'host': host,
        'capabilities': capabilities.map((c) => c.id).toList(),
        'health_status': healthStatus.name,
        'capacity': capacity.toJson(),
        'active_task_count': activeTaskCount,
        'registered_at': registeredAt.toIso8601String(),
        'last_heartbeat': lastHeartbeat.toIso8601String(),
        'metadata': metadata,
      };

  factory ControlledWorkerInfo.fromJson(Map<String, dynamic> json) {
    return ControlledWorkerInfo(
      workerId: json['worker_id'] as String? ?? 'w_unknown',
      displayName: json['display_name'] as String? ?? 'Unnamed Worker',
      host: json['host'] as String? ?? 'localhost',
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((c) => WorkerCapability.fromString(c.toString()))
              .toList() ??
          const [],
      healthStatus: WorkerHealthStatus.values.firstWhere(
        (s) => s.name == json['health_status'],
        orElse: () => WorkerHealthStatus.healthy,
      ),
      capacity: json['capacity'] is Map<String, dynamic>
          ? WorkerResourceLimits.fromJson(json['capacity'] as Map<String, dynamic>)
          : const WorkerResourceLimits(),
      activeTaskCount: json['active_task_count'] as int? ?? 0,
      registeredAt: json['registered_at'] is String
          ? DateTime.parse(json['registered_at'] as String)
          : DateTime.now(),
      lastHeartbeat: json['last_heartbeat'] is String
          ? DateTime.parse(json['last_heartbeat'] as String)
          : DateTime.now(),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Request to execute an isolated operation via a controlled worker.
class WorkerExecutionRequest {
  final String taskId;
  final String taskType;
  final WorkerCapability requiredCapability;
  final Map<String, dynamic> payload;
  final WorkerResourceLimits limits;
  final String requesterId;
  final String correlationId;
  final DateTime createdAt;

  const WorkerExecutionRequest({
    required this.taskId,
    required this.taskType,
    required this.requiredCapability,
    required this.payload,
    this.limits = const WorkerResourceLimits(),
    required this.requesterId,
    required this.correlationId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        'task_type': taskType,
        'required_capability': requiredCapability.id,
        'payload': payload,
        'limits': limits.toJson(),
        'requester_id': requesterId,
        'correlation_id': correlationId,
        'created_at': createdAt.toIso8601String(),
      };

  factory WorkerExecutionRequest.fromJson(Map<String, dynamic> json) {
    return WorkerExecutionRequest(
      taskId: json['task_id'] as String? ?? '',
      taskType: json['task_type'] as String? ?? 'generic_task',
      requiredCapability: WorkerCapability.fromString(json['required_capability'] as String?),
      payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
      limits: json['limits'] is Map<String, dynamic>
          ? WorkerResourceLimits.fromJson(json['limits'] as Map<String, dynamic>)
          : const WorkerResourceLimits(),
      requesterId: json['requester_id'] as String? ?? 'system',
      correlationId: json['correlation_id'] as String? ?? 'cid_unknown',
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Result returned from a worker execution.
class WorkerExecutionResult {
  final String taskId;
  final String workerId;
  final WorkerExecutionStatus status;
  final int exitCode;
  final Map<String, dynamic> outputData;
  final String stdoutLog;
  final String stderrLog;
  final String? errorMessage;
  final int durationMs;
  final DateTime startedAt;
  final DateTime completedAt;

  const WorkerExecutionResult({
    required this.taskId,
    required this.workerId,
    required this.status,
    this.exitCode = 0,
    this.outputData = const {},
    this.stdoutLog = '',
    this.stderrLog = '',
    this.errorMessage,
    required this.durationMs,
    required this.startedAt,
    required this.completedAt,
  });

  bool get isSuccess => status == WorkerExecutionStatus.completed && exitCode == 0;

  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        'worker_id': workerId,
        'status': status.name,
        'exit_code': exitCode,
        'output_data': outputData,
        'stdout_log': stdoutLog,
        'stderr_log': stderrLog,
        'error_message': errorMessage,
        'duration_ms': durationMs,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt.toIso8601String(),
      };

  factory WorkerExecutionResult.fromJson(Map<String, dynamic> json) {
    return WorkerExecutionResult(
      taskId: json['task_id'] as String? ?? '',
      workerId: json['worker_id'] as String? ?? 'unknown_worker',
      status: WorkerExecutionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => WorkerExecutionStatus.failed,
      ),
      exitCode: json['exit_code'] as int? ?? 0,
      outputData: (json['output_data'] as Map<String, dynamic>?) ?? const {},
      stdoutLog: json['stdout_log'] as String? ?? '',
      stderrLog: json['stderr_log'] as String? ?? '',
      errorMessage: json['error_message'] as String?,
      durationMs: json['duration_ms'] as int? ?? 0,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }
}
