import 'package:flutter_package_studio_core/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.17: Automated Validation Models', () {
    test('ValidationCheckItem and StudioValidationReport JSON roundtrip', () {
      const check = ValidationCheckItem(
        checkId: 'val_test_static',
        title: 'Static Analysis',
        category: StudioValidationCategory.architecture,
        status: ValidationCheckStatus.pass,
        details: '0 errors',
        durationMs: 15.0,
      );

      final report = StudioValidationReport(
        reportId: 'val_test_01',
        packageName: 'flutter_package_studio_core',
        packageVersion: '2.0.0',
        overallHealth: PackageHealthStatus.healthy,
        categorySummaries: {
          StudioValidationCategory.architecture: ValidationCheckStatus.pass,
          StudioValidationCategory.api: ValidationCheckStatus.pass,
          StudioValidationCategory.tests: ValidationCheckStatus.pass,
          StudioValidationCategory.rendering: ValidationCheckStatus.pass,
          StudioValidationCategory.performance: ValidationCheckStatus.pass,
          StudioValidationCategory.documentation: ValidationCheckStatus.pass,
          StudioValidationCategory.compatibility: ValidationCheckStatus.pass,
        },
        checks: [check],
        validatedAt: DateTime.parse('2026-09-08T12:00:00Z'),
      );

      final json = report.toJson();
      final restored = StudioValidationReport.fromJson(json);

      expect(restored.reportId, equals('val_test_01'));
      expect(restored.packageName, equals('flutter_package_studio_core'));
      expect(restored.overallHealth, equals(PackageHealthStatus.healthy));
      expect(restored.categorySummaries[StudioValidationCategory.architecture], equals(ValidationCheckStatus.pass));
      expect(restored.checks.length, equals(1));
      expect(restored.checks.first.title, equals('Static Analysis'));
    });
  });

  group('Phase 10.17: Studio Validation Engine Operations', () {
    test('Runs full validation covering all 7 categories and 9+ checks accurately', () {
      final controller = StudioV2Controller();
      final valEngine = StudioValidationEngine(controller: controller);

      final report = valEngine.runFullValidation();

      expect(report.overallHealth, equals(PackageHealthStatus.healthy));
      expect(report.categorySummaries.length, equals(7));

      for (final cat in StudioValidationCategory.values) {
        expect(report.categorySummaries[cat], equals(ValidationCheckStatus.pass));
      }

      expect(report.checks.length, greaterThanOrEqualTo(10));
      final checkTitles = report.checks.map((c) => c.title).toSet();
      expect(checkTitles, contains('Static Analysis'));
      expect(checkTitles, contains('Unit Tests'));
      expect(checkTitles, contains('Widget Tests'));
      expect(checkTitles, contains('Integration Tests'));
      expect(checkTitles, contains('Export Validation'));
      expect(checkTitles, contains('Configuration Validation'));
      expect(checkTitles, contains('Documentation Validation'));
      expect(checkTitles, contains('Platform Checks'));
      expect(checkTitles, contains('Performance Checks'));
      expect(checkTitles, contains('Rendering Pass Checks'));
    });
  });

  group('Phase 10.17: Studio Validation Renderer', () {
    test('Renders ASCII Package Health Dashboard, Markdown Report, and JSON schema', () {
      final controller = StudioV2Controller();
      final valEngine = StudioValidationEngine(controller: controller);

      final report = valEngine.runFullValidation();

      // 1. ASCII Dashboard
      final ascii = StudioValidationRenderer.renderAsciiDashboard(report);
      expect(ascii, contains('PACKAGE HEALTH'));
      expect(ascii, contains('Architecture       PASS'));
      expect(ascii, contains('API                PASS'));
      expect(ascii, contains('Tests              PASS'));
      expect(ascii, contains('Rendering          PASS'));
      expect(ascii, contains('Performance        PASS'));
      expect(ascii, contains('Documentation      PASS'));
      expect(ascii, contains('Compatibility      PASS'));
      expect(ascii, contains('Overall: HEALTHY'));

      // 2. Markdown Report
      final markdown = StudioValidationRenderer.renderMarkdown(report);
      expect(markdown, contains('# Automated Validation Center — Package Health Report'));
      expect(markdown, contains('**Overall Health Status:** `HEALTHY`'));
      expect(markdown, contains('## Category Summary Dashboard'));
      expect(markdown, contains('## Detailed Check Matrix'));
      expect(markdown, contains('| **Static Analysis** |'));

      // 3. JSON
      final json = StudioValidationRenderer.renderJson(report);
      expect(json, contains('"report_id"'));
      expect(json, contains('"overall_health": "healthy"'));
      expect(json, contains('"category_summaries"'));
    });
  });
}
