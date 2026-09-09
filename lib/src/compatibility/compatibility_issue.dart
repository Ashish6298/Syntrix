/// Severity level of a [CompatibilityIssue].
enum CompatibilityIssueSeverity {
  /// Hard incompatibility — template cannot be used in this environment.
  /// Causes [CompatibilityResult.isCompatible] to be `false`.
  error,

  /// Soft incompatibility — template may work but with caveats.
  /// Does NOT prevent use but is surfaced to the user.
  warning,

  /// Informational note — no action required.
  info,
}

/// Axis on which a compatibility issue was detected.
enum CompatibilityIssueAxis {
  /// Dart SDK version constraint.
  dartSdk,

  /// Flutter SDK version constraint.
  flutterSdk,

  /// Target platform (e.g., `android`, `windows`).
  platform,

  /// Project archetype (e.g., `flutter_package`, `dart_cli`).
  projectType,

  /// Required capability tag not provided by the environment.
  capability,

  /// Template dependency constraint is unsatisfied.
  dependency,

  /// Template metadata is malformed or missing required fields.
  metadata,
}

/// A single structured diagnostic reason for a compatibility check outcome.
///
/// [CompatibilityIssue] is immutable. A list of issues is the primary output
/// of [CompatibilityEvaluator] and is aggregated in [CompatibilityResult].
///
/// ## Determinism
///
/// Issue messages are constructed deterministically from the constraint strings
/// and version values provided at evaluation time. No randomness, timestamps,
/// or external state may influence the message content.
///
/// ## Security
///
/// Issue messages must not expose absolute file paths, user home directories,
/// process IDs, or environment variables beyond safe version strings.
class CompatibilityIssue implements Comparable<CompatibilityIssue> {
  /// Severity of this issue.
  final CompatibilityIssueSeverity severity;

  /// Which compatibility axis was evaluated.
  final CompatibilityIssueAxis axis;

  /// Human-readable explanation of the issue.
  ///
  /// Must be deterministic and safe to display in CLI output or logs.
  final String message;

  /// The constraint expression that caused this issue (safe to display).
  final String? constraint;

  /// The actual value that was tested against [constraint] (safe to display).
  final String? actual;

  /// Creates a [CompatibilityIssue].
  const CompatibilityIssue({
    required this.severity,
    required this.axis,
    required this.message,
    this.constraint,
    this.actual,
  });

  /// Convenience constructor for a Dart SDK error.
  factory CompatibilityIssue.dartSdkError(String constraint, String actual) =>
      CompatibilityIssue(
        severity: CompatibilityIssueSeverity.error,
        axis: CompatibilityIssueAxis.dartSdk,
        message: 'Dart SDK $actual does not satisfy constraint $constraint.',
        constraint: constraint,
        actual: actual,
      );

  /// Convenience constructor for a Flutter SDK error.
  factory CompatibilityIssue.flutterSdkError(
          String constraint, String? actual) =>
      CompatibilityIssue(
        severity: CompatibilityIssueSeverity.error,
        axis: CompatibilityIssueAxis.flutterSdk,
        message: actual == null
            ? 'Template requires Flutter SDK ($constraint) but Flutter is not available.'
            : 'Flutter SDK $actual does not satisfy constraint $constraint.',
        constraint: constraint,
        actual: actual ?? 'not installed',
      );

  /// Convenience constructor for a platform error.
  factory CompatibilityIssue.platformError(
          String requiredPlatform, String currentOs) =>
      CompatibilityIssue(
        severity: CompatibilityIssueSeverity.error,
        axis: CompatibilityIssueAxis.platform,
        message:
            'Template requires platform "$requiredPlatform" but the current '
            'environment is "$currentOs".',
        constraint: requiredPlatform,
        actual: currentOs,
      );

  /// Convenience constructor for a project type error.
  factory CompatibilityIssue.projectTypeError(String expected, String actual) =>
      CompatibilityIssue(
        severity: CompatibilityIssueSeverity.error,
        axis: CompatibilityIssueAxis.projectType,
        message:
            'Template is for project type "$expected" but "$actual" was requested.',
        constraint: expected,
        actual: actual,
      );

  /// Convenience constructor for a capability error.
  factory CompatibilityIssue.capabilityError(String capability) =>
      CompatibilityIssue(
        severity: CompatibilityIssueSeverity.error,
        axis: CompatibilityIssueAxis.capability,
        message: 'Required capability "$capability" is not available in this '
            'environment.',
        constraint: capability,
      );

  /// Convenience constructor for a dependency error.
  factory CompatibilityIssue.dependencyError(String depId, String constraint) =>
      CompatibilityIssue(
        severity: CompatibilityIssueSeverity.error,
        axis: CompatibilityIssueAxis.dependency,
        message:
            'Required template dependency "$depId" ($constraint) is not satisfied.',
        constraint: constraint,
        actual: depId,
      );

  /// Convenience constructor for a metadata warning.
  factory CompatibilityIssue.metadataWarning(String message) =>
      CompatibilityIssue(
        severity: CompatibilityIssueSeverity.warning,
        axis: CompatibilityIssueAxis.metadata,
        message: message,
      );

  /// Convenience constructor for an informational note.
  factory CompatibilityIssue.info(CompatibilityIssueAxis axis, String message,
          {String? constraint, String? actual}) =>
      CompatibilityIssue(
        severity: CompatibilityIssueSeverity.info,
        axis: axis,
        message: message,
        constraint: constraint,
        actual: actual,
      );

  /// Errors are first, then warnings, then info.
  /// Within the same severity, sorted by axis ordinal then message.
  @override
  int compareTo(CompatibilityIssue other) {
    final sev = severity.index.compareTo(other.severity.index);
    if (sev != 0) return sev;
    final ax = axis.index.compareTo(other.axis.index);
    if (ax != 0) return ax;
    return message.compareTo(other.message);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompatibilityIssue &&
          severity == other.severity &&
          axis == other.axis &&
          message == other.message &&
          constraint == other.constraint &&
          actual == other.actual;

  @override
  int get hashCode => Object.hash(severity, axis, message, constraint, actual);

  @override
  String toString() => '[${severity.name.toUpperCase()}/${axis.name}] $message';
}
