import 'dart:io';
import 'package:flutter_package_studio_core/src/enterprise/enterprise.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 9.14: Enterprise Compliance Reporting Models', () {
    test('EnterpriseComplianceReport serialization and deserialization', () {
      final report = EnterpriseComplianceReport(
        reportId: 'rep_test_001',
        organizationId: 'acme_corp',
        reportType: ComplianceReportType.securityCompliance,
        title: 'Security Compliance Audit Report',
        executiveSummary: 'Zero security violations identified.',
        isCompliant: true,
        sections: [
          const ComplianceReportSection(
            title: 'Control Matrix',
            description: 'Evaluated security controls',
            headers: ['Control', 'Status', 'Severity'],
            rows: [
              ['Secret Detection', 'PASSED', 'CRITICAL'],
              ['Encryption', 'PASSED', 'HIGH'],
            ],
          ),
        ],
        summaryMetrics: const {'total_controls': 2},
        generatedAt: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      final json = report.toJson();
      final restored = EnterpriseComplianceReport.fromJson(json);

      expect(restored.reportId, equals('rep_test_001'));
      expect(restored.organizationId, equals('acme_corp'));
      expect(restored.isCompliant, isTrue);
      expect(restored.sections.length, equals(1));
      expect(restored.sections.first.rows.length, equals(2));
    });
  });

  group('Phase 9.14: Enterprise Reporting Engine Report Generation', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_rep_test_');
      final pkgDir = Directory(tempDir.path);
      File('${pkgDir.path}/pubspec.yaml').writeAsStringSync('''
name: audit_pkg
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

    test('Generates Security Compliance Report', () async {
      final securityEngine = EnterpriseSecurityComplianceEngine(projectRoot: tempDir.path);
      final reportingEngine = EnterpriseReportingEngine(
        projectRoot: tempDir.path,
        securityEngine: securityEngine,
      );

      final report = await reportingEngine.generateSecurityComplianceReport(
        organizationId: 'acme_corp',
      );

      expect(report.reportType, equals(ComplianceReportType.securityCompliance));
      expect(report.isCompliant, isTrue);
      expect(report.sections, isNotEmpty);
      expect(report.summaryMetrics['compliance_passed'], isTrue);
    });

    test('Generates Dependency Compliance Report', () async {
      final depEngine = EnterpriseDependencyGovernanceEngine(projectRoot: tempDir.path);
      final reportingEngine = EnterpriseReportingEngine(
        projectRoot: tempDir.path,
        dependencyEngine: depEngine,
      );

      final report = await reportingEngine.generateDependencyComplianceReport(
        organizationId: 'acme_corp',
      );

      expect(report.reportType, equals(ComplianceReportType.dependencyCompliance));
      expect(report.isCompliant, isTrue);
      expect(report.sections.first.headers, contains('Package Name'));
    });

    test('Generates Audit Activity Report', () async {
      final auditEngine = EnterpriseAuditEngine(projectRoot: tempDir.path);
      await auditEngine.recordEvent(
        eventType: AuditEventType.packagePublished,
        actorIdentity: const EnterpriseIdentity(id: 'rel_mgr', displayName: 'Release Manager'),
        operation: 'PUBLISH',
        packageOrProject: 'audit_pkg',
        outcome: AuditEventOutcome.success,
      );

      final reportingEngine = EnterpriseReportingEngine(
        projectRoot: tempDir.path,
        auditEngine: auditEngine,
      );

      final report = await reportingEngine.generateAuditActivityReport(
        organizationId: 'acme_corp',
      );

      expect(report.reportType, equals(ComplianceReportType.auditActivity));
      expect(report.sections.first.rows.length, equals(1));
      expect(report.sections.first.rows.first[4], equals('PUBLISH'));
    });

    test('Generates Comprehensive Enterprise Governance Report', () async {
      final securityEngine = EnterpriseSecurityComplianceEngine(projectRoot: tempDir.path);
      final depEngine = EnterpriseDependencyGovernanceEngine(projectRoot: tempDir.path);
      final auditEngine = EnterpriseAuditEngine(projectRoot: tempDir.path);

      final reportingEngine = EnterpriseReportingEngine(
        projectRoot: tempDir.path,
        securityEngine: securityEngine,
        dependencyEngine: depEngine,
        auditEngine: auditEngine,
      );

      final report = await reportingEngine.generateComprehensiveReport(
        organizationId: 'acme_corp',
      );

      expect(report.reportType, equals(ComplianceReportType.comprehensiveGovernance));
      expect(report.isCompliant, isTrue);
      expect(report.sections.length, greaterThanOrEqualTo(2));
      expect(report.summaryMetrics['overall_compliant'], isTrue);
    });
  });

  group('Phase 9.14: Enterprise Reporting Renderer (Markdown, JSON, CSV)', () {
    test('Renders clean Markdown, JSON, and CSV exports', () {
      final report = EnterpriseComplianceReport(
        reportId: 'rep_export_100',
        organizationId: 'enterprise_holdings',
        reportType: ComplianceReportType.comprehensiveGovernance,
        title: 'Comprehensive Governance Certification',
        executiveSummary: 'Full certification passed across all enterprise controls.',
        isCompliant: true,
        sections: [
          const ComplianceReportSection(
            title: 'Control Matrix',
            headers: ['Control ID', 'Status', 'Risk Level'],
            rows: [
              ['CTL_01', 'PASSED', 'LOW'],
              ['CTL_02', 'PASSED', 'MEDIUM'],
            ],
          ),
        ],
        summaryMetrics: const {'score': '100%'},
        generatedAt: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      // 1. Markdown
      final markdown = EnterpriseReportingRenderer.renderMarkdown(report);
      expect(markdown, contains('# Comprehensive Governance Certification'));
      expect(markdown, contains('**Compliance Status:** `COMPLIANT`'));
      expect(markdown, contains('| Control ID | Status | Risk Level |'));
      expect(markdown, contains('| CTL_01 | PASSED | LOW |'));

      // 2. JSON
      final jsonString = EnterpriseReportingRenderer.renderJson(report);
      expect(jsonString, contains('"report_id": "rep_export_100"'));
      expect(jsonString, contains('"is_compliant": true'));

      // 3. CSV
      final csvString = EnterpriseReportingRenderer.renderCsv(report);
      expect(csvString, contains('Control ID,Status,Risk Level'));
      expect(csvString, contains('CTL_01,PASSED,LOW'));
    });
  });
}
