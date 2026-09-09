/// Domain models for Phase 9.11: Enterprise Workflow Orchestration.
library;

import 'package:syntrix/src/enterprise/identity/enterprise_identity_models.dart';

/// Status of an individual enterprise workflow stage.
enum EnterpriseWorkflowStageStatus {
  pending,
  running,
  passed,
  failed,
  skipped,
  waitingApproval,
  cancelled;

  String get label => name.toUpperCase();

  bool get isPassed => this == EnterpriseWorkflowStageStatus.passed;
  bool get isFailed => this == EnterpriseWorkflowStageStatus.failed;
  bool get isTerminal =>
      this == EnterpriseWorkflowStageStatus.passed ||
      this == EnterpriseWorkflowStageStatus.failed ||
      this == EnterpriseWorkflowStageStatus.skipped ||
      this == EnterpriseWorkflowStageStatus.cancelled;
}

/// Overall enterprise workflow execution status.
enum EnterpriseWorkflowExecutionStatus {
  planned,
  running,
  completed,
  failed,
  cancelled,
  blockedByGate;

  String get label => name.toUpperCase();

  bool get isSuccess => this == EnterpriseWorkflowExecutionStatus.completed;
  bool get isTerminal =>
      this == EnterpriseWorkflowExecutionStatus.completed ||
      this == EnterpriseWorkflowExecutionStatus.failed ||
      this == EnterpriseWorkflowExecutionStatus.cancelled ||
      this == EnterpriseWorkflowExecutionStatus.blockedByGate;
}

/// Type of workflow stage.
enum WorkflowStageType {
  projectDiscovery,
  contextAssembly,
  aiCodeReview,
  securityAudit,
  dependencyGovernance,
  versionPlanning,
  changelogGeneration,
  artifactBuild,
  manifestGeneration,
  releaseVerification,
  humanApproval,
  gitRelease,
  packagePublish,
  auditLogging,
  customStage;

  String get id => name;

  String get displayName {
    switch (this) {
      case WorkflowStageType.projectDiscovery:
        return 'Project Discovery';
      case WorkflowStageType.contextAssembly:
        return 'Context Assembly';
      case WorkflowStageType.aiCodeReview:
        return 'AI Code Review';
      case WorkflowStageType.securityAudit:
        return 'Security Audit';
      case WorkflowStageType.dependencyGovernance:
        return 'Dependency Governance';
      case WorkflowStageType.versionPlanning:
        return 'Version Planning';
      case WorkflowStageType.changelogGeneration:
        return 'Changelog Generation';
      case WorkflowStageType.artifactBuild:
        return 'Artifact Build';
      case WorkflowStageType.manifestGeneration:
        return 'Manifest Generation';
      case WorkflowStageType.releaseVerification:
        return 'Release Verification';
      case WorkflowStageType.humanApproval:
        return 'Human Approval Gate';
      case WorkflowStageType.gitRelease:
        return 'Git Release & Tagging';
      case WorkflowStageType.packagePublish:
        return 'Package Publishing';
      case WorkflowStageType.auditLogging:
        return 'Enterprise Audit Logging';
      case WorkflowStageType.customStage:
        return 'Custom Stage';
    }
  }

  static WorkflowStageType fromString(String? val) {
    if (val == null) return WorkflowStageType.customStage;
    return WorkflowStageType.values.firstWhere(
      (s) =>
          s.name.toLowerCase() == val.toLowerCase() ||
          s.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => WorkflowStageType.customStage,
    );
  }
}

/// Definition of a single stage in an orchestration workflow plan.
class OrchestrationStageDefinition {
  final String stageId;
  final WorkflowStageType stageType;
  final String name;
  final List<String> dependsOnStageIds;
  final bool isMandatoryGate;
  final int maxRetries;
  final Duration timeout;
  final Map<String, dynamic> stageConfig;

  const OrchestrationStageDefinition({
    required this.stageId,
    required this.stageType,
    required this.name,
    this.dependsOnStageIds = const [],
    this.isMandatoryGate = true,
    this.maxRetries = 0,
    this.timeout = const Duration(minutes: 5),
    this.stageConfig = const {},
  });

  Map<String, dynamic> toJson() => {
        'stage_id': stageId,
        'stage_type': stageType.id,
        'name': name,
        'depends_on_stage_ids': dependsOnStageIds,
        'is_mandatory_gate': isMandatoryGate,
        'max_retries': maxRetries,
        'timeout_seconds': timeout.inSeconds,
        'stage_config': stageConfig,
      };

