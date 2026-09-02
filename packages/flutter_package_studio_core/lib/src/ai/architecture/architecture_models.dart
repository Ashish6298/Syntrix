/// Domain models for AI Architecture Advisor (Phase 8.6).
library;

import 'package:flutter_package_studio_core/src/ai/review/code_review_models.dart';

/// Architectural concern categorization.
enum ArchitectureCategory {
  /// Circular import or dependency cycle between packages/files.
  circularDependency,

  /// Layering violation (e.g. CLI containing core business logic).
  layeringViolation,

  /// Responsibilities placed in the wrong subsystem/layer.
  misplacedResponsibility,

  /// Duplicate functionality across packages or modules.
  duplicateFunctionality,

  /// Excessive coupling / leaky abstractions.
  excessiveCoupling,

  /// Inconsistent API design/shapes across packages.
  apiInconsistency,

  /// Poor abstraction boundaries or god-objects.
  poorAbstractionBoundary,

  /// Violation of documented architecture rules/conventions.
  ruleViolation,

  /// General architectural concern.
  generalArchitecture;

  static ArchitectureCategory? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in ArchitectureCategory.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    return null;
  }
}

/// Scope of the architecture scan.
enum ArchitectureScanScope {
  /// Full monorepo project architecture scan.
  wholeProject,

  /// Scoped to a specific package.
  package,

  /// Scoped to a specific subsystem (e.g. cli, release, wizard).
  subsystem;

  static ArchitectureScanScope? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in ArchitectureScanScope.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    return null;
  }
}

/// Individual structured architectural finding.
///
/// Must contain:
/// 1. Component (e.g. "packages/flutter_package_studio_cli/lib/src/commands/create.dart")
/// 2. Issue (concise statement of architectural defect)
/// 3. Recommendation (concrete remediation advice)
/// 4. Reason (architectural rationale)
/// 5. Severity (critical, high, medium, low, informational from 8.3)
/// 6. Confidence (high, medium, low from 8.3)
/// 7. Category (ArchitectureCategory)
class ArchitectureFinding implements Comparable<ArchitectureFinding> {
  /// 1. Target component/file/package.
  final String component;

  /// 2. Architectural issue/anti-pattern detected.
  final String issue;

  /// 3. Concrete remediation advice.
  final String recommendation;

  /// 4. Rationale explaining why this is an issue.
  final String reason;

  /// 5. Shared severity rating.
  final CodeReviewSeverity severity;

  /// 6. Shared confidence rating.
  final CodeReviewConfidence confidence;

  /// 7. Category of architectural issue.
  final ArchitectureCategory category;

  const ArchitectureFinding({
    required this.component,
    required this.issue,
    required this.recommendation,
    required this.reason,
    required this.severity,
    required this.confidence,
    this.category = ArchitectureCategory.generalArchitecture,
  });

  factory ArchitectureFinding.fromJson(Map<String, dynamic> json) {
    final sevStr = json['severity'] as String? ?? 'medium';
    final confStr = json['confidence'] as String? ?? 'medium';
    final catStr = json['category'] as String? ?? 'generalArchitecture';

    final severity =
        CodeReviewSeverity.tryParse(sevStr) ?? CodeReviewSeverity.medium;
    final confidence =
        CodeReviewConfidence.tryParse(confStr) ?? CodeReviewConfidence.medium;
    final category = ArchitectureCategory.tryParse(catStr) ??
        ArchitectureCategory.generalArchitecture;

    return ArchitectureFinding(
      component: json['component'] as String? ?? 'Unknown Component',
      issue: json['issue'] as String? ?? 'Unspecified architectural issue',
      recommendation:
          json['recommendation'] as String? ?? 'No recommendation provided',
      reason: json['reason'] as String? ?? '',
      severity: severity,
      confidence: confidence,
      category: category,
    );
  }

  Map<String, dynamic> toJson() => {
        'component': component,
        'issue': issue,
        'recommendation': recommendation,
        'reason': reason,
        'severity': severity.name,
        'confidence': confidence.name,
        'category': category.name,
      };

