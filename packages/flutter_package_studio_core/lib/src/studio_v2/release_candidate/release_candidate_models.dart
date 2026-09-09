/// Domain models and gate verification criteria for Phase 10.21: Release Candidate Audit.
library;

/// Dimensions evaluated in Milestone 10 Release Gate.
enum Milestone10GateDimension {
  coreFunctionality,
  existingUi,
  existingLoaders,
  existingThemes,
  rendering,
  interaction,
  diagnostics,
  studioV2,
  codeGeneration,
  presets,
  persistence,
  exportImport,
  performance,
  documentation,
  tests,
  staticAnalysis,
  dependencyCompatibility,
  pubDevValidation,
  regressionTesting;

  String get id => name;

  String get label {
    switch (this) {
      case Milestone10GateDimension.coreFunctionality:
        return 'Core functionality';
      case Milestone10GateDimension.existingUi:
        return 'Existing UI';
      case Milestone10GateDimension.existingLoaders:
        return 'Existing loaders';
      case Milestone10GateDimension.existingThemes:
        return 'Existing themes';
      case Milestone10GateDimension.rendering:
        return 'Rendering';
      case Milestone10GateDimension.interaction:
        return 'Interaction';
      case Milestone10GateDimension.diagnostics:
        return 'Diagnostics';
      case Milestone10GateDimension.studioV2:
        return 'Studio v2';
      case Milestone10GateDimension.codeGeneration:
        return 'Code generation';
      case Milestone10GateDimension.presets:
        return 'Presets';
      case Milestone10GateDimension.persistence:
        return 'Persistence';
      case Milestone10GateDimension.exportImport:
        return 'Export/Import';
      case Milestone10GateDimension.performance:
        return 'Performance';
      case Milestone10GateDimension.documentation:
        return 'Documentation';
      case Milestone10GateDimension.tests:
        return 'Tests';
      case Milestone10GateDimension.staticAnalysis:
        return 'Static analysis';
      case Milestone10GateDimension.dependencyCompatibility:
        return 'Dependency compatibility';
      case Milestone10GateDimension.pubDevValidation:
        return 'Pub.dev validation';
      case Milestone10GateDimension.regressionTesting:
        return 'Regression testing';
    }
  }
}

/// Audit verification status for release candidate gates.
enum GateStatus {
  pass,
  warning,
  fail;

  String get id => name;

  String get label => name.toUpperCase();

  String get symbol => this == GateStatus.pass
      ? 'PASS'
      : (this == GateStatus.warning ? 'WARN' : 'FAIL');
}

/// Verification result for a single release gate.
class ReleaseCandidateGateItem {
  final Milestone10GateDimension dimension;
  final GateStatus status;
  final String verificationDetails;

  const ReleaseCandidateGateItem({
    required this.dimension,
    this.status = GateStatus.pass,
    required this.verificationDetails,
  });

  Map<String, dynamic> toJson() => {
        'dimension': dimension.id,
        'status': status.id,
        'verification_details': verificationDetails,
      };

  factory ReleaseCandidateGateItem.fromJson(Map<String, dynamic> json) {
    return ReleaseCandidateGateItem(
      dimension: Milestone10GateDimension.values.firstWhere(
        (d) => d.id == json['dimension'] || d.name == json['dimension'],
        orElse: () => Milestone10GateDimension.coreFunctionality,
      ),
      status: GateStatus.values.firstWhere(
        (s) => s.id == json['status'] || s.name == json['status'],
        orElse: () => GateStatus.pass,
      ),
      verificationDetails: json['verification_details'] as String? ?? '',
    );
  }
}

/// Comprehensive Phase 10.21 / Milestone 10 Release Candidate Audit Report.
class ReleaseCandidateAuditReport {
  final String reportId;
  final String targetVersion;
  final bool isMilestone10Complete;
  final bool isReleaseCandidateReady;
  final List<ReleaseCandidateGateItem> gates;
  final Map<String, dynamic> packageMetadataCheck;
  final DateTime auditedAt;

  const ReleaseCandidateAuditReport({
    required this.reportId,
    required this.targetVersion,
    required this.isMilestone10Complete,
    required this.isReleaseCandidateReady,
    required this.gates,
    required this.packageMetadataCheck,
    required this.auditedAt,
  });

  Map<String, dynamic> toJson() => {
        'report_id': reportId,
        'target_version': targetVersion,
        'is_milestone10_complete': isMilestone10Complete,
        'is_release_candidate_ready': isReleaseCandidateReady,
        'gates': gates.map((g) => g.toJson()).toList(),
        'package_metadata_check': packageMetadataCheck,
        'audited_at': auditedAt.toIso8601String(),
      };

  factory ReleaseCandidateAuditReport.fromJson(Map<String, dynamic> json) {
    return ReleaseCandidateAuditReport(
      reportId: json['report_id'] as String? ?? 'rc_audit_default',
      targetVersion: json['target_version'] as String? ?? '1.0.0',
      isMilestone10Complete: json['is_milestone10_complete'] as bool? ?? true,
      isReleaseCandidateReady:
          json['is_release_candidate_ready'] as bool? ?? true,
      gates: (json['gates'] as List<dynamic>?)
              ?.map((g) =>
                  ReleaseCandidateGateItem.fromJson(g as Map<String, dynamic>))
              .toList() ??
          const [],
      packageMetadataCheck:
          (json['package_metadata_check'] as Map<String, dynamic>?) ?? {},
      auditedAt: DateTime.parse(json['audited_at'] as String),
    );
  }
}
