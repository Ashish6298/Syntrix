/// Domain models for AI Security & Privacy Advisor (Phase 8.9).
library;

import 'package:syntrix/src/ai/review/code_review_models.dart';
import 'package:syntrix/src/ai/security/secret_redactor.dart';

/// Categories of security, privacy, and credential concerns.
enum SecurityFindingCategory {
  /// Unsafe file exposure in project or release bundle (e.g. .env, key.properties).
  fileExposure,

  /// Insecure authentication handling or transport.
  authenticationHandling,

  /// Insecure credential handling, storage, or hardcoding.
  credentialHandling,

  /// Dangerous or insecure build/analysis/platform configuration.
  dangerousConfiguration,

  /// Security risks originating from package dependencies or CVEs.
  dependencyRisk,

  /// Dangerous files bundled into release distribution artifacts.
  releaseArtifactRisk,

  /// Unsafe manifest declarations, permissions, or metadata leaks.
  manifestRisk,

  /// Direct secret, API key, token, or private key exposure.
  secretExposure;

  static SecurityFindingCategory? tryParse(String? raw) {
    if (raw == null) return null;
    final clean =
        raw.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '');
    for (final val in SecurityFindingCategory.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    if (clean == 'file' || clean == 'fileexposure')
      return SecurityFindingCategory.fileExposure;
    if (clean == 'auth' ||
        clean == 'authentication' ||
        clean == 'authenticationhandling') {
      return SecurityFindingCategory.authenticationHandling;
    }
    if (clean == 'credential' || clean == 'credentialhandling')
      return SecurityFindingCategory.credentialHandling;
    if (clean == 'config' ||
        clean == 'configuration' ||
        clean == 'dangerousconfiguration') {
      return SecurityFindingCategory.dangerousConfiguration;
    }
    if (clean == 'dep' || clean == 'dependency' || clean == 'dependencyrisk') {
      return SecurityFindingCategory.dependencyRisk;
    }
    if (clean == 'artifact' ||
        clean == 'releaseartifact' ||
        clean == 'releaseartifactrisk') {
      return SecurityFindingCategory.releaseArtifactRisk;
    }
    if (clean == 'manifest' || clean == 'manifestrisk')
      return SecurityFindingCategory.manifestRisk;
    if (clean == 'secret' || clean == 'secretexposure')
      return SecurityFindingCategory.secretExposure;
    return null;
  }
}

/// Five-tier security priority classification.
///
/// Maps cleanly to [CodeReviewSeverity] to guarantee 100% schema consistency with Phases 8.3–8.8:
/// - critical -> [CodeReviewSeverity.critical]
/// - high -> [CodeReviewSeverity.high]
/// - medium -> [CodeReviewSeverity.medium]
/// - low -> [CodeReviewSeverity.low]
/// - informational -> [CodeReviewSeverity.informational]
enum SecurityPriority {
  /// Critical security vulnerability or exposed high-privilege credential requiring immediate remediation.
  critical,

  /// High-risk vulnerability, exposed auth token, or dangerous release configuration.
  high,

  /// Moderate security smell, missing defense-in-depth, or unpinned dependencies.
  medium,

  /// Low-risk configuration hygiene issue or minor file permission discrepancy.
  low,

  /// Informational best-practice or hardening recommendation.
  informational;

