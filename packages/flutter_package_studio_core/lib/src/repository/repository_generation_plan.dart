import 'package:flutter_package_studio_core/src/template/generation_plan.dart';

/// Represents an individual repository generation action.
class RepositoryAction {
  /// The action type (createFile, overwriteFile, skip, createDir, executeGit).
  final ActionType type;

  /// Relative file path within repository root.
  final String relativePath;

  /// Absolute target filesystem path.
  final String absolutePath;

  /// Content to be written if this is a file creation or overwrite.
  final String? textContent;

  /// Skip or override reason description.
  final String? reason;

  /// Creates a [RepositoryAction] instance.
  const RepositoryAction({
    required this.type,
    required this.relativePath,
    required this.absolutePath,
    this.textContent,
    this.reason,
  });
}

/// Deterministic, inspectable plan for repository file generation and initialization.
class RepositoryGenerationPlan {
  /// Target root directory path.
  final String rootDirectory;

  /// Selected repository preset profile ID.
  final String presetId;

  /// Selected license identifier.
  final String licenseId;

  /// List of actions to perform.
  final List<RepositoryAction> actions;

  /// Whether Git initialization will be attempted.
  final bool executeGitInit;

  /// Primary Git branch name.
  final String branchName;

  /// Creates a [RepositoryGenerationPlan] instance.
  const RepositoryGenerationPlan({
    required this.rootDirectory,
    required this.presetId,
    required this.licenseId,
    required this.actions,
    required this.executeGitInit,
    required this.branchName,
  });

  /// Count of actions that create files.
  int get fileCount => actions
      .where((a) =>
          a.type == ActionType.createFile || a.type == ActionType.overwriteFile)
      .length;

  /// Count of skipped actions.
  int get skipCount => actions.where((a) => a.type == ActionType.skip).length;
}
