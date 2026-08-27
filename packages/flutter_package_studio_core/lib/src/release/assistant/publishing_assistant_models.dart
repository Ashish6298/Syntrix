/// Explicit authorization model required for executing release pipeline stages.
class PublishingAuthorization {
  final String authorizedBy;
  final bool isAuthorized;
  final String timestamp;

  const PublishingAuthorization({
    required this.authorizedBy,
    required this.isAuthorized,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'authorizedBy': authorizedBy,
        'isAuthorized': isAuthorized,
        'timestamp': timestamp,
      };
}

/// Status classification for an individual pipeline stage execution.
enum StageStatus {
  pending,
  inProgress,
  success,
  failed,
  skipped,
  rolledBack,
  manualInterventionRequired,
}

/// Individual recorded unit of a pipeline stage execution.
class StageRecord {
  final String stageName;
  final StageStatus status;
  final String timestamp;
  final String details;
  final Map<String, dynamic> evidence;
  final bool isRollbackable;

  const StageRecord({
    required this.stageName,
    required this.status,
    required this.timestamp,
    required this.details,
    this.evidence = const {},
    this.isRollbackable = false,
  });

  Map<String, dynamic> toJson() => {
        'stageName': stageName,
        'status': status.name,
        'timestamp': timestamp,
        'details': details,
        'evidence': evidence,
        'isRollbackable': isRollbackable,
      };
}

/// Options configuring the Release Publishing Assistant execution pipeline.
class PublishingAssistantOptions {
  final String packageName;
  final String currentVersion;
  final String targetVersion;
  final String channel;
  final bool isDraft;
  final String outputDir;
  final List<String>? availableArtifacts;
  final List<String>? existingGitHubReleases;
  final PublishingAuthorization? authorization;
  final bool simulateSecurityFailure;
  final bool simulateCertificationFailure;
  final bool simulateGitTagFailure;
  final bool simulatePublishFailure;

  const PublishingAssistantOptions({
    required this.packageName,
    this.currentVersion = '1.0.0',
    this.targetVersion = '1.1.0',
    this.channel = 'stable',
    this.isDraft = false,
    this.outputDir = 'doc/release',
    this.availableArtifacts,
    this.existingGitHubReleases,
    this.authorization,
    this.simulateSecurityFailure = false,
    this.simulateCertificationFailure = false,
    this.simulateGitTagFailure = false,
    this.simulatePublishFailure = false,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'currentVersion': currentVersion,
        'targetVersion': targetVersion,
        'channel': channel,
        'isDraft': isDraft,
        'outputDir': outputDir,
        'availableArtifacts': availableArtifacts,
        'existingGitHubReleases': existingGitHubReleases,
        'authorization': authorization?.toJson(),
        'simulateSecurityFailure': simulateSecurityFailure,
        'simulateCertificationFailure': simulateCertificationFailure,
        'simulateGitTagFailure': simulateGitTagFailure,
        'simulatePublishFailure': simulatePublishFailure,
      };
}

/// Complete result object summarizing pipeline execution, stage records, and rollback state.
class PublishingExecutionResult {
  final String packageName;
  final String targetVersion;
  final bool isSuccess;
  final String summary;
  final List<StageRecord> stageRecords;
  final List<String> rollbackLog;

  const PublishingExecutionResult({
    required this.packageName,
    required this.targetVersion,
    required this.isSuccess,
    required this.summary,
    required this.stageRecords,
    required this.rollbackLog,
  });

  String toFormattedReport() {
    final buf = StringBuffer();
    buf.writeln('RELEASE PUBLISHING EXECUTION REPORT');
    buf.writeln('===================================');
    buf.writeln('Package: $packageName');
    buf.writeln('Version: $targetVersion');
    buf.writeln('Status : ${isSuccess ? "SUCCESS ✓" : "FAILED / STOPPED ✗"}');
    buf.writeln();
    buf.writeln('### STAGE EXECUTION RECORDS');
    for (final s in stageRecords) {
      buf.writeln(
          '- [${s.status.name.toUpperCase()}] ${s.stageName}: ${s.details}');
    }
    if (rollbackLog.isNotEmpty) {
      buf.writeln();
      buf.writeln('### ROLLBACK LOG');
      for (final r in rollbackLog) {
        buf.writeln('- $r');
      }
    }
    buf.writeln();
    buf.writeln('Summary: $summary');
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'targetVersion': targetVersion,
        'isSuccess': isSuccess,
        'summary': summary,
        'stageRecords': stageRecords.map((s) => s.toJson()).toList(),
        'rollbackLog': rollbackLog,
      };
}