  static SecurityPriority? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in SecurityPriority.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    return null;
  }

  /// Converts this priority to its corresponding [CodeReviewSeverity].
  CodeReviewSeverity toSeverity() {
    switch (this) {
      case SecurityPriority.critical:
        return CodeReviewSeverity.critical;
      case SecurityPriority.high:
        return CodeReviewSeverity.high;
      case SecurityPriority.medium:
        return CodeReviewSeverity.medium;
      case SecurityPriority.low:
        return CodeReviewSeverity.low;
      case SecurityPriority.informational:
        return CodeReviewSeverity.informational;
    }
  }

  /// Factory creating [SecurityPriority] from [CodeReviewSeverity].
  static SecurityPriority fromSeverity(CodeReviewSeverity severity) {
    switch (severity) {
      case CodeReviewSeverity.critical:
        return SecurityPriority.critical;
      case CodeReviewSeverity.high:
        return SecurityPriority.high;
      case CodeReviewSeverity.medium:
        return SecurityPriority.medium;
      case CodeReviewSeverity.low:
        return SecurityPriority.low;
      case CodeReviewSeverity.informational:
        return SecurityPriority.informational;
    }
  }
}

/// Scope of security analysis.
enum SecurityAnalysisScope {
  /// Whole monorepo workspace across all packages and configuration.
  wholeProject,

  /// Scoped to a specific package within the workspace.
  package;

  static SecurityAnalysisScope? tryParse(String? raw) {
    if (raw == null) return null;
    final clean =
        raw.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '');
    for (final val in SecurityAnalysisScope.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    if (clean == 'all' ||
        clean == 'whole' ||
        clean == 'project' ||
        clean == 'wholeproject') {
      return SecurityAnalysisScope.wholeProject;
    }
    if (clean == 'pkg' || clean == 'package')
      return SecurityAnalysisScope.package;
    return null;
  }
}

/// Structured finding produced by the AI Security & Privacy Advisor.
///
/// Subclasses [CodeReviewFinding] to maintain 100% schema parity across Milestone 8:
/// - severity: [CodeReviewSeverity] (derived from priority)
/// - category: [CodeReviewCategory.unsafePattern] or mapped
/// - file: affected file path
/// - location: line or section identifier
/// - problem: concise statement of the security concern
/// - explanation: risk explanation in plain language
/// - recommendation: recommended mitigation
/// - confidence: [CodeReviewConfidence]
///
/// Extended with:
/// - [priority]: [SecurityPriority] (critical, high, medium, low, informational)
/// - [securityCategory]: [SecurityFindingCategory]
/// - [evidence]: references underlying deterministic audit output without raw secret values
/// - [impact]: plain-language explanation of impact if left unaddressed
/// - [verificationProcedure]: step-by-step procedure to verify the fix is resolved
class SecurityFindingItem extends CodeReviewFinding {
  /// The 5-tier security priority.
  final SecurityPriority priority;

  /// Domain security category.
  final SecurityFindingCategory securityCategory;

  /// Redacted evidence references supporting this finding (rule ID, path, sanitized snippet).
  final String evidence;

  /// Plain-language assessment of impact if unaddressed.
  final String impact;

  /// Step-by-step verification procedure for humans to confirm remediation.
  final String verificationProcedure;

  SecurityFindingItem({
    required super.severity,
    required super.category,
    required super.file,
    required super.location,
    required super.problem,
    required super.explanation,
    required super.recommendation,
    required super.confidence,
    required this.priority,
    required this.securityCategory,
    required String evidence,
    required String impact,
    required String verificationProcedure,
  })  : evidence = SecretRedactor.redact(evidence),
        impact = SecretRedactor.redact(impact),
        verificationProcedure = SecretRedactor.redact(verificationProcedure);

