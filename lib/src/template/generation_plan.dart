/// Type of filesystem action in a generation plan.
enum ActionType {
  /// Create a directory.
  createDir,

  /// Write a new text or binary file.
  createFile,

  /// Overwrite an existing file.
  overwriteFile,

  /// Skip file or directory creation due to existing policy.
  skip,
}

/// Individual action entry in a [GenerationPlan].
class GenerationAction {
  /// Type of action to perform.
  final ActionType type;

  /// Target relative path.
  final String relativePath;

  /// Full absolute target path.
  final String absolutePath;

  /// Text content for text files (null for directories or binary assets).
  final String? textContent;

  /// Raw byte contents for binary assets.
  final List<int>? binaryContent;

  /// Explanation or reason for the action (e.g., skip reason).
  final String? reason;

  /// Source template ID producing this action for provenance auditing.
  final String? sourceTemplateId;

  /// Creates a [GenerationAction] instance.
  const GenerationAction({
    required this.type,
    required this.relativePath,
    required this.absolutePath,
    this.textContent,
    this.binaryContent,
    this.reason,
    this.sourceTemplateId,
  });

  /// Returns true if this is a binary asset file.
  bool get isBinary => binaryContent != null;
}

/// Inspectable pre-execution plan detailing all filesystem operations.
class GenerationPlan {
  /// Target root directory path.
  final String targetDirectory;

  /// Template ID being generated.
  final String templateId;

  /// List of planned actions.
  final List<GenerationAction> actions;

  /// List of evaluated conditions.
  final Map<String, bool> conditionResults;

  /// Evaluated variable map used during rendering.
  final Map<String, dynamic> variablesUsed;

  /// Creates a [GenerationPlan] instance.
  const GenerationPlan({
    required this.targetDirectory,
    required this.templateId,
    required this.actions,
    required this.conditionResults,
    required this.variablesUsed,
  });

  /// Planned files count (create or overwrite).
  int get fileCount => actions
      .where((a) =>
          a.type == ActionType.createFile || a.type == ActionType.overwriteFile)
      .length;

  /// Planned directory count.
  int get directoryCount =>
      actions.where((a) => a.type == ActionType.createDir).length;

  /// Skipped actions count.
  int get skippedCount =>
      actions.where((a) => a.type == ActionType.skip).length;
}
