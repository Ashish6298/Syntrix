import 'package:syntrix/src/release_hardening/release_hardening.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 11.8: Release Candidate Models', () {
    test(
        'FinalValidationGateItem and ReleaseCandidatePromotionReport JSON roundtrip',
        () {
      const gateItem = FinalValidationGateItem(
        gate: IndependentValidationGate.apiFreezeCompliance,
        isPassed: true,
        verificationDetails:
            'Phase 11.1 API Freeze verified: 100% public symbols locked.',
      );

      final report = ReleaseCandidatePromotionReport(
        reportId: 'rc_test_01',
        releaseCandidateTag: 'v1.0.0-rc.1',
        promotedStableVersion: 'v1.0.0',
        currentStage: ReleaseStage.v100Promoted,
        isReadyForV100Promotion: true,
        totalGatesEvaluated: 1,
        gateItems: [gateItem],
        evaluatedAt: DateTime.parse('2026-09-08T12:00:00Z'),
      );

      final json = report.toJson();
      final restored = ReleaseCandidatePromotionReport.fromJson(json);

      expect(restored.reportId, equals('rc_test_01'));
      expect(restored.releaseCandidateTag, equals('v1.0.0-rc.1'));
      expect(restored.promotedStableVersion, equals('v1.0.0'));
      expect(restored.currentStage, equals(ReleaseStage.v100Promoted));
      expect(restored.isReadyForV100Promotion, isTrue);
      expect(restored.totalGatesEvaluated, equals(1));
      expect(restored.gateItems.first.gate,
          equals(IndependentValidationGate.apiFreezeCompliance));
      expect(restored.gateItems.first.isPassed, isTrue);
    });
  });

  group('Phase 11.8: Release Candidate Engine Operations', () {
    test(
        'Evaluates all 8 independent validation gates and promotes v1.0.0-rc.1 to v1.0.0',
        () {
      final engine = ReleaseCandidateEngine();
      final report = engine.runFinalValidationAndPromotion(
        rcTag: 'v1.0.0-rc.1',
        targetStableVersion: 'v1.0.0',
      );

      expect(report.releaseCandidateTag, equals('v1.0.0-rc.1'));
      expect(report.promotedStableVersion, equals('v1.0.0'));
      expect(report.isReadyForV100Promotion, isTrue);
      expect(report.currentStage, equals(ReleaseStage.v100Promoted));
      expect(report.totalGatesEvaluated, equals(8));

      final gates = report.gateItems.map((g) => g.gate).toSet();
      expect(gates, contains(IndependentValidationGate.apiFreezeCompliance));
      expect(
          gates, contains(IndependentValidationGate.breakingChangeZeroPolicy));
      expect(gates, contains(IndependentValidationGate.fullRegressionPass));
      expect(gates, contains(IndependentValidationGate.multiPlatformCertified));
      expect(gates, contains(IndependentValidationGate.performanceCertified));
      expect(gates, contains(IndependentValidationGate.documentationComplete));
      expect(gates, contains(IndependentValidationGate.pubArchiveClean));
      expect(
          gates, contains(IndependentValidationGate.tamperProofAuditRecorded));

      for (final gate in report.gateItems) {
        expect(gate.isPassed, isTrue);
      }
    });
  });

  group('Phase 11.8: Release Candidate Renderer', () {
    test('Renders ASCII Lifecycle Dashboard, Markdown report, and JSON schema',
        () {
      final engine = ReleaseCandidateEngine();
      final report = engine.runFinalValidationAndPromotion(
        rcTag: 'v1.0.0-rc.1',
        targetStableVersion: 'v1.0.0',
      );

      // 1. ASCII Dashboard
      final ascii =
          ReleaseHardeningCandidateRenderer.renderAsciiLifecycleDashboard(
              report);
      expect(
          ascii,
          contains(
              'PHASE 11.8 — FINAL RELEASE CANDIDATE & PROMOTION DASHBOARD'));
      expect(ascii, contains('v1.0.0-rc.1        ──> Tagged Candidate'));
      expect(ascii,
          contains('v1.0.0             ──> PROMOTED TO STABLE PRODUCTION'));
      expect(ascii, contains('Status: ALL GATES PASSED (100%)'));

      // 2. Markdown Report
      final markdown = ReleaseHardeningCandidateRenderer.renderMarkdown(report);
      expect(
          markdown,
          contains(
              '# Milestone 11 — Phase 11.8: Final Release Candidate & Promotion Report'));
      expect(markdown, contains('**Release Candidate Tag:** `v1.0.0-rc.1`'));
      expect(markdown, contains('**Promoted Production Release:** `v1.0.0`'));
      expect(markdown, contains('## Independent Validation Gates'));
      expect(markdown, contains('## Release Hardening Conclusion & Roadmap'));

      // 3. JSON
      final json = ReleaseHardeningCandidateRenderer.renderJson(report);
      expect(json, contains('"report_id"'));
      expect(json, contains('"release_candidate_tag": "v1.0.0-rc.1"'));
      expect(json, contains('"promoted_stable_version": "v1.0.0"'));
      expect(json, contains('"is_ready_for_v100_promotion": true'));
      expect(json, contains('"total_gates_evaluated": 8'));
      expect(json, contains('"gate_items"'));
    });
  });
}
