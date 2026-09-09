/// Status of a release readiness check.
enum ReadinessStatus {
  passed,
  warning,
  failed,
  missing,
  unavailable,
  notApplicable,
  blocked,
  insufficientEvidence,
}

/// Aggregate release readiness decision.
enum ReleaseDecision {
  ready,
  conditionallyReady,
  notReady,
  blocked,
  insufficientEvidence,
}

/// An individual requirement check evaluated during release planning.
class ReadinessCheck {
  final String id;
  final String description;
  final ReadinessStatus status;
  final bool isMandatory;
  final String details;

  const ReadinessCheck({
    required this.id,
    required this.description,
    required this.status,
    required this.isMandatory,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'status': status.name,
        'isMandatory': isMandatory,
        'details': details,
      };
}

/// Options configuring release planning and readiness evaluation.
class ReleasePlanningOptions {
  final String packageName;
  final String profile;
  final String targetVersion;
  final String configPath;

  const ReleasePlanningOptions({
    required this.packageName,
    this.profile = 'standard',
    this.targetVersion = '1.0.0',
    this.configPath = 'release_config.json',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'targetVersion': targetVersion,
        'configPath': configPath,
      };
}

/// Preview plan of release readiness checks.
class ReleasePlan {
  final String packageName;
  final String profile;
  final String targetVersion;
  final List<ReadinessCheck> plannedChecks;

  const ReleasePlan({
    required this.packageName,
    required this.profile,
    required this.targetVersion,
    required this.plannedChecks,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'targetVersion': targetVersion,
        'checkCount': plannedChecks.length,
        'plannedChecks': plannedChecks.map((c) => c.toJson()).toList(),
      };
}

/// Result of evaluating release readiness.
class ReleasePlanningResult {
  final String packageName;
  final String targetVersion;
  final ReleaseDecision decision;
  final List<ReadinessCheck> checks;

  const ReleasePlanningResult({
    required this.packageName,
    required this.targetVersion,
    required this.decision,
    required this.checks,
  });

  bool get isReady =>
      decision == ReleaseDecision.ready ||
      decision == ReleaseDecision.conditionallyReady;

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Release Readiness Plan Report: $packageName');
    buf.writeln();
    buf.writeln('**Target Version**: $targetVersion');
    buf.writeln('**Readiness Decision**: ${decision.name.toUpperCase()}');
    buf.writeln();
    buf.writeln('| Check ID | Description | Mandatory | Status | Details |');
    buf.writeln('|---|---|---|---|---|');
    for (final c in checks) {
      buf.writeln(
          '| ${c.id} | ${c.description} | ${c.isMandatory ? "YES" : "NO"} | ${c.status.name.toUpperCase()} | ${c.details} |');
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'targetVersion': targetVersion,
        'decision': decision.name,
        'isReady': isReady,
        'checkCount': checks.length,
        'checks': checks.map((c) => c.toJson()).toList(),
      };
}
