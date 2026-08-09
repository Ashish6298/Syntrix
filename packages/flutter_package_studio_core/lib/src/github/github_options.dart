import 'package:flutter_package_studio_core/src/wizard/wizard_context.dart';

/// Immutable domain model for GitHub repository creation and remote automation settings.
class GitHubOptions {
  /// Name of the repository on GitHub.
  final String repositoryName;

  /// Target owner user or organization account (optional).
  final String owner;

  /// Description of the GitHub repository.
  final String description;

  /// Whether the repository should be private (default: false for public).
  final bool isPrivate;

  /// Default branch name (default: 'main').
  final String defaultBranch;

  /// Homepage URL associated with the repository.
  final String homepageUrl;

  /// List of repository topics/tags.
  final List<String> topics;

  /// Whether issues are enabled on the repository.
  final bool enableIssues;

  /// Whether wiki is enabled on the repository.
  final bool enableWiki;

  /// Whether projects board is enabled on the repository.
  final bool enableProjects;

  /// Name of the local Git remote (default: 'origin').
  final String remoteName;

  /// Whether to automatically create the remote repository via API.
  final bool createRemote;

  /// Whether to push initial commit after remote configuration.
  final bool autoPush;

  /// Creates a [GitHubOptions] instance.
  const GitHubOptions({
    required this.repositoryName,
    this.owner = '',
    this.description = '',
    this.isPrivate = false,
    this.defaultBranch = 'main',
    this.homepageUrl = '',
    this.topics = const [],
    this.enableIssues = true,
    this.enableWiki = false,
    this.enableProjects = false,
    this.remoteName = 'origin',
    this.createRemote = true,
    this.autoPush = true,
  });

  /// Constructs [GitHubOptions] from a [WizardContext].
  factory GitHubOptions.fromWizardContext(
    WizardContext wizardContext, {
    String? owner,
    bool? isPrivate,
    String? remoteName,
    bool? createRemote,
    bool? autoPush,
  }) {
    final repoName = wizardContext.packageName.isNotEmpty
        ? wizardContext.packageName
        : 'my_package';

    return GitHubOptions(
      repositoryName: repoName,
      owner: owner ?? '',
      description: wizardContext.description,
      isPrivate: isPrivate ?? false,
      defaultBranch: 'main',
      homepageUrl: wizardContext.homepage,
      topics: [repoName, 'flutter', 'dart'],
      enableIssues: true,
      enableWiki: false,
      enableProjects: false,
      remoteName: remoteName ?? 'origin',
      createRemote: createRemote ?? true,
      autoPush: autoPush ?? true,
    );
  }
}
