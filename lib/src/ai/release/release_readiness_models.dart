/// Domain models for AI Release Readiness Advisor (Phase 8.10).
library;

import 'package:syntrix/src/ai/review/code_review_models.dart';
import 'package:syntrix/src/ai/security/secret_redactor.dart';

/// Overall release readiness decision status.
enum ReleaseReadinessStatus {
  /// All mandatory release gates passed, no blockers, and low/negligible risks.
  ready,

  /// One or more mandatory release gates failed, or fatal release blockers exist.
  notReady,

  /// Mandatory gates passed, but non-blocking warnings, elevated risk, or manual checks require human sign-off.
  needsReview;

  static ReleaseReadinessStatus? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw
        .trim()
        .toLowerCase()
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '');
    for (final val in ReleaseReadinessStatus.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    if (clean == 'ready') return ReleaseReadinessStatus.ready;
    if (clean == 'notready' || clean == 'blocked' || clean == 'failed')
      return ReleaseReadinessStatus.notReady;
    if (clean == 'needsreview' || clean == 'review' || clean == 'warning')
      return ReleaseReadinessStatus.needsReview;
    return null;
  }
}

/// A structured item in the release readiness assessment (Strength, Warning, Blocker, or Action).
class ReadinessEntry {
  /// Plain-language description of the concern, strength, or action.
  final String description;

  /// Originating subsystem or evidence reference (e.g. "Security Audit: 2 critical findings", "Pub.dev Validator: License check").
  final String evidenceSource;

  ReadinessEntry({
    required String description,
    required String evidenceSource,
  })  : description = SecretRedactor.redact(description),
        evidenceSource = SecretRedactor.redact(evidenceSource);

  factory ReadinessEntry.fromJson(Map<String, dynamic> json) {
    final desc = json['description'] as String? ?? '';
    final source = json['evidenceSource'] as String? ??
        json['source'] as String? ??
        'Deterministic Release Pipeline';
    return ReadinessEntry(
      description: desc,
      evidenceSource: source,
    );
  }

  Map<String, dynamic> toJson() => {
        'description': SecretRedactor.redact(description),
        'evidenceSource': SecretRedactor.redact(evidenceSource),
      };
}

/// Scope of release readiness analysis.
enum ReleaseReadinessScope {
  /// Whole monorepo workspace across all packages and release targets.
  wholeProject,

  /// Scoped strictly to a single target package.
  package;

  static ReleaseReadinessScope? tryParse(String? raw) {
    if (raw == null) return null;
    final clean =
        raw.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '');
    for (final val in ReleaseReadinessScope.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    if (clean == 'all' ||
        clean == 'whole' ||
        clean == 'project' ||
        clean == 'wholeproject') {
      return ReleaseReadinessScope.wholeProject;
    }
    if (clean == 'pkg' || clean == 'package')
      return ReleaseReadinessScope.package;
    return null;
  }
}

/// Request payload for release readiness assessment.
class ReleaseReadinessRequest {
  /// Target scope (wholeProject or package).
  final ReleaseReadinessScope scope;

  /// Target package identifier.
  final String? targetPackage;

  /// Version being evaluated for release.
  final String version;

  /// Context token budget.
  final int tokenBudget;

  const ReleaseReadinessRequest({
    this.scope = ReleaseReadinessScope.wholeProject,
    this.targetPackage,
    this.version = '1.0.0',
    this.tokenBudget = 4000,
  });

  Map<String, dynamic> toJson() => {
        'scope': scope.name,
        if (targetPackage != null) 'targetPackage': targetPackage,
        'version': version,
        'tokenBudget': tokenBudget,
      };
}

/// Holistic AI Release Readiness Assessment produced for a release candidate.
class ReleaseReadinessAssessment {
  /// Target scope representation.
  final ReleaseReadinessScope scope;

  /// Target scope identifier (e.g. package name or 'whole_project').
  final String targetScopeId;

  /// Evaluated package version.
  final String version;

  /// Overall release readiness decision status.
  final ReleaseReadinessStatus status;

  /// High-level executive synthesis.
  final String summary;

  /// What is solid and verified about this release candidate.
  final List<ReadinessEntry> strengths;

