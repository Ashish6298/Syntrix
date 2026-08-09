/// Severity levels for validation issues.
enum ValidationSeverity {
  /// Informational finding that does not impact quality or functionality.
  info,

  /// Warning finding indicating potential improvement or non-critical issue.
  warning,

  /// Error finding indicating structural failure or violation.
  error,
}

/// Categories for organizing validation rules.
enum ValidationCategory {
  structure,
  pubspec,
  source,
  api,
  documentation,
  testing,
  example,
  repository,
  github,
  security,
  publishing,
}

/// An individual validation finding/issue produced by a rule.
class ValidationIssue {
  /// Unique rule identifier.
  final String ruleId;

  /// Category of the validation issue.
  final ValidationCategory category;

  /// Severity level of the issue.
  final ValidationSeverity severity;

  /// Human-readable message describing the issue.
  final String message;

  /// Optional relative file path affected by the issue.
  final String? filePath;

  /// Optional actionable guidance to fix the issue.
  final String? remediation;

  /// Creates a [ValidationIssue] instance.
  const ValidationIssue({
    required this.ruleId,
    required this.category,
    required this.severity,
    required this.message,
    this.filePath,
    this.remediation,
  });

  Map<String, dynamic> toJson() => {
        'ruleId': ruleId,
        'category': category.name,
        'severity': severity.name,
        'message': message,
        'filePath': filePath,
        'remediation': remediation,
      };
}

/// Validation request context detailing target directory and profile.
class ValidationRequest {
  /// Target root directory of package to validate.
  final String targetDirectory;

  /// Selected profile identifier (`basic`, `standard`, `strict`, `release`).
  final String profile;

  /// Optional filter set of category names.
  final Set<ValidationCategory>? categories;

  /// Optional filter set of specific rule IDs.
  final Set<String>? ruleIds;

  /// Creates a [ValidationRequest] instance.
  const ValidationRequest({
    required this.targetDirectory,
    this.profile = 'standard',
    this.categories,
    this.ruleIds,
  });
}

/// Summary counts of validation issues.
class ValidationSummary {
  final int totalRulesExecuted;
  final int passedRulesCount;
  final int infoCount;
  final int warningCount;
  final int errorCount;

  const ValidationSummary({
    required this.totalRulesExecuted,
    required this.passedRulesCount,
    required this.infoCount,
    required this.warningCount,
    required this.errorCount,
  });

  Map<String, dynamic> toJson() => {
        'totalRulesExecuted': totalRulesExecuted,
        'passedRulesCount': passedRulesCount,
        'infoCount': infoCount,
        'warningCount': warningCount,
        'errorCount': errorCount,
      };
}

/// Comprehensive, immutable report produced by [ValidationEngine].
class ValidationReport {
  /// Target directory path validated.
  final String targetDirectory;

  /// Profile name used for validation run.
  final String profile;

  /// Duration spent in validation run.
  final Duration duration;

  /// List of all validation issues discovered.
  final List<ValidationIssue> issues;

  /// Summary metric metrics.
  final ValidationSummary summary;

  /// Creates a [ValidationReport] instance.
  const ValidationReport({
    required this.targetDirectory,
    required this.profile,
    required this.duration,
    required this.issues,
    required this.summary,
  });

  /// `true` if there are 0 errors in report.
  bool get isValid => summary.errorCount == 0;

  Map<String, dynamic> toJson() => {
        'targetDirectory': targetDirectory,
        'profile': profile,
        'durationMs': duration.inMilliseconds,
        'isValid': isValid,
        'summary': summary.toJson(),
        'issues': issues.map((i) => i.toJson()).toList(),
      };
}
