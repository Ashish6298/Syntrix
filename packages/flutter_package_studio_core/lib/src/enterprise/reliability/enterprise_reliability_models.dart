/// Domain models and abstractions for Phase 9.13: Enterprise Reliability, Recovery & Disaster Readiness.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/enterprise/orchestration/enterprise_orchestration_models.dart';

/// Status of an operation checkpoint or recovery state.
enum CheckpointStatus {
  active,
  completed,
  failed,
  interrupted,
  rolledBack;

  String get label => name.toUpperCase();

  bool get isTerminal =>
      this == CheckpointStatus.completed ||
      this == CheckpointStatus.failed ||
      this == CheckpointStatus.rolledBack;
}

/// A stage checkpoint within a persistent workflow execution.
class OperationCheckpoint {
  final String checkpointId;
  final String workflowId;
  final String stageId;
  final String stageName;
  final CheckpointStatus status;
  final bool isDestructiveOperation;
  final bool isCompleted;
  final Map<String, dynamic> stateData;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OperationCheckpoint({
    required this.checkpointId,
    required this.workflowId,
    required this.stageId,
    required this.stageName,
    required this.status,
    this.isDestructiveOperation = false,
    this.isCompleted = false,
    this.stateData = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'checkpoint_id': checkpointId,
        'workflow_id': workflowId,
        'stage_id': stageId,
        'stage_name': stageName,
        'status': status.name,
        'is_destructive_operation': isDestructiveOperation,
        'is_completed': isCompleted,
        'state_data': stateData,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory OperationCheckpoint.fromJson(Map<String, dynamic> json) {
    return OperationCheckpoint(
      checkpointId: json['checkpoint_id'] as String? ?? 'chk_unknown',
      workflowId: json['workflow_id'] as String? ?? 'wf_unknown',
      stageId: json['stage_id'] as String? ?? 'stg_unknown',
      stageName: json['stage_name'] as String? ?? 'Unknown Stage',
      status: CheckpointStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CheckpointStatus.failed,
      ),
      isDestructiveOperation: json['is_destructive_operation'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      stateData: (json['state_data'] as Map<String, dynamic>?) ?? const {},
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Complete persisted state of an interrupted or in-flight enterprise workflow execution.
class PersistentExecutionState {
  final String workflowId;
  final String targetPackageName;
  final String targetVersion;
  final String initiatorId;
  final CheckpointStatus executionStatus;
  final String? lastCompletedStageId;
  final List<OperationCheckpoint> checkpoints;
  final Map<String, dynamic> completedStageResults;
  final DateTime startedAt;
  final DateTime lastHeartbeat;

  const PersistentExecutionState({
    required this.workflowId,
    required this.targetPackageName,
    required this.targetVersion,
    required this.initiatorId,
    required this.executionStatus,
    this.lastCompletedStageId,
    this.checkpoints = const [],
    this.completedStageResults = const {},
    required this.startedAt,
    required this.lastHeartbeat,
  });

  bool get isInterrupted => executionStatus == CheckpointStatus.interrupted;
  bool get canResume =>
      executionStatus == CheckpointStatus.interrupted ||
      executionStatus == CheckpointStatus.active;

  Map<String, dynamic> toJson() => {
        'workflow_id': workflowId,
        'target_package_name': targetPackageName,
        'target_version': targetVersion,
        'initiator_id': initiatorId,
        'execution_status': executionStatus.name,
        'last_completed_stage_id': lastCompletedStageId,
        'checkpoints': checkpoints.map((c) => c.toJson()).toList(),
        'completed_stage_results': completedStageResults,
        'started_at': startedAt.toIso8601String(),
        'last_heartbeat': lastHeartbeat.toIso8601String(),
      };

  factory PersistentExecutionState.fromJson(Map<String, dynamic> json) {
    return PersistentExecutionState(
      workflowId: json['workflow_id'] as String? ?? '',
      targetPackageName: json['target_package_name'] as String? ?? 'unknown',
      targetVersion: json['target_version'] as String? ?? '0.0.0',
      initiatorId: json['initiator_id'] as String? ?? 'anonymous',
      executionStatus: CheckpointStatus.values.firstWhere(
        (e) => e.name == json['execution_status'],
        orElse: () => CheckpointStatus.failed,
      ),
      lastCompletedStageId: json['last_completed_stage_id'] as String?,
      checkpoints: (json['checkpoints'] as List<dynamic>?)
              ?.map((c) => OperationCheckpoint.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      completedStageResults: (json['completed_stage_results'] as Map<String, dynamic>?) ?? const {},
      startedAt: DateTime.parse(json['started_at'] as String),
      lastHeartbeat: DateTime.parse(json['last_heartbeat'] as String),
    );
  }
}

/// Result of a recovery, resume, or rollback operation.
class RecoveryOperationResult {
  final String workflowId;
  final bool isSuccess;
  final String operationType; // 'RESUME', 'ROLLBACK', 'REPAIR'
  final int recoveredCheckpointsCount;
  final int skippedDestructiveOperations;
  final List<String> actionsTaken;
  final String? errorMessage;
  final DateTime executedAt;

  const RecoveryOperationResult({
    required this.workflowId,
    required this.isSuccess,
    required this.operationType,
    required this.recoveredCheckpointsCount,
    required this.skippedDestructiveOperations,
    required this.actionsTaken,
    this.errorMessage,
    required this.executedAt,
  });

  Map<String, dynamic> toJson() => {
        'workflow_id': workflowId,
        'is_success': isSuccess,
        'operation_type': operationType,
        'recovered_checkpoints_count': recoveredCheckpointsCount,
        'skipped_destructive_operations': skippedDestructiveOperations,
        'actions_taken': actionsTaken,
        'error_message': errorMessage,
        'executed_at': executedAt.toIso8601String(),
      };

  factory RecoveryOperationResult.fromJson(Map<String, dynamic> json) {
    return RecoveryOperationResult(
      workflowId: json['workflow_id'] as String? ?? '',
      isSuccess: json['is_success'] as bool? ?? false,
      operationType: json['operation_type'] as String? ?? 'RESUME',
      recoveredCheckpointsCount: json['recovered_checkpoints_count'] as int? ?? 0,
      skippedDestructiveOperations: json['skipped_destructive_operations'] as int? ?? 0,
      actionsTaken: (json['actions_taken'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      errorMessage: json['error_message'] as String?,
      executedAt: DateTime.parse(json['executed_at'] as String),
    );
  }
}
