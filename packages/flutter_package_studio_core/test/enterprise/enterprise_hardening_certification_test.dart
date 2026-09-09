import 'dart:io';
import 'package:flutter_package_studio_core/src/enterprise/enterprise.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 9.15: Enterprise Hardening & Security Certification', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_hardening_test_');
      final pkgDir = Directory(tempDir.path);
      File('${pkgDir.path}/pubspec.yaml').writeAsStringSync('''
name: hardened_enterprise_pkg
version: 1.0.0
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

    test(
        '1. Authorization & Privilege Escalation Prevention: Developer cannot perform Admin/Publish operations',
        () {
      final rbac = RbacEngine();
      const devIdentity = EnterpriseIdentity(
        id: 'dev_01',
        displayName: 'Junior Developer',
        roles: [EnterpriseRole.developer],
      );

      // Inspect & Review: Allowed
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: devIdentity,
                  operation: EnterpriseOperation.inspectProject))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: devIdentity,
                  operation: EnterpriseOperation.runAiReview))
              .isAllowed,
          isTrue);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: devIdentity,
                  operation: EnterpriseOperation.modifyPackage))
              .isAllowed,
          isTrue);

      // Publish & Policy Change: Denied
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: devIdentity,
                  operation: EnterpriseOperation.publishPackage))
              .isAllowed,
          isFalse);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: devIdentity,
                  operation: EnterpriseOperation.changeEnterprisePolicy))
              .isAllowed,
          isFalse);
      expect(
          rbac
              .authorize(const AuthorizationRequest(
                  identity: devIdentity,
                  operation: EnterpriseOperation.overrideSecurityGate))
              .isAllowed,
          isFalse);
    });

    test(
        '2. Policy Bypass & Path Traversal Prevention: Rejects malicious traversal paths in credential references',
        () async {
      final credManager =
          EnterpriseCredentialManager(projectRoot: tempDir.path);

      // Check availability for path-traversal style key safely
      final check = await credManager.checkAvailability('../../../etc/shadow');
      expect(check.isAvailable, isFalse);

      // Reference objects never expose secrets
      const ref = CredentialReference(
        key: '../../../etc/shadow',
        providerId: 'env_provider',
        providerType: CredentialProviderType.environment,
        scope: CredentialScope.global,
        description: 'Testing path traversal boundary',
      );

      final json = ref.toJson();
      expect(json.containsKey('secret'), isFalse);
      expect(json.containsKey('value'), isFalse);
    });

    test('3. Secret Leakage Prevention & Redaction in Audit Logs', () async {
      final auditEngine = EnterpriseAuditEngine(projectRoot: tempDir.path);
      const secretPayload = 'ghp_SECRETTOKEN99999999999999999999';

      final record = await auditEngine.recordEvent(
        eventType: AuditEventType.securityAuditExecuted,
        actorIdentity: const EnterpriseIdentity(
            id: 'auditor', displayName: 'Security Auditor'),
        operation: 'AUDIT_SCAN',
        packageOrProject: 'hardened_pkg',
        outcome: AuditEventOutcome.failure,
        failureInformation: 'Found GitHub PAT in config: token=$secretPayload',
      );

      expect(record.failureInformation,
          isNot(contains('ghp_SECRETTOKEN99999999999999999999')));
      expect(record.failureInformation, contains('[REDACTED_'));
    });

    test('4. Audit Trail Integrity & Tamper-Evident Hash Chain Verification',
        () async {
      final auditEngine = EnterpriseAuditEngine(projectRoot: tempDir.path);
      const actor =
          EnterpriseIdentity(id: 'dev_user', displayName: 'Developer Alice');

      for (int i = 0; i < 5; i++) {
        await auditEngine.recordEvent(
          eventType: AuditEventType.projectInspected,
          actorIdentity: actor,
          operation: 'OP_$i',
          packageOrProject: 'pkg_test',
          outcome: AuditEventOutcome.success,
        );
      }

      final isIntact = await auditEngine.verifyAuditTrailIntegrity();
      expect(isIntact, isTrue);
    });

    test(
        '5. Approval Bypass Prevention: Release workflow cannot publish without human approval gate',
        () async {
      const initiator = EnterpriseIdentity(
        id: 'rel_lead',
        displayName: 'Release Lead',
        roles: [EnterpriseRole.releaseManager],
      );

      final plan = EnterpriseWorkflowPlan.standardEnterprisePipeline(
        targetPackageName: 'secure_pkg',
        targetVersion: '1.0.0',
        initiator: initiator,
      );

      // Reject human approval gate in configuration
      final modifiedStages = plan.stages.map((s) {
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

      final rejectingPlan = EnterpriseWorkflowPlan(
        workflowId: 'wf_gate_test',
        name: 'Gate Test Workflow',
        targetPackageName: 'secure_pkg',
        targetVersion: '1.0.0',
        initiator: initiator,
        createdAt: DateTime.now(),
        stages: modifiedStages,
      );

      final workflowEngine = EnterpriseWorkflowEngine();
      final result = await workflowEngine.executeWorkflow(rejectingPlan);

      expect(result.isSuccess, isFalse);
      expect(result.status,
          equals(EnterpriseWorkflowExecutionStatus.blockedByGate));

      // Publishing MUST be skipped
      final publishStage = result.stageResults
          .firstWhere((s) => s.stageType == WorkflowStageType.packagePublish);
      expect(
          publishStage.status, equals(EnterpriseWorkflowStageStatus.skipped));
    });

    test(
        '6. Idempotent Crash Recovery: Interrupted workflow resumes without repeating destructive publish',
        () async {
      final auditEngine = EnterpriseAuditEngine(projectRoot: tempDir.path);
      final workflowEngine = EnterpriseWorkflowEngine(auditEngine: auditEngine);
      final reliabilityEngine = EnterpriseReliabilityEngine(
        projectRoot: tempDir.path,
        auditEngine: auditEngine,
        workflowEngine: workflowEngine,
      );

      const initiator = EnterpriseIdentity(
        id: 'admin_01',
        displayName: 'Admin User',
        roles: [EnterpriseRole.administrator],
      );

      final plan = EnterpriseWorkflowPlan.standardEnterprisePipeline(
        targetPackageName: 'hardened_pkg',
        targetVersion: '1.0.0',
        initiator: initiator,
      );

      var state = await reliabilityEngine.initializeState(plan);

      // Mark up to GitRelease and PackagePublish as ALREADY completed in prior crashed run
      for (int i = 0; i < 13; i++) {
        state = await reliabilityEngine.recordCheckpoint(
          currentState: state,
          stage: plan.stages[i],
          status: CheckpointStatus.completed,
          isCompleted: true,
        );
      }

      await reliabilityEngine.markInterrupted(plan.workflowId);

      final resumeResult = await reliabilityEngine.resumeInterruptedWorkflow(
        plan: plan,
        actorIdentity: initiator,
      );

      expect(resumeResult.isSuccess, isTrue);
      expect(
          resumeResult.skippedDestructiveOperations, greaterThanOrEqualTo(2));
      expect(
          resumeResult.actionsTaken.any((a) => a.contains('IDEMPOTENCY GUARD')),
          isTrue);
    });

    test('7. Malformed Input & Fault-Tolerant Engine Resiliency', () async {
      final reliabilityEngine =
          EnterpriseReliabilityEngine(projectRoot: tempDir.path);
      final recoveryDir = Directory('${tempDir.path}/.fps/recovery');
      recoveryDir.createSync(recursive: true);
      File('${recoveryDir.path}/garbage_state.state.json')
          .writeAsStringSync('{{{ MALFORMED NOT JSON');

      final loaded = await reliabilityEngine.loadState('garbage_state');
      expect(loaded, isNull);

      final quarantined = recoveryDir
          .listSync()
          .where((e) => e.path.contains('.corrupt_'))
          .toList();
      expect(quarantined, isNotEmpty);
    });

    test('8. End-to-End Enterprise Governance Certification Report Generation',
        () async {
      final securityEngine =
          EnterpriseSecurityComplianceEngine(projectRoot: tempDir.path);
      final depEngine =
          EnterpriseDependencyGovernanceEngine(projectRoot: tempDir.path);
      final auditEngine = EnterpriseAuditEngine(projectRoot: tempDir.path);

      final reportingEngine = EnterpriseReportingEngine(
        projectRoot: tempDir.path,
        securityEngine: securityEngine,
        dependencyEngine: depEngine,
        auditEngine: auditEngine,
      );

      final certReport = await reportingEngine.generateComprehensiveReport(
        organizationId: 'certified_enterprise_corp',
      );

      expect(certReport.isCompliant, isTrue);
      expect(certReport.summaryMetrics['overall_compliant'], isTrue);

      final markdown = EnterpriseReportingRenderer.renderMarkdown(certReport);
      expect(
          markdown,
          contains(
              'Comprehensive Enterprise Governance & Compliance Certification Report'));
      expect(markdown, contains('COMPLIANT'));

      final json = EnterpriseReportingRenderer.renderJson(certReport);
      expect(json, contains('"is_compliant": true'));

      final csv = EnterpriseReportingRenderer.renderCsv(certReport);
      expect(csv, contains('Section: Recorded Enterprise Operations'));
    });
  });
}
