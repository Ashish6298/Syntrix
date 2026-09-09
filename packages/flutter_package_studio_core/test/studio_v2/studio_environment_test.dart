import 'package:flutter_package_studio_core/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.16: Cross-Platform Environment Models', () {
    test('StudioPlatformProfile and StudioEnvironmentReport JSON roundtrip',
        () {
      const profile = StudioPlatformProfile(
        platform: StudioPlatformType.ios,
        supportStatus: PlatformCapabilityStatus.verified,
        rendererBackend: 'Impeller (Metal)',
        shadersSupported: true,
        diagnosticsSupported: true,
        supportedFeatures: ['Metal Pipeline', 'High-Refresh 120Hz ProMotion'],
        knownLimitations: ['Requires iOS 12.0+'],
      );

      expect(profile.supportStatus.symbol, equals('✓'));

      final report = StudioEnvironmentReport(
        reportId: 'env_test_01',
        activeHostPlatform: 'macOS',
        platformProfiles: [profile],
        inspectedAt: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      final json = report.toJson();
      final restored = StudioEnvironmentReport.fromJson(json);

      expect(restored.reportId, equals('env_test_01'));
      expect(restored.activeHostPlatform, equals('macOS'));
      expect(restored.platformProfiles.length, equals(1));
      expect(restored.platformProfiles.first.platform,
          equals(StudioPlatformType.ios));
      expect(restored.platformProfiles.first.rendererBackend,
          equals('Impeller (Metal)'));
    });
  });

  group('Phase 10.16: Studio Environment Engine Operations', () {
    test(
        'Inspects environment covering Android, iOS, Web, Windows, macOS, Linux',
        () {
      final controller = StudioV2Controller();
      final envEngine = StudioEnvironmentEngine(controller: controller);

      final report = envEngine.inspectEnvironment();

      expect(report.platformProfiles.length, equals(6));
      final platforms = report.platformProfiles.map((p) => p.platform).toSet();

      expect(platforms, contains(StudioPlatformType.android));
      expect(platforms, contains(StudioPlatformType.ios));
      expect(platforms, contains(StudioPlatformType.web));
      expect(platforms, contains(StudioPlatformType.windows));
      expect(platforms, contains(StudioPlatformType.macos));
      expect(platforms, contains(StudioPlatformType.linux));

      final android = report.platformProfiles
          .firstWhere((p) => p.platform == StudioPlatformType.android);
      expect(android.supportStatus, equals(PlatformCapabilityStatus.verified));
      expect(android.rendererBackend, contains('Impeller'));
      expect(android.shadersSupported, isTrue);

      final web = report.platformProfiles
          .firstWhere((p) => p.platform == StudioPlatformType.web);
      expect(web.rendererBackend, contains('CanvasKit'));
      expect(web.knownLimitations, isNotEmpty);
    });
  });

  group('Phase 10.16: Studio Environment Renderer', () {
    test('Renders ASCII Environment list, Markdown Report, and JSON schema',
        () {
      final controller = StudioV2Controller();
      final envEngine = StudioEnvironmentEngine(controller: controller);

      final report = envEngine.inspectEnvironment();

      // 1. ASCII List Wireframe
      final ascii = StudioEnvironmentRenderer.renderAsciiEnvironment(report);
      expect(ascii, contains('Environment'));
      expect(ascii, contains('Android      ✓'));
      expect(ascii, contains('iOS          ✓'));
      expect(ascii, contains('Web          ✓'));
      expect(ascii, contains('Windows      ✓'));
      expect(ascii, contains('macOS        ✓'));
      expect(ascii, contains('Linux        ✓'));

      // 2. Markdown Report
      final markdown = StudioEnvironmentRenderer.renderMarkdown(report);
      expect(markdown, contains('# Cross-Platform Environment Center Report'));
      expect(markdown, contains('## Supported Platforms & Capability Matrix'));
      expect(markdown, contains('## Feature Breakdown by Platform'));
      expect(markdown, contains('**Android**'));

      // 3. JSON
      final json = StudioEnvironmentRenderer.renderJson(report);
      expect(json, contains('"report_id"'));
      expect(json, contains('"platform_profiles"'));
    });
  });
}
