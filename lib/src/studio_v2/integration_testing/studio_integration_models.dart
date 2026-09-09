/// Domain models and test matrix for Phase 10.20: Final Integration & Regression Testing.
library;

/// Subsystems verified in the Studio v2 complete pipeline.
enum StudioSubsystemPipelineStage {
  coreEngine,
  loaders,
  themes,
  particles,
  physics,
  shaders,
  interactions,
  diagnostics,
  studioV2;

  String get id => name;

  String get label {
    switch (this) {
      case StudioSubsystemPipelineStage.coreEngine:
        return 'Core Engine';
      case StudioSubsystemPipelineStage.loaders:
        return 'Loaders';
      case StudioSubsystemPipelineStage.themes:
        return 'Themes';
      case StudioSubsystemPipelineStage.particles:
        return 'Particles';
      case StudioSubsystemPipelineStage.physics:
        return 'Physics';
      case StudioSubsystemPipelineStage.shaders:
        return 'Shaders';
      case StudioSubsystemPipelineStage.interactions:
        return 'Interactions';
      case StudioSubsystemPipelineStage.diagnostics:
        return 'Diagnostics';
      case StudioSubsystemPipelineStage.studioV2:
        return 'Studio v2';
    }
  }
}

/// Verification test category types in Phase 10.20.
enum IntegrationTestType {
  unit,
  widget,
  integration,
  rendering,
  state,
  export,
  configuration,
  performance,
  regression;

  String get id => name;

  String get label => '${name[0].toUpperCase()}${name.substring(1)} Tests';
}

/// Verification status for a pipeline stage or test category.
enum TestExecutionStatus {
  passed,
  warning,
  failed;

  String get id => name;

  String get label => name.toUpperCase();

  String get symbol => this == TestExecutionStatus.passed
      ? '✓'
      : (this == TestExecutionStatus.warning ? '⚠' : '✗');
}

/// Verification result for a single subsystem stage.
class SubsystemStageVerification {
  final StudioSubsystemPipelineStage stage;
  final TestExecutionStatus status;
  final int testsExecuted;
  final double executionTimeMs;
  final String verificationDetails;

  const SubsystemStageVerification({
    required this.stage,
    this.status = TestExecutionStatus.passed,
    this.testsExecuted = 0,
    this.executionTimeMs = 0.0,
    required this.verificationDetails,
  });

  Map<String, dynamic> toJson() => {
        'stage': stage.id,
        'status': status.id,
        'tests_executed': testsExecuted,
        'execution_time_ms': executionTimeMs,
        'verification_details': verificationDetails,
      };

  factory SubsystemStageVerification.fromJson(Map<String, dynamic> json) {
    return SubsystemStageVerification(
      stage: StudioSubsystemPipelineStage.values.firstWhere(
        (s) => s.id == json['stage'] || s.name == json['stage'],
        orElse: () => StudioSubsystemPipelineStage.coreEngine,
      ),
      status: TestExecutionStatus.values.firstWhere(
        (s) => s.id == json['status'] || s.name == json['status'],
        orElse: () => TestExecutionStatus.passed,
      ),
      testsExecuted: json['tests_executed'] as int? ?? 0,
      executionTimeMs: (json['execution_time_ms'] as num?)?.toDouble() ?? 0.0,
      verificationDetails: json['verification_details'] as String? ?? '',
    );
  }
}

/// Comprehensive Milestone 10 Final Integration & Regression Test Report.
class StudioFinalIntegrationReport {
  final String reportId;
  final bool overallSuccess;
  final int totalTestsRun;
  final int totalTestsPassed;
  final int totalTestsFailed;
  final List<SubsystemStageVerification> stageVerifications;
  final Map<IntegrationTestType, int> testTypeBreakdown;
  final DateTime completedAt;

  const StudioFinalIntegrationReport({
    required this.reportId,
    required this.overallSuccess,
    required this.totalTestsRun,
    required this.totalTestsPassed,
    required this.totalTestsFailed,
    required this.stageVerifications,
    required this.testTypeBreakdown,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'report_id': reportId,
        'overall_success': overallSuccess,
        'total_tests_run': totalTestsRun,
        'total_tests_passed': totalTestsPassed,
        'total_tests_failed': totalTestsFailed,
        'stage_verifications':
            stageVerifications.map((s) => s.toJson()).toList(),
        'test_type_breakdown':
            testTypeBreakdown.map((k, v) => MapEntry(k.id, v)),
        'completed_at': completedAt.toIso8601String(),
      };

  factory StudioFinalIntegrationReport.fromJson(Map<String, dynamic> json) {
    final breakdown = <IntegrationTestType, int>{};
    if (json['test_type_breakdown'] != null) {
      final raw = json['test_type_breakdown'] as Map<String, dynamic>;
      for (final e in raw.entries) {
        final t = IntegrationTestType.values.firstWhere(
          (type) => type.id == e.key || type.name == e.key,
          orElse: () => IntegrationTestType.unit,
        );
        breakdown[t] = e.value as int;
      }
    }

    return StudioFinalIntegrationReport(
      reportId: json['report_id'] as String? ?? 'int_default',
      overallSuccess: json['overall_success'] as bool? ?? true,
      totalTestsRun: json['total_tests_run'] as int? ?? 0,
      totalTestsPassed: json['total_tests_passed'] as int? ?? 0,
      totalTestsFailed: json['total_tests_failed'] as int? ?? 0,
      stageVerifications: (json['stage_verifications'] as List<dynamic>?)
              ?.map((s) => SubsystemStageVerification.fromJson(
                  s as Map<String, dynamic>))
              .toList() ??
          const [],
      testTypeBreakdown: breakdown,
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }
}
