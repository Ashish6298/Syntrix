/// Domain models and data aggregations for Phase 9.12: Enterprise Observability & Operational Dashboard Foundation.
library;

/// High-level operational health status indicator.
enum OperationalHealthStatus {
  healthy,
  degraded,
  unhealthy,
  critical,
  unknown;

  String get label => name.toUpperCase();

  bool get isHealthy => this == OperationalHealthStatus.healthy;
}

/// Package health metrics and status snapshot.
class PackageHealthMetric {
  final String packageName;
  final String currentVersion;
  final OperationalHealthStatus status;
  final int totalDependencies;
  final int policyViolations;
  final int securityFindings;
  final double aiQualityScore;
  final DateTime lastInspectedAt;

  const PackageHealthMetric({
    required this.packageName,
    required this.currentVersion,
    required this.status,
    this.totalDependencies = 0,
    this.policyViolations = 0,
    this.securityFindings = 0,
    this.aiQualityScore = 100.0,
    required this.lastInspectedAt,
  });

  Map<String, dynamic> toJson() => {
        'package_name': packageName,
        'current_version': currentVersion,
        'status': status.name,
        'total_dependencies': totalDependencies,
        'policy_violations': policyViolations,
        'security_findings': securityFindings,
        'ai_quality_score': aiQualityScore,
        'last_inspected_at': lastInspectedAt.toIso8601String(),
      };

  factory PackageHealthMetric.fromJson(Map<String, dynamic> json) {
    return PackageHealthMetric(
      packageName: json['package_name'] as String? ?? 'unknown',
      currentVersion: json['current_version'] as String? ?? '0.0.0',
      status: OperationalHealthStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OperationalHealthStatus.unknown,
      ),
      totalDependencies: json['total_dependencies'] as int? ?? 0,
      policyViolations: json['policy_violations'] as int? ?? 0,
      securityFindings: json['security_findings'] as int? ?? 0,
      aiQualityScore: (json['ai_quality_score'] as num?)?.toDouble() ?? 100.0,
      lastInspectedAt: DateTime.parse(json['last_inspected_at'] as String),
    );
  }
}

/// Aggregated metrics for AI code reviews across projects.
class AiReviewTelemetry {
  final int totalReviewsExecuted;
  final double averageQualityScore;
  final int totalFindingsReported;
  final int securityRelatedFindings;
  final int approvedReleasesCount;
  final int blockedReleasesCount;

  const AiReviewTelemetry({
    this.totalReviewsExecuted = 0,
    this.averageQualityScore = 100.0,
    this.totalFindingsReported = 0,
    this.securityRelatedFindings = 0,
    this.approvedReleasesCount = 0,
    this.blockedReleasesCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'total_reviews_executed': totalReviewsExecuted,
        'average_quality_score': averageQualityScore,
        'total_findings_reported': totalFindingsReported,
        'security_related_findings': securityRelatedFindings,
        'approved_releases_count': approvedReleasesCount,
        'blocked_releases_count': blockedReleasesCount,
      };

  factory AiReviewTelemetry.fromJson(Map<String, dynamic> json) {
    return AiReviewTelemetry(
      totalReviewsExecuted: json['total_reviews_executed'] as int? ?? 0,
      averageQualityScore:
          (json['average_quality_score'] as num?)?.toDouble() ?? 100.0,
      totalFindingsReported: json['total_findings_reported'] as int? ?? 0,
      securityRelatedFindings: json['security_related_findings'] as int? ?? 0,
      approvedReleasesCount: json['approved_releases_count'] as int? ?? 0,
      blockedReleasesCount: json['blocked_releases_count'] as int? ?? 0,
    );
  }
}

/// Operational summary of active workers and compute nodes.
class WorkerPoolTelemetry {
  final int totalRegisteredWorkers;
  final int healthyWorkers;
  final int busyWorkers;
  final int degradedOrOfflineWorkers;
  final int activeTasksCount;
  final int completedTasksCount;
  final int failedTasksCount;

  const WorkerPoolTelemetry({
    this.totalRegisteredWorkers = 0,
    this.healthyWorkers = 0,
    this.busyWorkers = 0,
    this.degradedOrOfflineWorkers = 0,
    this.activeTasksCount = 0,
    this.completedTasksCount = 0,
    this.failedTasksCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'total_registered_workers': totalRegisteredWorkers,
        'healthy_workers': healthyWorkers,
        'busy_workers': busyWorkers,
        'degraded_or_offline_workers': degradedOrOfflineWorkers,
        'active_tasks_count': activeTasksCount,
        'completed_tasks_count': completedTasksCount,
        'failed_tasks_count': failedTasksCount,
      };

  factory WorkerPoolTelemetry.fromJson(Map<String, dynamic> json) {
    return WorkerPoolTelemetry(
      totalRegisteredWorkers: json['total_registered_workers'] as int? ?? 0,
      healthyWorkers: json['healthy_workers'] as int? ?? 0,
      busyWorkers: json['busy_workers'] as int? ?? 0,
      degradedOrOfflineWorkers:
          json['degraded_or_offline_workers'] as int? ?? 0,
      activeTasksCount: json['active_tasks_count'] as int? ?? 0,
      completedTasksCount: json['completed_tasks_count'] as int? ?? 0,
      failedTasksCount: json['failed_tasks_count'] as int? ?? 0,
    );
  }
}

/// Comprehensive Unified Operational Dashboard Snapshot.
class EnterpriseDashboardSnapshot {
  final String organizationId;
  final OperationalHealthStatus overallSystemHealth;
  final DateTime generatedAt;

