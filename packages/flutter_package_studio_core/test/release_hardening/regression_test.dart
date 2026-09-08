import 'package:flutter_package_studio_core/src/release_hardening/release_hardening.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 11.3: Full Regression Testing Models', () {
    test('RegressionTestItem and RegressionTestReport JSON roundtrip', () {
      const item = RegressionTestItem(
        category: RegressionTestCategory.unitAndWidgetTests,
        command: 'flutter test',
        status: RegressionStepStatus.passed,
        verificationDetails: '178 tests passed cleanly.',
        durationMs: 3200,
      );

      final report = RegressionTestReport(
        reportId: 'regression_test_01',
        targetVersion: '1.0.0',
        isRegressionPassed: true,
        totalChecks: 1,
        totalTestsRun: 178,
        coveragePercentage: 98.6,
        testItems: [item],
        testedAt: DateTime.parse('2026-09-08T12:00:00Z'),
      );

      final json = report.toJson();
      final restored = RegressionTestReport.fromJson(json);

      expect(restored.reportId, equals('regression_test_01'));
      expect(restored.targetVersion, equals('1.0.0'));
      expect(restored.isRegressionPassed, isTrue);
      expect(restored.totalChecks, equals(1));
      expect(restored.totalTestsRun, equals(178));
      expect(restored.coveragePercentage, closeTo(98.6, 0.01));
      expect(restored.testItems.length, equals(1));
      expect(restored.testItems.first.category, equals(RegressionTestCategory.unitAndWidgetTests));
      expect(restored.testItems.first.status, equals(RegressionStepStatus.passed));
    });
  });

  group('Phase 11.3: Full Regression Engine Operations', () {
    test('Runs full regression suite and verifies all 6 matrix dimensions', () {
      final engine = RegressionTestEngine();
      final report = engine.runRegressionSuite(
        targetVersion: '1.0.0',
        totalTestsExecuted: 178,
        coverage: 98.6,
      );

      expect(report.isRegressionPassed, isTrue);
      expect(report.targetVersion, equals('1.0.0'));
      expect(report.totalChecks, equals(6));
      expect(report.totalTestsRun, equals(178));
      expect(report.coveragePercentage, greaterThanOrEqualTo(95.0));

      final categories = report.testItems.map((i) => i.category).toSet();
      expect(categories, contains(RegressionTestCategory.cleanAndDeps));
      expect(categories, contains(RegressionTestCategory.staticAnalysis));
      expect(categories, contains(RegressionTestCategory.documentationGeneration));
      expect(categories, contains(RegressionTestCategory.unitAndWidgetTests));
      expect(categories, contains(RegressionTestCategory.codeCoverage));
      expect(categories, contains(RegressionTestCategory.minimumDependencyCompatibility));

      for (final item in report.testItems) {
        expect(item.status, equals(RegressionStepStatus.passed));
      }
    });
  });

  group('Phase 11.3: Full Regression Renderer', () {
    test('Renders ASCII Test Dashboard, Markdown report, and JSON schema', () {
      final engine = RegressionTestEngine();
      final report = engine.runRegressionSuite(
        targetVersion: '1.0.0',
        totalTestsExecuted: 178,
        coverage: 98.6,
      );

      // 1. ASCII Dashboard
      final ascii = RegressionTestRenderer.renderAsciiRegressionDashboard(report);
      expect(ascii, contains('PHASE 11.3 — FULL REGRESSION TEST MATRIX'));
      expect(ascii, contains('Static Analysis (Analyze)'));
      expect(ascii, contains('Code Coverage Certification'));
      expect(ascii, contains('Target Release: v1.0.0 (CERTIFIED)'));

      // 2. Markdown Report
      final markdown = RegressionTestRenderer.renderMarkdown(report);
      expect(markdown, contains('# Milestone 11 — Phase 11.3: Full Regression Testing Report'));
      expect(markdown, contains('**Regression Suite Status:** `PASSED (100% Green)`'));
      expect(markdown, contains('**Line Coverage:** `98.6%`'));
      expect(markdown, contains('**Phase 11.4 — Platform Verification**'));

      // 3. JSON
      final json = RegressionTestRenderer.renderJson(report);
      expect(json, contains('"report_id"'));
      expect(json, contains('"is_regression_passed": true'));
      expect(json, contains('"coverage_percentage": 98.6'));
      expect(json, contains('"test_items"'));
    });
  });
}
