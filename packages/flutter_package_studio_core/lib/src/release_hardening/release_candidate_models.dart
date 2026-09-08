/// Domain models and lifecycle validation for Phase 11.8: Release Candidate (RC1 & Final v1.0.0 Promotion).
library;

import 'dart:convert';

/// Stage of the release lifecycle.
enum ReleaseStage {
  rc1Candidate,
  finalValidation,
  v100Promoted;

  String get id => name;

  String get label {
    switch (this) {
      case ReleaseStage.rc1Candidate:
        return 'v1.0.0-rc.1 Tagged';
      case ReleaseStage.finalValidation:
        return 'Final Independent Validation';
      case ReleaseStage.v100Promoted:
        return 'v1.0.0 Stable Promoted';
    }
  }
}

/// Verification gate evaluated during final independent validation.
enum IndependentValidationGate {
  apiFreezeCompliance,
  breakingChangeZeroPolicy,
  fullRegressionPass,
  multiPlatformCertified,
  performanceCertified,
  documentationComplete,
  pubArchiveClean,
  tamperProofAuditRecorded;

  String get id => name;

  String get label {
    switch (this) {
      case IndependentValidationGate.apiFreezeCompliance:
        return 'Phase 11.1 API Freeze Compliance';
      case IndependentValidationGate.breakingChangeZeroPolicy:
        return 'Phase 11.2 Zero Breaking Change Guarantee';
      case IndependentValidationGate.fullRegressionPass:
        return 'Phase 11.3 100% Full Regression Pass';
      case IndependentValidationGate.multiPlatformCertified:
        return 'Phase 11.4 6-Tier Platform Parity Certified';
      case IndependentValidationGate.performanceCertified:
        return 'Phase 11.5 Hardware Performance Baselines Certified';
      case IndependentValidationGate.documentationComplete:
        return 'Phase 11.6 Complete Documentation Certified';
      case IndependentValidationGate.pubArchiveClean:
        return 'Phase 11.7 Clean Pub.dev Dry-Run Forensic Archive';
      case IndependentValidationGate.tamperProofAuditRecorded:
        return 'Tamper-Proof Audit Trail Recorded';
    }
  }
}

/// Item representing a final validation gate status.
class FinalValidationGateItem {
  final IndependentValidationGate gate;
  final bool isPassed;
  final String verificationDetails;

  const FinalValidationGateItem({
    required this.gate,
    this.isPassed = true,
    required this.verificationDetails,
  });

  Map<String, dynamic> toJson() => {
        'gate': gate.id,
        'is_passed': isPassed,
        'verification_details': verificationDetails,
      };

  factory FinalValidationGateItem.fromJson(Map<String, dynamic> json) {
    return FinalValidationGateItem(
      gate: IndependentValidationGate.values.firstWhere(
        (g) => g.id == json['gate'] || g.name == json['gate'],
        orElse: () => IndependentValidationGate.apiFreezeCompliance,
      ),
      isPassed: json['is_passed'] as bool? ?? true,
      verificationDetails: json['verification_details'] as String? ?? '',
    );
  }
}

/// Comprehensive Phase 11.8 Release Candidate & v1.0.0 Promotion Report.
class ReleaseCandidatePromotionReport {
  final String reportId;
  final String releaseCandidateTag; // e.g. 'v1.0.0-rc.1'
  final String promotedStableVersion; // e.g. 'v1.0.0'
  final ReleaseStage currentStage;
  final bool isReadyForV100Promotion;
  final int totalGatesEvaluated;
  final List<FinalValidationGateItem> gateItems;
  final DateTime evaluatedAt;

  const ReleaseCandidatePromotionReport({
    required this.reportId,
    required this.releaseCandidateTag,
    required this.promotedStableVersion,
    required this.currentStage,
    required this.isReadyForV100Promotion,
    required this.totalGatesEvaluated,
    required this.gateItems,
    required this.evaluatedAt,
  });

  Map<String, dynamic> toJson() => {
        'report_id': reportId,
        'release_candidate_tag': releaseCandidateTag,
        'promoted_stable_version': promotedStableVersion,
        'current_stage': currentStage.id,
        'is_ready_for_v100_promotion': isReadyForV100Promotion,
        'total_gates_evaluated': totalGatesEvaluated,
        'gate_items': gateItems.map((g) => g.toJson()).toList(),
        'evaluated_at': evaluatedAt.toIso8601String(),
      };

  factory ReleaseCandidatePromotionReport.fromJson(Map<String, dynamic> json) {
    return ReleaseCandidatePromotionReport(
      reportId: json['report_id'] as String? ?? 'rc_report_default',
      releaseCandidateTag: json['release_candidate_tag'] as String? ?? 'v1.0.0-rc.1',
      promotedStableVersion: json['promoted_stable_version'] as String? ?? 'v1.0.0',
      currentStage: ReleaseStage.values.firstWhere(
        (s) => s.id == json['current_stage'] || s.name == json['current_stage'],
        orElse: () => ReleaseStage.v100Promoted,
      ),
      isReadyForV100Promotion: json['is_ready_for_v100_promotion'] as bool? ?? true,
      totalGatesEvaluated: json['total_gates_evaluated'] as int? ?? 0,
      gateItems: (json['gate_items'] as List<dynamic>?)
              ?.map((g) => FinalValidationGateItem.fromJson(g as Map<String, dynamic>))
              .toList() ??
          const [],
      evaluatedAt: DateTime.parse(json['evaluated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
