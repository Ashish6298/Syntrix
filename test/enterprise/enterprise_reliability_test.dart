import 'dart:io';
import 'package:syntrix/src/enterprise/enterprise.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 9.13: Enterprise Reliability Models & State Serialization', () {
    test('OperationCheckpoint serialization and deserialization', () {
      final chk = OperationCheckpoint(
        checkpointId: 'chk_publish_01',
        workflowId: 'wf_rel_100',
        stageId: 'stg_13_publish',
        stageName: 'Package Publishing',
        status: CheckpointStatus.completed,
        isDestructiveOperation: true,
        isCompleted: true,
        stateData: {'pub_url': 'https://pub.enterprise.internal/pkg'},
        createdAt: DateTime.parse('2026-09-04T12:00:00Z'),
        updatedAt: DateTime.parse('2026-09-04T12:05:00Z'),
      );

      final json = chk.toJson();
      final restored = OperationCheckpoint.fromJson(json);

      expect(restored.checkpointId, equals('chk_publish_01'));
      expect(restored.stageId, equals('stg_13_publish'));
      expect(restored.isDestructiveOperation, isTrue);
      expect(restored.isCompleted, isTrue);
      expect(restored.stateData['pub_url'],
          equals('https://pub.enterprise.internal/pkg'));
    });

    test('PersistentExecutionState serialization and deserialization', () {
      final state = PersistentExecutionState(
        workflowId: 'wf_crash_test',
        targetPackageName: 'resilient_pkg',
        targetVersion: '2.0.0',
        initiatorId: 'admin_user',
        executionStatus: CheckpointStatus.interrupted,
        lastCompletedStageId: 'stg_08_artifact_build',
        checkpoints: [
          OperationCheckpoint(
            checkpointId: 'chk_08',
            workflowId: 'wf_crash_test',
            stageId: 'stg_08_artifact_build',
            stageName: 'Artifact Build',
            status: CheckpointStatus.completed,
            isDestructiveOperation: false,
            isCompleted: true,
            createdAt: DateTime.parse('2026-09-04T12:00:00Z'),
            updatedAt: DateTime.parse('2026-09-04T12:02:00Z'),
          ),
        ],
        startedAt: DateTime.parse('2026-09-04T12:00:00Z'),
        lastHeartbeat: DateTime.parse('2026-09-04T12:03:00Z'),
      );

      final json = state.toJson();
      final restored = PersistentExecutionState.fromJson(json);

      expect(restored.workflowId, equals('wf_crash_test'));
      expect(restored.targetPackageName, equals('resilient_pkg'));
      expect(restored.isInterrupted, isTrue);
      expect(restored.lastCompletedStageId, equals('stg_08_artifact_build'));
      expect(restored.checkpoints.length, equals(1));
    });
  });

  group('Phase 9.13: Enterprise Reliability & Recovery Engine Operations', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_rel_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Persists state, marks interrupted, and lists active executions',
        () async {
      final auditEngine = EnterpriseAuditEngine(projectRoot: tempDir.path);
      final reliabilityEngine = EnterpriseReliabilityEngine(
        projectRoot: tempDir.path,
        auditEngine: auditEngine,
      );

      const initiator = EnterpriseIdentity(
        id: 'dev_rel',
        displayName: 'Release Engineer',
        roles: [EnterpriseRole.releaseManager],
      );

      final plan = EnterpriseWorkflowPlan.standardEnterprisePipeline(
        targetPackageName: 'interrupted_pkg',
        targetVersion: '1.0.0',
        initiator: initiator,
      );

      // Initialize
      var state = await reliabilityEngine.initializeState(plan);
      expect(state.executionStatus, equals(CheckpointStatus.active));

      // Checkpoint first 3 stages
      for (int i = 0; i < 3; i++) {
        final stage = plan.stages[i];
        state = await reliabilityEngine.recordCheckpoint(
          currentState: state,
          stage: stage,
          status: CheckpointStatus.completed,
          isCompleted: true,
          stateData: {'stage_step': i + 1},
        );
      }

      expect(state.checkpoints.length, equals(3));
      expect(state.lastCompletedStageId, equals('stg_03_ai_review'));

      // Simulate crash / interruption
      final interrupted =
          await reliabilityEngine.markInterrupted(plan.workflowId);
      expect(interrupted, isNotNull);
      expect(interrupted!.isInterrupted, isTrue);

      final list = await reliabilityEngine.listActiveOrInterruptedExecutions();
      expect(list.length, equals(1));
      expect(list.first.workflowId, equals(plan.workflowId));
    });

    test(
        'Resumes interrupted workflow with Idempotency Guard preventing duplicate destructive ops',
        () async {
      final auditEngine = EnterpriseAuditEngine(projectRoot: tempDir.path);
      final workflowEngine = EnterpriseWorkflowEngine(auditEngine: auditEngine);
      final reliabilityEngine = EnterpriseReliabilityEngine(
        projectRoot: tempDir.path,
        auditEngine: auditEngine,
        workflowEngine: workflowEngine,
      );

      const initiator = EnterpriseIdentity(
        id: 'dev_rel',
        displayName: 'Release Engineer',
        roles: [EnterpriseRole.releaseManager],
      );

      final plan = EnterpriseWorkflowPlan.standardEnterprisePipeline(
        targetPackageName: 'idempotent_pkg',
        targetVersion: '1.0.0',
        initiator: initiator,
      );

      var state = await reliabilityEngine.initializeState(plan);

      // Mark stages up to package publishing (destructive stage 13) as ALREADY completed in prior crash
      for (int i = 0; i < 13; i++) {
        final stage = plan.stages[i];
        state = await reliabilityEngine.recordCheckpoint(
          currentState: state,
          stage: stage,
          status: CheckpointStatus.completed,
          isCompleted: true,
          stateData: {'simulated_prior_result': 'OK'},
        );
      }

      await reliabilityEngine.markInterrupted(plan.workflowId);

      // Execute Resume
      final recoveryResult = await reliabilityEngine.resumeInterruptedWorkflow(
        plan: plan,
        actorIdentity: initiator,
      );

      expect(recoveryResult.isSuccess, isTrue);
      expect(recoveryResult.operationType, equals('RESUME'));
      expect(recoveryResult.recoveredCheckpointsCount, equals(13));
      expect(recoveryResult.skippedDestructiveOperations,
          greaterThanOrEqualTo(2)); // gitRelease and packagePublish skipped!
      expect(
          recoveryResult.actionsTaken
              .any((a) => a.contains('IDEMPOTENCY GUARD')),
          isTrue);

      // State on disk should now be completed
      final finalState = await reliabilityEngine.loadState(plan.workflowId);
      expect(finalState, isNotNull);
      expect(finalState!.executionStatus, equals(CheckpointStatus.completed));
    });

    test('Rollback safely compensates completed stages and records audit trail',
        () async {
      final auditEngine = EnterpriseAuditEngine(projectRoot: tempDir.path);
      final reliabilityEngine = EnterpriseReliabilityEngine(
        projectRoot: tempDir.path,
        auditEngine: auditEngine,
      );

      const initiator = EnterpriseIdentity(
        id: 'admin_user',
        displayName: 'Admin User',
        roles: [EnterpriseRole.administrator],
      );

      final plan = EnterpriseWorkflowPlan.standardEnterprisePipeline(
        targetPackageName: 'rollback_pkg',
        targetVersion: '2.5.0',
        initiator: initiator,
      );

      var state = await reliabilityEngine.initializeState(plan);
      for (int i = 0; i < 5; i++) {
        state = await reliabilityEngine.recordCheckpoint(
          currentState: state,
          stage: plan.stages[i],
          status: CheckpointStatus.completed,
          isCompleted: true,
        );
      }

      final rollbackResult = await reliabilityEngine.rollbackWorkflow(
        workflowId: plan.workflowId,
        actorIdentity: initiator,
        reason: 'Severe vulnerability discovered in dependency tree',
      );

      expect(rollbackResult.isSuccess, isTrue);
      expect(rollbackResult.operationType, equals('ROLLBACK'));
      expect(
          rollbackResult.actionsTaken
              .any((a) => a.contains('Compensating/Rolling back')),
          isTrue);

      final rolledBackState =
          await reliabilityEngine.loadState(plan.workflowId);
      expect(rolledBackState!.executionStatus,
          equals(CheckpointStatus.rolledBack));
      expect(
          auditEngine.inMemoryRecords
              .any((r) => r.operation == 'WORKFLOW_ROLLBACK'),
          isTrue);
    });

    test('Gracefully handles corrupted state files without crashing', () async {
      final reliabilityEngine =
          EnterpriseReliabilityEngine(projectRoot: tempDir.path);

      // Write corrupted JSON to recovery dir
      final recoveryDir = Directory('${tempDir.path}/.fps/recovery');
      recoveryDir.createSync(recursive: true);
      File('${recoveryDir.path}/corrupt_wf.state.json')
          .writeAsStringSync('{ INVALID JSON MALFORMED CORRUPTED ...');

      final loaded = await reliabilityEngine.loadState('corrupt_wf');
      expect(loaded, isNull);

      // Corrupted file was quarantined
      final quarantined = recoveryDir
          .listSync()
          .where((e) => e.path.contains('.corrupt_'))
          .toList();
      expect(quarantined, isNotEmpty);
    });
  });

  group('Phase 9.13: Enterprise Reliability Renderer', () {
    test('Renders Markdown report and JSON payload accurately', () {
      final result = RecoveryOperationResult(
        workflowId: 'wf_rec_999',
        isSuccess: true,
        operationType: 'RESUME',
        recoveredCheckpointsCount: 10,
        skippedDestructiveOperations: 2,
        actionsTaken: [
          'Recovered execution state for workflow "wf_rec_999"',
          'IDEMPOTENCY GUARD: Stage "Git Release & Tagging" skipped.',
          'Resumed workflow execution finished with status: COMPLETED',
        ],
        executedAt: DateTime.parse('2026-09-04T12:00:00Z'),
      );

      final markdown = EnterpriseReliabilityRenderer.renderMarkdown(result);
      expect(markdown,
          contains('# Enterprise Recovery & Disaster Readiness Report'));
      expect(markdown, contains('**Workflow ID:** `wf_rec_999`'));
      expect(markdown,
          contains('**Destructive Ops Skipped (Idempotency Guard):** 2'));
      expect(markdown, contains('IDEMPOTENCY GUARD'));

      final jsonString = EnterpriseReliabilityRenderer.renderJson(result);
      expect(jsonString, contains('"workflow_id": "wf_rec_999"'));
      expect(jsonString, contains('"is_success": true'));
      expect(jsonString, contains('"recovered_checkpoints_count": 10'));
    });
  });
}
