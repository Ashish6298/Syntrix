import 'package:flutter_package_studio_core/src/template/generation_plan.dart';

/// Represents an individual example application generation action.
class ExampleAction {
  /// The action type (createDir, createFile, overwriteFile, skip).
  final ActionType type;

  /// Relative file or directory path within example application root.
  final String relativePath;

  /// Absolute target filesystem path.
  final String absolutePath;

  /// Content to be written if creating or overwriting a file.
  final String? textContent;

  /// Reason description if skipped.
  final String? reason;

  /// Creates an [ExampleAction] instance.
  const ExampleAction({
    required this.type,
    required this.relativePath,
    required this.absolutePath,
    this.textContent,
    this.reason,
  });
}

/// Deterministic, inspectable plan for generating an example Flutter application.
class ExampleGenerationPlan {
  /// Target root directory path of the example application.
  final String exampleDirectory;

  /// Absolute path to parent Flutter package directory.
  final String parentPackageDirectory;

  /// Expected package name dependency.
  final String expectedPackageName;

  /// Selected example template ID.
  final String templateId;

  /// List of actions to perform.
  final List<ExampleAction> actions;

  /// Creates an [ExampleGenerationPlan] instance.
  const ExampleGenerationPlan({
    required this.exampleDirectory,
    required this.parentPackageDirectory,
    required this.expectedPackageName,
    required this.templateId,
    required this.actions,
  });

  /// Count of created or overwritten files.
  int get fileCount => actions
      .where((a) =>
          a.type == ActionType.createFile || a.type == ActionType.overwriteFile)
      .length;

  /// Count of created directories.
  int get directoryCount =>
      actions.where((a) => a.type == ActionType.createDir).length;
}
