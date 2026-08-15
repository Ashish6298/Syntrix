/// Assertion definition and result models for template testing.
library;

import 'package:flutter_package_studio_core/src/template/hooks/hook_context.dart';

/// Represents an individual assertion expectation result.
class TemplateTestAssertionResult {
  /// Name of the assertion expectation.
  final String name;

  /// Whether the assertion passed.
  final bool passed;

  /// Diagnostic message explaining result (secrets automatically redacted).
  final String message;

  /// Expected value string representation.
  final String? expected;

  /// Actual value string representation.
  final String? actual;

  /// Creates a [TemplateTestAssertionResult].
  TemplateTestAssertionResult({
    required this.name,
    required this.passed,
    required String message,
    this.expected,
    this.actual,
  }) : message = TemplateHookContext.redactSecrets(message);

  /// Factory constructor for a passing assertion.
  factory TemplateTestAssertionResult.pass(String name,
      {String message = 'Assertion passed'}) {
    return TemplateTestAssertionResult(
      name: name,
      passed: true,
      message: message,
    );
  }

  /// Factory constructor for a failing assertion.
  factory TemplateTestAssertionResult.fail(String name,
      {required String message, String? expected, String? actual}) {
    return TemplateTestAssertionResult(
      name: name,
      passed: false,
      message: message,
      expected: expected,
      actual: actual,
    );
  }

  /// Serializes assertion result to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'passed': passed,
      'message': message,
      if (expected != null) 'expected': expected,
      if (actual != null) 'actual': actual,
    };
  }
}
