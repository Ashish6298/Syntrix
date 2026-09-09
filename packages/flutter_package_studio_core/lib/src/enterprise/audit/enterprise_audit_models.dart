/// Domain models for Phase 9.4: Enterprise Audit Logging.
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_package_studio_core/src/ai/security/secret_redactor.dart';

/// Standard Enterprise Audit Event Types.
enum AuditEventType {
  projectInspected,
  aiAnalysisExecuted,
  securityAuditExecuted,
  versionChanged,
  artifactGenerated,
  releaseVerified,
  gitTagCreated,
  packagePublished,
  rollbackExecuted,
  policyChanged,
  permissionChanged,
  customEvent;

  String get id => name;

  String get displayName {
    switch (this) {
      case AuditEventType.projectInspected:
        return 'Project Inspected';
      case AuditEventType.aiAnalysisExecuted:
        return 'AI Analysis Executed';
      case AuditEventType.securityAuditExecuted:
        return 'Security Audit Executed';
      case AuditEventType.versionChanged:
        return 'Version Changed';
      case AuditEventType.artifactGenerated:
        return 'Artifact Generated';
      case AuditEventType.releaseVerified:
        return 'Release Verified';
      case AuditEventType.gitTagCreated:
        return 'Git Tag Created';
      case AuditEventType.packagePublished:
        return 'Package Published';
      case AuditEventType.rollbackExecuted:
        return 'Rollback Executed';
      case AuditEventType.policyChanged:
        return 'Policy Changed';
      case AuditEventType.permissionChanged:
        return 'Permission Changed';
      case AuditEventType.customEvent:
        return 'Custom Enterprise Event';
    }
  }

  static AuditEventType fromString(String? val) {
    if (val == null) return AuditEventType.customEvent;
    return AuditEventType.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == val.toLowerCase() ||
          e.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => AuditEventType.customEvent,
    );
  }
}

/// Audit Outcome Status.
enum AuditEventOutcome {
  success,
  failure,
  blocked,
  warning;

  String get label => name.toUpperCase();
}

/// Security Classification of the Audit Record.
enum AuditSecurityClassification {
  unclassified,
  internal,
  confidential,
  restricted;

  String get label => name.toUpperCase();

  static AuditSecurityClassification fromString(String? val) {
    if (val == null) return AuditSecurityClassification.internal;
    return AuditSecurityClassification.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => AuditSecurityClassification.internal,
    );
  }
}

/// Actor who performed the operation.
class AuditActor {
  final String id;
  final String displayName;
  final String type;
  final String role;
  final String organizationId;

  const AuditActor({
    required this.id,
    required this.displayName,
    this.type = 'user',
    this.role = 'developer',
    this.organizationId = 'default_org',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'type': type,
        'role': role,
        'organization_id': organizationId,
      };

  factory AuditActor.fromJson(Map<String, dynamic> json) {
    return AuditActor(
      id: json['id'] as String? ?? 'anonymous',
      displayName: json['display_name'] as String? ?? 'Anonymous Principal',
      type: json['type'] as String? ?? 'anonymous',
      role: json['role'] as String? ?? 'readOnly',
      organizationId: json['organization_id'] as String? ?? 'none',
    );
  }
}

/// Tamper-Aware Enterprise Audit Record.
class EnterpriseAuditRecord {
  final String eventId;
  final String correlationId;
  final DateTime timestamp;
  final AuditEventType eventType;
  final AuditActor actor;
  final String operation;
  final String packageOrProject;
  final String? command;
  final AuditEventOutcome outcome;
  final String? relevantVersion;
  final AuditSecurityClassification securityClassification;
  final String? failureInformation;
  final String? policyDecision;
  final Map<String, dynamic> metadata;
  final String? previousRecordHash;
  final String recordHash;

  EnterpriseAuditRecord._({
    required this.eventId,
    required this.correlationId,
    required this.timestamp,
    required this.eventType,
    required this.actor,
    required this.operation,
    required this.packageOrProject,
    required this.command,
    required this.outcome,
    required this.relevantVersion,
    required this.securityClassification,
    required this.failureInformation,
    required this.policyDecision,
    required this.metadata,
    required this.previousRecordHash,
    required this.recordHash,
  });

