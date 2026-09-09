/// Detailed result of project generation execution.
class GenerationResult {
  /// Whether generation completed successfully.
  final bool isSuccess;

  /// Whether execution was performed in dry-run preview mode.
  final bool isDryRun;

  /// Template ID used.
  final String templateId;

  /// Target output directory.
  final String outputDirectory;

  /// List of relative file paths created or overwritten.
  final List<String> filesCreated;

  /// List of relative directory paths created.
  final List<String> directoriesCreated;

  /// List of relative paths skipped.
  final List<String> filesSkipped;

  /// List of non-fatal warning messages.
  final List<String> warnings;

  /// List of error messages if generation failed.
  final List<String> errors;

  /// Total execution duration.
  final Duration duration;

  /// Creates a [GenerationResult] instance.
  const GenerationResult({
    required this.isSuccess,
    required this.isDryRun,
    required this.templateId,
    required this.outputDirectory,
    required this.filesCreated,
    required this.directoriesCreated,
    required this.filesSkipped,
    required this.warnings,
    required this.errors,
    required this.duration,
  });

  /// Total files generated count.
  int get totalFiles => filesCreated.length;

  /// Total directories created count.
  int get totalDirectories => directoriesCreated.length;
}
