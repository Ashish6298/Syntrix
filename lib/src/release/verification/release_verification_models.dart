/// Evaluation status of an individual pipeline verification stage.
enum VerificationStageStatus {
  passed,
  failed,
  blocked,
  skipped,
  notRun,
  insufficientEvidence,
  unavailable,
}

/// Verification stage representation in the pipeline.
class VerificationStage {
  final String id;
  final String name;
  final VerificationStageStatus status;
  final String details;

  const VerificationStage({
    required this.id,
    required this.name,
    required this.status,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status.name,
        'details': details,
      };
}

/// Verification policy controlling pipeline strictness.
class VerificationPolicy {
  final String profile; // 'standard', 'strict', 'custom'

  const VerificationPolicy({
    this.profile = 'standard',
  });

  Map<String, dynamic> toJson() => {
        'profile': profile,
      };
}

/// Options configuring release verification pipeline.
class ReleaseVerificationOptions {
  final String packageName;
  final String version;
  final String profile;
  final String outputDir;

  const ReleaseVerificationOptions({
    required this.packageName,
    this.version = '1.0.0',
    this.profile = 'standard',
    this.outputDir = 'doc/release',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'profile': profile,
        'outputDir': outputDir,
      };
}

/// Preview plan of release verification pipeline stages.
class ReleaseVerificationPlan {
  final String packageName;
  final String version;
  final VerificationPolicy policy;
  final List<VerificationStage> stages;

  const ReleaseVerificationPlan({
    required this.packageName,
    required this.version,
    required this.policy,
    required this.stages,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'policy': policy.toJson(),
        'stageCount': stages.length,
        'stages': stages.map((s) => s.toJson()).toList(),
      };
}

/// Result of release verification pipeline evaluation.
class ReleaseVerificationResult {
  final String packageName;
  final String version;
  final bool isReady;
  final List<VerificationStage> stages;

  const ReleaseVerificationResult({
    required this.packageName,
    required this.version,
    required this.isReady,
    required this.stages,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Release Verification Pipeline Report: $packageName');
    buf.writeln();
    buf.writeln('**Package Version**: $version');
    buf.writeln(
        '**Release Gate Decision**: ${isReady ? "READY FOR RELEASE ✓" : "NOT READY / BLOCKED ✗"}');
    buf.writeln();
    buf.writeln('| Stage ID | Stage Name | Status | Details |');
    buf.writeln('|---|---|---|---|');
    for (final s in stages) {
      buf.writeln(
          '| ${s.id} | ${s.name} | ${s.status.name.toUpperCase()} | ${s.details} |');
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'isReady': isReady,
        'stageCount': stages.length,
        'stages': stages.map((s) => s.toJson()).toList(),
      };
}
