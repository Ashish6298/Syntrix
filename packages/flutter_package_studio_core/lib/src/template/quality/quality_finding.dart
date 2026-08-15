/// Severity level of a template quality finding.
enum TemplateQualitySeverity {
  info,
  warning,
  error,
}

/// Category of template quality inspection rule.
enum TemplateQualityCategory {
  manifest,
  schema,
  placeholder,
  pathSecurity,
  conflict,
  metadata,
  pattern,
}

/// Structured finding produced by a [TemplateQualityRule].
class TemplateQualityFinding implements Comparable<TemplateQualityFinding> {
  final String ruleId;
  final TemplateQualityCategory category;
  final TemplateQualitySeverity severity;
  final String message;
  final String? filePath;
  final String? remediation;

  const TemplateQualityFinding({
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
        if (filePath != null) 'filePath': filePath,
        if (remediation != null) 'remediation': remediation,
      };

  @override
  int compareTo(TemplateQualityFinding other) {
    final sev = severity.index.compareTo(other.severity.index);
    if (sev != 0) return sev;
    final cat = category.index.compareTo(other.category.index);
    if (cat != 0) return cat;
    final r = ruleId.compareTo(other.ruleId);
    if (r != 0) return r;
    return message.compareTo(other.message);
  }

  @override
  String toString() =>
      '[${severity.name.toUpperCase()}/${category.name}] ($ruleId) $message'
      '${filePath != null ? " @ $filePath" : ""}';
}
