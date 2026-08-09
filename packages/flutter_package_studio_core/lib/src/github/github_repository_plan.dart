/// Action types in GitHub automation plan.
enum GitHubActionType {
  /// Create remote repository via API.
  createRepository,

  /// Configure remote metadata/topics.
  configureMetadata,

  /// Add or update local Git remote (e.g. `origin`).
  configureRemote,

  /// Stage files and create initial commit.
  createInitialCommit,

  /// Push initial commit to GitHub remote.
  pushRemote,

  /// Skip remote creation because repository already exists.
  skipExistingRepository,
}

/// Individual action entry in a [GitHubRepositoryPlan].
class GitHubAction {
  /// Type of GitHub automation action.
  final GitHubActionType type;

  /// Target remote name, URL, or repository identifier.
  final String target;

  /// Description of the action.
  final String description;

  /// Whether this action mutates local or remote state.
  final bool isMutating;

  /// Creates a [GitHubAction] instance.
  const GitHubAction({
    required this.type,
    required this.target,
    required this.description,
    this.isMutating = true,
  });
}

/// Deterministic, plan-first model for GitHub remote automation.
class GitHubRepositoryPlan {
  /// Target repository name.
  final String repositoryName;

  /// Remote URL to be configured.
  final String remoteUrl;

  /// List of planned automation actions.
  final List<GitHubAction> actions;

  /// Creates a [GitHubRepositoryPlan] instance.
  const GitHubRepositoryPlan({
    required this.repositoryName,
    required this.remoteUrl,
    required this.actions,
  });

  /// Count of mutating actions in plan.
  int get mutatingActionCount => actions.where((a) => a.isMutating).length;
}
