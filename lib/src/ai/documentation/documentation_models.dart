/// Domain models for AI Documentation Assistant (Phase 8.7).
library;

import 'package:syntrix/src/ai/review/code_review_models.dart';

/// Supported types of generated documentation.
enum DocumentationType {
  /// Public API surface documentation (classes, methods, parameters).
  apiDoc,

  /// README sections (e.g. Overview, Getting Started, Features).
  readmeSection,

  /// CLI command documentation (options, flags, usage).
  cliDoc,

  /// Architecture and subsystem explanations.
  architectureExplanation,

  /// Runnable or idiomatic code usage examples.
  usageExample,

  /// Troubleshooting, common pitfalls, and error resolution guides.
  troubleshootingDoc,

  /// Release notes and changelog entries.
  releaseDoc,

  /// Version migration notes and breaking change guides.
  migrationNote,

  /// Contributor and developer guides.
  developerGuide;

  static DocumentationType? tryParse(String? raw) {
    if (raw == null) return null;
    final clean =
        raw.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '');
    for (final val in DocumentationType.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    // Convenience aliases
    if (clean == 'api' || clean == 'apidoc') return DocumentationType.apiDoc;
    if (clean == 'readme' || clean == 'readmesection')
      return DocumentationType.readmeSection;
    if (clean == 'cli' || clean == 'clidoc') return DocumentationType.cliDoc;
    if (clean == 'architecture' || clean == 'arch')
      return DocumentationType.architectureExplanation;
    if (clean == 'example' || clean == 'usage' || clean == 'usageexample')
      return DocumentationType.usageExample;
    if (clean == 'troubleshooting' || clean == 'troubleshoot')
      return DocumentationType.troubleshootingDoc;
    if (clean == 'release' || clean == 'releasedoc')
      return DocumentationType.releaseDoc;
    if (clean == 'migration' || clean == 'migrationnote')
      return DocumentationType.migrationNote;
    if (clean == 'devguide' || clean == 'developerguide' || clean == 'guide')
      return DocumentationType.developerGuide;
    return null;
  }
}

/// Target artifact type in documentation inconsistency checks.
enum DocumentationArtifactType {
  /// CLI flag or option.
  cliOption,

  /// Public API member (method, property, class).
  apiMember,

  /// Configuration key (yaml, json, options).
  configKey,

  /// Thrown or handled exception type.
  exceptionType,

  /// General architectural or package convention.
  generalDoc;

  static DocumentationArtifactType? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in DocumentationArtifactType.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    return null;
  }
}

/// Structured mismatch finding between implemented code and documentation.
///
/// Reuses and maps to Phase 8.3 structured finding schema:
/// - severity: [CodeReviewSeverity]
/// - category: [CodeReviewCategory.apiUsage] or [CodeReviewCategory.maintainability]
/// - file: documentation file path
/// - location: line or section in documentation
/// - problem: concise statement of discrepancy
/// - explanation: contrast between implemented reality vs documented claim
/// - recommendation: concrete fix to bring doc in sync with reality
/// - confidence: [CodeReviewConfidence]
class DocumentationMismatchFinding extends CodeReviewFinding {
  /// Specific artifact type (CLI option, API member, config key, etc.).
  final DocumentationArtifactType artifactType;

  /// The implemented reality in source code.
  final String implementedReality;

  /// What existing documentation currently claims.
  final String documentedClaim;

  const DocumentationMismatchFinding({
    required super.severity,
    required super.category,
    required super.file,
    required super.location,
    required super.problem,
    required super.explanation,
    required super.recommendation,
    required super.confidence,
    required this.artifactType,
    required this.implementedReality,
    required this.documentedClaim,
  });

