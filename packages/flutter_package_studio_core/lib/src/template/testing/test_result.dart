/// Individual test execution outcome model.
library;

import 'package:flutter_package_studio_core/src/template/hooks/hook_context.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_assertion.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_finding.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_status.dart';

/// Structured outcome of running a single template test.
class TemplateTestResult {
  /// Test identifier.
  final String testId;

  /// Test human-readable name.
  final String testName;

  /// Execution status.
  final TemplateTestStatus status;

  /// Execution duration.
  final Duration duration;

  /// List of evaluated assertions.
  final List<TemplateTestAssertionResult> assertions;

  /// List of findings produced during the test.
  final List<TemplateTestFinding> findings;

  /// Error details if the test threw an unexpected exception.
  final String? errorMessage;

  /// Creates a [TemplateTestResult].
  TemplateTestResult({
    required this.testId,
    required this.testName,
    required this.status,
    required this.duration,
    this.assertions = const [],
    this.findings = const [],
    String? errorMessage,
  }) : errorMessage = errorMessage != null
            ? TemplateHookContext.redactSecrets(errorMessage)
            : null;

  /// Factory constructor for successful execution.
  factory TemplateTestResult.passed({
    required String testId,
    required String testName,
    required Duration duration,
    List<TemplateTestAssertionResult> assertions = const [],
    List<TemplateTestFinding> findings = const [],
  }) {
    return TemplateTestResult(
      testId: testId,
      testName: testName,
      status: TemplateTestStatus.passed,
      duration: duration,
      assertions: assertions,
      findings: findings,
    );
  }

  /// Factory constructor for failed execution.
  factory TemplateTestResult.failed({
    required String testId,
    required String testName,
    required Duration duration,
    List<TemplateTestAssertionResult> assertions = const [],
    List<TemplateTestFinding> findings = const [],
    String? error,
  }) {
    return TemplateTestResult(
      testId: testId,
      testName: testName,
      status: TemplateTestStatus.failed,
      duration: duration,
      assertions: assertions,
      findings: findings,
      errorMessage: error,
    );
  }

  /// Factory constructor for skipped test.
  factory TemplateTestResult.skipped({
    required String testId,
    required String testName,
    String reason = 'Skipped based on active profile or condition',
  }) {
    return TemplateTestResult(
      testId: testId,
      testName: testName,
      status: TemplateTestStatus.skipped,
      duration: Duration.zero,
      assertions: [
        TemplateTestAssertionResult.pass('Skip Condition', message: reason)
      ],
    );
  }

  /// Returns `true` if test succeeded or was skipped.
  bool get isPassed => status.isSuccessful;

  /// Serializes result to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'testName': testName,
      'status': status.name,
      'durationMs': duration.inMilliseconds,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'assertions': assertions.map((a) => a.toJson()).toList(),
      'findings': findings.map((f) => f.toJson()).toList(),
    };
  }
}
