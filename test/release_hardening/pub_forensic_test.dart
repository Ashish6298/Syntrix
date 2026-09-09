import 'package:syntrix/src/release_hardening/release_hardening.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 11.7: Pub.dev Forensic Audit Models', () {
    test('PubArchiveCheckItem and PubForensicAuditReport JSON roundtrip', () {
      const checkItem = PubArchiveCheckItem(
        ruleIdentifier: 'lib/ Source Directory Included',
        category: ArchiveAuditCategory.requiredContent,
        status: ArchiveCheckStatus.compliant,
        verificationDetails: 'All Dart source files packaged cleanly.',
      );

      final report = PubForensicAuditReport(
        reportId: 'pub_test_01',
        targetVersion: '1.0.0',
        isArchiveCertified: true,
        isDryRunClean: true,
        totalChecksRun: 1,
        checkItems: [checkItem],
        auditedAt: DateTime.parse('2026-09-08T12:00:00Z'),
      );

      final json = report.toJson();
      final restored = PubForensicAuditReport.fromJson(json);

      expect(restored.reportId, equals('pub_test_01'));
      expect(restored.targetVersion, equals('1.0.0'));
      expect(restored.isArchiveCertified, isTrue);
      expect(restored.isDryRunClean, isTrue);
      expect(restored.totalChecksRun, equals(1));
      expect(restored.checkItems.first.ruleIdentifier,
          equals('lib/ Source Directory Included'));
      expect(restored.checkItems.first.category,
          equals(ArchiveAuditCategory.requiredContent));
      expect(restored.checkItems.first.status,
          equals(ArchiveCheckStatus.compliant));
    });
  });

  group('Phase 11.7: Pub.dev Forensic Audit Engine Operations', () {
    test(
        'Executes dry-run and forensic archive inspections across all 3 audit categories',
        () {
      final engine = PubForensicAuditEngine();
      final report = engine.runPubForensicAudit(targetVersion: '1.0.0');

      expect(report.isArchiveCertified, isTrue);
      expect(report.isDryRunClean, isTrue);
      expect(report.targetVersion, equals('1.0.0'));
      expect(report.totalChecksRun, equals(16));

      final rules = report.checkItems.map((c) => c.ruleIdentifier).toSet();
      // Required content checks
      expect(rules, contains('lib/ Source Directory Included'));
      expect(rules, contains('example/ Demonstration Project Included'));
      expect(rules, contains('README.md Documentation Included'));
      expect(rules, contains('CHANGELOG.md Version History Included'));
      expect(rules, contains('LICENSE Permissive License Included'));
      expect(rules, contains('pubspec.yaml Package Metadata Included'));
      expect(rules, contains('shaders/ GLSL Shader Assets Included'));
      expect(rules, contains('assets/ Static Resources Included'));

      // Hygiene checks
      expect(rules, contains('No Accidental Secrets / Credentials'));
      expect(rules, contains('No Private Files or .env Configurations'));
      expect(rules, contains('No Development Logs or Debug Dumps'));
      expect(rules, contains('No Non-Shippable Test Artifacts'));

      // Tool exclusion checks
      expect(rules, contains('No .dart_tool/ Metadata Directory'));
      expect(rules, contains('No build/ Output Binaries'));
      expect(rules, contains('No Unnecessary Generated Files'));
      expect(rules, contains('All Exported Symbols Matched to Sources'));

      for (final check in report.checkItems) {
        expect(check.status, equals(ArchiveCheckStatus.compliant));
      }
    });
  });

  group('Phase 11.7: Pub.dev Forensic Audit Renderer', () {
    test('Renders ASCII Forensic Dashboard, Markdown report, and JSON schema',
        () {
      final engine = PubForensicAuditEngine();
      final report = engine.runPubForensicAudit(targetVersion: '1.0.0');

      // 1. ASCII Dashboard
      final ascii =
          PubForensicAuditRenderer.renderAsciiForensicDashboard(report);
      expect(ascii, contains('PHASE 11.7 — PUB.DEV FORENSIC AUDIT DASHBOARD'));
      expect(ascii, contains('Required Content & Assets'));
      expect(ascii, contains('Hygiene & Security'));
      expect(ascii, contains('Artifact & Tool Exclusion'));
      expect(ascii, contains('Status: PASSED (0 VIOLATIONS)'));

      // 2. Markdown Report
      final markdown = PubForensicAuditRenderer.renderMarkdown(report);
      expect(
          markdown,
          contains(
              '# Milestone 11 — Phase 11.7: Pub.dev Forensic Audit Report'));
      expect(
          markdown,
          contains(
              '**Pub.dev Archive Status:** `CERTIFIED (Zero Violations)`'));
      expect(markdown,
          contains('**Dry-Run Verification:** `PASSED (Clean Exit Code 0)`'));
      expect(markdown, contains('## Required Content & Assets'));
      expect(markdown,
          contains('**Phase 11.8 — Community Release Candidate (RC1)**'));

      // 3. JSON
      final json = PubForensicAuditRenderer.renderJson(report);
      expect(json, contains('"report_id"'));
      expect(json, contains('"is_archive_certified": true'));
      expect(json, contains('"is_dry_run_clean": true'));
      expect(json, contains('"total_checks_run": 16'));
      expect(json, contains('"check_items"'));
    });
  });
}
