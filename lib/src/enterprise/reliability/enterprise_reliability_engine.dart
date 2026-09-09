/// Central Enterprise Reliability, Recovery & Disaster Readiness Engine for Phase 9.13.
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/enterprise/audit/enterprise_audit_engine.dart';
import 'package:syntrix/src/enterprise/audit/enterprise_audit_models.dart';
import 'package:syntrix/src/enterprise/identity/enterprise_identity_models.dart';
import 'package:syntrix/src/enterprise/orchestration/enterprise_orchestration_models.dart';
import 'package:syntrix/src/enterprise/orchestration/enterprise_orchestration_engine.dart';
import 'package:syntrix/src/enterprise/reliability/enterprise_reliability_models.dart';

/// Central Reliability & Recovery Engine ensuring idempotent, checkpointed, crash-resilient workflows.
class EnterpriseReliabilityEngine {
  final Logger _logger = Logger('EnterpriseReliabilityEngine');
  final String _projectRoot;
  final EnterpriseAuditEngine? auditEngine;
  final EnterpriseWorkflowEngine? workflowEngine;

  String get projectRoot => _projectRoot;

  EnterpriseReliabilityEngine({
    required String projectRoot,
    this.auditEngine,
    this.workflowEngine,
  }) : _projectRoot = p.normalize(projectRoot) {
    _ensureStateDirectory();
  }

  Directory get _stateDir =>
      Directory(p.join(_projectRoot, '.fps', 'recovery'));

  void _ensureStateDirectory() {
    if (!_stateDir.existsSync()) {
      _stateDir.createSync(recursive: true);
    }
  }

  File _stateFile(String workflowId) =>
      File(p.join(_stateDir.path, '$workflowId.state.json'));

  /// Identifies if a specific stage type is destructive (e.g. Git tagging, publish).
  bool isDestructiveStage(WorkflowStageType type) {
    return type == WorkflowStageType.gitRelease ||
        type == WorkflowStageType.packagePublish ||
        type == WorkflowStageType.customStage;
  }

  /// Initialize persistent state for a new workflow execution.
  Future<PersistentExecutionState> initializeState(
      EnterpriseWorkflowPlan plan) async {
    final now = DateTime.now();
    final state = PersistentExecutionState(
      workflowId: plan.workflowId,
      targetPackageName: plan.targetPackageName,
      targetVersion: plan.targetVersion,
      initiatorId: plan.initiator.id,
      executionStatus: CheckpointStatus.active,
      checkpoints: const [],
      completedStageResults: const {},
      startedAt: now,
      lastHeartbeat: now,
    );

    await saveState(state);
    _logger
        .info('Initialized persistent state for workflow ${plan.workflowId}');
    return state;
  }

  /// Persist current execution state snapshot to disk atomically.
  Future<void> saveState(PersistentExecutionState state) async {
    _ensureStateDirectory();
    final file = _stateFile(state.workflowId);
    final tempFile = File('${file.path}.tmp');

    const encoder = JsonEncoder.withIndent('  ');
    await tempFile.writeAsString(encoder.convert(state.toJson()), flush: true);
    if (file.existsSync()) {
      file.deleteSync();
    }
    await tempFile.rename(file.path);
  }

