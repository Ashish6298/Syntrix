import 'dart:io';
import 'package:flutter_package_studio_core/src/enterprise/enterprise.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 9.11: Enterprise Workflow Orchestration Models & Validation',
      () {
    test('Standard pipeline factory constructs complete 14-stage definition',
        () {
      const initiator = EnterpriseIdentity(
        id: 'user_rel_mgr',
        displayName: 'Alex Release Manager',
        roles: [EnterpriseRole.releaseManager],
      );

      final plan = EnterpriseWorkflowPlan.standardEnterprisePipeline(
        targetPackageName: 'enterprise_core_pkg',
        targetVersion: '1.2.0',
        initiator: initiator,
      );

      expect(plan.stages.length, equals(14));
      expect(plan.stages.first.stageType,
          equals(WorkflowStageType.projectDiscovery));
      expect(
          plan.stages.last.stageType, equals(WorkflowStageType.auditLogging));
      expect(plan.targetPackageName, equals('enterprise_core_pkg'));
      expect(plan.targetVersion, equals('1.2.0'));
    });

    test('Engine detects invalid stage dependency graph', () {
      final engine = EnterpriseWorkflowEngine();
      const initiator = EnterpriseIdentity(
        id: 'user_dev',
        displayName: 'Dev Bob',
        roles: [EnterpriseRole.developer],
      );

      final invalidPlan = EnterpriseWorkflowPlan(
        workflowId: 'wf_invalid',
        name: 'Invalid Dependency Workflow',
        targetPackageName: 'test_pkg',
        targetVersion: '1.0.0',
        initiator: initiator,
        createdAt: DateTime.now(),
        stages: const [
          OrchestrationStageDefinition(
            stageId: 'stg_1',
            stageType: WorkflowStageType.projectDiscovery,
            name: 'Discovery',
            dependsOnStageIds: ['non_existent_stage'],
          ),
        ],
      );

      final errors = engine.validatePlan(invalidPlan);
      expect(errors, isNotEmpty);
      expect(errors.first,
          contains('depends on non-existent stage "non_existent_stage"'));
    });

    test('Engine detects circular dependencies in workflow plan', () {
      final engine = EnterpriseWorkflowEngine();
      const initiator = EnterpriseIdentity(
        id: 'user_dev',
        displayName: 'Dev Bob',
        roles: [EnterpriseRole.developer],
      );

      final circularPlan = EnterpriseWorkflowPlan(
        workflowId: 'wf_cycle',
        name: 'Circular Workflow',
        targetPackageName: 'test_pkg',
        targetVersion: '1.0.0',
        initiator: initiator,
        createdAt: DateTime.now(),
        stages: const [
          OrchestrationStageDefinition(
            stageId: 'stg_A',
            stageType: WorkflowStageType.projectDiscovery,
            name: 'Stage A',
            dependsOnStageIds: ['stg_B'],
          ),
          OrchestrationStageDefinition(
            stageId: 'stg_B',
            stageType: WorkflowStageType.contextAssembly,
            name: 'Stage B',
            dependsOnStageIds: ['stg_A'],
          ),
        ],
      );

      final errors = engine.validatePlan(circularPlan);
      expect(errors, isNotEmpty);
      expect(errors.any((e) => e.contains('Circular dependency detected')),
          isTrue);
    });

    test(
        'Serialization and Deserialization of workflow plan and execution result',
        () {
      const initiator = EnterpriseIdentity(
        id: 'user_admin',
        displayName: 'Super Admin',
        roles: [EnterpriseRole.administrator],
      );

      final plan = EnterpriseWorkflowPlan.standardEnterprisePipeline(
        targetPackageName: 'my_pkg',
        targetVersion: '2.0.0',
        initiator: initiator,
      );

      final json = plan.toJson();
      final restored = EnterpriseWorkflowPlan.fromJson(json);

      expect(restored.workflowId, equals(plan.workflowId));
      expect(restored.stages.length, equals(14));
      expect(
          restored.stages[2].stageType, equals(WorkflowStageType.aiCodeReview));
    });
  });

  group('Phase 9.11: Enterprise Workflow Engine Execution', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_wf_test_');
      final pkgDir = Directory(tempDir.path);
      File('${pkgDir.path}/pubspec.yaml').writeAsStringSync('''
name: enterprise_auth
version: 3.1.0
environment:
  sdk: '>=3.5.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
''');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Executes full 14-stage standard release workflow successfully',
        () async {
      final auditEngine = EnterpriseAuditEngine(projectRoot: tempDir.path);
      final securityEngine =
          EnterpriseSecurityComplianceEngine(projectRoot: tempDir.path);
      final depEngine =
          EnterpriseDependencyGovernanceEngine(projectRoot: tempDir.path);

      final engine = EnterpriseWorkflowEngine(
        auditEngine: auditEngine,
        securityEngine: securityEngine,
        dependencyEngine: depEngine,
      );

      const initiator = EnterpriseIdentity(
        id: 'rel_lead',
        displayName: 'Release Lead',
        roles: [EnterpriseRole.releaseManager, EnterpriseRole.securityAuditor],
      );

      final plan = EnterpriseWorkflowPlan.standardEnterprisePipeline(
        targetPackageName: 'enterprise_auth',
        targetVersion: '3.1.0',
        initiator: initiator,
      );

      final result = await engine.executeWorkflow(plan);

      expect(result.isSuccess, isTrue);
      expect(
          result.status, equals(EnterpriseWorkflowExecutionStatus.completed));
      expect(result.totalStages, equals(14));
      expect(result.passedStages, equals(14));
      expect(result.failedStages, equals(0));
      expect(result.skippedStages, equals(0));
      expect(result.blockedStageId, isNull);

      // Verify audit logs were written
      expect(auditEngine.inMemoryRecords.length, greaterThanOrEqualTo(2));
      expect(engine.executionHistory.length, equals(1));
    });

    test('Halts downstream stages when mandatory gate (Security Audit) fails',
        () async {
      const initiator = EnterpriseIdentity(
        id: 'rel_lead',
        displayName: 'Release Lead',
        roles: [EnterpriseRole.releaseManager],
      );

      // Construct standard plan but inject security violation
      final standardPlan = EnterpriseWorkflowPlan.standardEnterprisePipeline(
        targetPackageName: 'leaky_pkg',
        targetVersion: '1.0.0',
        initiator: initiator,
      );

      final modifiedStages = standardPlan.stages.map((s) {
        if (s.stageType == WorkflowStageType.securityAudit) {
          return OrchestrationStageDefinition(
            stageId: s.stageId,
            stageType: s.stageType,
            name: s.name,
            dependsOnStageIds: s.dependsOnStageIds,
            isMandatoryGate: true,
            stageConfig: const {'mock_secret_detected': true},
          );
        }
        return s;
      }).toList();

      final securityFailingPlan = EnterpriseWorkflowPlan(
        workflowId: 'wf_sec_fail',
        name: 'Security Failing Workflow',
        targetPackageName: 'leaky_pkg',
        targetVersion: '1.0.0',
        initiator: initiator,
        createdAt: DateTime.now(),
        stages: modifiedStages,
      );

      final securityEngine =
          EnterpriseSecurityComplianceEngine(projectRoot: tempDir.path);
      final failingEngine =
          EnterpriseWorkflowEngine(securityEngine: securityEngine);
      final result = await failingEngine.executeWorkflow(securityFailingPlan);

      expect(result.isSuccess, isFalse);
      expect(result.status, equals(EnterpriseWorkflowExecutionStatus.failed));
      expect(result.failedStages, equals(1));
      expect(result.blockedStageId, equals('stg_04_security_audit'));
      expect(result.skippedStages, greaterThan(0));

      // Publishing & Git Release must be skipped
      final publishStage = result.stageResults
          .firstWhere((s) => s.stageType == WorkflowStageType.packagePublish);
      expect(
          publishStage.status, equals(EnterpriseWorkflowStageStatus.skipped));
    });

    test('Halts release when human approval gate is rejected', () async {
      const initiator = EnterpriseIdentity(
        id: 'rel_lead',
        displayName: 'Release Lead',
        roles: [EnterpriseRole.releaseManager],
      );

      final standardPlan = EnterpriseWorkflowPlan.standardEnterprisePipeline(
        targetPackageName: 'unapproved_pkg',
        targetVersion: '1.0.0',
        initiator: initiator,
      );

      final modifiedStages = standardPlan.stages.map((s) {
        if (s.stageType == WorkflowStageType.humanApproval) {
          return OrchestrationStageDefinition(
            stageId: s.stageId,
            stageType: s.stageType,
            name: s.name,
            dependsOnStageIds: s.dependsOnStageIds,
            isMandatoryGate: true,
            stageConfig: const {'mock_approved': false},
          );
        }
        return s;
      }).toList();

      final rejectionPlan = EnterpriseWorkflowPlan(
        workflowId: 'wf_rejected',
        name: 'Rejected Approval Workflow',
        targetPackageName: 'unapproved_pkg',
        targetVersion: '1.0.0',
        initiator: initiator,
        createdAt: DateTime.now(),
        stages: modifiedStages,
      );

      final engine = EnterpriseWorkflowEngine();
      final result = await engine.executeWorkflow(rejectionPlan);

      expect(result.isSuccess, isFalse);
      expect(result.status,
          equals(EnterpriseWorkflowExecutionStatus.blockedByGate));
      expect(result.blockedStageId, equals('stg_11_approval'));

      // Ensure publishing did not occur
      final publishResult = result.stageResults
          .firstWhere((s) => s.stageType == WorkflowStageType.packagePublish);
      expect(
          publishResult.status, equals(EnterpriseWorkflowStageStatus.skipped));
    });

    test('Cancellation signal immediately stops subsequent stage execution',
        () async {
      const initiator = EnterpriseIdentity(
        id: 'rel_lead',
        displayName: 'Release Lead',
        roles: [EnterpriseRole.releaseManager],
      );

      final plan = EnterpriseWorkflowPlan.standardEnterprisePipeline(
        targetPackageName: 'cancelled_pkg',
        targetVersion: '1.0.0',
        initiator: initiator,
      );

      int stageRunCount = 0;
      final engine = EnterpriseWorkflowEngine();

      final result = await engine.executeWorkflow(
        plan,
        isCancelled: () {
          stageRunCount++;
          return stageRunCount > 3; // Cancel after 3 stages
        },
      );

      expect(result.isSuccess, isFalse);
      expect(
          result.status, equals(EnterpriseWorkflowExecutionStatus.cancelled));
      expect(result.skippedStages, greaterThan(0));
    });

    test('Custom stage handler registration and retry mechanism', () async {
      final engine = EnterpriseWorkflowEngine();
      const initiator = EnterpriseIdentity(
        id: 'custom_user',
        displayName: 'Custom User',
        roles: [EnterpriseRole.developer],
      );

      int customTries = 0;
      engine.registerStageHandler(WorkflowStageType.customStage,
          (stage, plan, prevResults) async {
        customTries++;
        if (customTries < 3) {
          return OrchestrationStageResult(
            stageId: stage.stageId,
            stageType: stage.stageType,
            name: stage.name,
            status: EnterpriseWorkflowStageStatus.failed,
            errorMessage: 'Flaky network error attempt $customTries',
            durationMs: 5,
            startedAt: DateTime.now(),
            completedAt: DateTime.now(),
          );
        }
        return OrchestrationStageResult(
          stageId: stage.stageId,
          stageType: stage.stageType,
          name: stage.name,
          status: EnterpriseWorkflowStageStatus.passed,
          outputData: {'custom_success': true},
          durationMs: 5,
          startedAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
      });

      final customPlan = EnterpriseWorkflowPlan(
        workflowId: 'wf_retry_custom',
        name: 'Custom Retry Workflow',
        targetPackageName: 'retry_pkg',
        targetVersion: '1.0.0',
        initiator: initiator,
        createdAt: DateTime.now(),
        stages: const [
          OrchestrationStageDefinition(
            stageId: 'stg_retry',
            stageType: WorkflowStageType.customStage,
            name: 'Flaky Custom Stage',
            maxRetries: 3,
          ),
        ],
      );

      final result = await engine.executeWorkflow(customPlan);

      expect(result.isSuccess, isTrue);
      expect(result.stageResults.first.status,
          equals(EnterpriseWorkflowStageStatus.passed));
      expect(result.stageResults.first.retryCount, equals(2));
      expect(customTries, equals(3));
    });
  });

  group('Phase 9.11: Enterprise Workflow Renderer', () {
    test('Renders Markdown report and JSON with stage progression', () async {
      final engine = EnterpriseWorkflowEngine();
      const initiator = EnterpriseIdentity(
        id: 'admin_user',
        displayName: 'Admin User',
        roles: [EnterpriseRole.administrator],
      );

      final plan = EnterpriseWorkflowPlan.standardEnterprisePipeline(
        targetPackageName: 'render_pkg',
        targetVersion: '4.0.0',
        initiator: initiator,
      );

      final result = await engine.executeWorkflow(plan);

      final markdown = EnterpriseWorkflowRenderer.renderMarkdown(result);
      expect(markdown, contains('# Enterprise Release Workflow Report'));
      expect(markdown, contains('**Target Package:** `render_pkg` @ `4.0.0`'));
      expect(markdown, contains('`PASSED`'));
      expect(markdown, contains('Enterprise Audit Trail Recording'));

      final jsonString = EnterpriseWorkflowRenderer.renderJson(result);
      expect(jsonString, contains('"workflow_id"'));
      expect(jsonString, contains('"status": "completed"'));
      expect(jsonString, contains('"total_stages": 14'));
    });
  });
}
