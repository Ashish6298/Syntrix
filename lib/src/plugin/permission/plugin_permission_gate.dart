import 'package:syntrix/src/error/exceptions.dart';
import 'package:syntrix/src/plugin/contract/plugin_contract_models.dart';
import 'package:syntrix/src/plugin/permission/plugin_permission_models.dart';

/// Single authority for permission approval store, deny-by-default runtime checks, and audit logging.
class PluginPermissionGate {
  final Map<String, Set<PluginPermission>> _approvedPermissions = {};
  final List<PermissionAuditRecord> _auditLog = [];

  /// Explicitly approve a permission grant for a specific plugin ID.
  void approvePermission(String pluginId, PluginPermission permission) {
    _approvedPermissions.putIfAbsent(pluginId, () => {}).add(permission);
  }

  /// Revoke an approved permission grant for a specific plugin ID.
  void revokePermission(String pluginId, PluginPermission permission) {
    _approvedPermissions[pluginId]?.remove(permission);
  }

  /// Get unmodifiable list of audit log records.
  List<PermissionAuditRecord> get auditLog => List.unmodifiable(_auditLog);

  /// Evaluate whether an attempted operation backed by [permission] is allowed for [manifest].
  ///
  /// Enforces three-stage permission check:
  /// Stage 1 (Declared): Must be in `manifest.securityRequirements.permissions`.
  /// Stage 2 (Approved): Must be in `_approvedPermissions[pluginId]`.
  /// Stage 3 (Enforced): Both declared and approved required. Deny-by-default posture.
  bool check({
    required PluginManifest manifest,
    required PluginPermission permission,
    required String operationAttempted,
    bool throwOnDeny = false,
  }) {
    final pluginId = manifest.id.value;

    // Stage 1: Check declared permissions in manifest
    final declaredPerms = <PluginPermission>{};
    for (final raw in manifest.securityRequirements.permissions) {
      final parsed = PluginPermission.tryParse(raw);
      if (parsed != null) {
        declaredPerms.add(parsed);
      }
    }

    final isDeclared = declaredPerms.contains(permission);
    final isApproved =
        _approvedPermissions[pluginId]?.contains(permission) ?? false;

    if (!isDeclared) {
      final record = PermissionAuditRecord(
        pluginId: pluginId,
        permissionName: permission.wireName,
        operationAttempted: operationAttempted,
        isGranted: false,
        reason:
            'DENIED: Permission "${permission.wireName}" was not declared in plugin manifest.',
      );
      _auditLog.add(record);
      if (throwOnDeny) {
        throw PluginPermissionException(record.reason);
      }
      return false;
    }

    if (!isApproved) {
      final record = PermissionAuditRecord(
        pluginId: pluginId,
        permissionName: permission.wireName,
        operationAttempted: operationAttempted,
        isGranted: false,
        reason:
            'DENIED (Deny-by-Default): Permission "${permission.wireName}" is declared but not approved for plugin "$pluginId".',
      );
      _auditLog.add(record);
      if (throwOnDeny) {
        throw PluginPermissionException(record.reason);
      }
      return false;
    }

    final record = PermissionAuditRecord(
      pluginId: pluginId,
      permissionName: permission.wireName,
      operationAttempted: operationAttempted,
      isGranted: true,
      reason:
          'GRANTED: Permission "${permission.wireName}" is declared and approved.',
    );
    _auditLog.add(record);
    return true;
  }

  /// Generate roadmap-style permission status summary (✓/✗ per permission) for a manifest.
  PermissionStatusSummary queryStatus(PluginManifest manifest) {
    final pluginId = manifest.id.value;
    final declaredPerms = <PluginPermission>{};
    for (final raw in manifest.securityRequirements.permissions) {
      final parsed = PluginPermission.tryParse(raw);
      if (parsed != null) {
        declaredPerms.add(parsed);
      }
    }

    final approved = _approvedPermissions[pluginId] ?? const {};

    final items = <PermissionStatusItem>[];
    for (final perm in PluginPermission.values) {
      final dec = declaredPerms.contains(perm);
      final app = approved.contains(perm);
      items.add(PermissionStatusItem(
        permission: perm,
        isDeclared: dec,
        isApproved: app,
      ));
    }

    return PermissionStatusSummary(pluginId: pluginId, items: items);
  }
}
