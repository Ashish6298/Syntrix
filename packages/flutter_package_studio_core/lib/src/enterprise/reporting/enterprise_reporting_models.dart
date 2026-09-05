/// Domain models for Phase 9.14: Enterprise Compliance Reporting & Governance Reports.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/enterprise/security/enterprise_security_compliance_models.dart';

/// Supported formats for enterprise compliance and governance exports.
enum ComplianceReportFormat {
  json,
  markdown,
  csv,
  machineReadable;

  String get id => name;
}

/// Category of enterprise compliance and governance reports.
enum ComplianceReportType {
  securityCompliance,
  releaseCompliance,
  dependencyCompliance,
  policyViolations,
  approvalHistory,
  auditActivity,
  packageInventory,
  organizationStatus,
  releaseHistory,
  comprehensiveGovernance;

  String get id => name;

  String get displayName {
    switch (this) {
      case ComplianceReportType.securityCompliance:
        return 'Security Compliance Report';
      case ComplianceReportType.releaseCompliance:
        return 'Release Compliance Report';
      case ComplianceReportType.dependencyCompliance:
        return 'Dependency Compliance Report';
      case ComplianceReportType.policyViolations:
        return 'Policy Violations Report';
      case ComplianceReportType.approvalHistory:
        return 'Approval & Governance History Report';
      case ComplianceReportType.auditActivity:
        return 'Audit Trail Activity Report';
      case ComplianceReportType.packageInventory:
        return 'Package Inventory & Health Report';
      case ComplianceReportType.organizationStatus:
        return 'Organization Hierarchy & Status Report';
      case ComplianceReportType.releaseHistory:
        return 'Release & Publishing History Report';
      case ComplianceReportType.comprehensiveGovernance:
        return 'Comprehensive Enterprise Governance Report';
    }
  }
}

/// Generic container for a compliance table row or metric item.
class ComplianceReportSection {
  final String title;
  final String description;
  final List<String> headers;
  final List<List<String>> rows;
  final Map<String, dynamic> metadata;

  const ComplianceReportSection({
    required this.title,
    this.description = '',
    required this.headers,
    required this.rows,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'headers': headers,
        'rows': rows,
        'metadata': metadata,
      };

  factory ComplianceReportSection.fromJson(Map<String, dynamic> json) {
    return ComplianceReportSection(
      title: json['title'] as String? ?? 'Section',
      description: json['description'] as String? ?? '',
      headers: (json['headers'] as List<dynamic>?)
              ?.map((h) => h.toString())
              .toList() ??
          const [],
      rows: (json['rows'] as List<dynamic>?)
              ?.map((r) => (r as List<dynamic>).map((c) => c.toString()).toList())
              .toList() ??
          const [],
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Formally structured Enterprise Compliance & Governance Document.
class EnterpriseComplianceReport {
  final String reportId;
  final String organizationId;
  final ComplianceReportType reportType;
  final String title;
  final String executiveSummary;
  final bool isCompliant;
  final List<ComplianceReportSection> sections;
  final Map<String, dynamic> summaryMetrics;
  final DateTime generatedAt;

  const EnterpriseComplianceReport({
    required this.reportId,
    required this.organizationId,
    required this.reportType,
    required this.title,
    required this.executiveSummary,
    required this.isCompliant,
    required this.sections,
    this.summaryMetrics = const {},
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'report_id': reportId,
        'organization_id': organizationId,
        'report_type': reportType.id,
        'title': title,
        'executive_summary': executiveSummary,
        'is_compliant': isCompliant,
        'sections': sections.map((s) => s.toJson()).toList(),
        'summary_metrics': summaryMetrics,
        'generated_at': generatedAt.toIso8601String(),
      };

  factory EnterpriseComplianceReport.fromJson(Map<String, dynamic> json) {
    return EnterpriseComplianceReport(
      reportId: json['report_id'] as String? ?? 'rep_unknown',
      organizationId: json['organization_id'] as String? ?? 'default_org',
      reportType: ComplianceReportType.values.firstWhere(
        (t) => t.id == json['report_type'] || t.name == json['report_type'],
        orElse: () => ComplianceReportType.comprehensiveGovernance,
      ),
      title: json['title'] as String? ?? 'Enterprise Compliance Report',
      executiveSummary: json['executive_summary'] as String? ?? '',
      isCompliant: json['is_compliant'] as bool? ?? false,
      sections: (json['sections'] as List<dynamic>?)
              ?.map((s) => ComplianceReportSection.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      summaryMetrics: (json['summary_metrics'] as Map<String, dynamic>?) ?? const {},
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }
}
