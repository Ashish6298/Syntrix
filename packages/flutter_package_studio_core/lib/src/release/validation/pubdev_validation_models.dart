/// Severity level of a validation check finding.
enum PubDevValidationSeverity {
  info,
  warning,
  error,
  critical,
}

/// Status of a pub.dev package validation check.
enum ValidationStatus {
  passed,
  failed,
  warning,
  skipped,
  unavailable,
  insufficientEvidence,
}

/// An individual validation check evaluated for pub.dev readiness.
class ValidationCheck {
  final String id;
  final String description;
  final ValidationStatus status;
  final PubDevValidationSeverity severity;
  final bool isMandatory;
  final String details;

  const ValidationCheck({
    required this.id,
    required this.description,
    required this.status,
    required this.severity,
    required this.isMandatory,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'status': status.name,
        'severity': severity.name,
        'isMandatory': isMandatory,
        'details': details,
      };
}

/// Options configuring pub.dev package validation.
class PubDevValidationOptions {
  final String packageName;
  final String version;
  final String profile; // 'standard', 'strict', 'offline'
  final String? artifactPath;
  final String configPath;

  const PubDevValidationOptions({
    required this.packageName,
    this.version = '1.0.0',
    this.profile = 'standard',
    this.artifactPath,
    this.configPath = 'pubdev_validation.json',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'profile': profile,
        if (artifactPath != null) 'artifactPath': artifactPath,
        'configPath': configPath,
      };
}

/// Preview plan of pub.dev validation checks.
class PubDevValidationPlan {
  final String packageName;
  final String version;
  final String profile;
  final List<ValidationCheck> checks;

  const PubDevValidationPlan({
    required this.packageName,
    required this.version,
    required this.profile,
    required this.checks,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'profile': profile,
        'checkCount': checks.length,
        'checks': checks.map((c) => c.toJson()).toList(),
      };
}

/// Result of pub.dev package validation.
class PubDevValidationResult {
  final String packageName;
  final String version;
  final bool isPublishable;
  final List<ValidationCheck> checks;

  const PubDevValidationResult({
    required this.packageName,
    required this.version,
    required this.isPublishable,
    required this.checks,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Pub.dev Package Validation Report: $packageName');
    buf.writeln();
    buf.writeln('**Package Version**: $version');
    buf.writeln(
        '**Publishable**: ${isPublishable ? "READY FOR PUB.DEV ✓" : "NOT READY ✗"}');
    buf.writeln();
    buf.writeln(
        '| Check ID | Description | Severity | Mandatory | Status | Details |');
    buf.writeln('|---|---|---|---|---|---|');
    for (final c in checks) {
      buf.writeln(
          '| ${c.id} | ${c.description} | ${c.severity.name.toUpperCase()} | ${c.isMandatory ? "YES" : "NO"} | ${c.status.name.toUpperCase()} | ${c.details} |');
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'isPublishable': isPublishable,
        'checkCount': checks.length,
        'checks': checks.map((c) => c.toJson()).toList(),
      };
}
