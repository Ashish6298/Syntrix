import 'package:flutter_package_studio_core/src/testing/coverage/coverage_models.dart';
import 'package:flutter_package_studio_core/src/testing/runner/test_runner_models.dart';

/// Options configuring test report generation.
class ReportOptions {
  final String packageName;
  final String profile; // 'unit', 'widget', 'integration', 'all'
  final String outputFormat; // 'markdown', 'json'

  const ReportOptions({
    required this.packageName,
    this.profile = 'all',
    this.outputFormat = 'markdown',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'outputFormat': outputFormat,
      };
}

/// Preview plan of report generation.
class ReportPlan {
  final String packageName;
  final String profile;
  final String outputFormat;

  const ReportPlan({
    required this.packageName,
    required this.profile,
    required this.outputFormat,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'outputFormat': outputFormat,
      };
}

/// Aggregate test execution and coverage report model.
class AggregateTestReport {
  final String packageName;
  final TestExecutionResult? executionResult;
  final CoverageResult? coverageResult;

  const AggregateTestReport({
    required this.packageName,
    this.executionResult,
    this.coverageResult,
  });

  bool get overallSuccess =>
      (executionResult?.success ?? true) && (coverageResult?.isPassed ?? true);

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Test & Coverage Report: $packageName');
    buf.writeln();
    buf.writeln(
        '**Overall Status**: ${overallSuccess ? "PASSED ✓" : "FAILED ✗"}');
    buf.writeln();

    buf.writeln('## Execution Summary');
    if (executionResult != null) {
      buf.writeln('- Passed Suites: ${executionResult!.passedCount}');
      buf.writeln('- Failed Suites: ${executionResult!.failedCount}');
    } else {
      buf.writeln('_Execution evidence unavailable._');
    }
    buf.writeln();

    buf.writeln('## Coverage Summary');
    if (coverageResult != null) {
      buf.writeln(
          '- Overall Line Coverage: ${coverageResult!.overallPercentage.toStringAsFixed(1)}%');
      buf.writeln(
          '- Threshold Status: ${coverageResult!.isPassed ? "PASSED ✓" : "FAILED ✗"}');
    } else {
      buf.writeln('_Coverage evidence unavailable._');
    }

    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'overallSuccess': overallSuccess,
        'execution': executionResult?.toJson(),
        'coverage': coverageResult?.toJson(),
      };
}
