/// Domain models for AI Debugging & Failure Diagnosis (Phase 8.5).
library;

import 'package:syntrix/src/ai/review/code_review_models.dart';
import 'package:syntrix/src/ai/testing/test_intelligence_models.dart';

/// Explicit certainty tier for a diagnosed cause.
/// Must never be collapsed into an unqualified free-text string.
enum CauseCertainty {
  /// Directly reproduced or unambiguously demonstrated by the collected evidence.
  confirmed,

  /// Strongly implied by the evidence but not independently reproduced.
  probable,

  /// Plausible given partial or circumstantial evidence.
  possible;

  static CauseCertainty? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in CauseCertainty.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    return null;
  }
}

/// A structured likely cause tagged with its certainty level.
class DiagnosedCause implements Comparable<DiagnosedCause> {
  /// Clear description of the diagnosed cause.
  final String description;

  /// Explicit certainty level (confirmed, probable, possible).
  final CauseCertainty certainty;

  /// Specific reasoning supporting this cause assessment.
  final String rationale;

  const DiagnosedCause({
    required this.description,
    required this.certainty,
    required this.rationale,
  });

  factory DiagnosedCause.fromJson(Map<String, dynamic> json) {
    final certStr = json['certainty'] as String? ?? 'probable';
    final certainty =
        CauseCertainty.tryParse(certStr) ?? CauseCertainty.probable;
    return DiagnosedCause(
      description: json['description'] as String? ?? 'Unknown cause',
      certainty: certainty,
      rationale: json['rationale'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'certainty': certainty.name,
        'rationale': rationale,
      };

  @override
  int compareTo(DiagnosedCause other) =>
      certainty.index.compareTo(other.certainty.index);
}

/// Category classification of ingested failure evidence.
enum EvidenceType {
  /// Dart runtime or framework stack trace.
  stackTrace,

  /// Test failure or assertion error (e.g. from Phase 8.4 tracking).
  testFailure,

  /// Dart analyzer error, warning, or lint issue.
  analyzerOutput,

  /// CLI usage, argument parsing, or command exit code error.
  cliError,

  /// Compiler, Gradle, CocoaPods, or CMake build error.
  buildError,

  /// Prior phase implementation or verification report finding.
  historicalReport,

  /// General error message or logs.
  generalLog;

  static EvidenceType? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in EvidenceType.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    return null;
  }
}

/// Individual item of collected engineering evidence.
class DiagnosisEvidenceItem {
  /// Unique identifier or label for this evidence item.
  final String id;

  /// Type of evidence.
  final EvidenceType type;

  /// Origin or source path (e.g. "test/widget_test.dart:L42" or "dart analyze").
  final String source;

  /// Raw textual content or payload of the evidence.
  final String content;

  /// Optional contextual metadata.
  final Map<String, dynamic> metadata;

  const DiagnosisEvidenceItem({
    required this.id,
    required this.type,
    required this.source,
    required this.content,
    this.metadata = const {},
  });

