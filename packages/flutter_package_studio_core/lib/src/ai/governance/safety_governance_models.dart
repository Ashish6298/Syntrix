/// Domain models for AI Safety, Governance & Verification (Phase 8.15).
library;

import 'package:flutter_package_studio_core/src/ai/security/secret_redactor.dart';

/// Categories of safety, governance, and verification checks.
enum SafetyVerificationCategory {
  /// Secret leakage, credential exposure, prompt injection, and sensitive file protection.
  security,

  /// Provider timeout handling, invalid responses, partial failures, and graceful degradation.
  reliability,

  /// Stable non-AI processing, deterministic reports, and idempotent results.
  determinism,

  /// Release gate bypass prevention, file modification restrictions, command sandboxing.
  safety,

  /// Unit, integration, CLI, mock, and regression test suite validation.
  testing,
}

/// Status of an individual verification gate check.
enum VerificationGateStatus {
  /// Verification gate passed completely with 0 violations.
  passed,

  /// Verification gate failed due to a critical safety, security, or reliability defect.
  failed,

  /// Non-blocking warning or informational observation.
  warning,
}

/// An individual safety or governance check finding.
class SafetyCheckItem {
  /// Unique check identifier (e.g. "SEC_001_SECRET_LEAKAGE").
  final String id;

  /// Human-readable title of the safety check.
  final String title;

  /// Classification category.
  final SafetyVerificationCategory category;

  /// Gate evaluation status.
  final VerificationGateStatus status;

  /// Concise description of the check outcome.
  final String description;

  /// Remediation or mitigation if failed/warning.
  final String? remediation;

  const SafetyCheckItem({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.description,
    this.remediation,
  });

  factory SafetyCheckItem.fromJson(Map<String, dynamic> json) => SafetyCheckItem(
        id: json['id'] as String? ?? 'SEC_UNKNOWN',
        title: json['title'] as String? ?? 'Unknown Check',
        category: SafetyVerificationCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => SafetyVerificationCategory.security,
        ),
        status: VerificationGateStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => VerificationGateStatus.failed,
        ),
        description: json['description'] as String? ?? '',
        remediation: json['remediation'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'status': status.name,
        'description': SecretRedactor.redact(description),
        if (remediation != null) 'remediation': SecretRedactor.redact(remediation!),
      };
}

/// Comprehensive Milestone 8 safety, governance, and verification audit result.
class SafetyGovernanceResult {
  /// Target project root directory evaluated.
  final String projectRoot;

  /// Whether all verification gates passed without blockers.
  final bool allGatesPassed;

  /// Whether existing deterministic functionality was preserved without regression.
  final bool existingFunctionalityPreserved;

  /// Security verification status (PASS/FAIL).
  final bool securityVerificationPassed;

  /// AI safety verification status (PASS/FAIL).
  final bool aiSafetyVerificationPassed;

  /// List of unresolved blocker messages (empty if none).
  final List<String> unresolvedBlockers;

  /// Whether the codebase is ready for Milestone 9.
  final bool readyForMilestone9;

  /// Detailed list of evaluated safety check items across all categories.
  final List<SafetyCheckItem> checks;

  /// Executive summary of the safety and governance audit.
  final String summary;

  /// Execution duration in milliseconds.
  final int durationMs;

  /// Timestamp of audit execution.
  final DateTime timestamp;

  const SafetyGovernanceResult({
    required this.projectRoot,
    required this.allGatesPassed,
    required this.existingFunctionalityPreserved,
    required this.securityVerificationPassed,
    required this.aiSafetyVerificationPassed,
    required this.unresolvedBlockers,
    required this.readyForMilestone9,
    required this.checks,
    required this.summary,
    required this.durationMs,
    required this.timestamp,
  });

  factory SafetyGovernanceResult.fromJson(Map<String, dynamic> json) {
    final rawChecks = json['checks'] as List<dynamic>? ?? const [];
    final rawBlockers = json['unresolvedBlockers'] as List<dynamic>? ?? const [];

    return SafetyGovernanceResult(
      projectRoot: json['projectRoot'] as String? ?? '.',
      allGatesPassed: json['allGatesPassed'] as bool? ?? false,
      existingFunctionalityPreserved:
          json['existingFunctionalityPreserved'] as bool? ?? false,
      securityVerificationPassed:
          json['securityVerificationPassed'] as bool? ?? false,
      aiSafetyVerificationPassed:
          json['aiSafetyVerificationPassed'] as bool? ?? false,
      unresolvedBlockers: rawBlockers.map((b) => b.toString()).toList(),
      readyForMilestone9: json['readyForMilestone9'] as bool? ?? false,
      checks: rawChecks
          .whereType<Map<String, dynamic>>()
          .map(SafetyCheckItem.fromJson)
          .toList(),
      summary: json['summary'] as String? ?? '',
      durationMs: json['durationMs'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'projectRoot': projectRoot,
        'allGatesPassed': allGatesPassed,
        'existingFunctionalityPreserved': existingFunctionalityPreserved,
        'securityVerificationPassed': securityVerificationPassed,
        'aiSafetyVerificationPassed': aiSafetyVerificationPassed,
        'unresolvedBlockers': unresolvedBlockers,
        'readyForMilestone9': readyForMilestone9,
        'checks': checks.map((c) => c.toJson()).toList(),
        'summary': SecretRedactor.redact(summary),
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };
}
