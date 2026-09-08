import 'package:flutter_package_studio_core/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.21: Release Candidate Audit Models', () {
    test('ReleaseCandidateGateItem and ReleaseCandidateAuditReport JSON roundtrip', () {
      const gate = ReleaseCandidateGateItem(
        dimension: Milestone10GateDimension.pubDevValidation,
        status: GateStatus.pass,
        verificationDetails: 'pubspec, LICENSE, README, CHANGELOG verified',
      );

      final report = ReleaseCandidateAuditReport(
        reportId: 'rc_test_01',
        targetVersion: '1.0.0',
        isMilestone10Complete: true,
        isReleaseCandidateReady: true,
        gates: [gate],
        packageMetadataCheck: {'pubspec_valid': true},
        auditedAt: DateTime.parse('2026-09-08T12:00:00Z'),
      );

      final json = report.toJson();
      final restored = ReleaseCandidateAuditReport.fromJson(json);

      expect(restored.reportId, equals('rc_test_01'));
      expect(restored.targetVersion, equals('1.0.0'));
      expect(restored.isMilestone10Complete, isTrue);
      expect(restored.isReleaseCandidateReady, isTrue);
      expect(restored.gates.length, equals(1));
      expect(restored.gates.first.dimension, equals(Milestone10GateDimension.pubDevValidation));
      expect(restored.packageMetadataCheck['pubspec_valid'], isTrue);
    });
  });

  group('Phase 10.21: Release Candidate Audit Engine Operations', () {
    test('Audits all 19 Milestone 10 Release Gates and proves Release Candidate readiness', () {
      final controller = StudioV2Controller();
      final auditEngine = ReleaseCandidateAuditEngine(controller: controller);

      final report = auditEngine.runReleaseCandidateAudit(targetVersion: '1.0.0');

      expect(report.isMilestone10Complete, isTrue);
      expect(report.isReleaseCandidateReady, isTrue);
      expect(report.gates.length, equals(19));

      final dims = report.gates.map((g) => g.dimension).toSet();
      expect(dims, contains(Milestone10GateDimension.coreFunctionality));
      expect(dims, contains(Milestone10GateDimension.existingUi));
      expect(dims, contains(Milestone10GateDimension.existingLoaders));
      expect(dims, contains(Milestone10GateDimension.existingThemes));
      expect(dims, contains(Milestone10GateDimension.rendering));
      expect(dims, contains(Milestone10GateDimension.interaction));
      expect(dims, contains(Milestone10GateDimension.diagnostics));
      expect(dims, contains(Milestone10GateDimension.studioV2));
      expect(dims, contains(Milestone10GateDimension.codeGeneration));
      expect(dims, contains(Milestone10GateDimension.presets));
      expect(dims, contains(Milestone10GateDimension.persistence));
      expect(dims, contains(Milestone10GateDimension.exportImport));
      expect(dims, contains(Milestone10GateDimension.performance));
      expect(dims, contains(Milestone10GateDimension.documentation));
      expect(dims, contains(Milestone10GateDimension.tests));
      expect(dims, contains(Milestone10GateDimension.staticAnalysis));
      expect(dims, contains(Milestone10GateDimension.dependencyCompatibility));
      expect(dims, contains(Milestone10GateDimension.pubDevValidation));
      expect(dims, contains(Milestone10GateDimension.regressionTesting));

      for (final g in report.gates) {
        expect(g.status, equals(GateStatus.pass));
      }

      expect(report.packageMetadataCheck['pubspec_valid'], isTrue);
      expect(report.packageMetadataCheck['license_present'], isTrue);
      expect(report.packageMetadataCheck['shaders_included'], isTrue);
    });
  });

  group('Phase 10.21: Release Candidate Renderer', () {
    test('Renders ASCII Milestone 10 Release Gate Box, Markdown Report, and JSON schema', () {
      final controller = StudioV2Controller();
      final auditEngine = ReleaseCandidateAuditEngine(controller: controller);

      final report = auditEngine.runReleaseCandidateAudit(targetVersion: '1.0.0');

      // 1. ASCII Release Gate Box
      final ascii = ReleaseCandidateRenderer.renderAsciiReleaseGate(report);
      expect(ascii, contains('MILESTONE 10 RELEASE GATE'));
      expect(ascii, contains('Core functionality'));
      expect(ascii, contains('Existing UI'));
      expect(ascii, contains('Pub.dev validation'));
      expect(ascii, contains('Regression testing'));
      expect(ascii, contains('PASS'));
      expect(ascii, contains('Milestone 10 Status: COMPLETE'));
      expect(ascii, contains('Project Status:      RELEASE CANDIDATE (RC)'));

      // 2. Markdown Report
      final markdown = ReleaseCandidateRenderer.renderMarkdown(report);
      expect(markdown, contains('# Milestone 10 — Release Candidate Audit Report'));
      expect(markdown, contains('**Milestone 10 Status:** `COMPLETE`'));
      expect(markdown, contains('**Project Status:** `RELEASE CANDIDATE READY (RC)`'));
      expect(markdown, contains('## Milestone 10 Release Gate Evaluation Matrix'));
      expect(markdown, contains('## Next Steps'));

      // 3. JSON
      final json = ReleaseCandidateRenderer.renderJson(report);
      expect(json, contains('"report_id"'));
      expect(json, contains('"is_milestone10_complete": true'));
      expect(json, contains('"is_release_candidate_ready": true'));
      expect(json, contains('"gates"'));
    });
  });
}
