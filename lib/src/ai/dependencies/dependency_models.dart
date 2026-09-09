/// Domain models for AI Dependency & Compatibility Advisor (Phase 8.8).
library;

import 'package:syntrix/src/ai/review/code_review_models.dart';

/// Distinct categories of dependency and compatibility concerns.
enum DependencyArtifactType {
  /// Conflicting or incompatible version constraints between packages or SDKs.
  versionConflict,

  /// Identical or diverging dependency versions declared across monorepo packages.
  duplication,

  /// Deprecated, discontinued, or unmaintained package.
  deprecatedPackage,

  /// Dart SDK or Flutter SDK environment constraint violation or incompatibility.
  sdkConstraintViolation,

  /// Cross-package constraint inconsistency in a monorepo workspace.
  crossPackageInconsistency,

  /// High upgrade risk due to breaking changes or major semver gap.
  upgradeRisk,

  /// General dependency concern.
  generalDependency;

  static DependencyArtifactType? tryParse(String? raw) {
    if (raw == null) return null;
    final clean =
        raw.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '');
    for (final val in DependencyArtifactType.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    if (clean == 'conflict' || clean == 'versionconflict')
      return DependencyArtifactType.versionConflict;
    if (clean == 'duplicate' || clean == 'duplication')
      return DependencyArtifactType.duplication;
    if (clean == 'deprecated' || clean == 'deprecatedpackage')
      return DependencyArtifactType.deprecatedPackage;
    if (clean == 'sdk' ||
        clean == 'sdkconstraint' ||
        clean == 'sdkconstraintviolation') {
      return DependencyArtifactType.sdkConstraintViolation;
    }
    if (clean == 'crosspackage' || clean == 'crosspackageinconsistency') {
      return DependencyArtifactType.crossPackageInconsistency;
    }
    if (clean == 'risk' || clean == 'upgraderisk')
      return DependencyArtifactType.upgradeRisk;
    return null;
  }
}

/// Three-way compatibility certainty classification.
///
/// Must be visibly distinguished and carried on every finding:
/// - [locallyVerified]: determined by directly parsing and cross-checking version constraints already present in workspace pubspec files.
/// - [inferred]: reasoned by the AI provider from constraint semantics without direct verification.
/// - [externallyResearched]: based on training data or external knowledge, flagged as unverified against live pubspec registry.
enum CompatibilityCertainty {
  /// Locally verified through direct workspace pubspec constraint parsing and comparison.
  locallyVerified,

  /// Inferred through semantic version logic and AI constraint reasoning.
  inferred,

  /// Externally researched from AI knowledge base; unverified against live pub.dev registry.
  externallyResearched;

  static CompatibilityCertainty? tryParse(String? raw) {
    if (raw == null) return null;
    final clean =
        raw.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '');
    for (final val in CompatibilityCertainty.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    if (clean == 'local' || clean == 'locallyverified' || clean == 'verified') {
      return CompatibilityCertainty.locallyVerified;
    }
    if (clean == 'inferred' || clean == 'infer') {
      return CompatibilityCertainty.inferred;
    }
    if (clean == 'external' ||
        clean == 'externallyresearched' ||
        clean == 'unverified') {
      return CompatibilityCertainty.externallyResearched;
    }
    return null;
  }
}

/// Scope of dependency analysis.
enum DependencyAnalysisScope {
  /// Whole monorepo workspace across all discovered packages.
  wholeProject,

  /// Scoped strictly to a single target package.
  package;

  static DependencyAnalysisScope? tryParse(String? raw) {
    if (raw == null) return null;
    final clean =
        raw.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '');
    for (final val in DependencyAnalysisScope.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    if (clean == 'all' ||
        clean == 'whole' ||
        clean == 'project' ||
        clean == 'wholeproject') {
      return DependencyAnalysisScope.wholeProject;
    }
    if (clean == 'pkg' || clean == 'package') {
      return DependencyAnalysisScope.package;
    }
    return null;
  }
}

/// Structured finding for dependency & compatibility analysis.
///
/// Subclasses [CodeReviewFinding] to conform 100% to Phase 8.3 / Phase 8.7 schema:
/// - severity: [CodeReviewSeverity] (critical, high, medium, low, informational)
/// - category: [CodeReviewCategory] (maintainability, apiUsage, architecture, etc.)
/// - file: pubspec.yaml file path where dependency is declared
/// - location: line or section (e.g. `dependencies.meta`, `environment.sdk`)
/// - problem: concise statement of dependency conflict or risk
/// - explanation: detailed rationale for the incompatibility or duplication
/// - recommendation: concrete upgrade or constraint alignment guidance
/// - confidence: [CodeReviewConfidence] (high, medium, low)
///
/// Extended with:
/// - [dependencyName]: package identifier (e.g. `meta`, `path`, `provider`)
/// - [currentConstraint]: declared constraint in current pubspec (e.g. `^1.11.0`, `>=3.0.0 <4.0.0`)
/// - [artifactType]: [DependencyArtifactType]
/// - [certainty]: [CompatibilityCertainty] (locallyVerified, inferred, externallyResearched)
/// - [affectedPackages]: list of packages in the workspace impacted by this finding
class DependencyFinding extends CodeReviewFinding {
  /// Package name of the dependency.
  final String dependencyName;