  /// Non-blocking concerns, advisory notes, or pending checks.
  final List<ReadinessEntry> warnings;

  /// Blocking conditions preventing release.
  final List<ReadinessEntry> blockers;

  /// Concrete recommended next steps to reach full release readiness.
  final List<ReadinessEntry> recommendedActions;

  /// Confidence indication describing how complete and reliable the gathered evidence is.
  final CodeReviewConfidence confidence;

  /// Mandatory release gates evaluated deterministically.
  final List<String> mandatoryGatesEvaluated;

  /// Failed mandatory release gates (if any).
  final List<String> failedMandatoryGates;

  /// Total count of deterministic findings and stages gathered across subsystems.
  final int totalEvidenceCount;

  /// Duration of assessment in milliseconds.
  final int durationMs;

  /// Timestamp of assessment.
  final DateTime timestamp;

  /// Error message if synthesis degraded or failed.
  final String? errorMessage;

  /// Whether the assessment execution completed without fatal failures.
  bool get isSuccess => errorMessage == null;

  /// Whether AI narrative synthesis was executed or degraded to status-only.
  final bool isAiSynthesized;

  ReleaseReadinessAssessment({
    required this.scope,
    required this.targetScopeId,
    required this.version,
    required this.status,
    required String summary,
    required this.strengths,
    required this.warnings,
    required this.blockers,
    required this.recommendedActions,
    required this.confidence,
    required this.mandatoryGatesEvaluated,
    required this.failedMandatoryGates,
    required this.totalEvidenceCount,
    required this.durationMs,
    required this.timestamp,
    this.errorMessage,
    this.isAiSynthesized = true,
  }) : summary = SecretRedactor.redact(summary);

  factory ReleaseReadinessAssessment.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'needsReview';
    final status = ReleaseReadinessStatus.tryParse(statusStr) ??
        ReleaseReadinessStatus.needsReview;

    final confStr = json['confidence'] as String? ?? 'high';
    final conf =
        CodeReviewConfidence.tryParse(confStr) ?? CodeReviewConfidence.high;

    final scopeStr = json['scope'] as String? ?? 'wholeProject';
    final scope = ReleaseReadinessScope.tryParse(scopeStr) ??
        ReleaseReadinessScope.wholeProject;

    List<ReadinessEntry> parseEntries(dynamic list) {
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(ReadinessEntry.fromJson)
            .toList();
      }
      return const [];
    }

    return ReleaseReadinessAssessment(
      scope: scope,
      targetScopeId: json['targetScopeId'] as String? ?? 'whole_project',
      version: json['version'] as String? ?? '1.0.0',
      status: status,
      summary: json['summary'] as String? ?? '',
      strengths: parseEntries(json['strengths']),
      warnings: parseEntries(json['warnings']),
      blockers: parseEntries(json['blockers']),
      recommendedActions: parseEntries(json['recommendedActions']),
      confidence: conf,
      mandatoryGatesEvaluated:
          (json['mandatoryGatesEvaluated'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
      failedMandatoryGates: (json['failedMandatoryGates'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      totalEvidenceCount: json['totalEvidenceCount'] as int? ?? 0,
      durationMs: json['durationMs'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      errorMessage: json['errorMessage'] as String?,
      isAiSynthesized: json['isAiSynthesized'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'scope': scope.name,
        'targetScopeId': targetScopeId,
        'version': version,
        'status': status.name,
        'summary': SecretRedactor.redact(summary),
        'strengths': strengths.map((e) => e.toJson()).toList(),
        'warnings': warnings.map((e) => e.toJson()).toList(),
        'blockers': blockers.map((e) => e.toJson()).toList(),
        'recommendedActions':
            recommendedActions.map((e) => e.toJson()).toList(),
        'confidence': confidence.name,
        'mandatoryGatesEvaluated': mandatoryGatesEvaluated,
        'failedMandatoryGates': failedMandatoryGates,
        'totalEvidenceCount': totalEvidenceCount,
        'isAiSynthesized': isAiSynthesized,
        if (errorMessage != null)
          'errorMessage': SecretRedactor.redact(errorMessage!),
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };
}
