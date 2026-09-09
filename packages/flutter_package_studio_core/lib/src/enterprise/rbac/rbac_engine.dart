/// Central Role-Based Access Control (RBAC) Engine for Phase 9.3.
library;

import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/enterprise/identity/enterprise_identity_models.dart';
import 'package:flutter_package_studio_core/src/enterprise/rbac/rbac_models.dart';

/// Central Role-Based Access Control (RBAC) Engine.
///
/// Features:
/// 1. Evaluates operations against standard enterprise role matrix.
/// 2. Handles role hierarchy, wildcard permissions, direct subject permissions, and elevated approvals (`✓*`).
/// 3. Reusable authorization authority for all subsystems (Generator, Review, AI, Release, Packaging).
class RbacEngine {
  final Logger _logger = Logger('RbacEngine');

  /// Maps EnterpriseOperation to default permitted roles.
  static final Map<EnterpriseOperation, List<EnterpriseRole>> _roleMatrix = {
    EnterpriseOperation.inspectProject: [
      EnterpriseRole.developer,
      EnterpriseRole.reviewer,
      EnterpriseRole.releaseManager,
      EnterpriseRole.securityAuditor,
      EnterpriseRole.administrator,
      EnterpriseRole.readOnly,
    ],
    EnterpriseOperation.runAiReview: [
      EnterpriseRole.developer,
      EnterpriseRole.reviewer,
      EnterpriseRole.releaseManager,
      EnterpriseRole.securityAuditor,
      EnterpriseRole.administrator,
    ],
    EnterpriseOperation.modifyPackage: [
      EnterpriseRole.developer,
      EnterpriseRole.reviewer,
      EnterpriseRole.releaseManager,
      EnterpriseRole.administrator,
    ],
    EnterpriseOperation.createRelease: [
      EnterpriseRole.releaseManager,
      EnterpriseRole.administrator,
    ],
    EnterpriseOperation.publishPackage: [
      EnterpriseRole.releaseManager,
      EnterpriseRole.administrator,
    ],
    EnterpriseOperation.changeEnterprisePolicy: [
      EnterpriseRole.administrator,
    ],
    EnterpriseOperation.overrideSecurityGate: [
      EnterpriseRole.releaseManager, // Requires elevated approval (✓*)
      EnterpriseRole.administrator,
    ],
    EnterpriseOperation.manageUsers: [
      EnterpriseRole.administrator,
    ],
    EnterpriseOperation.executeControlledWorker: [
      EnterpriseRole.developer,
      EnterpriseRole.releaseManager,
      EnterpriseRole.administrator,
    ],
    EnterpriseOperation.viewAuditLogs: [
      EnterpriseRole.securityAuditor,
      EnterpriseRole.releaseManager,
      EnterpriseRole.administrator,
    ],
  };

  RbacEngine();

  /// Evaluates an authorization request.
  AuthorizationResult authorize(AuthorizationRequest request) {
    final sw = Stopwatch()..start();
    final now = DateTime.now();
    final identity = request.identity;
    final op = request.operation;
    final permKey = op.permissionKey;

    final permittedRoles = _roleMatrix[op] ?? [EnterpriseRole.administrator];

    _logger.info(
        'Evaluating authorization for principal "${identity.displayName}" (${identity.id}) -> $permKey');

    // 1. Direct permission check (Wildcard '*' or exact key match)
    if (identity.hasDirectPermission(permKey)) {
      sw.stop();
      return AuthorizationResult(
        decision: AuthorizationDecision.allow,
        identity: identity,
        operation: op,
        reason: 'Granted by direct permission assignment: "$permKey"',
        requiredPermissions: [permKey],
        authorizedRoles: permittedRoles,
        requiresAdditionalApproval: false,
        durationMs: sw.elapsedMilliseconds,
        timestamp: now,
      );
    }

    // 2. Administrator Role bypass (Superuser)
    if (identity.hasRole(EnterpriseRole.administrator)) {
      sw.stop();
      return AuthorizationResult(
        decision: AuthorizationDecision.allow,
        identity: identity,
        operation: op,
        reason: 'Granted by Administrator superuser privileges.',
        requiredPermissions: [permKey],
        authorizedRoles: permittedRoles,
        requiresAdditionalApproval: false,
        durationMs: sw.elapsedMilliseconds,
        timestamp: now,
      );
    }

    // 3. Special case: Override Security Gate (Requires elevated approval for Release Manager)
    if (op == EnterpriseOperation.overrideSecurityGate) {
      if (identity.hasRole(EnterpriseRole.releaseManager)) {
        if (request.hasElevatedApproval) {
          sw.stop();
          return AuthorizationResult(
            decision: AuthorizationDecision.allow,
            identity: identity,
            operation: op,
            reason:
                'Granted to Release Manager with verified elevated approval.',
            requiredPermissions: [permKey],
            authorizedRoles: permittedRoles,
            requiresAdditionalApproval: true,
            durationMs: sw.elapsedMilliseconds,
            timestamp: now,
          );
        } else {
          sw.stop();
          return AuthorizationResult(
            decision: AuthorizationDecision.requiresApproval,
            identity: identity,
            operation: op,
            reason:
                'Release Manager requires secondary elevated approval (✓*) to override security gate.',
            requiredPermissions: [permKey],
            authorizedRoles: permittedRoles,
            requiresAdditionalApproval: true,
            durationMs: sw.elapsedMilliseconds,
            timestamp: now,
          );
        }
      }
    }

    // 4. Role Matrix Evaluation
    final matchedRole = identity.roles.firstWhere(
      (r) => permittedRoles.contains(r),
      orElse: () => EnterpriseRole.custom,
    );

    if (matchedRole != EnterpriseRole.custom &&
        permittedRoles.contains(matchedRole)) {
      sw.stop();
      return AuthorizationResult(
        decision: AuthorizationDecision.allow,
        identity: identity,
        operation: op,
        reason: 'Granted through assigned role: ${matchedRole.displayName}',
        requiredPermissions: [permKey],
        authorizedRoles: permittedRoles,
        requiresAdditionalApproval: false,
        durationMs: sw.elapsedMilliseconds,
        timestamp: now,
      );
    }

    // 5. Fail-Closed Deny
    sw.stop();
    return AuthorizationResult(
      decision: AuthorizationDecision.deny,
      identity: identity,
      operation: op,
      reason:
          'Denied: Assigned role(s) [${identity.roles.map((r) => r.displayName).join(", ")}] lack permission "$permKey". Permitted roles: [${permittedRoles.map((r) => r.displayName).join(", ")}].',
      requiredPermissions: [permKey],
      authorizedRoles: permittedRoles,
      requiresAdditionalApproval: false,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
    );
  }
}
