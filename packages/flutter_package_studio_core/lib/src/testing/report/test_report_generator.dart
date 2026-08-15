import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/testing/coverage/coverage_models.dart';
import 'package:flutter_package_studio_core/src/testing/report/report_models.dart';
import 'package:flutter_package_studio_core/src/testing/runner/test_runner_models.dart';

/// Core service for aggregating execution and coverage evidence into structured reports.
class TestReportGenerator {
  final Logger _logger = Logger('TestReportGenerator');

  /// Plans test report generation without process execution or disk writes.
  ReportPlan planTestReport(ReportOptions options) {
    _logger.info('Planning test report for "${options.packageName}"');

    if (options.packageName.trim().isEmpty) {
      throw TestReportGenerationException('Package name must not be empty.');
    }

    return ReportPlan(
      packageName: options.packageName,
      profile: options.profile,
      outputFormat: options.outputFormat,
    );
  }

  /// Aggregates optional [executionResult] and [coverageResult] into [AggregateTestReport].
  AggregateTestReport generateReport(
    ReportPlan plan, {
    TestExecutionResult? executionResult,
    CoverageResult? coverageResult,
  }) {
    _logger.info('Aggregating test report for "${plan.packageName}"');

    final cleanName = ReadmeSanitizer.escapeText(plan.packageName);

    return AggregateTestReport(
      packageName: cleanName,
      executionResult: executionResult,
      coverageResult: coverageResult,
    );
  }
}
