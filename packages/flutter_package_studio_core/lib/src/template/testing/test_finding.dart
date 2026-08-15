/// Structured finding model for template testing.
library;

import 'package:flutter_package_studio_core/src/template/hooks/hook_context.dart';

/// Severity level of a template test finding.
enum TemplateTestSeverity {
  /// Informational finding.
  info,

  /// Warning finding.
  warning,

  /// Error finding.
  error;
}

/// Category of template test.
enum TemplateTestCategory {
  /// Manifest structure and semver identity tests.
  manifest,

  /// Dependency resolution and cycle tests.
  dependency,

  /// SDK and platform compatibility tests.
  compatibility,

  /// File and path security bounds tests.
  security,

  /// Placeholder syntax and rendering tests.
  placeholder,

  /// Layer composition and provenance tests.
  composition,

  /// Customization variable and condition tests.
  customization,

  /// Lifecycle hook registration and security tests.
  hooks,

  /// Quality engine findings verification tests.
  quality,

  /// Certification eligibility tests.
  certification,

  /// Generation plan determinism tests.
  generation;
}

/// Represents an individual finding produced during template test evaluation.
class TemplateTestFinding {
  /// Unique identifier of the test that produced this finding.
  final String testId;

  /// Finding category.
  final TemplateTestCategory category;

  /// Severity level.
  final TemplateTestSeverity severity;

  /// Human-readable message (secrets automatically redacted).
  final String message;

  /// Associated relative file path (if applicable).
  final String? filePath;

  /// Recommended remediation advice for resolving this finding.
  final String? remediationAdvice;

  /// Creates a [TemplateTestFinding].
  TemplateTestFinding({
    required this.testId,
    required this.category,
    required this.severity,
    required String message,
    this.filePath,
    this.remediationAdvice,
  }) : message = TemplateHookContext.redactSecrets(message);

  /// Returns `true` if this finding is an error.
  bool get isError => severity == TemplateTestSeverity.error;

  /// Returns `true` if this finding is a warning.
  bool get isWarning => severity == TemplateTestSeverity.warning;

  /// Serializes finding to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'category': category.name,
      'severity': severity.name,
      'message': message,
      if (filePath != null) 'filePath': filePath,
      if (remediationAdvice != null) 'remediationAdvice': remediationAdvice,
    };
  }
}