  // Domain metrics
  final List<PackageHealthMetric> packageHealth;
  final AiReviewTelemetry aiReviewStats;
  final WorkerPoolTelemetry workerStats;

  // Release & workflow telemetry
  final int totalWorkflowsExecuted;
  final int successfulWorkflows;
  final int failedWorkflows;
  final int gateBlockedWorkflows;

  // Security & governance telemetry
  final int activePolicyViolations;
  final int blockedDependencyCount;
  final int totalAuditEventsRecorded;
  final int failedOperationsRecorded;

  // Recent operational activity
  final List<Map<String, dynamic>> recentFailedOperations;
  final List<Map<String, dynamic>> recentAuditActivity;

  const EnterpriseDashboardSnapshot({
    required this.organizationId,
    required this.overallSystemHealth,
    required this.generatedAt,
    this.packageHealth = const [],
    this.aiReviewStats = const AiReviewTelemetry(),
    this.workerStats = const WorkerPoolTelemetry(),
    this.totalWorkflowsExecuted = 0,
    this.successfulWorkflows = 0,
    this.failedWorkflows = 0,
    this.gateBlockedWorkflows = 0,
    this.activePolicyViolations = 0,
    this.blockedDependencyCount = 0,
    this.totalAuditEventsRecorded = 0,
    this.failedOperationsRecorded = 0,
    this.recentFailedOperations = const [],
    this.recentAuditActivity = const [],
  });

  Map<String, dynamic> toJson() => {
        'organization_id': organizationId,
        'overall_system_health': overallSystemHealth.name,
        'generated_at': generatedAt.toIso8601String(),
        'package_health': packageHealth.map((p) => p.toJson()).toList(),
        'ai_review_stats': aiReviewStats.toJson(),
        'worker_stats': workerStats.toJson(),
        'total_workflows_executed': totalWorkflowsExecuted,
        'successful_workflows': successfulWorkflows,
        'failed_workflows': failedWorkflows,
        'gate_blocked_workflows': gateBlockedWorkflows,
        'active_policy_violations': activePolicyViolations,
        'blocked_dependency_count': blockedDependencyCount,
        'total_audit_events_recorded': totalAuditEventsRecorded,
        'failed_operations_recorded': failedOperationsRecorded,
        'recent_failed_operations': recentFailedOperations,
        'recent_audit_activity': recentAuditActivity,
      };

  factory EnterpriseDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    return EnterpriseDashboardSnapshot(
      organizationId: json['organization_id'] as String? ?? 'default_org',
      overallSystemHealth: OperationalHealthStatus.values.firstWhere(
        (e) => e.name == json['overall_system_health'],
        orElse: () => OperationalHealthStatus.unknown,
      ),
      generatedAt: DateTime.parse(json['generated_at'] as String),
      packageHealth: (json['package_health'] as List<dynamic>?)
              ?.map((p) =>
                  PackageHealthMetric.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      aiReviewStats: json['ai_review_stats'] != null
          ? AiReviewTelemetry.fromJson(
              json['ai_review_stats'] as Map<String, dynamic>)
          : const AiReviewTelemetry(),
      workerStats: json['worker_stats'] != null
          ? WorkerPoolTelemetry.fromJson(
              json['worker_stats'] as Map<String, dynamic>)
          : const WorkerPoolTelemetry(),
      totalWorkflowsExecuted: json['total_workflows_executed'] as int? ?? 0,
      successfulWorkflows: json['successful_workflows'] as int? ?? 0,
      failedWorkflows: json['failed_workflows'] as int? ?? 0,
      gateBlockedWorkflows: json['gate_blocked_workflows'] as int? ?? 0,
      activePolicyViolations: json['active_policy_violations'] as int? ?? 0,
      blockedDependencyCount: json['blocked_dependency_count'] as int? ?? 0,
      totalAuditEventsRecorded:
          json['total_audit_events_recorded'] as int? ?? 0,
      failedOperationsRecorded: json['failed_operations_recorded'] as int? ?? 0,
      recentFailedOperations:
          (json['recent_failed_operations'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              const [],
      recentAuditActivity: (json['recent_audit_activity'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
    );
  }
}
