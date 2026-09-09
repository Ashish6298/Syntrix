/// Closed, enumerable set of concrete plugin permissions formalizing Phase 7.5 SecurityRequirements.
enum PluginPermission {
  packageRead,
  packageFilesRead,
  artifactsWrite,
  processExecute,
  gitAccess,
  networkAccess,
  cliCommandAdd,
  releaseInfoAccess,
  documentationWrite,
  packagePublish;

  /// Parse permission string into enum, returning null if invalid or unrecognized.
  static PluginPermission? tryParse(String raw) {
    final clean = raw.trim();
    for (final val in PluginPermission.values) {
      if (val.name == clean || _toWireFormat(val) == clean) {
        return val;
      }
    }
    return null;
  }

  /// Converts enum value to canonical dot-notation wire format (e.g. package.read, git.access).
  static String _toWireFormat(PluginPermission perm) {
    switch (perm) {
      case PluginPermission.packageRead:
        return 'package.read';
      case PluginPermission.packageFilesRead:
        return 'packageFiles.read';
      case PluginPermission.artifactsWrite:
        return 'artifacts.write';
      case PluginPermission.processExecute:
        return 'process.execute';
      case PluginPermission.gitAccess:
        return 'git.access';
      case PluginPermission.networkAccess:
        return 'network.access';
      case PluginPermission.cliCommandAdd:
        return 'cliCommand.add';
      case PluginPermission.releaseInfoAccess:
        return 'releaseInfo.access';
      case PluginPermission.documentationWrite:
        return 'documentation.write';
      case PluginPermission.packagePublish:
        return 'package.publish';
    }
  }

  String get wireName => _toWireFormat(this);
}

/// Audit log entry capturing permission enforcement decisions (granted or denied).
class PermissionAuditRecord {
  final String pluginId;
  final String permissionName;
  final String operationAttempted;
  final bool isGranted;
  final String reason;
  final DateTime timestamp;

  PermissionAuditRecord({
    required this.pluginId,
    required this.permissionName,
    required this.operationAttempted,
    required this.isGranted,
    required this.reason,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'permissionName': permissionName,
        'operationAttempted': operationAttempted,
        'isGranted': isGranted,
        'reason': reason,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() =>
      '[$pluginId] ${isGranted ? "GRANTED" : "DENIED"} ($permissionName for $operationAttempted): $reason';
}

/// Permission status item for rendering roadmap-style status summaries.
class PermissionStatusItem {
  final PluginPermission permission;
  final bool isDeclared;
  final bool isApproved;

  bool get isEffective => isDeclared && isApproved;

  const PermissionStatusItem({
    required this.permission,
    required this.isDeclared,
    required this.isApproved,
  });

  Map<String, dynamic> toJson() => {
        'permission': permission.wireName,
        'isDeclared': isDeclared,
        'isApproved': isApproved,
        'isEffective': isEffective,
        'symbol': isEffective ? '✓' : '✗',
      };
}

/// Summary report of all declared and approved permissions for a plugin.
class PermissionStatusSummary {
  final String pluginId;
  final List<PermissionStatusItem> items;

  const PermissionStatusSummary({
    required this.pluginId,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'permissions': items.map((i) => i.toJson()).toList(),
      };
}
