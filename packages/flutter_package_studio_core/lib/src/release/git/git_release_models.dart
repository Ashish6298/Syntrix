/// Represents snapshot state of a Git repository.
class GitReleaseState {
  final String currentBranch;
  final String currentCommit;
  final bool isClean;
  final List<String> existingTags;
  final List<String> existingBranches;

  const GitReleaseState({
    required this.currentBranch,
    required this.currentCommit,
    required this.isClean,
    required this.existingTags,
    required this.existingBranches,
  });

  Map<String, dynamic> toJson() => {
        'currentBranch': currentBranch,
        'currentCommit': currentCommit,
        'isClean': isClean,
        'existingTags': existingTags,
        'existingBranches': existingBranches,
      };
}

/// Options configuring Git tagging and release branching.
class GitReleaseOptions {
  final String packageName;
  final String version;
  final String? tagName;
  final String? branchName;
  final bool execute;
  final String outputDir;

  const GitReleaseOptions({
    required this.packageName,
    this.version = '1.0.0',
    this.tagName,
    this.branchName,
    this.execute = false,
    this.outputDir = 'doc/release',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        if (tagName != null) 'tagName': tagName,
        if (branchName != null) 'branchName': branchName,
        'execute': execute,
        'outputDir': outputDir,
      };
}

/// Plan for Git release tag and branch operations.
class GitReleasePlan {
  final String packageName;
  final String targetVersion;
  final String tagName;
  final String branchName;
  final bool isClean;
  final bool tagConflict;
  final bool branchConflict;
  final bool isValid;
  final String details;

  const GitReleasePlan({
    required this.packageName,
    required this.targetVersion,
    required this.tagName,
    required this.branchName,
    required this.isClean,
    required this.tagConflict,
    required this.branchConflict,
    required this.isValid,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'targetVersion': targetVersion,
        'tagName': tagName,
        'branchName': branchName,
        'isClean': isClean,
        'tagConflict': tagConflict,
        'branchConflict': branchConflict,
        'isValid': isValid,
        'details': details,
      };
}

/// Result of executing Git release tag and branch operations.
class GitReleaseResult {
  final String packageName;
  final String tagName;
  final String branchName;
  final bool isExecuted;
  final String details;

  const GitReleaseResult({
    required this.packageName,
    required this.tagName,
    required this.branchName,
    required this.isExecuted,
    required this.details,
  });

  String toMarkdownReport() {
    final buf = StringBuffer();
    buf.writeln('# Git Release Tag & Branch Report: $packageName');
    buf.writeln();
    buf.writeln('**Release Tag**: $tagName');
    buf.writeln('**Release Branch**: $branchName');
    buf.writeln(
        '**Status**: ${isExecuted ? "EXECUTED (TAG & BRANCH CREATED) ✓" : "PREVIEW DRY-RUN (NOT CREATED)"}');
    buf.writeln();
    buf.writeln('### Details');
    buf.writeln(details);
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'tagName': tagName,
        'branchName': branchName,
        'isExecuted': isExecuted,
        'details': details,
      };
}
