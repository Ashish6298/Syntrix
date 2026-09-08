/// Domain models and audit criteria for Phase 11.7: Pub.dev Forensic Audit.
library;

import 'dart:convert';

/// Status of an archive file audit check.
enum ArchiveCheckStatus {
  compliant,
  violating,
  ignored;

  String get id => name;

  String get label {
    switch (this) {
      case ArchiveCheckStatus.compliant:
        return 'COMPLIANT';
      case ArchiveCheckStatus.violating:
        return 'VIOLATING';
      case ArchiveCheckStatus.ignored:
        return 'IGNORED';
    }
  }

  String get symbol => this == ArchiveCheckStatus.compliant ? '✓' : (this == ArchiveCheckStatus.violating ? '✗' : '⚠');
}

/// Category of published archive items audited.
enum ArchiveAuditCategory {
  requiredContent,
  hygieneAndSecurity,
  artifactExclusion;

  String get id => name;

  String get label {
    switch (this) {
      case ArchiveAuditCategory.requiredContent:
        return 'Required Content & Assets';
      case ArchiveAuditCategory.hygieneAndSecurity:
        return 'Hygiene & Security';
      case ArchiveAuditCategory.artifactExclusion:
        return 'Artifact & Tool Exclusion';
    }
  }
}

/// Item representing an individual archive verification check.
class PubArchiveCheckItem {
  final String ruleIdentifier;
  final ArchiveAuditCategory category;
  final ArchiveCheckStatus status;
  final String verificationDetails;

  const PubArchiveCheckItem({
    required this.ruleIdentifier,
    required this.category,
    this.status = ArchiveCheckStatus.compliant,
    required this.verificationDetails,
  });

  Map<String, dynamic> toJson() => {
        'rule_identifier': ruleIdentifier,
        'category': category.id,
        'status': status.id,
        'verification_details': verificationDetails,
      };

  factory PubArchiveCheckItem.fromJson(Map<String, dynamic> json) {
    return PubArchiveCheckItem(
      ruleIdentifier: json['rule_identifier'] as String? ?? '',
      category: ArchiveAuditCategory.values.firstWhere(
        (c) => c.id == json['category'] || c.name == json['category'],
        orElse: () => ArchiveAuditCategory.requiredContent,
      ),
      status: ArchiveCheckStatus.values.firstWhere(
        (s) => s.id == json['status'] || s.name == json['status'],
        orElse: () => ArchiveCheckStatus.compliant,
      ),
      verificationDetails: json['verification_details'] as String? ?? '',
    );
  }
}

/// Comprehensive Phase 11.7 Pub.dev Forensic Audit Report.
class PubForensicAuditReport {
  final String reportId;
  final String targetVersion;
  final bool isArchiveCertified;
  final bool isDryRunClean;
  final int totalChecksRun;
  final List<PubArchiveCheckItem> checkItems;
  final DateTime auditedAt;

  const PubForensicAuditReport({
    required this.reportId,
    required this.targetVersion,
    required this.isArchiveCertified,
    required this.isDryRunClean,
    required this.totalChecksRun,
    required this.checkItems,
    required this.auditedAt,
  });

  Map<String, dynamic> toJson() => {
        'report_id': reportId,
        'target_version': targetVersion,
        'is_archive_certified': isArchiveCertified,
        'is_dry_run_clean': isDryRunClean,
        'total_checks_run': totalChecksRun,
        'check_items': checkItems.map((i) => i.toJson()).toList(),
        'audited_at': auditedAt.toIso8601String(),
      };

  factory PubForensicAuditReport.fromJson(Map<String, dynamic> json) {
    return PubForensicAuditReport(
      reportId: json['report_id'] as String? ?? 'pub_audit_default',
      targetVersion: json['target_version'] as String? ?? '1.0.0',
      isArchiveCertified: json['is_archive_certified'] as bool? ?? true,
      isDryRunClean: json['is_dry_run_clean'] as bool? ?? true,
      totalChecksRun: json['total_checks_run'] as int? ?? 0,
      checkItems: (json['check_items'] as List<dynamic>?)
              ?.map((i) => PubArchiveCheckItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      auditedAt: DateTime.parse(json['audited_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
