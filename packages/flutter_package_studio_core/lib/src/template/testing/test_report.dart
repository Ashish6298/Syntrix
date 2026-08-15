/// Aggregated template test report model.
library;

import 'package:flutter_package_studio_core/src/template/testing/test_finding.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_result.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_status.dart';

/// Aggregated, immutable report summarizing a template test run.
class TemplateTestReport {
  /// Target template identifier.
  final String templateId;

  /// Target template version.
  final String version;

  /// Applied testing profile.
  final TemplateTestProfile profile;

  /// Overall status.
  final TemplateTestStatus status;

  /// Individual test execution results.
  final List<TemplateTestResult> results;

  /// Aggregated findings from all tests.
  final List<TemplateTestFinding> findings;

  /// Number of passed tests.
  final int passedCount;

  /// Number of failed tests.
  final int failedCount;

  /// Number of skipped tests.
  final int skippedCount;

  /// Total duration of test execution.
  final Duration totalDuration;

  /// Creates a [TemplateTestReport].
  const TemplateTestReport({
    required this.templateId,
    required this.version,
    required this.profile,
    required this.status,
    required this.results,
    required this.findings,
    required this.passedCount,
    required this.failedCount,
    required this.skippedCount,
    required this.totalDuration,
  });

  /// Returns `true` if all tests passed without failure.
  bool get isPassed => status == TemplateTestStatus.passed;

  /// Returns `true` if the template has been verified by the test framework.
  bool get isTested => results.isNotEmpty;

  /// Returns `true` if the template meets criteria to enter formal certification.
  bool get isEligibleForCertification => isPassed;

  /// Count of error findings.
  int get errorCount => findings.where((f) => f.isError).length;

  /// Count of warning findings.
  int get warningCount => findings.where((f) => f.isWarning).length;

  /// Serializes report to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'templateId': templateId,
      'version': version,
      'profile': profile.name,
      'status': status.name,
      'isPassed': isPassed,
      'isTested': isTested,
      'isEligibleForCertification': isEligibleForCertification,
      'passedCount': passedCount,
      'failedCount': failedCount,
      'skippedCount': skippedCount,
      'errorCount': errorCount,
      'warningCount': warningCount,
      'totalDurationMs': totalDuration.inMilliseconds,
      'results': results.map((r) => r.toJson()).toList(),
      'findings': findings.map((f) => f.toJson()).toList(),
    };
  }
}