  /// The declared version constraint in source.
  final String currentConstraint;

  /// Specific dependency concern artifact type.
  final DependencyArtifactType artifactType;

  /// Explicit 3-way certainty classification.
  final CompatibilityCertainty certainty;

  /// Packages in workspace affected by this concern.
  final List<String> affectedPackages;

  const DependencyFinding({
    required super.severity,
    required super.category,
    required super.file,
    required super.location,
    required super.problem,
    required super.explanation,
    required super.recommendation,
    required super.confidence,
    required this.dependencyName,
    required this.currentConstraint,
    required this.artifactType,
    required this.certainty,
    this.affectedPackages = const [],
  });

  factory DependencyFinding.fromJson(Map<String, dynamic> json) {
    final base = CodeReviewFinding.fromJson(json);
    final depName = json['dependencyName'] as String? ?? '';
    final constraint = json['currentConstraint'] as String? ?? '*';
    final artTypeStr = json['artifactType'] as String? ?? 'generalDependency';
    final artType = DependencyArtifactType.tryParse(artTypeStr) ??
        DependencyArtifactType.generalDependency;
    final certStr = json['certainty'] as String? ?? 'inferred';
    final cert = CompatibilityCertainty.tryParse(certStr) ??
        CompatibilityCertainty.inferred;

    final affected = (json['affectedPackages'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    return DependencyFinding(
      severity: base.severity,
      category: base.category,
      file: base.file,
      location: base.location,
      problem: base.problem,
      explanation: base.explanation,
      recommendation: base.recommendation,
      confidence: base.confidence,
      dependencyName: depName,
      currentConstraint: constraint,
      artifactType: artType,
      certainty: cert,
      affectedPackages: affected,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'dependencyName': dependencyName,
        'currentConstraint': currentConstraint,
        'artifactType': artifactType.name,
        'certainty': certainty.name,
        'affectedPackages': affectedPackages,
      };
}

/// Request to analyze dependencies and compatibility.
class DependencyAnalysisRequest {
  /// Target scope (wholeProject or package).
  final DependencyAnalysisScope scope;

  /// Target package name when scope is [DependencyAnalysisScope.package].
  final String? targetPackage;

  /// Optional specific target dependency to focus on.
  final String? targetDependency;

  /// Whether to perform duplicate dependency checks across packages.
  final bool checkDuplicates;

  /// Token budget for assembled context.
  final int tokenBudget;

  const DependencyAnalysisRequest({
    this.scope = DependencyAnalysisScope.wholeProject,
    this.targetPackage,
    this.targetDependency,
    this.checkDuplicates = true,
    this.tokenBudget = 4000,
  });

  Map<String, dynamic> toJson() => {
        'scope': scope.name,
        if (targetPackage != null) 'targetPackage': targetPackage,
        if (targetDependency != null) 'targetDependency': targetDependency,
        'checkDuplicates': checkDuplicates,
        'tokenBudget': tokenBudget,
      };
}

/// Result of dependency and compatibility analysis.
class DependencyAnalysisResult {
  final DependencyAnalysisScope scope;
  final String targetScopeId;
  final bool isSuccess;

  /// Overall summary of the analysis.
  final String summary;

  /// Total count of findings.
  int get findingCount => findings.length;

  /// Structured findings.
  final List<DependencyFinding> findings;

  /// Discovered packages analyzed.
  final List<String> analyzedPackages;

  /// Total count of unique dependencies analyzed.
  final int totalDependenciesCount;

  /// Execution duration in milliseconds.
  final int durationMs;

  /// Timestamp of analysis.
  final DateTime timestamp;

  /// Error message if analysis failed.
  final String? errorMessage;

  const DependencyAnalysisResult({
    required this.scope,
    required this.targetScopeId,
    required this.isSuccess,
    required this.summary,
    required this.findings,
    required this.analyzedPackages,
    required this.totalDependenciesCount,
    required this.durationMs,
    required this.timestamp,
    this.errorMessage,
  });

  factory DependencyAnalysisResult.failure({
    required DependencyAnalysisScope scope,
    required String targetScopeId,
    required String errorMessage,
    int durationMs = 0,
    DateTime? timestamp,
  }) =>
      DependencyAnalysisResult(
        scope: scope,
        targetScopeId: targetScopeId,
        isSuccess: false,
        summary: 'Dependency analysis failed: $errorMessage',
        findings: const [],
        analyzedPackages: const [],
        totalDependenciesCount: 0,
        errorMessage: errorMessage,
        durationMs: durationMs,
        timestamp: timestamp ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'scope': scope.name,
        'targetScopeId': targetScopeId,
        'isSuccess': isSuccess,
        'summary': summary,
        'findingCount': findingCount,
        'findings': findings.map((f) => f.toJson()).toList(),
        'analyzedPackages': analyzedPackages,
        'totalDependenciesCount': totalDependenciesCount,
        if (errorMessage != null) 'errorMessage': errorMessage,
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };
}
