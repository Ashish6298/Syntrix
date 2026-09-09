/// Domain models and evaluation criteria for Phase 11.3: Full Regression Testing.
library;

/// Categories evaluated in the regression test matrix.
enum RegressionTestCategory {
  cleanAndDeps,
  staticAnalysis,
  documentationGeneration,
  unitAndWidgetTests,
  codeCoverage,
  minimumDependencyCompatibility;

  String get id => name;

  String get label {
    switch (this) {
      case RegressionTestCategory.cleanAndDeps:
        return 'Clean & Dependency Resolution';
      case RegressionTestCategory.staticAnalysis:
        return 'Static Analysis (Analyze)';
      case RegressionTestCategory.documentationGeneration:
        return 'Documentation Generation (Dart Doc)';
      case RegressionTestCategory.unitAndWidgetTests:
        return 'Unit & Integration Test Suite';
      case RegressionTestCategory.codeCoverage:
        return 'Code Coverage Certification';
      case RegressionTestCategory.minimumDependencyCompatibility:
        return 'Minimum Dependency Version Matrix';
    }
  }
}

/// Status of a regression test step.
enum RegressionStepStatus {
  passed,
  failed,
  warning;

  String get id => name;

  String get label {
    switch (this) {
      case RegressionStepStatus.passed:
        return 'PASS';
      case RegressionStepStatus.failed:
        return 'FAIL';
      case RegressionStepStatus.warning:
        return 'WARN';
    }
  }

  String get symbol => this == RegressionStepStatus.passed
      ? '✓'
      : (this == RegressionStepStatus.warning ? '⚠' : '✗');
}

/// Individual item in the regression test matrix.
class RegressionTestItem {
  final RegressionTestCategory category;
  final String command;
  final RegressionStepStatus status;
  final String verificationDetails;
  final int durationMs;

  const RegressionTestItem({
    required this.category,
    required this.command,
    this.status = RegressionStepStatus.passed,
    required this.verificationDetails,
    this.durationMs = 0,
  });

  Map<String, dynamic> toJson() => {
        'category': category.id,
        'command': command,
        'status': status.id,
        'verification_details': verificationDetails,
        'duration_ms': durationMs,
      };

  factory RegressionTestItem.fromJson(Map<String, dynamic> json) {
    return RegressionTestItem(
      category: RegressionTestCategory.values.firstWhere(
        (c) => c.id == json['category'] || c.name == json['category'],
        orElse: () => RegressionTestCategory.unitAndWidgetTests,
      ),
      command: json['command'] as String? ?? '',
      status: RegressionStepStatus.values.firstWhere(
        (s) => s.id == json['status'] || s.name == json['status'],
        orElse: () => RegressionStepStatus.passed,
      ),
      verificationDetails: json['verification_details'] as String? ?? '',
      durationMs: json['duration_ms'] as int? ?? 0,
    );
  }
}

/// Comprehensive Phase 11.3 Full Regression Testing Report.
class RegressionTestReport {
  final String reportId;
  final String targetVersion;
  final bool isRegressionPassed;
  final int totalChecks;
  final int totalTestsRun;
  final double coveragePercentage;
  final List<RegressionTestItem> testItems;
  final DateTime testedAt;

  const RegressionTestReport({
    required this.reportId,
    required this.targetVersion,
    required this.isRegressionPassed,
    required this.totalChecks,
    required this.totalTestsRun,
    required this.coveragePercentage,
    required this.testItems,
    required this.testedAt,
  });

  Map<String, dynamic> toJson() => {
        'report_id': reportId,
        'target_version': targetVersion,
        'is_regression_passed': isRegressionPassed,
        'total_checks': totalChecks,
        'total_tests_run': totalTestsRun,
        'coverage_percentage': coveragePercentage,
        'test_items': testItems.map((i) => i.toJson()).toList(),
        'tested_at': testedAt.toIso8601String(),
      };

  factory RegressionTestReport.fromJson(Map<String, dynamic> json) {
    return RegressionTestReport(
      reportId: json['report_id'] as String? ?? 'regression_report_default',
      targetVersion: json['target_version'] as String? ?? '1.0.0',
      isRegressionPassed: json['is_regression_passed'] as bool? ?? true,
      totalChecks: json['total_checks'] as int? ?? 0,
      totalTestsRun: json['total_tests_run'] as int? ?? 0,
      coveragePercentage:
          (json['coverage_percentage'] as num?)?.toDouble() ?? 0.0,
      testItems: (json['test_items'] as List<dynamic>?)
              ?.map(
                  (i) => RegressionTestItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          const [],
      testedAt: DateTime.parse(json['tested_at'] as String),
    );
  }
}
