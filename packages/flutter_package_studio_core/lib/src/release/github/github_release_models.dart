/// Opaque container for GitHub authentication credentials with automatic string redaction.
class GitHubCredential {
  final String token;

  const GitHubCredential(this.token);

  @override
  String toString() => '[REDACTED_GITHUB_TOKEN]';

  Map<String, dynamic> toJson() => {'token': '[REDACTED]'};
}

/// Options configuring GitHub release planning and execution.
class GitHubReleaseOptions {
  final String packageName;
  final String version;
  final String tagName;
  final String targetCommitish;
  final String releaseTitle;
  final String releaseBody;
  final String channel;
  final bool isDraft;
  final bool updateExisting;
  final List<String> artifacts;
  final String outputDir;

  const GitHubReleaseOptions({
    required this.packageName,
    required this.version,
    required this.tagName,
    this.targetCommitish = 'main',
    required this.releaseTitle,
    required this.releaseBody,
    this.channel = 'stable',
    this.isDraft = false,
    this.updateExisting = false,
    this.artifacts = const ['package.tar.gz', 'package.zip', 'manifest.json'],
    this.outputDir = 'doc/release',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'tagName': tagName,
        'targetCommitish': targetCommitish,
        'releaseTitle': releaseTitle,
        'channel': channel,
        'isDraft': isDraft,
        'updateExisting': updateExisting,
        'artifacts': artifacts,
        'outputDir': outputDir,
      };
}

/// Immutable plan describing a GitHub release to be created or updated.
class GitHubReleasePlan {
  final String packageName;
  final String version;
  final String tagName;
  final String targetCommitish;
  final String releaseTitle;
  final String releaseBody;
  final bool isPrerelease;
  final bool isDraft;
  final bool updateExisting;
  final List<String> artifacts;
  final bool isValid;
  final String details;

  const GitHubReleasePlan({
    required this.packageName,
    required this.version,
    required this.tagName,
    required this.targetCommitish,
    required this.releaseTitle,
    required this.releaseBody,
    required this.isPrerelease,
    required this.isDraft,
    required this.updateExisting,
    required this.artifacts,
    required this.isValid,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'tagName': tagName,
        'targetCommitish': targetCommitish,
        'releaseTitle': releaseTitle,
        'isPrerelease': isPrerelease,
        'isDraft': isDraft,
        'updateExisting': updateExisting,
        'artifacts': artifacts,
        'isValid': isValid,
        'details': details,
      };
}

/// Result of executing GitHub release operations.
class GitHubReleaseResult {
  final String packageName;
  final String tagName;
  final String releaseUrl;
  final bool isExecuted;
  final bool isDraft;
  final List<String> uploadedArtifacts;
  final String details;

  const GitHubReleaseResult({
    required this.packageName,
    required this.tagName,
    required this.releaseUrl,
    required this.isExecuted,
    required this.isDraft,
    required this.uploadedArtifacts,
    required this.details,
  });

  String toMarkdownReport() {
    final buf = StringBuffer();
    buf.writeln('# GitHub Release Integration Report: $packageName');
    buf.writeln();
    buf.writeln('**Target Tag**: $tagName');
    buf.writeln('**Release URL**: $releaseUrl');
    buf.writeln('**Draft Status**: ${isDraft ? "DRAFT" : "PUBLISHED"}');
    buf.writeln(
        '**Status**: ${isExecuted ? "EXECUTED (RELEASE CREATED/UPDATED) ✓" : "PREVIEW DRY-RUN (NOT EXECUTED)"}');
    buf.writeln();
    buf.writeln('### Uploaded Artifacts');
    for (final a in uploadedArtifacts) {
      buf.writeln('- $a');
    }
    buf.writeln();
    buf.writeln('### Details');
    buf.writeln(details);
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'tagName': tagName,
        'releaseUrl': releaseUrl,
        'isExecuted': isExecuted,
        'isDraft': isDraft,
        'uploadedArtifacts': uploadedArtifacts,
        'details': details,
      };
}