  factory DiagnosisEvidenceItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'generalLog';
    final type = EvidenceType.tryParse(typeStr) ?? EvidenceType.generalLog;
    return DiagnosisEvidenceItem(
      id: json['id'] as String? ??
          'ev_${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      source: json['source'] as String? ?? 'unknown',
      content: json['content'] as String? ?? '',
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'source': source,
        'content': content,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

/// Complete evidence bundle supplied to the diagnosis engine.
class FailureEvidenceBundle {
  /// Primary error message or failure headline.
  final String primaryError;

  /// List of structured evidence items.
  final List<DiagnosisEvidenceItem> items;

  /// Target package identifier (if known).
  final String? targetPackage;

  /// Target file path (if known).
  final String? targetFile;

  /// Tracked test failure record (from Phase 8.4, if applicable).
  final TrackedTestCase? failedTestRecord;

  /// Historical report excerpts or citations.
  final List<String> historicalReportCitations;

  const FailureEvidenceBundle({
    required this.primaryError,
    this.items = const [],
    this.targetPackage,
    this.targetFile,
    this.failedTestRecord,
    this.historicalReportCitations = const [],
  });

  factory FailureEvidenceBundle.fromSingleError({
    required String errorMessage,
    String? stackTrace,
    String? targetPackage,
    String? targetFile,
    TrackedTestCase? failedTestRecord,
  }) {
    final items = <DiagnosisEvidenceItem>[];
    if (stackTrace != null && stackTrace.trim().isNotEmpty) {
      items.add(DiagnosisEvidenceItem(
        id: 'ev_stack_trace',
        type: EvidenceType.stackTrace,
        source: targetFile ?? 'runtime',
        content: stackTrace,
      ));
    }
    if (failedTestRecord != null) {
      items.add(DiagnosisEvidenceItem(
        id: 'ev_test_failure',
        type: EvidenceType.testFailure,
        source: failedTestRecord.testFilePath,
        content:
            'Test "${failedTestRecord.name}" failed on ${failedTestRecord.targetSourceFile}',
      ));
    }

    return FailureEvidenceBundle(
      primaryError: errorMessage,
      items: items,
      targetPackage: targetPackage,
      targetFile: targetFile,
      failedTestRecord: failedTestRecord,
    );
  }

  Map<String, dynamic> toJson() => {
        'primaryError': primaryError,
        if (targetPackage != null) 'targetPackage': targetPackage,
        if (targetFile != null) 'targetFile': targetFile,
        'items': items.map((i) => i.toJson()).toList(),
        if (failedTestRecord != null)
          'failedTestRecord': failedTestRecord!.toJson(),
        if (historicalReportCitations.isNotEmpty)
          'historicalReportCitations': historicalReportCitations,
      };
}

/// Step-by-step verification plan instructions to confirm the fix works.
/// Contains concrete steps (e.g. "re-run test X", "run dart analyze on Y")
/// that the human maintainer can execute. The engine itself never executes them.
class VerificationStep {
  /// Step order index.
  final int stepNumber;

  /// Instruction or command to run.
  final String action;

  /// Expected outcome confirming remediation success.
  final String expectedOutcome;

  const VerificationStep({
    required this.stepNumber,
    required this.action,
    required this.expectedOutcome,
  });

  factory VerificationStep.fromJson(Map<String, dynamic> json) =>
      VerificationStep(
        stepNumber: json['stepNumber'] as int? ?? 1,
        action: json['action'] as String? ?? '',
        expectedOutcome: json['expectedOutcome'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'stepNumber': stepNumber,
        'action': action,
        'expectedOutcome': expectedOutcome,
      };
}

/// Structured diagnosis containing all 7 mandatory fields:
/// 1. Problem
/// 2. Likely Cause (tiered with CauseCertainty: confirmed/probable/possible)
/// 3. Evidence (cited specific inputs)
/// 4. Affected Components (narrowed packages/files)
/// 5. Recommended Fix (remediation plan)
/// 6. Risk (remediation risk rating)
/// 7. Verification Steps (concrete verification instructions)
class FailureDiagnosis {
  /// 1. Concise description of the problem/defect.
  final String problem;

  /// 2. Tiered likely causes with explicit certainty levels.
  final List<DiagnosedCause> likelyCauses;

  /// 3. Explicit citations and references to the specific evidence items used.
  final List<String> citedEvidence;

  /// 4. Narrowed affected components (package names and relative file paths).
  final List<String> affectedComponents;

  /// 5. Detailed recommended remediation fix.
  final String recommendedFix;

  /// 6. Remediation risk assessment (critical/high/medium/low).
  final CodeReviewSeverity risk;

  /// 7. Concrete human-executable verification plan steps.
  final List<VerificationStep> verificationSteps;

  const FailureDiagnosis({
    required this.problem,
    required this.likelyCauses,
    required this.citedEvidence,
    required this.affectedComponents,
    required this.recommendedFix,
    required this.risk,
    required this.verificationSteps,
  });

  factory FailureDiagnosis.fromJson(Map<String, dynamic> json) {
    final rawCauses = json['likelyCauses'] as List<dynamic>? ?? const [];
    final rawCited = json['citedEvidence'] as List<dynamic>? ?? const [];
    final rawComponents =
        json['affectedComponents'] as List<dynamic>? ?? const [];
    final rawSteps = json['verificationSteps'] as List<dynamic>? ?? const [];

    final riskStr = json['risk'] as String? ?? 'medium';
    final risk =
        CodeReviewSeverity.tryParse(riskStr) ?? CodeReviewSeverity.medium;

    return FailureDiagnosis(
      problem: json['problem'] as String? ?? 'Unspecified problem',
      likelyCauses: rawCauses
          .whereType<Map<String, dynamic>>()
          .map(DiagnosedCause.fromJson)
          .toList(),
      citedEvidence: rawCited.map((e) => e.toString()).toList(),
      affectedComponents: rawComponents.map((c) => c.toString()).toList(),
      recommendedFix: json['recommendedFix'] as String? ?? 'No fix proposed.',
      risk: risk,
      verificationSteps: rawSteps
          .whereType<Map<String, dynamic>>()
          .map(VerificationStep.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'problem': problem,
        'likelyCauses': likelyCauses.map((c) => c.toJson()).toList(),
        'citedEvidence': citedEvidence,
        'affectedComponents': affectedComponents,
        'recommendedFix': recommendedFix,
        'risk': risk.name,
        'verificationSteps': verificationSteps.map((s) => s.toJson()).toList(),
      };
}

/// Request supplied to the Diagnosis Engine.
class DiagnosisRequest {
  /// The evidence bundle to diagnose.
  final FailureEvidenceBundle evidence;

  /// Target package override.
  final String? targetPackage;

  /// Token budget limit.
  final int tokenBudget;

  const DiagnosisRequest({
    required this.evidence,
    this.targetPackage,
    this.tokenBudget = 4000,
  });

  Map<String, dynamic> toJson() => {
        'evidence': evidence.toJson(),
        if (targetPackage != null) 'targetPackage': targetPackage,
        'tokenBudget': tokenBudget,
      };
}

/// Overall result emitted by the Diagnosis Engine.
class DiagnosisResult {
  /// Target package or scope diagnosed.
  final String packageId;

  /// Whether the diagnosis succeeded.
  final bool isSuccess;

  /// The structured failure diagnosis (if successful).
  final FailureDiagnosis? diagnosis;

  /// High-level summary of the diagnosis.
  final String summary;

  /// Citations to historical reports (e.g. phase_8_x_verification_report.txt).
  final List<String> historicalCitations;

  /// Duration in milliseconds.
  final int durationMs;

  /// Timestamp.
  final DateTime timestamp;

  /// Error message if diagnosis failed.
  final String? errorMessage;

  const DiagnosisResult({
    required this.packageId,
    required this.isSuccess,
    this.diagnosis,
    required this.summary,
    this.historicalCitations = const [],
    required this.durationMs,
    required this.timestamp,
    this.errorMessage,
  });

  factory DiagnosisResult.failure({
    required String packageId,
    required String errorMessage,
    int durationMs = 0,
    DateTime? timestamp,
  }) =>
      DiagnosisResult(
        packageId: packageId,
        isSuccess: false,
        diagnosis: null,
        summary: 'Diagnosis failed: $errorMessage',
        durationMs: durationMs,
        timestamp: timestamp ?? DateTime.now(),
        errorMessage: errorMessage,
      );

  Map<String, dynamic> toJson() => {
        'packageId': packageId,
        'isSuccess': isSuccess,
        'summary': summary,
        if (diagnosis != null) 'diagnosis': diagnosis!.toJson(),
        if (historicalCitations.isNotEmpty)
          'historicalCitations': historicalCitations,
        if (errorMessage != null) 'errorMessage': errorMessage,
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };
}
