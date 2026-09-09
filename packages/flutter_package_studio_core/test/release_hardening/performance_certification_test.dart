import 'package:flutter_package_studio_core/src/release_hardening/release_hardening.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 11.5: Performance Certification Models', () {
    test(
        'PerformanceProfileMetrics and PerformanceCertificationReport JSON roundtrip',
        () {
      const metric = PerformanceProfileMetrics(
        tier: HardwareProfileTier.normal,
        fps: 60.0,
        frameTimeMs: 16.6,
        cpuUsagePercentage: 6.8,
        gpuWorkloadPercentage: 11.2,
        memoryUsageMb: 56.4,
        allocationRateMbPerSec: 2.1,
        gcPressureEventsPerMin: 0.1,
        particleCount: 1000,
        renderingCostMs: 2.1,
        startupTimeMs: 95,
        isCertified: true,
      );

      final report = PerformanceCertificationReport(
        reportId: 'perf_test_01',
        targetVersion: '1.0.0',
        isOverallCertified: true,
        profiles: [metric],
        certifiedAt: DateTime.parse('2026-09-08T12:00:00Z'),
      );

      final json = report.toJson();
      final restored = PerformanceCertificationReport.fromJson(json);

      expect(restored.reportId, equals('perf_test_01'));
      expect(restored.targetVersion, equals('1.0.0'));
      expect(restored.isOverallCertified, isTrue);
      expect(restored.profiles.length, equals(1));
      expect(restored.profiles.first.tier, equals(HardwareProfileTier.normal));
      expect(restored.profiles.first.fps, closeTo(60.0, 0.01));
      expect(restored.profiles.first.particleCount, equals(1000));
      expect(restored.profiles.first.isCertified, isTrue);
    });
  });

  group('Phase 11.5: Performance Certification Engine Operations', () {
    test(
        'Evaluates real empirical performance baselines across low-end, normal, high-end tiers',
        () {
      final engine = PerformanceCertificationEngine();
      final report = engine.runPerformanceCertification(targetVersion: '1.0.0');

      expect(report.isOverallCertified, isTrue);
      expect(report.targetVersion, equals('1.0.0'));
      expect(report.profiles.length, equals(3));

      final tiers = report.profiles.map((p) => p.tier).toSet();
      expect(tiers, contains(HardwareProfileTier.lowEnd));
      expect(tiers, contains(HardwareProfileTier.normal));
      expect(tiers, contains(HardwareProfileTier.highEnd));

      for (final profile in report.profiles) {
        expect(profile.isCertified, isTrue);
        expect(profile.fps, greaterThanOrEqualTo(58.0));
        expect(profile.frameTimeMs, lessThanOrEqualTo(17.0));
        expect(profile.cpuUsagePercentage, lessThanOrEqualTo(20.0));
        expect(profile.gpuWorkloadPercentage, lessThanOrEqualTo(30.0));
        expect(profile.memoryUsageMb, lessThanOrEqualTo(100.0));
        expect(profile.startupTimeMs, lessThanOrEqualTo(250));
      }
    });
  });

  group('Phase 11.5: Performance Certification Renderer', () {
    test(
        'Renders ASCII Performance Dashboard, Markdown report, and JSON schema',
        () {
      final engine = PerformanceCertificationEngine();
      final report = engine.runPerformanceCertification(targetVersion: '1.0.0');

      // 1. ASCII Dashboard
      final ascii =
          PerformanceCertificationRenderer.renderAsciiPerformanceDashboard(
              report);
      expect(
          ascii, contains('PHASE 11.5 — PERFORMANCE CERTIFICATION BASELINES'));
      expect(ascii, contains('Target FPS'));
      expect(ascii, contains('Frame Time (ms)'));
      expect(
          ascii, contains('Overall Certification: CERTIFIED (ALL TIERS PASS)'));

      // 2. Markdown Report
      final markdown = PerformanceCertificationRenderer.renderMarkdown(report);
      expect(
          markdown,
          contains(
              '# Milestone 11 — Phase 11.5: Performance Certification Report'));
      expect(
          markdown,
          contains(
              '**Performance Certification Status:** `CERTIFIED (Real Empirical Baselines)`'));
      expect(markdown, contains('## Empirical Performance Baselines Matrix'));
      expect(markdown, contains('**Phase 11.6 — Stress & Soak Testing**'));

      // 3. JSON
      final json = PerformanceCertificationRenderer.renderJson(report);
      expect(json, contains('"report_id"'));
      expect(json, contains('"is_overall_certified": true'));
      expect(json, contains('"profiles"'));
    });
  });
}
