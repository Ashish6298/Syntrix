import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('TestReportGenerator Unit Tests', () {
    late TestReportGenerator generator;

    setUp(() {
      generator = TestReportGenerator();
    });

    test('Plans test report generation', () {
      const options = ReportOptions(packageName: 'awesome_pkg');
      final plan = generator.planTestReport(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.outputFormat, equals('markdown'));
    });

    test('Generates report aggregating execution and coverage results', () {
      const options = ReportOptions(packageName: 'awesome_pkg');
      final plan = generator.planTestReport(options);

      const execResult = TestExecutionResult(
        packageName: 'awesome_pkg',
        success: true,
        passedCount: 3,
        failedCount: 0,
        logs: ['Log 1'],
      );

      const covResult = CoverageResult(
        packageName: 'awesome_pkg',
        isPassed: true,
        totalLines: 100,
        coveredLines: 85,
        files: [],
      );

      final report = generator.generateReport(plan,
          executionResult: execResult, coverageResult: covResult);

      expect(report.packageName, equals('awesome_pkg'));
      expect(report.overallSuccess, isTrue);

      final md = report.toMarkdown();
      expect(md, contains('# Test & Coverage Report: awesome_pkg'));
      expect(md, contains('Passed Suites: 3'));
      expect(md, contains('Overall Line Coverage: 85.0%'));
    });

    test('Rejects empty package names', () {
      const options = ReportOptions(packageName: '');
      expect(() => generator.planTestReport(options),
          throwsA(isA<TestReportGenerationException>()));
    });
  });
}