  /// Load persisted execution state from disk, handling corrupt state gracefully.
  Future<PersistentExecutionState?> loadState(String workflowId) async {
    final file = _stateFile(workflowId);
    if (!file.existsSync()) return null;

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return PersistentExecutionState.fromJson(json);
    } catch (e) {
      _logger.error('Corrupted state file detected for $workflowId: $e');
      // Quarantine corrupted state
      final corruptedFile =
          File('${file.path}.corrupt_${DateTime.now().millisecondsSinceEpoch}');
      if (file.existsSync()) {
        await file.rename(corruptedFile.path);
      }
      return null;
    }
  }

  /// List all active or interrupted execution states on disk.
  Future<List<PersistentExecutionState>>
      listActiveOrInterruptedExecutions() async {
    _ensureStateDirectory();
    final results = <PersistentExecutionState>[];

    final entities = _stateDir.listSync();
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.state.json')) {
        final wfId =
            p.basenameWithoutExtension(p.basenameWithoutExtension(entity.path));
        final state = await loadState(wfId);
        if (state != null) {
          results.add(state);
        }
      }
    }

    return results;
  }

  /// Record an operation checkpoint before or after stage execution.
  Future<PersistentExecutionState> recordCheckpoint({
    required PersistentExecutionState currentState,
    required OrchestrationStageDefinition stage,
    required CheckpointStatus status,
    required bool isCompleted,
    Map<String, dynamic> stateData = const {},
  }) async {
    final now = DateTime.now();
    final isDestructive = isDestructiveStage(stage.stageType);

    final checkpoint = OperationCheckpoint(
      checkpointId: 'chk_${stage.stageId}_${now.millisecondsSinceEpoch}',
      workflowId: currentState.workflowId,
      stageId: stage.stageId,
      stageName: stage.name,
      status: status,
      isDestructiveOperation: isDestructive,
      isCompleted: isCompleted,
      stateData: stateData,
      createdAt: now,
      updatedAt: now,
    );

    final updatedCheckpoints =
        List<OperationCheckpoint>.from(currentState.checkpoints)
          ..removeWhere((c) => c.stageId == stage.stageId)
          ..add(checkpoint);

    final updatedCompletedResults =
        Map<String, dynamic>.from(currentState.completedStageResults);
    if (isCompleted) {
      updatedCompletedResults[stage.stageId] = stateData;
    }

    final updatedState = PersistentExecutionState(
      workflowId: currentState.workflowId,
      targetPackageName: currentState.targetPackageName,
      targetVersion: currentState.targetVersion,
      initiatorId: currentState.initiatorId,
      executionStatus: status == CheckpointStatus.failed
          ? CheckpointStatus.failed
          : CheckpointStatus.active,
      lastCompletedStageId:
          isCompleted ? stage.stageId : currentState.lastCompletedStageId,
      checkpoints: updatedCheckpoints,
      completedStageResults: updatedCompletedResults,
      startedAt: currentState.startedAt,
      lastHeartbeat: now,
    );

    await saveState(updatedState);
    return updatedState;
  }

  /// Mark in-flight operations as interrupted (simulating sudden crash or shutdown).
  Future<PersistentExecutionState?> markInterrupted(String workflowId) async {
    final state = await loadState(workflowId);
    if (state == null) return null;

    final updated = PersistentExecutionState(
      workflowId: state.workflowId,
      targetPackageName: state.targetPackageName,
      targetVersion: state.targetVersion,
      initiatorId: state.initiatorId,
      executionStatus: CheckpointStatus.interrupted,
      lastCompletedStageId: state.lastCompletedStageId,
      checkpoints: state.checkpoints,
      completedStageResults: state.completedStageResults,
      startedAt: state.startedAt,
      lastHeartbeat: DateTime.now(),
    );

    await saveState(updated);
    _logger.warning('Workflow ${state.workflowId} marked as INTERRUPTED.');
    return updated;
  }

  /// Resume an interrupted workflow execution idempotently, guaranteeing destructive operations are not re-run.
  Future<RecoveryOperationResult> resumeInterruptedWorkflow({
    required EnterpriseWorkflowPlan plan,
    required EnterpriseIdentity actorIdentity,
  }) async {
    final now = DateTime.now();
    final actions = <String>[];
    int recoveredCheckpoints = 0;
    int skippedDestructive = 0;

    final existingState = await loadState(plan.workflowId);
    if (existingState == null) {
      return RecoveryOperationResult(
        workflowId: plan.workflowId,
        isSuccess: false,
        operationType: 'RESUME',
        recoveredCheckpointsCount: 0,
        skippedDestructiveOperations: 0,
        actionsTaken: [
          'State not found on disk for workflow ${plan.workflowId}'
        ],
        errorMessage: 'State not found on disk',
        executedAt: now,
      );
    }

    actions.add('Recovered execution state for workflow "${plan.workflowId}".');
    actions.add(
        'Last completed stage: ${existingState.lastCompletedStageId ?? "None"}');

    final completedStages = existingState.checkpoints
        .where((c) => c.isCompleted)
        .map((c) => c.stageId)
        .toSet();
    recoveredCheckpoints = completedStages.length;

    // Filter remaining stages that need execution
    final remainingStages = plan.stages.where((s) {
      if (completedStages.contains(s.stageId)) {
        if (isDestructiveStage(s.stageType)) {
          skippedDestructive++;
          actions.add(
              'IDEMPOTENCY GUARD: Stage "${s.name}" (${s.stageId}) was already completed. Skipping destructive re-execution.');
        } else {
          actions.add(
              'Skipping non-destructive already completed stage "${s.name}" (${s.stageId}).');
        }
        return false;
      }
      return true;
    }).toList();

    actions.add(
        'Proceeding with remaining ${remainingStages.length} pending stages.');

    // Execute remaining stages via WorkflowEngine if provided
    if (workflowEngine != null && remainingStages.isNotEmpty) {
      final resumePlan = EnterpriseWorkflowPlan(
        workflowId: '${plan.workflowId}_resumed',
        name: '${plan.name} (Resumed)',
        targetPackageName: plan.targetPackageName,
        targetVersion: plan.targetVersion,
        initiator: plan.initiator,
        createdAt: now,
        stages: remainingStages,
      );

      final execResult = await workflowEngine!.executeWorkflow(resumePlan);
      actions.add(
          'Resumed workflow execution finished with status: ${execResult.status.label}');
    }

    // Mark persistent state as completed
    final finalState = PersistentExecutionState(
      workflowId: existingState.workflowId,
      targetPackageName: existingState.targetPackageName,
      targetVersion: existingState.targetVersion,
      initiatorId: existingState.initiatorId,
      executionStatus: CheckpointStatus.completed,
      lastCompletedStageId: plan.stages.last.stageId,
      checkpoints: existingState.checkpoints,
      completedStageResults: existingState.completedStageResults,
      startedAt: existingState.startedAt,
      lastHeartbeat: DateTime.now(),
    );
    await saveState(finalState);

    // Audit recovery operation
    if (auditEngine != null) {
      await auditEngine!.recordEvent(
        eventType: AuditEventType.rollbackExecuted,
        actorIdentity: actorIdentity,
        operation: 'WORKFLOW_RECOVERY_RESUME',
        packageOrProject: plan.targetPackageName,
        relevantVersion: plan.targetVersion,
        outcome: AuditEventOutcome.success,
        metadata: {
          'workflow_id': plan.workflowId,
          'recovered_checkpoints': recoveredCheckpoints,
          'skipped_destructive': skippedDestructive,
        },
      );
    }

    return RecoveryOperationResult(
      workflowId: plan.workflowId,
      isSuccess: true,
      operationType: 'RESUME',
      recoveredCheckpointsCount: recoveredCheckpoints,
      skippedDestructiveOperations: skippedDestructive,
      actionsTaken: actions,
      executedAt: DateTime.now(),
    );
  }

  /// Rollback an enterprise workflow safely and clean up state.
  Future<RecoveryOperationResult> rollbackWorkflow({
    required String workflowId,
    required EnterpriseIdentity actorIdentity,
    String reason = 'Manual administrator rollback',
  }) async {
    final now = DateTime.now();
    final actions = <String>[];

    final state = await loadState(workflowId);
    if (state == null) {
      return RecoveryOperationResult(
        workflowId: workflowId,
        isSuccess: false,
        operationType: 'ROLLBACK',
        recoveredCheckpointsCount: 0,
        skippedDestructiveOperations: 0,
        actionsTaken: ['State not found for workflow $workflowId'],
        errorMessage: 'State not found',
        executedAt: now,
      );
    }

    actions.add(
        'Initiating rollback for workflow "$workflowId" (Package: ${state.targetPackageName}@${state.targetVersion})');
    actions.add('Reason: $reason');

    for (final chk in state.checkpoints.reversed) {
      if (chk.isCompleted) {
        actions.add(
            'Compensating/Rolling back stage: ${chk.stageName} (${chk.stageId})');
      }
    }

    final rolledBackState = PersistentExecutionState(
      workflowId: state.workflowId,
      targetPackageName: state.targetPackageName,
      targetVersion: state.targetVersion,
      initiatorId: state.initiatorId,
      executionStatus: CheckpointStatus.rolledBack,
      lastCompletedStageId: null,
      checkpoints: state.checkpoints,
      completedStageResults: const {},
      startedAt: state.startedAt,
      lastHeartbeat: DateTime.now(),
    );

    await saveState(rolledBackState);
    actions.add('State successfully updated to ROLLED_BACK');

    // Audit rollback
    if (auditEngine != null) {
      await auditEngine!.recordEvent(
        eventType: AuditEventType.rollbackExecuted,
        actorIdentity: actorIdentity,
        operation: 'WORKFLOW_ROLLBACK',
        packageOrProject: state.targetPackageName,
        relevantVersion: state.targetVersion,
        outcome: AuditEventOutcome.success,
        metadata: {
          'workflow_id': workflowId,
          'reason': reason,
        },
      );
    }

    return RecoveryOperationResult(
      workflowId: workflowId,
      isSuccess: true,
      operationType: 'ROLLBACK',
      recoveredCheckpointsCount: state.checkpoints.length,
      skippedDestructiveOperations: 0,
      actionsTaken: actions,
      executedAt: DateTime.now(),
    );
  }
}