  factory DocumentationMismatchFinding.fromJson(Map<String, dynamic> json) {
    final base = CodeReviewFinding.fromJson(json);
    final artTypeStr = json['artifactType'] as String? ?? 'generalDoc';
    final artType = DocumentationArtifactType.tryParse(artTypeStr) ??
        DocumentationArtifactType.generalDoc;

    return DocumentationMismatchFinding(
      severity: base.severity,
      category: base.category,
      file: base.file,
      location: base.location,
      problem: base.problem,
      explanation: base.explanation,
      recommendation: base.recommendation,
      confidence: base.confidence,
      artifactType: artType,
      implementedReality: json['implementedReality'] as String? ?? '',
      documentedClaim: json['documentedClaim'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'artifactType': artifactType.name,
        'implementedReality': implementedReality,
        'documentedClaim': documentedClaim,
      };
}

/// Request to generate documentation grounded in source evidence.
class DocumentationGenerationRequest {
  /// Target identifier (e.g. package name, class name, command name, or 'all').
  final String target;

  /// Type of documentation to generate.
  final DocumentationType docType;

  /// Optional specific target package in a monorepo workspace.
  final String? targetPackage;

  /// Optional user guidance or focus area.
  final String? instruction;

  /// Token budget for gathered context.
  final int tokenBudget;

  const DocumentationGenerationRequest({
    required this.target,
    required this.docType,
    this.targetPackage,
    this.instruction,
    this.tokenBudget = 4000,
  });

  Map<String, dynamic> toJson() => {
        'target': target,
        'docType': docType.name,
        if (targetPackage != null) 'targetPackage': targetPackage,
        if (instruction != null) 'instruction': instruction,
        'tokenBudget': tokenBudget,
      };
}

/// Result of documentation generation.
class DocumentationGenerationResult {
  final String target;
  final DocumentationType docType;
  final bool isSuccess;

  /// The generated Markdown content.
  final String markdownContent;

  /// Explicit manifest of source files and evidence items grounded in reality.
  final List<String> sourceEvidenceManifest;

  /// Explicit note if any requested content could not be found in source.
  final String? evidenceGapNotice;

  /// Execution duration in milliseconds.
  final int durationMs;

  /// Timestamp of generation.
  final DateTime timestamp;

  /// Error message if generation failed.
  final String? errorMessage;

  const DocumentationGenerationResult({
    required this.target,
    required this.docType,
    required this.isSuccess,
    required this.markdownContent,
    required this.sourceEvidenceManifest,
    this.evidenceGapNotice,
    required this.durationMs,
    required this.timestamp,
    this.errorMessage,
  });

  factory DocumentationGenerationResult.failure({
    required String target,
    required DocumentationType docType,
    required String errorMessage,
    int durationMs = 0,
    DateTime? timestamp,
  }) =>
      DocumentationGenerationResult(
        target: target,
        docType: docType,
        isSuccess: false,
        markdownContent: '',
        sourceEvidenceManifest: const [],
        errorMessage: errorMessage,
        durationMs: durationMs,
        timestamp: timestamp ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'target': target,
        'docType': docType.name,
        'isSuccess': isSuccess,
        'markdownContent': markdownContent,
        'sourceEvidenceManifest': sourceEvidenceManifest,
        if (evidenceGapNotice != null) 'evidenceGapNotice': evidenceGapNotice,
        if (errorMessage != null) 'errorMessage': errorMessage,
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Request to perform a documentation consistency check.
class DocumentationConsistencyRequest {
  /// Target package or scope in monorepo.
  final String? targetPackage;

  /// Token budget for gathered context.
  final int tokenBudget;

  const DocumentationConsistencyRequest({
    this.targetPackage,
    this.tokenBudget = 4000,
  });

  Map<String, dynamic> toJson() => {
        if (targetPackage != null) 'targetPackage': targetPackage,
        'tokenBudget': tokenBudget,
      };
}

/// Result of a documentation consistency check.
class DocumentationConsistencyResult {
  final String targetScope;
  final bool isSuccess;

  /// Structured mismatch findings.
  final List<DocumentationMismatchFinding> findings;

  /// List of documentation and implementation files compared.
  final List<String> comparedFiles;

  /// Summary of check outcome.
  final String summary;

  /// Execution duration in milliseconds.
  final int durationMs;

  /// Timestamp of check.
  final DateTime timestamp;

  /// Error message if check failed.
  final String? errorMessage;

  const DocumentationConsistencyResult({
    required this.targetScope,
    required this.isSuccess,
    required this.findings,
    required this.comparedFiles,
    required this.summary,
    required this.durationMs,
    required this.timestamp,
    this.errorMessage,
  });

  factory DocumentationConsistencyResult.failure({
    required String targetScope,
    required String errorMessage,
    int durationMs = 0,
    DateTime? timestamp,
  }) =>
      DocumentationConsistencyResult(
        targetScope: targetScope,
        isSuccess: false,
        findings: const [],
        comparedFiles: const [],
        summary: 'Documentation consistency check failed: $errorMessage',
        errorMessage: errorMessage,
        durationMs: durationMs,
        timestamp: timestamp ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'targetScope': targetScope,
        'isSuccess': isSuccess,
        'summary': summary,
        'mismatchCount': findings.length,
        'findings': findings.map((f) => f.toJson()).toList(),
        'comparedFiles': comparedFiles,
        if (errorMessage != null) 'errorMessage': errorMessage,
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };
}
