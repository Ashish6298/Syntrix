/// Domain models and permission definitions for Phase 9.3: Role-Based Access Control (RBAC).
library;

import 'package:syntrix/src/enterprise/identity/enterprise_identity_models.dart';

/// Standard Enterprise Operations.
enum EnterpriseOperation {
  inspectProject,
  runAiReview,
  modifyPackage,
  createRelease,
  publishPackage,
  changeEnterprisePolicy,
  overrideSecurityGate,
  manageUsers,
  executeControlledWorker,
  viewAuditLogs;

  String get id => name;

  String get permissionKey {
    switch (this) {
      case EnterpriseOperation.inspectProject:
        return 'project:inspect';
      case EnterpriseOperation.runAiReview:
        return 'ai:review';
      case EnterpriseOperation.modifyPackage:
        return 'package:modify';
      case EnterpriseOperation.createRelease:
        return 'release:create';
      case EnterpriseOperation.publishPackage:
        return 'release:publish';
      case EnterpriseOperation.changeEnterprisePolicy:
        return 'policy:change';
      case EnterpriseOperation.overrideSecurityGate:
        return 'security:override_gate';
      case EnterpriseOperation.manageUsers:
        return 'identity:manage_users';
      case EnterpriseOperation.executeControlledWorker:
        return 'worker:execute';
      case EnterpriseOperation.viewAuditLogs:
        return 'audit:view';
    }
  }

  static EnterpriseOperation fromString(String? val) {
    if (val == null) return EnterpriseOperation.inspectProject;
    return EnterpriseOperation.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == val.toLowerCase() ||
          e.permissionKey.toLowerCase() == val.toLowerCase(),
      orElse: () => EnterpriseOperation.inspectProject,
    );
  }
}

/// Authorization Decision Outcome.
enum AuthorizationDecision {
  allow,
  deny,
  requiresApproval;

  bool get isAllowed => this == AuthorizationDecision.allow;
  bool get isDenied => this == AuthorizationDecision.deny;
  bool get needsApproval => this == AuthorizationDecision.requiresApproval;
}

/// Structured Authorization Request.
class AuthorizationRequest {
  final EnterpriseIdentity identity;
  final EnterpriseOperation operation;
  final String? targetResource;
  final String? targetPackage;
  final Map<String, dynamic> context;
  final bool hasElevatedApproval;

  const AuthorizationRequest({
    required this.identity,
    required this.operation,
    this.targetResource,
    this.targetPackage,
    this.context = const {},
    this.hasElevatedApproval = false,
  });
}

/// Structured Authorization Result.
class AuthorizationResult {
  final AuthorizationDecision decision;
  final EnterpriseIdentity identity;
  final EnterpriseOperation operation;
  final String reason;
  final List<String> requiredPermissions;
  final List<EnterpriseRole> authorizedRoles;
  final bool requiresAdditionalApproval;
  final int durationMs;
  final DateTime timestamp;

  const AuthorizationResult({
    required this.decision,
    required this.identity,
    required this.operation,
    required this.reason,
    required this.requiredPermissions,
    required this.authorizedRoles,
    required this.requiresAdditionalApproval,
    required this.durationMs,
    required this.timestamp,
  });

  bool get isAllowed => decision == AuthorizationDecision.allow;

  Map<String, dynamic> toJson() => {
        'decision': decision.name,
        'identity_id': identity.id,
        'identity_name': identity.displayName,
        'operation': operation.name,
        'permission_key': operation.permissionKey,
        'reason': reason,
        'required_permissions': requiredPermissions,
        'authorized_roles': authorizedRoles.map((r) => r.id).toList(),
        'requires_additional_approval': requiresAdditionalApproval,
        'duration_ms': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AuthorizationResult.fromJson(Map<String, dynamic> json) {
    return AuthorizationResult(
      decision: AuthorizationDecision.values.firstWhere(
        (d) => d.name == json['decision'],
        orElse: () => AuthorizationDecision.deny,
      ),
      identity: EnterpriseIdentity(
        id: json['identity_id'] as String? ?? 'unknown',
        displayName: json['identity_name'] as String? ?? 'Unknown',
      ),
      operation: EnterpriseOperation.fromString(json['operation'] as String?),
      reason: json['reason'] as String? ?? '',
      requiredPermissions: (json['required_permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      authorizedRoles: (json['authorized_roles'] as List<dynamic>?)
              ?.map((r) => EnterpriseRole.fromString(r.toString()))
              .toList() ??
          const [],
      requiresAdditionalApproval:
          json['requires_additional_approval'] as bool? ?? false,
      durationMs: json['duration_ms'] as int? ?? 0,
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}
