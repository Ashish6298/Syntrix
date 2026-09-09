/// Domain models for AI Engineering Workflow Planner (Phase 8.11).
library;

import 'package:syntrix/src/ai/review/code_review_models.dart';
import 'package:syntrix/src/ai/security/secret_redactor.dart';

/// Structured item distinguishing verified workspace facts from reasoned assumptions.
class GroundedItem {
  /// The statement or claim.
  final String text;

  /// Whether this statement is a verified fact (grounded in existing code/pubspec) or an unverified assumption.
  final bool isFact;

  /// Source evidence or reference (file path, symbol, or "Assumption: requires verification").
  final String evidence;

  GroundedItem({
    required String text,
    required this.isFact,
    required String evidence,
  })  : text = SecretRedactor.redact(text),
        evidence = SecretRedactor.redact(evidence);

  factory GroundedItem.fact(String text, String evidence) => GroundedItem(
        text: text,
        isFact: true,
        evidence: evidence,
      );

  factory GroundedItem.assumption(String text,
          [String evidence =
              'Inferred assumption; requires implementation verification']) =>
      GroundedItem(
        text: text,
        isFact: false,
        evidence: evidence,
      );

  factory GroundedItem.fromJson(Map<String, dynamic> json) => GroundedItem(
        text: json['text'] as String? ?? '',
        isFact: json['isFact'] as bool? ?? false,
        evidence: json['evidence'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'text': SecretRedactor.redact(text),
        'isFact': isFact,
        'evidence': SecretRedactor.redact(evidence),
      };
}

/// Detailed discrete step in the implementation plan.
class WorkflowImplementationStep {
  final int stepNumber;
  final String title;
  final String description;
  final String targetComponent;
  final List<String> estimatedFiles;
  final List<String> dependencies;

  WorkflowImplementationStep({
    required this.stepNumber,
    required String title,
    required String description,
    required String targetComponent,
    this.estimatedFiles = const [],
    this.dependencies = const [],
  })  : title = SecretRedactor.redact(title),
        description = SecretRedactor.redact(description),
        targetComponent = SecretRedactor.redact(targetComponent);

