import 'package:flutter_package_studio_core/src/compatibility/compatibility_issue.dart';
import 'package:flutter_package_studio_core/src/compatibility/compatibility_policy.dart';
import 'package:flutter_package_studio_core/src/compatibility/compatibility_result.dart';
import 'package:flutter_package_studio_core/src/compatibility/sdk_environment.dart';
import 'package:flutter_package_studio_core/src/compatibility/sdk_version_constraint.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';
import 'package:flutter_package_studio_core/src/template/template_registry.dart';
import 'package:flutter_package_studio_core/src/template/template_semver.dart';

/// Core compatibility evaluation engine.
///
/// [CompatibilityEvaluator] determines whether a given [Template] is
/// compatible with a [SdkEnvironment] under a specified [CompatibilityPolicy].
///
/// ## Evaluation Order
///
/// Axes are always evaluated in a fixed order to produce deterministic output:
/// 1. Dart SDK
/// 2. Flutter SDK
/// 3. Project type
/// 4. Platforms
/// 5. Capabilities
/// 6. Dependencies
///
/// ## Determinism Guarantees
///
/// - No random values, timestamps, or system state affect evaluation.
/// - Issue lists are always produced in the same order for the same inputs.
/// - Multiple calls with the same arguments produce identical results.
///
/// ## Security
///
/// - Never logs or exposes absolute SDK install paths.
/// - Version strings in issues come directly from [SdkEnvironment] (safe values).
/// - No process execution, file system access, or network calls.
class CompatibilityEvaluator {
  final SdkEnvironment environment;
  final CompatibilityPolicy policy;
  final Logger _logger = Logger('CompatibilityEvaluator');

  /// Creates a [CompatibilityEvaluator].
  ///
  /// [environment] is the SDK environment to test against.
  /// [policy] controls which axes are evaluated and promotion rules.
  CompatibilityEvaluator({
    required this.environment,
    this.policy = CompatibilityPolicy.standard,
  });

  // ── Single-template evaluation ─────────────────────────────────────────────

  /// Evaluates compatibility of [template] against [environment] under [policy].
  ///
  /// - For a pure metadata-only result (no environment check), use [policy]
  ///   with [CompatibilityPolicy.permissive].
  /// - [requiredProjectType] is the project type the user requested (optional).
  /// - [requiredCapabilities] are capability tags required by the project context.
  /// - [availableTemplates] is required when [policy] has `checksDependencies` enabled.

  CompatibilityResult evaluate(
    Template template, {
    String? requiredProjectType,
    List<String> requiredCapabilities = const [],
    TemplateRegistry? availableTemplates,
  }) {
    _logger
        .debug('Evaluating compatibility: ${template.id}@${template.version} '
            'policy=${policy.name}');

    final issues = <CompatibilityIssue>[];
    final m = template.manifest;

    // ── 1. Dart SDK ────────────────────────────────────────────────────────
    if (policy.checksDartSdk && m.minimumDartSdk.trim().isNotEmpty) {
      final issue = _checkDartSdk(m.minimumDartSdk);
      if (issue != null) issues.add(issue);
    }

    // ── 2. Flutter SDK ─────────────────────────────────────────────────────
    if (policy.checksFlutterSdk) {
      if (m.minimumFlutterSdk != null &&
          m.minimumFlutterSdk!.trim().isNotEmpty) {
        final issue = _checkFlutterSdk(m.minimumFlutterSdk!);
        if (issue != null) issues.add(issue);
      }
    }

    // ── 3. Project type ────────────────────────────────────────────────────
    if (policy.checksProjectType && requiredProjectType != null) {
      if (m.projectType != requiredProjectType) {
        issues.add(CompatibilityIssue.projectTypeError(
            m.projectType, requiredProjectType));
      }
    }

    // ── 4. Platforms ───────────────────────────────────────────────────────
    if (policy.checksPlatforms && m.supportedPlatforms.isNotEmpty) {
      final issue = _checkPlatform(m.supportedPlatforms);
      if (issue != null) issues.add(issue);
    }

    // ── 5. Capabilities ────────────────────────────────────────────────────
    if (policy.checksCapabilities && requiredCapabilities.isNotEmpty) {
      final templateCaps = Set<String>.from(m.capabilities);
      for (final cap in requiredCapabilities) {
        if (!templateCaps.contains(cap)) {
          issues.add(CompatibilityIssue.capabilityError(cap));
        }
      }
    }

    // ── 6. Dependencies ────────────────────────────────────────────────────
    if (policy.checksDependencies &&
        m.dependencies.isNotEmpty &&
        availableTemplates != null) {
      final depIssues = _checkDependencies(m.dependencies, availableTemplates);
      issues.addAll(depIssues);
    }

    // Apply policy promotions (e.g., release: warning → error)
    final promoted = policy.applyPromotions(issues);

    return CompatibilityResult(
      templateId: template.id,
      templateVersion: template.version,
      issues: promoted,
      environmentSummary: _envSummary(),
    );
  }

  // ── Multi-version evaluation ───────────────────────────────────────────────

