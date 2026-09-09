/// Sealed result hierarchy representing outcome of GitHub automation.
sealed class GitHubAutomationResult {
  /// Target repository name.
  final String repositoryName;

  /// Duration spent in GitHub automation.
  final Duration duration;

  /// Whether automation ran in dry-run mode.
  final bool isDryRun;

  const GitHubAutomationResult({
    required this.repositoryName,
    required this.duration,
    required this.isDryRun,
  });

  /// Whether automation succeeded.
  bool get isSuccess;
}

/// Successful GitHub automation result.
final class GitHubAutomationSuccess extends GitHubAutomationResult {
  /// Generated remote URL (e.g. `https://github.com/owner/repo.git`).
  final String remoteUrl;

  /// List of executed actions.
  final List<String> executedActions;

  /// Whether remote repository was created via API.
  final bool remoteCreated;

  /// Whether initial commit was pushed to remote.
  final bool pushed;

  /// Optional safe warnings logged during automation.
  final List<String> warnings;

  /// Creates a [GitHubAutomationSuccess] result.
  const GitHubAutomationSuccess({
    required super.repositoryName,
    required super.duration,
    required super.isDryRun,
    required this.remoteUrl,
    required this.executedActions,
    required this.remoteCreated,
    required this.pushed,
    this.warnings = const [],
  });

  @override
  bool get isSuccess => true;
}

/// Failed GitHub automation result.
final class GitHubAutomationFailure extends GitHubAutomationResult {
  /// Error message explaining the failure.
  final String message;

  /// List of specific error diagnostics (redacted of tokens).
  final List<String> errors;

  /// Creates a [GitHubAutomationFailure] result.
  const GitHubAutomationFailure({
    required super.repositoryName,
    required super.duration,
    required super.isDryRun,
    required this.message,
    required this.errors,
  });

  @override
  bool get isSuccess => false;
}
