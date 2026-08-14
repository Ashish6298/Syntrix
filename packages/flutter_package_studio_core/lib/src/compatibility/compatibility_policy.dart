import 'package:flutter_package_studio_core/src/compatibility/compatibility_issue.dart';

/// Defines how strictly the compatibility engine evaluates template constraints.
///
/// Policies control:
/// - Which axes are evaluated (e.g., skip platform check in permissive mode).
/// - Whether warnings are upgraded to errors (strict/release mode).
/// - Whether Flutter SDK checks are enforced for dart-only templates.
///
/// ## Policy Hierarchy (strictness ascending)
///
///  permissive → standard → strict → release
///
/// - **Permissive**: Only evaluate Dart SDK; skip platform/capability/dependency
///   checks. Suitable for exploration and templates that have not yet declared
///   all constraints.
/// - **Standard**: Evaluate Dart SDK, Flutter SDK (when required), and project
///   type. Skip platform and capability checks. Warnings remain warnings. This
///   is the default policy for `fps create` and catalog browsing.
/// - **Strict**: Evaluate all axes including platforms, capabilities, and
///   dependencies. Warnings remain warnings. Used for pre-release validation.
/// - **Release**: Same as strict but all warnings are promoted to errors.
///   Used for publishing gate checks.
enum CompatibilityPolicy {
  /// Only check Dart SDK constraint. Skip all other axes.
  permissive,

  /// Check Dart SDK, Flutter SDK, and project type. Default policy.
  standard,

  /// Check all axes (Dart, Flutter, platform, project type, capabilities,
  /// dependencies). Warnings remain warnings.
  strict,

  /// Same as strict but warnings are promoted to errors.
  release,
}

/// Utilities for working with [CompatibilityPolicy].
extension CompatibilityPolicyX on CompatibilityPolicy {
  /// Whether the Dart SDK axis is evaluated under this policy.
  /// Always true for all policies.
  bool get checksDartSdk => true;

  /// Whether the Flutter SDK axis is evaluated under this policy.
  bool get checksFlutterSdk =>
      this == CompatibilityPolicy.standard ||
      this == CompatibilityPolicy.strict ||
      this == CompatibilityPolicy.release;

  /// Whether the project type axis is evaluated.
  bool get checksProjectType =>
      this == CompatibilityPolicy.standard ||
      this == CompatibilityPolicy.strict ||
      this == CompatibilityPolicy.release;

  /// Whether platform compatibility is evaluated.
  bool get checksPlatforms =>
      this == CompatibilityPolicy.strict || this == CompatibilityPolicy.release;

  /// Whether capability requirements are evaluated.
  bool get checksCapabilities =>
      this == CompatibilityPolicy.strict || this == CompatibilityPolicy.release;

  /// Whether dependency compatibility is evaluated.
  bool get checksDependencies =>
      this == CompatibilityPolicy.strict || this == CompatibilityPolicy.release;

  /// Whether warnings are promoted to errors under this policy.
  bool get warningsAreErrors => this == CompatibilityPolicy.release;

  /// Applies this policy's promotion rules to an issue list.
  ///
  /// In [CompatibilityPolicy.release] mode, all warnings are promoted to errors.
  List<CompatibilityIssue> applyPromotions(List<CompatibilityIssue> issues) {
    if (!warningsAreErrors) return issues;
    return issues.map((issue) {
      if (issue.severity == CompatibilityIssueSeverity.warning) {
        return CompatibilityIssue(
          severity: CompatibilityIssueSeverity.error,
          axis: issue.axis,
          message: '[Release policy] ${issue.message}',
          constraint: issue.constraint,
          actual: issue.actual,
        );
      }
      return issue;
    }).toList();
  }

  /// Parses a [CompatibilityPolicy] from a string name (case-insensitive).
  /// Returns [CompatibilityPolicy.standard] for unknown strings.
  static CompatibilityPolicy fromString(String name) {
    switch (name.toLowerCase().trim()) {
      case 'permissive':
        return CompatibilityPolicy.permissive;
      case 'standard':
        return CompatibilityPolicy.standard;
      case 'strict':
        return CompatibilityPolicy.strict;
      case 'release':
        return CompatibilityPolicy.release;
      default:
        return CompatibilityPolicy.standard;
    }
  }
}