  /// Factory constructing and hashing a sanitized tamper-aware record.
  factory EnterpriseAuditRecord.create({
    required String correlationId,
    required AuditEventType eventType,
    required AuditActor actor,
    required String operation,
    required String packageOrProject,
    String? command,
    required AuditEventOutcome outcome,
    String? relevantVersion,
    AuditSecurityClassification securityClassification =
        AuditSecurityClassification.internal,
    String? failureInformation,
    String? policyDecision,
    Map<String, dynamic> metadata = const {},
    String? previousRecordHash,
    DateTime? timestamp,
    String? eventId,
  }) {
    final now = timestamp ?? DateTime.now();
    final id =
        eventId ?? 'evt_${now.millisecondsSinceEpoch}_${now.microsecond}';

    // Strict non-negotiable security invariant: Secret and Credential Redaction on all fields
    final safeOperation = SecretRedactor.redact(operation);
    final safePackageOrProject = SecretRedactor.redact(packageOrProject);
    final safeCommand = command != null ? SecretRedactor.redact(command) : null;
    final safeFailure = failureInformation != null
        ? SecretRedactor.redact(failureInformation)
        : null;
    final safePolicy =
        policyDecision != null ? SecretRedactor.redact(policyDecision) : null;

    // Sanitize metadata
    final safeMetadata = <String, dynamic>{};
    for (final entry in metadata.entries) {
      if (entry.value is String) {
        safeMetadata[entry.key] = SecretRedactor.redact(entry.value as String);
      } else {
        safeMetadata[entry.key] = entry.value;
      }
    }

    // Compute tamper-evident SHA-256 hash
    final payloadForHash = jsonEncode({
      'event_id': id,
      'correlation_id': correlationId,
      'timestamp': now.toIso8601String(),
      'event_type': eventType.name,
      'actor_id': actor.id,
      'operation': safeOperation,
      'package_or_project': safePackageOrProject,
      'command': safeCommand,
      'outcome': outcome.name,
      'relevant_version': relevantVersion,
      'previous_record_hash': previousRecordHash ?? '',
    });

    final hash = sha256.convert(utf8.encode(payloadForHash)).toString();

    return EnterpriseAuditRecord._(
      eventId: id,
      correlationId: correlationId,
      timestamp: now,
      eventType: eventType,
      actor: actor,
      operation: safeOperation,
      packageOrProject: safePackageOrProject,
      command: safeCommand,
      outcome: outcome,
      relevantVersion: relevantVersion,
      securityClassification: securityClassification,
      failureInformation: safeFailure,
      policyDecision: safePolicy,
      metadata: safeMetadata,
      previousRecordHash: previousRecordHash,
      recordHash: hash,
    );
  }

  /// Verifies cryptographic integrity of this record against its payload and previous hash.
  bool verifyIntegrity() {
    final payloadForHash = jsonEncode({
      'event_id': eventId,
      'correlation_id': correlationId,
      'timestamp': timestamp.toIso8601String(),
      'event_type': eventType.name,
      'actor_id': actor.id,
      'operation': operation,
      'package_or_project': packageOrProject,
      'command': command,
      'outcome': outcome.name,
      'relevant_version': relevantVersion,
      'previous_record_hash': previousRecordHash ?? '',
    });

    final computedHash = sha256.convert(utf8.encode(payloadForHash)).toString();
    return computedHash == recordHash;
  }

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'correlation_id': correlationId,
        'timestamp': timestamp.toIso8601String(),
        'event_type': eventType.name,
        'actor': actor.toJson(),
        'operation': operation,
        'package_or_project': packageOrProject,
        'command': command,
        'outcome': outcome.name,
        'relevant_version': relevantVersion,
        'security_classification': securityClassification.name,
        'failure_information': failureInformation,
        'policy_decision': policyDecision,
        'metadata': metadata,
        'previous_record_hash': previousRecordHash,
        'record_hash': recordHash,
      };

  factory EnterpriseAuditRecord.fromJson(Map<String, dynamic> json) {
    return EnterpriseAuditRecord._(
      eventId: json['event_id'] as String? ?? '',
      correlationId: json['correlation_id'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      eventType: AuditEventType.fromString(json['event_type'] as String?),
      actor: AuditActor.fromJson(json['actor'] as Map<String, dynamic>),
      operation: json['operation'] as String? ?? '',
      packageOrProject: json['package_or_project'] as String? ?? '',
      command: json['command'] as String?,
      outcome: AuditEventOutcome.values.firstWhere(
        (o) => o.name == json['outcome'],
        orElse: () => AuditEventOutcome.success,
      ),
      relevantVersion: json['relevant_version'] as String?,
      securityClassification: AuditSecurityClassification.fromString(
          json['security_classification'] as String?),
      failureInformation: json['failure_information'] as String?,
      policyDecision: json['policy_decision'] as String?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      previousRecordHash: json['previous_record_hash'] as String?,
      recordHash: json['record_hash'] as String? ?? '',
    );
  }
}
