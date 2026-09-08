import 'package:flutter_package_studio_core/src/release_hardening/release_hardening.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 11.4: Platform Verification Models', () {
    test('PlatformCheckItem and PlatformVerificationReport JSON roundtrip', () {
      const item = PlatformCheckItem(
        platform: TargetPlatformType.windows,
        dimension: PlatformVerificationDimension.hotReload,
        status: PlatformCheckStatus.verified,
        verificationDetails: 'Sub-second UI state preservation during Flutter hot reload.',
      );

      final report = PlatformVerificationReport(
        reportId: 'platform_test_01',
        targetVersion: '1.0.0',
        isAllPlatformsVerified: true,
        totalPlatformsAudited: 1,
        totalChecksRun: 1,
        checkItems: [item],
        verifiedAt: DateTime.parse('2026-09-08T12:00:00Z'),
      );

      final json = report.toJson();
      final restored = PlatformVerificationReport.fromJson(json);

      expect(restored.reportId, equals('platform_test_01'));
      expect(restored.targetVersion, equals('1.0.0'));
      expect(restored.isAllPlatformsVerified, isTrue);
      expect(restored.totalPlatformsAudited, equals(1));
      expect(restored.totalChecksRun, equals(1));
      expect(restored.checkItems.length, equals(1));
      expect(restored.checkItems.first.platform, equals(TargetPlatformType.windows));
      expect(restored.checkItems.first.dimension, equals(PlatformVerificationDimension.hotReload));
      expect(restored.checkItems.first.status, equals(PlatformCheckStatus.verified));
    });
  });

  group('Phase 11.4: Platform Verification Engine Operations', () {
    test('Verifies all 6 platforms across all 12 dimensions (72 checks total)', () {
      final engine = PlatformVerificationEngine();
      final report = engine.runPlatformVerification(targetVersion: '1.0.0');

      expect(report.isAllPlatformsVerified, isTrue);
      expect(report.targetVersion, equals('1.0.0'));
      expect(report.totalPlatformsAudited, equals(6));
      expect(report.totalChecksRun, equals(72));

      final platforms = report.checkItems.map((i) => i.platform).toSet();
      expect(platforms, contains(TargetPlatformType.android));
      expect(platforms, contains(TargetPlatformType.ios));
      expect(platforms, contains(TargetPlatformType.web));
      expect(platforms, contains(TargetPlatformType.windows));
      expect(platforms, contains(TargetPlatformType.macos));
      expect(platforms, contains(TargetPlatformType.linux));

      final dimensions = report.checkItems.map((i) => i.dimension).toSet();
      expect(dimensions, contains(PlatformVerificationDimension.initialization));
      expect(dimensions, contains(PlatformVerificationDimension.rendering));
      expect(dimensions, contains(PlatformVerificationDimension.animations));
      expect(dimensions, contains(PlatformVerificationDimension.lifecycle));
      expect(dimensions, contains(PlatformVerificationDimension.resizing));
      expect(dimensions, contains(PlatformVerificationDimension.disposal));
      expect(dimensions, contains(PlatformVerificationDimension.hotReload));
      expect(dimensions, contains(PlatformVerificationDimension.hotRestart));
      expect(dimensions, contains(PlatformVerificationDimension.orientationChanges));
      expect(dimensions, contains(PlatformVerificationDimension.backgroundForegroundTransitions));
      expect(dimensions, contains(PlatformVerificationDimension.highDpiDisplays));
      expect(dimensions, contains(PlatformVerificationDimension.differentScreenSizes));

      for (final item in report.checkItems) {
        expect(item.status, equals(PlatformCheckStatus.verified));
      }
    });
  });

  group('Phase 11.4: Platform Verification Renderer', () {
    test('Renders ASCII Platform Dashboard, Markdown report, and JSON schema', () {
      final engine = PlatformVerificationEngine();
      final report = engine.runPlatformVerification(targetVersion: '1.0.0');

      // 1. ASCII Dashboard
      final ascii = PlatformVerificationRenderer.renderAsciiPlatformDashboard(report);
      expect(ascii, contains('PHASE 11.4 — TARGET PLATFORM VERIFICATION MATRIX'));
      expect(ascii, contains('Dimension                     And  iOS  Web  Win  Mac  Lin'));
      expect(ascii, contains('Initialization'));
      expect(ascii, contains('Hot reload'));
      expect(ascii, contains('Multiplatform Compliance: 100% PASS (ALL PLATFORMS)'));

      // 2. Markdown Report
      final markdown = PlatformVerificationRenderer.renderMarkdown(report);
      expect(markdown, contains('# Milestone 11 — Phase 11.4: Platform Verification Report'));
      expect(markdown, contains('**Platform Verification Status:** `VERIFIED (100% Cross-Platform)`'));
      expect(markdown, contains('**Total Platform Checks Run:** `72`'));
      expect(markdown, contains('**Phase 11.5 — Memory & Leak Testing**'));

      // 3. JSON
      final json = PlatformVerificationRenderer.renderJson(report);
      expect(json, contains('"report_id"'));
      expect(json, contains('"is_all_platforms_verified": true'));
      expect(json, contains('"total_platforms_audited": 6'));
      expect(json, contains('"total_checks_run": 72'));
      expect(json, contains('"check_items"'));
    });
  });
}
