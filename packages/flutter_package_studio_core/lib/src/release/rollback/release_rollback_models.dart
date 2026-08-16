/// Target release snapshot to recover to.
class RollbackTarget {
  final String version;
  final String channel;
  final String manifestChecksum;

  const RollbackTarget({
    required this.version,
    required this.channel,
    required this.manifestChecksum,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'channel': channel,
        'manifestChecksum': manifestChecksum,
      };
}

/// Evaluation status of release rollback/recovery.
enum RollbackStatus {
  planned,
  passed,
  failed,
  blocked,
  recovered,
  dryRunSuccess,
}

/// Options configuring release rollback & recovery.
class RollbackOptions {
  final String packageName;
  final String currentVersion;
  final String targetVersion;
  final String channel;
  final bool recover;
  final String outputDir;

  const RollbackOptions({
    required this.packageName,
    this.currentVersion = '1.1.0',
    this.targetVersion = '1.0.0',
    this.channel = 'stable',
    this.recover = false,
    this.outputDir = 'doc/release',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'currentVersion': currentVersion,
        'targetVersion': targetVersion,
        'channel': channel,
        'recover': recover,
        'outputDir': outputDir,
      };
}

/// Preview plan of release rollback & recovery.
class ReleaseRollbackPlan {
  final String packageName;
  final String currentVersion;
  final RollbackTarget target;
  final RollbackStatus status;

  const ReleaseRollbackPlan({
    required this.packageName,
    required this.currentVersion,
    required this.target,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'currentVersion': currentVersion,
        'target': target.toJson(),
        'status': status.name,
      };
}

/// Result of release rollback & recovery execution.
class ReleaseRollbackResult {
  final String packageName;
  final String currentVersion;
  final String targetVersion;
  final bool isSuccess;
  final RollbackStatus status;
  final String details;

  const ReleaseRollbackResult({
    required this.packageName,
    required this.currentVersion,
    required this.targetVersion,
    required this.isSuccess,
    required this.status,
    required this.details,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Release Rollback & Recovery Report: $packageName');
    buf.writeln();
    buf.writeln('**Current Version**: $currentVersion');
    buf.writeln('**Target Rollback Version**: $targetVersion');
    buf.writeln('**Recovery Status**: ${status.name.toUpperCase()}');
    buf.writeln(
        '**Result**: ${isSuccess ? "RECOVERY SUCCESS ✓" : "RECOVERY BLOCKED / FAILED ✗"}');
    buf.writeln();
    buf.writeln('### Details');
    buf.writeln(details);
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'currentVersion': currentVersion,
        'targetVersion': targetVersion,
        'isSuccess': isSuccess,
        'status': status.name,
        'details': details,
      };
}
