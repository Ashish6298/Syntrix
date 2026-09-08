/// Domain models and audit metrics for Phase 10.19: Studio UX & Accessibility Hardening.
library;

import 'dart:convert';

/// Accessibility and UX audit check dimension.
enum UxAuditDimension {
  responsiveLayouts,
  desktopLayouts,
  mobileLayouts,
  keyboardNavigation,
  focusBehavior,
  readableTypography,
  overflowHandling,
  semanticLabels,
  accessibleControls,
  themeCompatibility,
  errorStates,
  loadingStates,
  emptyStates;

  String get id => name;

  String get label {
    switch (this) {
      case UxAuditDimension.responsiveLayouts:
        return 'Responsive Layouts';
      case UxAuditDimension.desktopLayouts:
        return 'Desktop Layouts';
      case UxAuditDimension.mobileLayouts:
        return 'Mobile Layouts';
      case UxAuditDimension.keyboardNavigation:
        return 'Keyboard Navigation';
      case UxAuditDimension.focusBehavior:
        return 'Focus Traversal & Rings';
      case UxAuditDimension.readableTypography:
        return 'Readable Typography';
      case UxAuditDimension.overflowHandling:
        return 'Overflow & Clipping Handling';
      case UxAuditDimension.semanticLabels:
        return 'Semantic Labels & ARIA';
      case UxAuditDimension.accessibleControls:
        return 'Accessible Hit Targets (48x48)';
      case UxAuditDimension.themeCompatibility:
        return 'Dark & Light Theme Contrast';
      case UxAuditDimension.errorStates:
        return 'Resilient Error States';
      case UxAuditDimension.loadingStates:
        return 'Smooth Loading & Shimmer States';
      case UxAuditDimension.emptyStates:
        return 'Informative Empty States';
    }
  }
}

/// Status for an individual UX audit dimension.
enum UxAuditStatus {
  verified,
  warning,
  failed;

  String get id => name;

  String get label => name.toUpperCase();

  String get symbol {
    switch (this) {
      case UxAuditStatus.verified:
        return '✓';
      case UxAuditStatus.warning:
        return '⚠';
      case UxAuditStatus.failed:
        return '✗';
    }
  }
}

/// Individual UX hardening audit finding.
class UxAuditItem {
  final UxAuditDimension dimension;
  final UxAuditStatus status;
  final String complianceDetails;
  final double minimumContrastRatio;
  final bool keyboardAccessible;

  const UxAuditItem({
    required this.dimension,
    this.status = UxAuditStatus.verified,
    required this.complianceDetails,
    this.minimumContrastRatio = 4.5,
    this.keyboardAccessible = true,
  });

  Map<String, dynamic> toJson() => {
        'dimension': dimension.id,
        'status': status.id,
        'compliance_details': complianceDetails,
        'minimum_contrast_ratio': minimumContrastRatio,
        'keyboard_accessible': keyboardAccessible,
      };

  factory UxAuditItem.fromJson(Map<String, dynamic> json) {
    return UxAuditItem(
      dimension: UxAuditDimension.values.firstWhere(
        (d) => d.id == json['dimension'] || d.name == json['dimension'],
        orElse: () => UxAuditDimension.responsiveLayouts,
      ),
      status: UxAuditStatus.values.firstWhere(
        (s) => s.id == json['status'] || s.name == json['status'],
        orElse: () => UxAuditStatus.verified,
      ),
      complianceDetails: json['compliance_details'] as String? ?? '',
      minimumContrastRatio: (json['minimum_contrast_ratio'] as num?)?.toDouble() ?? 4.5,
      keyboardAccessible: json['keyboard_accessible'] as bool? ?? true,
    );
  }
}

/// Comprehensive UX & Accessibility Hardening Report.
class StudioUxHardeningReport {
  final String reportId;
  final bool overallCompliant;
  final List<UxAuditItem> auditItems;
  final DateTime auditedAt;

  const StudioUxHardeningReport({
    required this.reportId,
    required this.overallCompliant,
    required this.auditItems,
    required this.auditedAt,
  });

  Map<String, dynamic> toJson() => {
        'report_id': reportId,
        'overall_compliant': overallCompliant,
        'audit_items': auditItems.map((a) => a.toJson()).toList(),
        'audited_at': auditedAt.toIso8601String(),
      };

  factory StudioUxHardeningReport.fromJson(Map<String, dynamic> json) {
    return StudioUxHardeningReport(
      reportId: json['report_id'] as String? ?? 'ux_default',
      overallCompliant: json['overall_compliant'] as bool? ?? true,
      auditItems: (json['audit_items'] as List<dynamic>?)
              ?.map((a) => UxAuditItem.fromJson(a as Map<String, dynamic>))
              .toList() ??
          const [],
      auditedAt: DateTime.parse(json['audited_at'] as String),
    );
  }
}
