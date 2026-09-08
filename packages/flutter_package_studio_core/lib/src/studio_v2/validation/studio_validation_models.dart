/// Domain models and validation checks for Phase 10.17: Automated Validation Center.
library;

import 'dart:convert';

/// Status for an individual validation check or category.
enum ValidationCheckStatus {
  pass,
  warning,
  fail,
  skipped;

  String get id => name;

  String get label => name.toUpperCase();

  String get symbol {
    switch (this) {
      case ValidationCheckStatus.pass:
        return '✓';
      case ValidationCheckStatus.warning:
        return '⚠';
      case ValidationCheckStatus.fail:
        return '✗';
      case ValidationCheckStatus.skipped:
        return '○';
    }
  }
}

/// Category grouping validation checks in Studio v2.
enum StudioValidationCategory {
  architecture,
  api,
  tests,
  rendering,
  performance,
  documentation,
  compatibility;

  String get id => name;

  String get label {
    switch (this) {
      case StudioValidationCategory.architecture:
        return 'Architecture';
      case StudioValidationCategory.api:
        return 'API';
      case StudioValidationCategory.tests:
        return 'Tests';
      case StudioValidationCategory.rendering:
        return 'Rendering';
      case StudioValidationCategory.performance:
        return 'Performance';
      case StudioValidationCategory.documentation:
        return 'Documentation';
      case StudioValidationCategory.compatibility:
        return 'Compatibility';
    }
  }
}

/// Overall package health evaluation.
enum PackageHealthStatus {
  healthy,
  degraded,
  unhealthy;

  String get id => name;

  String get label => name.toUpperCase();
}

/// Individual validation check item.
class ValidationCheckItem {
  final String checkId;
  final String title;
  final StudioValidationCategory category;
  final ValidationCheckStatus status;
  final String details;
  final double durationMs;

  const ValidationCheckItem({
    required this.checkId,
    required this.title,
    required this.category,
    this.status = ValidationCheckStatus.pass,
    this.details = '',
    this.durationMs = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'check_id': checkId,
        'title': title,
        'category': category.id,
        'status': status.id,
        'details': details,
        'duration_ms': durationMs,
      };

  factory ValidationCheckItem.fromJson(Map<String, dynamic> json) {
    return ValidationCheckItem(
      checkId: json['check_id'] as String? ?? 'check_default',
      title: json['title'] as String? ?? 'Validation Check',
      category: StudioValidationCategory.values.firstWhere(
        (c) => c.id == json['category'] || c.name == json['category'],
        orElse: () => StudioValidationCategory.architecture,
      ),
      status: ValidationCheckStatus.values.firstWhere(
        (s) => s.id == json['status'] || s.name == json['status'],
        orElse: () => ValidationCheckStatus.pass,
      ),
      details: json['details'] as String? ?? '',
      durationMs: (json['duration_ms'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Comprehensive Package Health & Validation Report.
class StudioValidationReport {
  final String reportId;
  final String packageName;
  final String packageVersion;
  final PackageHealthStatus overallHealth;
  final Map<StudioValidationCategory, ValidationCheckStatus> categorySummaries;
  final List<ValidationCheckItem> checks;
  final DateTime validatedAt;

  const StudioValidationReport({
    required this.reportId,
    required this.packageName,
    required this.packageVersion,
    required this.overallHealth,
    required this.categorySummaries,
    required this.checks,
    required this.validatedAt,
  });

  Map<String, dynamic> toJson() => {
        'report_id': reportId,
        'package_name': packageName,
        'package_version': packageVersion,
        'overall_health': overallHealth.id,
        'category_summaries': categorySummaries.map((k, v) => MapEntry(k.id, v.id)),
        'checks': checks.map((c) => c.toJson()).toList(),
        'validated_at': validatedAt.toIso8601String(),
      };

  factory StudioValidationReport.fromJson(Map<String, dynamic> json) {
    final catMap = <StudioValidationCategory, ValidationCheckStatus>{};
    if (json['category_summaries'] != null) {
      final raw = json['category_summaries'] as Map<String, dynamic>;
      for (final e in raw.entries) {
        final cat = StudioValidationCategory.values.firstWhere(
          (c) => c.id == e.key || c.name == e.key,
          orElse: () => StudioValidationCategory.architecture,
        );
        final st = ValidationCheckStatus.values.firstWhere(
          (s) => s.id == e.value || s.name == e.value,
          orElse: () => ValidationCheckStatus.pass,
        );
        catMap[cat] = st;
      }
    }

    return StudioValidationReport(
      reportId: json['report_id'] as String? ?? 'val_default',
      packageName: json['package_name'] as String? ?? 'Syntrix',
      packageVersion: json['package_version'] as String? ?? '2.0.0',
      overallHealth: PackageHealthStatus.values.firstWhere(
        (h) => h.id == json['overall_health'] || h.name == json['overall_health'],
        orElse: () => PackageHealthStatus.healthy,
      ),
      categorySummaries: catMap,
      checks: (json['checks'] as List<dynamic>?)
              ?.map((c) => ValidationCheckItem.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      validatedAt: DateTime.parse(json['validated_at'] as String),
    );
  }
}