  /// Evaluates all versions of [templateId] found in [registry].
  ///
  /// Returns a [MultiVersionCompatibilityResult] with one [CompatibilityResult]
  /// per version.
  MultiVersionCompatibilityResult evaluateAllVersions(
    String templateId,
    TemplateRegistry registry, {
    String? requiredProjectType,
    List<String> requiredCapabilities = const [],
  }) {
    final all = registry.listAll().where((t) => t.id == templateId).toList();

    final byVersion = <String, CompatibilityResult>{};
    for (final template in all) {
      final result = evaluate(
        template,
        requiredProjectType: requiredProjectType,
        requiredCapabilities: requiredCapabilities,
        availableTemplates: registry,
      );
      byVersion[template.version] = result;
    }

    return MultiVersionCompatibilityResult(
      templateId: templateId,
      resultsByVersion: Map.unmodifiable(byVersion),
    );
  }

  /// Selects the highest compatible version of [templateId] from [registry]
  /// that satisfies [versionConstraint].
  ///
  /// Returns the best [Template] or `null` if no compatible version exists.
  Template? selectBestCompatibleVersion(
    String templateId,
    TemplateRegistry registry, {
    String versionConstraint = '*',
    String? requiredProjectType,
    List<String> requiredCapabilities = const [],
  }) {
    final candidates =
        registry.listAll().where((t) => t.id == templateId).toList();

    // Filter by version constraint first
    final constrained = candidates.where((t) {
      try {
        return TemplateSemVer.parse(t.version).satisfies(versionConstraint);
      } catch (_) {
        return false;
      }
    }).toList();

    if (constrained.isEmpty) return null;

    // Sort descending (newest first)
    constrained.sort((a, b) => TemplateSemVer.parse(b.version)
        .compareTo(TemplateSemVer.parse(a.version)));

    // Return first compatible
    for (final template in constrained) {
      final result = evaluate(
        template,
        requiredProjectType: requiredProjectType,
        requiredCapabilities: requiredCapabilities,
        availableTemplates: registry,
      );
      if (result.isCompatible) return template;
    }

    return null;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  CompatibilityIssue? _checkDartSdk(String constraint) {
    try {
      final c = SdkVersionConstraint.parse(constraint);
      if (c.isWildcard) return null;
      if (!c.isSatisfiedBy(environment.dartVersion)) {
        return CompatibilityIssue.dartSdkError(
            constraint, environment.dartVersion);
      }
    } on InvalidSdkConstraintException {
      return CompatibilityIssue.metadataWarning(
          'Template declares malformed Dart SDK constraint: "$constraint".');
    }
    return null;
  }

  CompatibilityIssue? _checkFlutterSdk(String constraint) {
    try {
      final c = SdkVersionConstraint.parse(constraint);
      if (c.isWildcard) return null;

      if (!environment.isFlutterAvailable) {
        return CompatibilityIssue.flutterSdkError(constraint, null);
      }
      if (!c.isSatisfiedBy(environment.flutterVersion!)) {
        return CompatibilityIssue.flutterSdkError(
            constraint, environment.flutterVersion);
      }
    } on InvalidSdkConstraintException {
      return CompatibilityIssue.metadataWarning(
          'Template declares malformed Flutter SDK constraint: "$constraint".');
    }
    return null;
  }

  CompatibilityIssue? _checkPlatform(List<String> supportedPlatforms) {
    final os = environment.operatingSystem.toLowerCase();
    final supported = supportedPlatforms.map((p) => p.toLowerCase()).toSet();

    // If the template doesn't list the current OS as supported, that's a warning
    // (not an error) because platform support is declarative, not exclusive.
    if (!supported.contains(os)) {
      return CompatibilityIssue(
        severity: CompatibilityIssueSeverity.warning,
        axis: CompatibilityIssueAxis.platform,
        message: 'Template declares support for platforms '
            '[${supported.join(', ')}] but the current OS is "$os". '
            'The template may not fully support this platform.',
        constraint: supported.join(', '),
        actual: os,
      );
    }
    return null;
  }

  List<CompatibilityIssue> _checkDependencies(
    List<dynamic> dependencies,
    TemplateRegistry registry,
  ) {
    final issues = <CompatibilityIssue>[];
    for (final dep in dependencies) {
      // Dependencies are TemplateDependency instances
      final depId = dep.templateId as String;
      final constraint = dep.versionConstraint as String;
      final isRequired = dep.isRequired as bool;

      final candidates = registry.listAll().where((t) => t.id == depId);
      if (candidates.isEmpty) {
        if (isRequired) {
          issues.add(CompatibilityIssue.dependencyError(depId, constraint));
        }
        continue;
      }

      final satisfying = candidates.where((t) {
        try {
          return TemplateSemVer.parse(t.version).satisfies(constraint);
        } catch (_) {
          return false;
        }
      });

      if (satisfying.isEmpty && isRequired) {
        issues.add(CompatibilityIssue.dependencyError(depId, constraint));
      }
    }
    return issues;
  }

  String _envSummary() =>
      'dart:${environment.dartVersion} flutter:${environment.flutterVersion ?? "n/a"} '
      'os:${environment.operatingSystem}';
}
