/// Sealed result hierarchy representing outcome of repository generation.
sealed class RepositoryGenerationResult {
  /// Target root directory path.
  final String targetPath;

  /// Duration spent in repository generation.
  final Duration duration;

  /// Whether generation ran in dry-run preview mode.
  final bool isDryRun;

  const RepositoryGenerationResult({
    required this.targetPath,
    required this.duration,
    required this.isDryRun,
  });

  /// Whether repository generation succeeded.
  bool get isSuccess;
}

/// Successful repository generation result.
final class RepositoryGenerationSuccess extends RepositoryGenerationResult {
  /// Created repository file paths.
  final List<String> createdFiles;

  /// Skipped repository file paths.
  final List<String> skippedFiles;

  /// Whether local Git repository was initialized.
  final bool gitInitialized;

  /// Selected repository preset profile ID.
  final String preset;

  /// Selected open-source license ID.
  final String license;

  /// Optional warnings logged during generation.
  final List<String> warnings;

  /// Creates a [RepositoryGenerationSuccess] result.
  const RepositoryGenerationSuccess({
    required super.targetPath,
    required super.duration,
    required super.isDryRun,
    required this.createdFiles,
    required this.skippedFiles,
    required this.gitInitialized,
    required this.preset,
    required this.license,
    this.warnings = const [],
  });

  @override
  bool get isSuccess => true;
}

/// Cancelled repository generation result.
final class RepositoryGenerationCancelled extends RepositoryGenerationResult {
  /// Reason for cancellation.
  final String reason;

  /// Creates a [RepositoryGenerationCancelled] result.
  const RepositoryGenerationCancelled({
    required super.targetPath,
    required super.duration,
    required super.isDryRun,
    required this.reason,
  });

  @override
  bool get isSuccess => false;
}

/// Failed repository generation result.
final class RepositoryGenerationFailure extends RepositoryGenerationResult {
  /// Error message explaining the failure.
  final String message;

  /// List of specific error diagnostics.
  final List<String> errors;

  /// Creates a [RepositoryGenerationFailure] result.
  const RepositoryGenerationFailure({
    required super.targetPath,
    required super.duration,
    required super.isDryRun,
    required this.message,
    required this.errors,
  });

  @override
  bool get isSuccess => false;
}