  @override
  int compareTo(ArchitectureFinding other) {
    final s = severity.index.compareTo(other.severity.index);
    if (s != 0) return s;
    return component.compareTo(other.component);
  }
}

/// Request for architecture analysis.
class ArchitectureScanRequest {
  /// Scope of the scan.
  final ArchitectureScanScope scope;

  /// Target package name/id when scope is [ArchitectureScanScope.package].
  final String? targetPackage;

  /// Target subsystem name when scope is [ArchitectureScanScope.subsystem].
  final String? targetSubsystem;

  /// Maximum token budget for context assembly.
  final int tokenBudget;

  const ArchitectureScanRequest({
    this.scope = ArchitectureScanScope.wholeProject,
    this.targetPackage,
    this.targetSubsystem,
    this.tokenBudget = 4000,
  });

  Map<String, dynamic> toJson() => {
        'scope': scope.name,
        if (targetPackage != null) 'targetPackage': targetPackage,
        if (targetSubsystem != null) 'targetSubsystem': targetSubsystem,
        'tokenBudget': tokenBudget,
      };
}

/// Structural relationship model representing monorepo topology.
class MonorepoStructuralModel {
  /// Monorepo root path.
  final String rootPath;

  /// Discovered packages mapped by identifier.
  final List<String> packageNames;

  /// Inter-package dependency edges (pkgA -> [pkgB, pkgC]).
  final Map<String, List<String>> dependencyGraph;

  /// Detected circular dependencies between packages or files.
  final List<List<String>> detectedCycles;

  const MonorepoStructuralModel({
    required this.rootPath,
    required this.packageNames,
    required this.dependencyGraph,
    this.detectedCycles = const [],
  });

  Map<String, dynamic> toJson() => {
        'rootPath': rootPath,
        'packageNames': packageNames,
        'dependencyGraph': dependencyGraph,
        'detectedCycles': detectedCycles,
      };
}

/// Complete result emitted by the Architecture Advisor.
class ArchitectureScanResult {
  /// Scope evaluated.
  final ArchitectureScanScope scope;

  /// Target scope identifier (package name or 'whole_project').
  final String targetScopeId;

  /// Success indicator.
  final bool isSuccess;

  /// Structured architectural findings.
  final List<ArchitectureFinding> findings;

  /// Structural model snapshot.
  final MonorepoStructuralModel structuralModel;

  /// High-level executive summary.
  final String summary;

  /// Duration in milliseconds.
  final int durationMs;

  /// Timestamp of scan execution.
  final DateTime timestamp;

  /// Error message if scan failed.
  final String? errorMessage;

  const ArchitectureScanResult({
    required this.scope,
    required this.targetScopeId,
    required this.isSuccess,
    required this.findings,
    required this.structuralModel,
    required this.summary,
    required this.durationMs,
    required this.timestamp,
    this.errorMessage,
  });

  factory ArchitectureScanResult.failure({
    required ArchitectureScanScope scope,
    required String targetScopeId,
    required String errorMessage,
    required MonorepoStructuralModel structuralModel,
    int durationMs = 0,
    DateTime? timestamp,
  }) =>
      ArchitectureScanResult(
        scope: scope,
        targetScopeId: targetScopeId,
        isSuccess: false,
        findings: const [],
        structuralModel: structuralModel,
        summary: 'Architecture advisory scan failed: $errorMessage',
        durationMs: durationMs,
        timestamp: timestamp ?? DateTime.now(),
        errorMessage: errorMessage,
      );

  Map<String, dynamic> toJson() => {
        'scope': scope.name,
        'targetScopeId': targetScopeId,
        'isSuccess': isSuccess,
        'summary': summary,
        'findingCount': findings.length,
        'findings': findings.map((f) => f.toJson()).toList(),
        'structuralModel': structuralModel.toJson(),
        if (errorMessage != null) 'errorMessage': errorMessage,
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };
}
