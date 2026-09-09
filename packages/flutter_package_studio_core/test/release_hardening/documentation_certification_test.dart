import 'package:flutter_package_studio_core/src/release_hardening/release_hardening.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 11.6: Documentation Certification Models', () {
    test(
        'DocumentationAuditItem and DocumentationCertificationReport JSON roundtrip',
        () {
      const fileItem = DocumentationAuditItem(
        identifier: 'README.md',
        itemType: 'file',
        status: DocAuditStatus.certified,
        verificationDetails:
            'Root project overview, badges, quickstart, visual showcases.',
      );

      const topicItem = DocumentationAuditItem(
        identifier: 'Installation',
        itemType: 'topic',
        status: DocAuditStatus.certified,
        verificationDetails:
            'CLI & Flutter package dependency declaration instructions.',
      );

      final report = DocumentationCertificationReport(
        reportId: 'doc_test_01',
        targetVersion: '1.0.0',
        isDocCertified: true,
        totalFilesAudited: 1,
        totalTopicsAudited: 1,
        fileItems: [fileItem],
        topicItems: [topicItem],
        certifiedAt: DateTime.parse('2026-09-08T12:00:00Z'),
      );

      final json = report.toJson();
      final restored = DocumentationCertificationReport.fromJson(json);

      expect(restored.reportId, equals('doc_test_01'));
      expect(restored.targetVersion, equals('1.0.0'));
      expect(restored.isDocCertified, isTrue);
      expect(restored.totalFilesAudited, equals(1));
      expect(restored.totalTopicsAudited, equals(1));
      expect(restored.fileItems.first.identifier, equals('README.md'));
      expect(restored.topicItems.first.identifier, equals('Installation'));
    });
  });

  group('Phase 11.6: Documentation Certification Engine Operations', () {
    test('Audits all 8 mandatory files and 12 core documentation topics', () {
      final engine = DocumentationCertificationEngine();
      final report =
          engine.runDocumentationCertification(targetVersion: '1.0.0');

      expect(report.isDocCertified, isTrue);
      expect(report.targetVersion, equals('1.0.0'));
      expect(report.totalFilesAudited, equals(8));
      expect(report.totalTopicsAudited, equals(12));

      final filenames = report.fileItems.map((f) => f.identifier).toSet();
      expect(filenames, contains('README.md'));
      expect(filenames, contains('CHANGELOG.md'));
      expect(filenames, contains('LICENSE'));
      expect(filenames, contains('CONTRIBUTING.md'));
      expect(filenames, contains('CODE_OF_CONDUCT.md'));
      expect(filenames, contains('SECURITY.md'));
      expect(filenames, contains('doc/'));
      expect(filenames, contains('example/'));

      final topics = report.topicItems.map((t) => t.identifier).toSet();
      expect(topics, contains('Installation'));
      expect(topics, contains('Basic usage'));
      expect(topics, contains('Advanced usage'));
      expect(topics, contains('Architecture'));
      expect(topics, contains('Customization'));
      expect(topics, contains('Themes'));
      expect(topics, contains('Loaders'));
      expect(topics, contains('Performance'));
      expect(topics, contains('API reference'));
      expect(topics, contains('Troubleshooting'));
      expect(topics, contains('Examples'));
      expect(topics, contains('Migration information'));

      for (final f in report.fileItems) {
        expect(f.status, equals(DocAuditStatus.certified));
      }
      for (final t in report.topicItems) {
        expect(t.status, equals(DocAuditStatus.certified));
      }
    });
  });

  group('Phase 11.6: Documentation Certification Renderer', () {
    test(
        'Renders ASCII Documentation Dashboard, Markdown report, and JSON schema',
        () {
      final engine = DocumentationCertificationEngine();
      final report =
          engine.runDocumentationCertification(targetVersion: '1.0.0');

      // 1. ASCII Dashboard
      final ascii =
          DocumentationCertificationRenderer.renderAsciiDocDashboard(report);
      expect(ascii, contains('PHASE 11.6 — DOCUMENTATION CERTIFICATION AUDIT'));
      expect(ascii, contains('README.md'));
      expect(ascii, contains('Architecture'));
      expect(ascii, contains('Files: 8  | Topics: 12 | Status: CERTIFIED'));

      // 2. Markdown Report
      final markdown =
          DocumentationCertificationRenderer.renderMarkdown(report);
      expect(
          markdown,
          contains(
              '# Milestone 11 — Phase 11.6: Documentation Certification Report'));
      expect(
          markdown,
          contains(
              '**Documentation Certification Status:** `CERTIFIED (100% Complete)`'));
      expect(markdown, contains('## Mandatory File Verification'));
      expect(markdown, contains('## Mandatory Topic Coverage'));
      expect(markdown,
          contains('**Phase 11.7 — Example Application Verification**'));

      // 3. JSON
      final json = DocumentationCertificationRenderer.renderJson(report);
      expect(json, contains('"report_id"'));
      expect(json, contains('"is_doc_certified": true'));
      expect(json, contains('"total_files_audited": 8'));
      expect(json, contains('"total_topics_audited": 12'));
      expect(json, contains('"file_items"'));
      expect(json, contains('"topic_items"'));
    });
  });
}