  factory OrchestrationStageDefinition.fromJson(Map<String, dynamic> json) {
    return OrchestrationStageDefinition(
      stageId: json['stage_id'] as String? ?? 'stage_unknown',
      stageType: WorkflowStageType.fromString(json['stage_type'] as String?),
      name: json['name'] as String? ?? 'Unnamed Stage',
      dependsOnStageIds: (json['depends_on_stage_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isMandatoryGate: json['is_mandatory_gate'] as bool? ?? true,
      maxRetries: json['max_retries'] as int? ?? 0,
      timeout: Duration(seconds: json['timeout_seconds'] as int? ?? 300),
      stageConfig: (json['stage_config'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Execution outcome of an individual stage.
class OrchestrationStageResult {
  final String stageId;
  final WorkflowStageType stageType;
  final String name;
  final EnterpriseWorkflowStageStatus status;
  final Map<String, dynamic> outputData;
  final String? errorMessage;
  final int retryCount;
  final int durationMs;
  final DateTime startedAt;
  final DateTime completedAt;

  const OrchestrationStageResult({
    required this.stageId,
    required this.stageType,
    required this.name,
    required this.status,
    this.outputData = const {},
    this.errorMessage,
    this.retryCount = 0,
    required this.durationMs,
    required this.startedAt,
    required this.completedAt,
  });

  bool get isPassed => status == EnterpriseWorkflowStageStatus.passed;

  Map<String, dynamic> toJson() => {
        'stage_id': stageId,
        'stage_type': stageType.id,
        'name': name,
        'status': status.name,
        'output_data': outputData,
        'error_message': errorMessage,
        'retry_count': retryCount,
        'duration_ms': durationMs,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt.toIso8601String(),
      };

  factory OrchestrationStageResult.fromJson(Map<String, dynamic> json) {
    return OrchestrationStageResult(
      stageId: json['stage_id'] as String? ?? '',
      stageType: WorkflowStageType.fromString(json['stage_type'] as String?),
      name: json['name'] as String? ?? '',
      status: EnterpriseWorkflowStageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => EnterpriseWorkflowStageStatus.failed,
      ),
      outputData: (json['output_data'] as Map<String, dynamic>?) ?? const {},
      errorMessage: json['error_message'] as String?,
      retryCount: json['retry_count'] as int? ?? 0,
      durationMs: json['duration_ms'] as int? ?? 0,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }
}

/// Full Enterprise Workflow Orchestration Plan.
class EnterpriseWorkflowPlan {
  final String workflowId;
  final String name;
  final String targetPackageName;
  final String targetVersion;
  final EnterpriseIdentity initiator;
  final List<OrchestrationStageDefinition> stages;
  final DateTime createdAt;

  const EnterpriseWorkflowPlan({
    required this.workflowId,
    required this.name,
    required this.targetPackageName,
    required this.targetVersion,
    required this.initiator,
    required this.stages,
    required this.createdAt,
  });

  /// Factory creating the standard 14-stage Enterprise End-to-End Release Pipeline.
  factory EnterpriseWorkflowPlan.standardEnterprisePipeline({
    required String targetPackageName,
    required String targetVersion,
    required EnterpriseIdentity initiator,
  }) {
    final now = DateTime.now();
    return EnterpriseWorkflowPlan(
      workflowId: 'wf_rel_${now.millisecondsSinceEpoch}_$targetPackageName',
      name: 'Standard Enterprise Release & Publishing Orchestration Pipeline',
      targetPackageName: targetPackageName,
      targetVersion: targetVersion,
      initiator: initiator,
      createdAt: now,
      stages: const [
        OrchestrationStageDefinition(
          stageId: 'stg_01_discovery',
          stageType: WorkflowStageType.projectDiscovery,
          name: 'Project Discovery',
        ),
        OrchestrationStageDefinition(
          stageId: 'stg_02_context',
          stageType: WorkflowStageType.contextAssembly,
          name: 'Context Assembly',
          dependsOnStageIds: ['stg_01_discovery'],
        ),
        OrchestrationStageDefinition(
          stageId: 'stg_03_ai_review',
          stageType: WorkflowStageType.aiCodeReview,
          name: 'AI Code Review',
          dependsOnStageIds: ['stg_02_context'],
        ),
        OrchestrationStageDefinition(
          stageId: 'stg_04_security_audit',
          stageType: WorkflowStageType.securityAudit,
          name: 'Security Audit',
          dependsOnStageIds: ['stg_02_context'],
        ),
        OrchestrationStageDefinition(
          stageId: 'stg_05_dependency_gov',
          stageType: WorkflowStageType.dependencyGovernance,
          name: 'Dependency Governance',
          dependsOnStageIds: ['stg_01_discovery'],
        ),
        OrchestrationStageDefinition(
          stageId: 'stg_06_version_planning',
          stageType: WorkflowStageType.versionPlanning,
          name: 'Version Planning',
          dependsOnStageIds: ['stg_03_ai_review', 'stg_04_security_audit'],
        ),
        OrchestrationStageDefinition(
          stageId: 'stg_07_changelog',
          stageType: WorkflowStageType.changelogGeneration,
          name: 'Changelog Generation',
          dependsOnStageIds: ['stg_06_version_planning'],
        ),
        OrchestrationStageDefinition(
          stageId: 'stg_08_artifact_build',
          stageType: WorkflowStageType.artifactBuild,
          name: 'Artifact Build',
          dependsOnStageIds: ['stg_07_changelog'],
        ),
        OrchestrationStageDefinition(
          stageId: 'stg_09_manifest',
          stageType: WorkflowStageType.manifestGeneration,
          name: 'Manifest Generation',
          dependsOnStageIds: ['stg_08_artifact_build'],
        ),
        OrchestrationStageDefinition(
          stageId: 'stg_10_release_verification',
          stageType: WorkflowStageType.releaseVerification,
          name: 'Release Verification',
          dependsOnStageIds: ['stg_09_manifest'],
        ),
        OrchestrationStageDefinition(
          stageId: 'stg_11_approval',
          stageType: WorkflowStageType.humanApproval,
          name: 'Reviewer & Release Manager Approval Gate',
          dependsOnStageIds: ['stg_10_release_verification'],
        ),
        OrchestrationStageDefinition(
          stageId: 'stg_12_git_release',
          stageType: WorkflowStageType.gitRelease,
          name: 'Git Release & Tagging',
          dependsOnStageIds: ['stg_11_approval'],
        ),
        OrchestrationStageDefinition(
          stageId: 'stg_13_publish',
          stageType: WorkflowStageType.packagePublish,
          name: 'Package Publishing',
          dependsOnStageIds: ['stg_12_git_release'],
        ),
        OrchestrationStageDefinition(
          stageId: 'stg_14_audit',
          stageType: WorkflowStageType.auditLogging,
          name: 'Enterprise Audit Trail Recording',
          dependsOnStageIds: ['stg_13_publish'],
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'workflow_id': workflowId,
        'name': name,
        'target_package_name': targetPackageName,
        'target_version': targetVersion,
        'initiator': initiator.toJson(),
        'stages': stages.map((s) => s.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
      };

  factory EnterpriseWorkflowPlan.fromJson(Map<String, dynamic> json) {
    return EnterpriseWorkflowPlan(
      workflowId: json['workflow_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Workflow Plan',
      targetPackageName: json['target_package_name'] as String? ?? 'unknown',
      targetVersion: json['target_version'] as String? ?? '0.0.0',
      initiator: EnterpriseIdentity.fromJson(
          json['initiator'] as Map<String, dynamic>),
      stages: (json['stages'] as List<dynamic>?)
              ?.map((s) => OrchestrationStageDefinition.fromJson(
                  s as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Comprehensive Execution Outcome of an Orchestrated Enterprise Workflow.
class EnterpriseWorkflowExecutionResult {
  final String workflowId;
  final String name;
  final String targetPackageName;
  final String targetVersion;
  final EnterpriseWorkflowExecutionStatus status;
  final List<OrchestrationStageResult> stageResults;
  final int totalStages;
  final int passedStages;
  final int failedStages;
  final int skippedStages;
  final String? blockedStageId;
  final String summary;
  final int durationMs;
  final DateTime startedAt;
  final DateTime completedAt;

  const EnterpriseWorkflowExecutionResult({
    required this.workflowId,
    required this.name,
    required this.targetPackageName,
    required this.targetVersion,
    required this.status,
    required this.stageResults,
    required this.totalStages,
    required this.passedStages,
    required this.failedStages,
    required this.skippedStages,
    this.blockedStageId,
    required this.summary,
    required this.durationMs,
    required this.startedAt,
    required this.completedAt,
  });

  bool get isSuccess => status == EnterpriseWorkflowExecutionStatus.completed;

  Map<String, dynamic> toJson() => {
        'workflow_id': workflowId,
        'name': name,
        'target_package_name': targetPackageName,
        'target_version': targetVersion,
        'status': status.name,
        'stage_results': stageResults.map((s) => s.toJson()).toList(),
        'total_stages': totalStages,
        'passed_stages': passedStages,
        'failed_stages': failedStages,
        'skipped_stages': skippedStages,
        'blocked_stage_id': blockedStageId,
        'summary': summary,
        'duration_ms': durationMs,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt.toIso8601String(),
      };

  factory EnterpriseWorkflowExecutionResult.fromJson(
      Map<String, dynamic> json) {
    return EnterpriseWorkflowExecutionResult(
      workflowId: json['workflow_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      targetPackageName: json['target_package_name'] as String? ?? 'unknown',
      targetVersion: json['target_version'] as String? ?? '0.0.0',
      status: EnterpriseWorkflowExecutionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => EnterpriseWorkflowExecutionStatus.failed,
      ),
      stageResults: (json['stage_results'] as List<dynamic>?)
              ?.map((s) =>
                  OrchestrationStageResult.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      totalStages: json['total_stages'] as int? ?? 0,
      passedStages: json['passed_stages'] as int? ?? 0,
      failedStages: json['failed_stages'] as int? ?? 0,
      skippedStages: json['skipped_stages'] as int? ?? 0,
      blockedStageId: json['blocked_stage_id'] as String?,
      summary: json['summary'] as String? ?? '',
      durationMs: json['duration_ms'] as int? ?? 0,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }
}
