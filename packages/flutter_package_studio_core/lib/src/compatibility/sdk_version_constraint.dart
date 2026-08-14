import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/template/template_semver.dart';

/// Parses and evaluates a Dart/Flutter SDK version constraint expression.
///
/// Delegates all constraint matching to [TemplateSemVer.satisfies()] to avoid
/// duplicating version logic. The primary role of this class is:
/// - Validate that a constraint string is well-formed and parseable.
/// - Evaluate whether a concrete SDK version satisfies the constraint.
/// - Provide human-readable descriptions of the constraint for diagnostics.
///
/// ## Supported Constraint Syntax
///
/// Inherits all forms supported by [TemplateSemVer.satisfies()]:
/// - `*` — any version
/// - `>=1.0.0 <2.0.0` — compound range
/// - `^1.0.0` — caret (same major)
/// - `>=1.0.0`, `>1.0.0`, `<=1.0.0`, `<1.0.0`
/// - `1.0.0` or `=1.0.0` — exact version
///
/// ## Security
///
/// This class must never expose SDK install paths, file system state, or
/// process environment. It accepts version strings as pure text values and
/// performs only arithmetic comparison.
class SdkVersionConstraint {
  /// The raw constraint string exactly as declared.
  final String raw;

  /// Whether this constraint accepts any version (wildcard `*` or empty).
  final bool isWildcard;

  const SdkVersionConstraint._(this.raw, this.isWildcard);

  /// Parses [constraint] and returns a validated [SdkVersionConstraint].
  ///
  /// Throws [InvalidSdkConstraintException] if [constraint] is malformed.
  factory SdkVersionConstraint.parse(String constraint) {
    final trimmed = constraint.trim();
    if (trimmed.isEmpty || trimmed == '*') {
      return SdkVersionConstraint._(trimmed.isEmpty ? '*' : trimmed, true);
    }

    // Validate each part of a space-separated compound constraint
    final parts = trimmed.split(' ').where((p) => p.trim().isNotEmpty).toList();
    for (final part in parts) {
      _validateSingleConstraint(part.trim(), constraint);
    }

    return SdkVersionConstraint._(trimmed, false);
  }

  /// Returns true if [version] satisfies this constraint.
  ///
  /// Throws [InvalidSdkConstraintException] if [version] itself is not a
  /// valid semver string.
  bool isSatisfiedBy(String version) {
    final trimmed = version.trim();
    if (trimmed.isEmpty) {
      throw InvalidSdkConstraintException(
          'SDK version string must not be empty.');
    }

    final TemplateSemVer semver;
    try {
      semver = TemplateSemVer.parse(trimmed);
    } on TemplateException catch (e) {
      throw InvalidSdkConstraintException(
          'Invalid SDK version "$version": ${e.message}');
    }

    return semver.satisfies(raw);
  }

  /// Evaluates compatibility without throwing.
  /// Returns `null` if [version] cannot be parsed.
  bool? isSatisfiedBySafe(String version) {
    try {
      return isSatisfiedBy(version);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => raw;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SdkVersionConstraint && raw == other.raw;

  @override
  int get hashCode => raw.hashCode;

  // ── Validation ─────────────────────────────────────────────────────────────

  static void _validateSingleConstraint(String part, String fullExpr) {
    if (part == '*') return;

    String versionPart;
    if (part.startsWith('>=') || part.startsWith('<=')) {
      versionPart = part.substring(2);
    } else if (part.startsWith('^') ||
        part.startsWith('>') ||
        part.startsWith('<')) {
      versionPart = part.substring(1);
    } else if (part.startsWith('==') || part.startsWith('=')) {
      versionPart = part.replaceAll('=', '');
    } else {
      versionPart = part;
    }

    final trimmedVersion = versionPart.trim();
    if (trimmedVersion.isEmpty) {
      throw InvalidSdkConstraintException(
          'Malformed SDK constraint: "$part" in expression "$fullExpr". '
          'Operator must be followed by a version number.');
    }

    try {
      TemplateSemVer.parse(trimmedVersion);
    } on TemplateException catch (e) {
      throw InvalidSdkConstraintException(
          'Malformed SDK constraint version "$trimmedVersion" in "$fullExpr": '
          '${e.message}');
    }
  }
}
