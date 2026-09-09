/// Sealed result hierarchy representing outcome of example application generation.
sealed class ExampleGenerationResult {
  /// Target root directory of generated example application.
  final String targetPath;

  /// Duration spent in generation.
  final Duration duration;

  /// Whether generation ran in dry-run preview mode.
  final bool isDryRun;

  const ExampleGenerationResult({
    required this.targetPath,
    required this.duration,
    required this.isDryRun,
  });

  /// Whether generation succeeded.
  bool get isSuccess;
}

/// Successful example generation result.
final class ExampleGenerationSuccess extends ExampleGenerationResult {
  /// Created example file paths.
  final List<String> createdFiles;

  /// Skipped file paths.
  final List<String> skippedFiles;

  /// Selected template ID.
  final String templateId;

  /// Optional warnings logged during generation.
  final List<String> warnings;

  /// Creates an [ExampleGenerationSuccess] result.
  const ExampleGenerationSuccess({
    required super.targetPath,
    required super.duration,
    required super.isDryRun,
    required this.createdFiles,
    required this.skippedFiles,
    required this.templateId,
    this.warnings = const [],
  });

  @override
  bool get isSuccess => true;
}

/// Failed example generation result.
final class ExampleGenerationFailure extends ExampleGenerationResult {
  /// Error message explaining the failure.
  final String message;

  /// List of specific error diagnostics.
  final List<String> errors;

  /// Creates an [ExampleGenerationFailure] result.
  const ExampleGenerationFailure({
    required super.targetPath,
    required super.duration,
    required super.isDryRun,
    required this.message,
    required this.errors,
  });

  @override
  bool get isSuccess => false;
}