  factory WorkflowImplementationStep.fromJson(Map<String, dynamic> json) =>
      WorkflowImplementationStep(
        stepNumber: json['stepNumber'] as int? ?? 1,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        targetComponent: json['targetComponent'] as String? ?? 'core',
        estimatedFiles: (json['estimatedFiles'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        dependencies: (json['dependencies'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'stepNumber': stepNumber,
        'title': SecretRedactor.redact(title),
        'description': SecretRedactor.redact(description),
        'targetComponent': SecretRedactor.redact(targetComponent),
        'estimatedFiles': estimatedFiles,
        'dependencies': dependencies,
      };
}

/// Structured test strategy entry.
class WorkflowTestRequirement {
  final String testType; // 'unit', 'integration', 'e2e', 'regression'
  final String description;
  final String targetFile;

  WorkflowTestRequirement({
    required String testType,
    required String description,
    required String targetFile,
  })  : testType = SecretRedactor.redact(testType),
        description = SecretRedactor.redact(description),
        targetFile = SecretRedactor.redact(targetFile);

  factory WorkflowTestRequirement.fromJson(Map<String, dynamic> json) =>
      WorkflowTestRequirement(
        testType: json['testType'] as String? ?? 'unit',
        description: json['description'] as String? ?? '',
        targetFile: json['targetFile'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'testType': SecretRedactor.redact(testType),
        'description': SecretRedactor.redact(description),
        'targetFile': SecretRedactor.redact(targetFile),
      };
}

/// Request payload for generating an engineering implementation plan.
class WorkflowPlanRequest {
  /// The natural-language feature request or engineering task (e.g. "Add support for Debian packages").
  final String request;

  /// Target scope or package (optional).
  final String? targetPackage;

  /// Context token budget.
  final int tokenBudget;

  const WorkflowPlanRequest({
    required this.request,
    this.targetPackage,
    this.tokenBudget = 4000,
  });

  Map<String, dynamic> toJson() => {
        'request': SecretRedactor.redact(request),
        if (targetPackage != null) 'targetPackage': targetPackage,
        'tokenBudget': tokenBudget,
      };
}

/// Comprehensive structured implementation plan produced by Phase 8.11.
///
/// Contains all 9 pipeline stages:
/// 1. Requirement Analysis (Facts vs Assumptions)
/// 2. Affected Components
/// 3. Architecture Changes
/// 4. Implementation Steps
/// 5. Tests
/// 6. Security Checks (Security considerations)
/// 7. Documentation
/// 8. Verification (Regression checks & acceptance criteria)
/// 9. Next Phase Recommendation
class WorkflowPlanResult {
  final String objective;
  final String scope;

  /// Requirement analysis clearly partitioned into known facts and explicit assumptions.
  final List<GroundedItem> requirementAnalysis;

  /// Components and existing packages affected.
  final List<String> affectedComponents;

  /// Files likely created or modified.
  final List<String> affectedFiles;

  /// External and internal dependencies needed.
  final List<String> dependencies;

  /// Architectural and design modifications needed.
  final String architectureChanges;

  /// Ordered concrete implementation steps.
  final List<WorkflowImplementationStep> implementationSteps;

  /// Unit, integration, and regression test plan.
  final List<WorkflowTestRequirement> tests;

  /// Dedicated security checks and considerations.
  final List<String> securityChecks;

  /// Documentation updates needed.
  final List<String> documentationRequirements;

  /// Regression verification checks.
  final List<String> regressionChecks;

  /// Acceptance criteria that must be satisfied.
  final List<String> acceptanceCriteria;

  /// Recommended next phase or follow-up milestone.
  final String nextPhaseRecommendation;

  /// Confidence indication describing evidence sufficiency.
  final CodeReviewConfidence confidence;

  /// Duration of plan generation in milliseconds.
  final int durationMs;

  /// Timestamp of plan creation.
  final DateTime timestamp;

  /// Error message if generation failed or degraded.
  final String? errorMessage;

  /// Whether the plan succeeded.
  final bool isSuccess;

  WorkflowPlanResult({
    required String objective,
    required String scope,
    required this.requirementAnalysis,
    required this.affectedComponents,
    required this.affectedFiles,
    required this.dependencies,
    required String architectureChanges,
    required this.implementationSteps,
    required this.tests,
    required this.securityChecks,
    required this.documentationRequirements,
    required this.regressionChecks,
    required this.acceptanceCriteria,
    required String nextPhaseRecommendation,
    required this.confidence,
    required this.durationMs,
    required this.timestamp,
    this.errorMessage,
    this.isSuccess = true,
  })  : objective = SecretRedactor.redact(objective),
        scope = SecretRedactor.redact(scope),
        architectureChanges = SecretRedactor.redact(architectureChanges),
        nextPhaseRecommendation =
            SecretRedactor.redact(nextPhaseRecommendation);

  factory WorkflowPlanResult.failure({
    required String objective,
    required String errorMessage,
    int durationMs = 0,
    DateTime? timestamp,
  }) =>
      WorkflowPlanResult(
        objective: objective,
        scope: 'undefined',
        requirementAnalysis: const [],
        affectedComponents: const [],
        affectedFiles: const [],
        dependencies: const [],
        architectureChanges: '',
        implementationSteps: const [],
        tests: const [],
        securityChecks: const [],
        documentationRequirements: const [],
        regressionChecks: const [],
        acceptanceCriteria: const [],
        nextPhaseRecommendation: 'Resolve error and regenerate plan.',
        confidence: CodeReviewConfidence.low,
        durationMs: durationMs,
        timestamp: timestamp ?? DateTime.now(),
        isSuccess: false,
        errorMessage: SecretRedactor.redact(errorMessage),
      );

  factory WorkflowPlanResult.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(dynamic raw, T Function(dynamic) mapper) {
      if (raw is List) {
        return raw.map(mapper).toList();
      }
      return const [];
    }

    final confStr = json['confidence'] as String? ?? 'high';
    final conf =
        CodeReviewConfidence.tryParse(confStr) ?? CodeReviewConfidence.high;

    return WorkflowPlanResult(
      objective: json['objective'] as String? ?? 'Engineering Plan',
      scope: json['scope'] as String? ?? 'workspace',
      requirementAnalysis: parseList(json['requirementAnalysis'],
          (e) => GroundedItem.fromJson(e as Map<String, dynamic>)),
      affectedComponents:
          parseList(json['affectedComponents'], (e) => e.toString()),
      affectedFiles: parseList(json['affectedFiles'], (e) => e.toString()),
      dependencies: parseList(json['dependencies'], (e) => e.toString()),
      architectureChanges: json['architectureChanges'] as String? ?? '',
      implementationSteps: parseList(
          json['implementationSteps'],
          (e) =>
              WorkflowImplementationStep.fromJson(e as Map<String, dynamic>)),
      tests: parseList(json['tests'],
          (e) => WorkflowTestRequirement.fromJson(e as Map<String, dynamic>)),
      securityChecks: parseList(json['securityChecks'], (e) => e.toString()),
      documentationRequirements:
          parseList(json['documentationRequirements'], (e) => e.toString()),
      regressionChecks:
          parseList(json['regressionChecks'], (e) => e.toString()),
      acceptanceCriteria:
          parseList(json['acceptanceCriteria'], (e) => e.toString()),
      nextPhaseRecommendation: json['nextPhaseRecommendation'] as String? ?? '',
      confidence: conf,
      durationMs: json['durationMs'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      errorMessage: json['errorMessage'] as String?,
      isSuccess: json['isSuccess'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'objective': SecretRedactor.redact(objective),
        'scope': SecretRedactor.redact(scope),
        'requirementAnalysis':
            requirementAnalysis.map((e) => e.toJson()).toList(),
        'affectedComponents': affectedComponents,
        'affectedFiles': affectedFiles,
        'dependencies': dependencies,
        'architectureChanges': SecretRedactor.redact(architectureChanges),
        'implementationSteps':
            implementationSteps.map((e) => e.toJson()).toList(),
        'tests': tests.map((e) => e.toJson()).toList(),
        'securityChecks': securityChecks.map(SecretRedactor.redact).toList(),
        'documentationRequirements':
            documentationRequirements.map(SecretRedactor.redact).toList(),
        'regressionChecks':
            regressionChecks.map(SecretRedactor.redact).toList(),
        'acceptanceCriteria':
            acceptanceCriteria.map(SecretRedactor.redact).toList(),
        'nextPhaseRecommendation':
            SecretRedactor.redact(nextPhaseRecommendation),
        'confidence': confidence.name,
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
        'isSuccess': isSuccess,
        if (errorMessage != null)
          'errorMessage': SecretRedactor.redact(errorMessage!),
      };
}
