/// Domain models and evaluation criteria for Phase 11.2: Breaking-Change Audit.
library;

/// Dimensions audited for potential unintentional breaking changes.
enum BreakingChangeDimension {
  constructorSignatures,
  parameterNames,
  defaultValues,
  nullabilityTypes,
  enumValues,
  callbackSignatures,
  methodNames,
  returnTypes,
  publicInheritance,
  publicInterfaces;

  String get id => name;

  String get label {
    switch (this) {
      case BreakingChangeDimension.constructorSignatures:
        return 'Constructor signatures';
      case BreakingChangeDimension.parameterNames:
        return 'Parameter names';
      case BreakingChangeDimension.defaultValues:
        return 'Default values';
      case BreakingChangeDimension.nullabilityTypes:
        return 'Nullable/non-nullable types';
      case BreakingChangeDimension.enumValues:
        return 'Enum values';
      case BreakingChangeDimension.callbackSignatures:
        return 'Callback signatures';
      case BreakingChangeDimension.methodNames:
        return 'Method names';
      case BreakingChangeDimension.returnTypes:
        return 'Return types';
      case BreakingChangeDimension.publicInheritance:
        return 'Public inheritance';
      case BreakingChangeDimension.publicInterfaces:
        return 'Public interfaces';
    }
  }
}

/// Audit verification status for breaking change checks.
enum BreakingChangeStatus {
  compliant,
  breakingChangeDetected,
  intentionalChangeVerified;

  String get id => name;

  String get label {
    switch (this) {
      case BreakingChangeStatus.compliant:
        return 'COMPLIANT';
      case BreakingChangeStatus.breakingChangeDetected:
        return 'BREAKING';
      case BreakingChangeStatus.intentionalChangeVerified:
        return 'INTENTIONAL';
    }
  }

  String get symbol => this == BreakingChangeStatus.compliant
      ? '✓'
      : (this == BreakingChangeStatus.intentionalChangeVerified ? 'ℹ' : '✗');
}

/// Item representing an individual breaking-change audit evaluation.
class BreakingChangeAuditItem {
  final BreakingChangeDimension dimension;
  final BreakingChangeStatus status;
  final String auditedTarget;
  final String verificationDetails;

  const BreakingChangeAuditItem({
    required this.dimension,
    this.status = BreakingChangeStatus.compliant,
    required this.auditedTarget,
    required this.verificationDetails,
  });

  Map<String, dynamic> toJson() => {
        'dimension': dimension.id,
        'status': status.id,
        'audited_target': auditedTarget,
        'verification_details': verificationDetails,
      };

  factory BreakingChangeAuditItem.fromJson(Map<String, dynamic> json) {
    return BreakingChangeAuditItem(
      dimension: BreakingChangeDimension.values.firstWhere(
        (d) => d.id == json['dimension'] || d.name == json['dimension'],
        orElse: () => BreakingChangeDimension.constructorSignatures,
      ),
      status: BreakingChangeStatus.values.firstWhere(
        (s) => s.id == json['status'] || s.name == json['status'],
        orElse: () => BreakingChangeStatus.compliant,
      ),
      auditedTarget: json['audited_target'] as String? ?? '',
      verificationDetails: json['verification_details'] as String? ?? '',
    );
  }
}

/// Comprehensive Phase 11.2 Breaking-Change Audit Report.
class BreakingChangeAuditReport {
  final String reportId;
  final String targetVersion;
  final bool isBackwardCompatible;
  final int totalDimensionsAudited;
  final int totalViolationsFound;
  final List<BreakingChangeAuditItem> auditItems;
  final DateTime auditedAt;

  const BreakingChangeAuditReport({
    required this.reportId,
    required this.targetVersion,
    required this.isBackwardCompatible,
    required this.totalDimensionsAudited,
    required this.totalViolationsFound,
    required this.auditItems,
    required this.auditedAt,
  });

  Map<String, dynamic> toJson() => {
        'report_id': reportId,
        'target_version': targetVersion,
        'is_backward_compatible': isBackwardCompatible,
        'total_dimensions_audited': totalDimensionsAudited,
        'total_violations_found': totalViolationsFound,
        'audit_items': auditItems.map((i) => i.toJson()).toList(),
        'audited_at': auditedAt.toIso8601String(),
      };

  factory BreakingChangeAuditReport.fromJson(Map<String, dynamic> json) {
    return BreakingChangeAuditReport(
      reportId: json['report_id'] as String? ?? 'breaking_audit_default',
      targetVersion: json['target_version'] as String? ?? '1.0.0',
      isBackwardCompatible: json['is_backward_compatible'] as bool? ?? true,
      totalDimensionsAudited: json['total_dimensions_audited'] as int? ?? 0,
      totalViolationsFound: json['total_violations_found'] as int? ?? 0,
      auditItems: (json['audit_items'] as List<dynamic>?)
              ?.map((i) =>
                  BreakingChangeAuditItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      auditedAt: DateTime.parse(json['audited_at'] as String),
    );
  }
}
