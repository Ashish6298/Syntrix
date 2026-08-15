/// Structured certification finding model.
library;

import 'package:flutter_package_studio_core/src/template/certification/certification_evidence.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_context.dart';

/// Severity level of a certification finding.
enum TemplateCertificationSeverity {
  /// Informational finding.
  info,

  /// Warning finding (non-blocking in basic/standard, promoted in release).
  warning,

  /// Blocking error finding.
  error;
}

/// Category of certification check.
enum TemplateCertificationCategory {
  /// Manifest structure and semver identity checks.
  manifest,

  /// Template dependencies and resolution checks.
  dependency,

  /// SDK and platform compatibility checks.
  compatibility,

  /// File and path security bounds checks.
  security,

  /// Layer composition and file provenance checks.
  composition,

  /// Customization variable and condition checks.
  customization,

  /// Lifecycle hook registration and security checks.
  hooks,

  /// Quality engine quality finding aggregation checks.
  quality,

  /// Metadata completeness checks.
  metadata;
}

/// Represents an individual finding produced during certification evaluation.
class TemplateCertificationFinding {
  /// Rule identifier that produced this finding.
  final String ruleId;

  /// Finding category.
  final TemplateCertificationCategory category;

  /// Severity level.
  final TemplateCertificationSeverity severity;

  /// Human-readable message (secrets automatically redacted).
  final String message;

  /// Associated relative file path (if applicable).
  final String? filePath;

  /// Recommended remediation advice for resolving this finding.
  final String? remediationAdvice;

  /// Supporting evidence items attached to this finding.
  final List<TemplateCertificationEvidence> evidence;

  /// Creates a [TemplateCertificationFinding].
  TemplateCertificationFinding({
    required this.ruleId,
    required this.category,
    required this.severity,
    required String message,
    this.filePath,
    this.remediationAdvice,
    this.evidence = const [],
  }) : message = TemplateHookContext.redactSecrets(message);

  /// Returns `true` if this finding represents a blocking error.
  bool get isError => severity == TemplateCertificationSeverity.error;

  /// Returns `true` if this finding represents a warning.
  bool get isWarning => severity == TemplateCertificationSeverity.warning;

  /// Serializes finding to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'ruleId': ruleId,
      'category': category.name,
      'severity': severity.name,
      'message': message,
      if (filePath != null) 'filePath': filePath,
      if (remediationAdvice != null) 'remediationAdvice': remediationAdvice,
      if (evidence.isNotEmpty)
        'evidence': evidence.map((e) => e.toJson()).toList(),
    };
  }
}
