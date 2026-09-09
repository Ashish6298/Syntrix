/// Severity level of a security finding.
enum SecurityFindingSeverity {
  info,
  warning,
  error,
  critical,
}

/// Category of security issue detected during release audit.
enum SecurityFindingType {
  apiKey,
  accessToken,
  privateKey,
  password,
  envFile,
  sensitiveFile,
  unsafePath,
}

/// An individual security finding with redacted sensitive content.
class SecurityFinding {
  final String id;
  final String path;
  final SecurityFindingType type;
  final SecurityFindingSeverity severity;
  final String description;
  final String redactedValue;

  const SecurityFinding({
    required this.id,
    required this.path,
    required this.type,
    required this.severity,
    required this.description,
    this.redactedValue = '[REDACTED]',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'type': type.name,
        'severity': severity.name,
        'description': description,
        'redactedValue': redactedValue,
      };
}

/// Target scope representation for security audit scan.
class SecurityScanTarget {
  final String path;
  final String targetType;

  const SecurityScanTarget({
    required this.path,
    required this.targetType,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'targetType': targetType,
      };
}

/// Options configuring release security & secret audit.
class SecurityAuditOptions {
  final String packageName;
  final String version;
  final String profile; // 'standard', 'strict'
  final String? artifactDir;
  final String? manifestPath;
  final String outputDir;

  const SecurityAuditOptions({
    required this.packageName,
    this.version = '1.0.0',
    this.profile = 'standard',
    this.artifactDir,
    this.manifestPath,
    this.outputDir = 'doc/release',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'profile': profile,
        if (artifactDir != null) 'artifactDir': artifactDir,
        if (manifestPath != null) 'manifestPath': manifestPath,
        'outputDir': outputDir,
      };
}

/// Preview plan of security scan checks and targets.
class ReleaseSecurityAuditPlan {
  final String packageName;
  final String version;
  final String profile;
  final List<SecurityScanTarget> targets;

  const ReleaseSecurityAuditPlan({
    required this.packageName,
    required this.version,
    required this.profile,
    required this.targets,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'profile': profile,
        'targetCount': targets.length,
        'targets': targets.map((t) => t.toJson()).toList(),
      };
}

/// Result of release security and secret audit.
class ReleaseSecurityAuditResult {
  final String packageName;
  final String version;
  final bool isClean;
  final List<SecurityFinding> findings;

  const ReleaseSecurityAuditResult({
    required this.packageName,
    required this.version,
    required this.isClean,
    required this.findings,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Release Security & Secret Audit Report: $packageName');
    buf.writeln();
    buf.writeln('**Package Version**: $version');
    buf.writeln(
        '**Audit Status**: ${isClean ? "CLEAN ✓" : "SECURITY ISSUES DETECTED ✗"}');
    buf.writeln();
    if (findings.isEmpty) {
      buf.writeln(
          'No security violations, credentials, or unsafe files detected.');
    } else {
      buf.writeln(
          '| Finding ID | File Path | Type | Severity | Description | Value |');
      buf.writeln('|---|---|---|---|---|---|');
      for (final f in findings) {
        buf.writeln(
            '| ${f.id} | ${f.path} | ${f.type.name} | ${f.severity.name.toUpperCase()} | ${f.description} | ${f.redactedValue} |');
      }
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'isClean': isClean,
        'findingCount': findings.length,
        'findings': findings.map((f) => f.toJson()).toList(),
      };
}