  factory SecurityFindingItem.fromJson(Map<String, dynamic> json) {
    // Redact the JSON first as an absolute safety invariant
    final redactedJson =
        SecretRedactor.redactJson(json) as Map<String, dynamic>;

    final base = CodeReviewFinding.fromJson(redactedJson);
    final prioStr = redactedJson['priority'] as String? ?? base.severity.name;
    final prio = SecurityPriority.tryParse(prioStr) ??
        SecurityPriority.fromSeverity(base.severity);

    final catStr =
        redactedJson['securityCategory'] as String? ?? 'secretExposure';
    final secCat = SecurityFindingCategory.tryParse(catStr) ??
        SecurityFindingCategory.secretExposure;

    return SecurityFindingItem(
      severity: prio.toSeverity(),
      category: base.category,
      file: base.file,
      location: base.location,
      problem: base.problem,
      explanation: base.explanation,
      recommendation: base.recommendation,
      confidence: base.confidence,
      priority: prio,
      securityCategory: secCat,
      evidence: redactedJson['evidence'] as String? ??
          'Deterministic audit rule finding',
      impact: redactedJson['impact'] as String? ??
          'Potential unauthorized access or compromise.',
      verificationProcedure: redactedJson['verificationProcedure'] as String? ??
          'Review file contents and re-run fps security to confirm finding is resolved.',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'priority': priority.name,
        'securityCategory': securityCategory.name,
        'evidence': SecretRedactor.redact(evidence),
        'impact': SecretRedactor.redact(impact),
        'verificationProcedure': SecretRedactor.redact(verificationProcedure),
      };
}

/// Request payload for security and privacy analysis.
class SecurityAnalysisRequest {
  /// Target scope (wholeProject or package).
  final SecurityAnalysisScope scope;

  /// Target package name when scope is [SecurityAnalysisScope.package].
  final String? targetPackage;

  /// Minimum priority threshold to include in findings.
  final SecurityPriority minPriority;

  /// Context token budget.
  final int tokenBudget;

  const SecurityAnalysisRequest({
    this.scope = SecurityAnalysisScope.wholeProject,
    this.targetPackage,
    this.minPriority = SecurityPriority.informational,
    this.tokenBudget = 4000,
  });

  Map<String, dynamic> toJson() => {
        'scope': scope.name,
        if (targetPackage != null) 'targetPackage': targetPackage,
        'minPriority': minPriority.name,
        'tokenBudget': tokenBudget,
      };
}

/// Result of security and privacy analysis.
class SecurityAnalysisResult {
  final SecurityAnalysisScope scope;
  final String targetScopeId;
  final bool isSuccess;

  /// High-level executive summary of security posture.
  final String summary;

  /// Total count of findings.
  int get findingCount => findings.length;

  /// Structured security findings, ordered by priority.
  final List<SecurityFindingItem> findings;

  /// Scanned packages list.
  final List<String> scannedPackages;

  /// Total count of deterministic audit findings consumed.
  final int deterministicAuditFindingsCount;

  /// Duration of execution in milliseconds.
  final int durationMs;

  /// Timestamp of analysis.
  final DateTime timestamp;

  /// Error message if analysis failed.
  final String? errorMessage;

  const SecurityAnalysisResult({
    required this.scope,
    required this.targetScopeId,
    required this.isSuccess,
    required this.summary,
    required this.findings,
    required this.scannedPackages,
    required this.deterministicAuditFindingsCount,
    required this.durationMs,
    required this.timestamp,
    this.errorMessage,
  });

  factory SecurityAnalysisResult.failure({
    required SecurityAnalysisScope scope,
    required String targetScopeId,
    required String errorMessage,
    int durationMs = 0,
    DateTime? timestamp,
  }) =>
      SecurityAnalysisResult(
        scope: scope,
        targetScopeId: targetScopeId,
        isSuccess: false,
        summary: 'Security analysis failed: $errorMessage',
        findings: const [],
        scannedPackages: const [],
        deterministicAuditFindingsCount: 0,
        errorMessage: errorMessage,
        durationMs: durationMs,
        timestamp: timestamp ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'scope': scope.name,
        'targetScopeId': targetScopeId,
        'isSuccess': isSuccess,
        'summary': SecretRedactor.redact(summary),
        'findingCount': findingCount,
        'findings': findings.map((f) => f.toJson()).toList(),
        'scannedPackages': scannedPackages,
        'deterministicAuditFindingsCount': deterministicAuditFindingsCount,
        if (errorMessage != null)
          'errorMessage': SecretRedactor.redact(errorMessage!),
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };
}
