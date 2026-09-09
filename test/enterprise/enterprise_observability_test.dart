import 'dart:io';
import 'package:syntrix/src/enterprise/enterprise.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 9.12: Enterprise Observability & Operational Dashboard Models',
      () {
    test('PackageHealthMetric serialization and deserialization', () {
      final metric = PackageHealthMetric(
        packageName: 'core_security_pkg',
        currentVersion: '2.1.0',
        status: OperationalHealthStatus.healthy,
        totalDependencies: 8,
        policyViolations: 0,
        securityFindings: 0,
        aiQualityScore: 99.4,
        lastInspectedAt: DateTime.parse('2026-09-04T12:00:00Z'),
      );

      final json = metric.toJson();
      final restored = PackageHealthMetric.fromJson(json);

      expect(restored.packageName, equals('core_security_pkg'));
      expect(restored.currentVersion, equals('2.1.0'));
      expect(restored.status, equals(OperationalHealthStatus.healthy));
      expect(restored.aiQualityScore, equals(99.4));
    });

    test('EnterpriseDashboardSnapshot serialization and deserialization', () {
      final snapshot = EnterpriseDashboardSnapshot(
        organizationId: 'acme_corp',
        overallSystemHealth: OperationalHealthStatus.degraded,
        generatedAt: DateTime.parse('2026-09-04T12:00:00Z'),
        totalWorkflowsExecuted: 20,
        successfulWorkflows: 18,
        failedWorkflows: 1,
        gateBlockedWorkflows: 1,
        activePolicyViolations: 2,
        blockedDependencyCount: 1,
        totalAuditEventsRecorded: 55,
        failedOperationsRecorded: 2,
        packageHealth: [
          PackageHealthMetric(
            packageName: 'flutter_auth',
            currentVersion: '1.0.0',
            status: OperationalHealthStatus.degraded,
            policyViolations: 2,
            lastInspectedAt: DateTime.parse('2026-09-04T12:00:00Z'),
          ),
        ],
        aiReviewStats: const AiReviewTelemetry(
          totalReviewsExecuted: 15,
          averageQualityScore: 94.2,
          totalFindingsReported: 4,
          approvedReleasesCount: 14,
          blockedReleasesCount: 1,
        ),
        workerStats: const WorkerPoolTelemetry(
          totalRegisteredWorkers: 4,
          healthyWorkers: 3,
          busyWorkers: 1,
          degradedOrOfflineWorkers: 0,
          completedTasksCount: 12,
        ),
      );

      final json = snapshot.toJson();
      final restored = EnterpriseDashboardSnapshot.fromJson(json);

      expect(restored.organizationId, equals('acme_corp'));
      expect(restored.overallSystemHealth,
          equals(OperationalHealthStatus.degraded));
      expect(restored.totalWorkflowsExecuted, equals(20));
      expect(restored.packageHealth.length, equals(1));
      expect(restored.aiReviewStats.averageQualityScore, equals(94.2));
      expect(restored.workerStats.totalRegisteredWorkers, equals(4));
    });
  });

  group('Phase 9.12: Enterprise Observability Engine Aggregation', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_obs_test_');
      final pkgDir = Directory(tempDir.path);
      File('${pkgDir.path}/pubspec.yaml').writeAsStringSync('''
name: acme_pkg
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

    test('Aggregates full operational telemetry across subsystems', () async {
      final auditEngine = EnterpriseAuditEngine(projectRoot: tempDir.path);
      final workerManager = EnterpriseWorkerManager(projectRoot: tempDir.path);
      final workflowEngine = EnterpriseWorkflowEngine();
      final securityEngine =
          EnterpriseSecurityComplianceEngine(projectRoot: tempDir.path);
      final dependencyEngine =
          EnterpriseDependencyGovernanceEngine(projectRoot: tempDir.path);

      // Record sample audit events
      await auditEngine.recordEvent(
        eventType: AuditEventType.projectInspected,
        actorIdentity: const EnterpriseIdentity(
            id: 'dev_1', displayName: 'Developer Alice'),
        operation: 'INSPECT_PROJECT',
        packageOrProject: 'acme_pkg',
        outcome: AuditEventOutcome.success,
      );

      await auditEngine.recordEvent(
        eventType: AuditEventType.securityAuditExecuted,
        actorIdentity: const EnterpriseIdentity(
            id: 'auditor_1', displayName: 'Auditor Bob'),
        operation: 'SECURITY_AUDIT',
        packageOrProject: 'acme_pkg',
        outcome: AuditEventOutcome.failure,
        failureInformation: 'Found high severity dependency risk',
      );

      // Run sample workflow
      const initiator = EnterpriseIdentity(
        id: 'rel_mgr_1',
        displayName: 'Release Manager Charlie',
        roles: [EnterpriseRole.releaseManager],
      );

      final plan = EnterpriseWorkflowPlan.standardEnterprisePipeline(
        targetPackageName: 'acme_pkg',
        targetVersion: '1.0.0',
        initiator: initiator,
      );

      await workflowEngine.executeWorkflow(plan);

      // Initialize Observability Engine
      final obsEngine = EnterpriseObservabilityEngine(
        projectRoot: tempDir.path,
        auditEngine: auditEngine,
        workerManager: workerManager,
        workflowEngine: workflowEngine,
        securityEngine: securityEngine,
        dependencyEngine: dependencyEngine,
      );

      final snapshot = await obsEngine.generateDashboardSnapshot(
        organizationId: 'enterprise_org_test',
        knownPackages: ['acme_pkg'],
      );

      expect(snapshot.organizationId, equals('enterprise_org_test'));
      expect(snapshot.totalAuditEventsRecorded, greaterThanOrEqualTo(2));
      expect(snapshot.failedOperationsRecorded, equals(1));
      expect(snapshot.recentFailedOperations.length, equals(1));
      expect(snapshot.recentFailedOperations.first['failure_info'],
          contains('Found high severity dependency risk'));
      expect(snapshot.totalWorkflowsExecuted, equals(1));
      expect(snapshot.successfulWorkflows, equals(1));
      expect(
          snapshot.workerStats.totalRegisteredWorkers, greaterThanOrEqualTo(1));
      expect(snapshot.workerStats.healthyWorkers, greaterThanOrEqualTo(1));
      expect(snapshot.packageHealth.length, equals(1));
      expect(snapshot.packageHealth.first.packageName, equals('acme_pkg'));
    });
  });

  group('Phase 9.12: Enterprise Dashboard Renderer', () {
    test('Renders Markdown report and JSON payload accurately', () {
      final snapshot = EnterpriseDashboardSnapshot(
        organizationId: 'acme_global',
        overallSystemHealth: OperationalHealthStatus.healthy,
        generatedAt: DateTime.parse('2026-09-04T12:00:00Z'),
        totalWorkflowsExecuted: 10,
        successfulWorkflows: 10,
        packageHealth: [
          PackageHealthMetric(
            packageName: 'acme_core',
            currentVersion: '3.0.0',
            status: OperationalHealthStatus.healthy,
            policyViolations: 0,
            aiQualityScore: 99.1,
            lastInspectedAt: DateTime.parse('2026-09-04T12:00:00Z'),
          ),
        ],
        workerStats: const WorkerPoolTelemetry(
          totalRegisteredWorkers: 2,
          healthyWorkers: 2,
        ),
        recentFailedOperations: [
          {
            'event_id': 'evt_001',
            'operation': 'PACKAGE_PUBLISH',
            'package': 'acme_legacy',
            'actor': 'Dev Alice',
            'failure_info': 'Invalid token signature',
            'timestamp': '2026-09-04T11:55:00Z',
          }
        ],
      );

      final markdown = EnterpriseDashboardRenderer.renderMarkdown(snapshot);
      expect(markdown, contains('# Enterprise Operational Dashboard'));
      expect(markdown, contains('**Organization:** `acme_global`'));
      expect(markdown, contains('`acme_core`'));
      expect(markdown, contains('Recent Failed Operations'));
      expect(markdown, contains('Invalid token signature'));

      final jsonString = EnterpriseDashboardRenderer.renderJson(snapshot);
      expect(jsonString, contains('"organization_id": "acme_global"'));
      expect(jsonString, contains('"overall_system_health": "healthy"'));
      expect(jsonString, contains('"total_workflows_executed": 10'));
    });
  });
}
