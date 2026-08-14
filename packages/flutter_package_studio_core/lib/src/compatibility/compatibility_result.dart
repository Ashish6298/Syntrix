import 'package:flutter_package_studio_core/src/compatibility/compatibility_issue.dart';

/// Aggregated result of a compatibility evaluation for a single template version.
///
/// [CompatibilityResult] is **immutable**. Its [isCompatible] flag reflects
/// whether any [CompatibilityIssueSeverity.error] issues are present.
/// Warnings and info issues do not affect compatibility.
///
/// ## Determinism
///
/// The [issues] list is always sorted via [CompatibilityIssue.compareTo]:
/// errors first, then warnings, then info; within each group by axis then
/// message. This order is independent of evaluation order.
///
/// ## Usage
///
/// ```dart
/// final result = evaluator.evaluate(template, environment);
/// if (!result.isCompatible) {
///   for (final issue in result.errors) {
///     print(issue.message);
///   }
/// }
/// ```
class CompatibilityResult {
  /// The evaluated template ID.
  final String templateId;

  /// The evaluated template version.
  final String templateVersion;

  /// All detected issues, sorted deterministically.
  final List<CompatibilityIssue> issues;

  /// The [SdkEnvironment] description used for evaluation (safe, no paths).
  final String environmentSummary;

  /// Creates a [CompatibilityResult] and sorts [issues] deterministically.
  CompatibilityResult({
    required this.templateId,
    required this.templateVersion,
    required List<CompatibilityIssue> issues,
    this.environmentSummary = '',
  }) : issues = _sorted(issues);

  /// Whether the template is compatible with the evaluated environment.
  ///
  /// `true` only when there are no [CompatibilityIssueSeverity.error] issues.
  bool get isCompatible => errors.isEmpty;

  /// All issues with severity == error.
  List<CompatibilityIssue> get errors => issues
      .where((i) => i.severity == CompatibilityIssueSeverity.error)
      .toList();

  /// All issues with severity == warning.
  List<CompatibilityIssue> get warnings => issues
      .where((i) => i.severity == CompatibilityIssueSeverity.warning)
      .toList();

  /// All issues with severity == info.
  List<CompatibilityIssue> get infos => issues
      .where((i) => i.severity == CompatibilityIssueSeverity.info)
      .toList();

  /// Whether there are any issues (errors, warnings, or info).
  bool get hasIssues => issues.isNotEmpty;

  /// Number of error-severity issues.
  int get errorCount => errors.length;

  /// Number of warning-severity issues.
  int get warningCount => warnings.length;

  /// A compatible, zero-issue result.
  factory CompatibilityResult.compatible(
          String templateId, String version, String envSummary) =>
      CompatibilityResult(
        templateId: templateId,
        templateVersion: version,
        issues: const [],
        environmentSummary: envSummary,
      );

  /// An incompatible result with a single error.
  factory CompatibilityResult.incompatible(
    String templateId,
    String version,
    CompatibilityIssue issue,
    String envSummary,
  ) =>
      CompatibilityResult(
        templateId: templateId,
        templateVersion: version,
        issues: [issue],
        environmentSummary: envSummary,
      );

  static List<CompatibilityIssue> _sorted(List<CompatibilityIssue> issues) {
    final copy = List<CompatibilityIssue>.from(issues);
    copy.sort();
    return List.unmodifiable(copy);
  }

  @override
  String toString() => 'CompatibilityResult($templateId@$templateVersion, '
      'compatible: $isCompatible, issues: ${issues.length})';
}

/// Aggregated results from evaluating multiple template versions.
class MultiVersionCompatibilityResult {
  /// Results per version, keyed by version string.
  final Map<String, CompatibilityResult> resultsByVersion;

  /// Template ID that was evaluated.
  final String templateId;

  const MultiVersionCompatibilityResult({
    required this.templateId,
    required this.resultsByVersion,
  });

  /// Returns all compatible version strings, sorted newest-first by semver.
  List<String> get compatibleVersions {
    final compatible = resultsByVersion.entries
        .where((e) => e.value.isCompatible)
        .map((e) => e.key)
        .toList();

    compatible.sort((a, b) {
      try {
        // Import-free: parse using split
        final aParts = a.split('.').map(int.tryParse).toList();
        final bParts = b.split('.').map(int.tryParse).toList();
        for (int i = 0; i < 3; i++) {
          final aP = i < aParts.length ? (aParts[i] ?? 0) : 0;
          final bP = i < bParts.length ? (bParts[i] ?? 0) : 0;
          if (bP != aP) return bP.compareTo(aP);
        }
        return b.compareTo(a);
      } catch (_) {
        return b.compareTo(a);
      }
    });

    return List.unmodifiable(compatible);
  }

  /// The highest compatible version string, or `null` if none.
  String? get highestCompatibleVersion => compatibleVersions.firstOrNull;

  /// Whether at least one version is compatible.
  bool get hasCompatibleVersion => compatibleVersions.isNotEmpty;

  @override
  String toString() =>
      'MultiVersionCompatibilityResult($templateId, compatible: '
      '${compatibleVersions.length}/${resultsByVersion.length})';
}
