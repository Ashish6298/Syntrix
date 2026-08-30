/// Domain models and structured records for Plugin Removal, Cleanup, and Reversibility (Phase 7.16).
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Reason why a candidate file or asset is excluded from removal.
enum FileExclusionReason {
  /// File is part of core application code or system configuration.
  coreApplication,

  /// File is shared with or referenced by another plugin.
  sharedPluginAsset,

  /// Configuration key/file is shared across plugins or with core.
  sharedConfiguration,

  /// File belongs to the user's Flutter/Dart package under development.
  userPackageData,

  /// File is a release artifact produced by release pipeline (changelog, tag, build).
  releaseArtifact,

  /// File cannot be confidently and specifically attributed to the target plugin.
  unattributed,
}

/// Structured record describing an excluded file.
class ExcludedFileRecord {
  final String path;
  final FileExclusionReason reason;
  final String description;

  const ExcludedFileRecord({
    required this.path,
    required this.reason,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'reason': reason.name,
        'description': description,
      };

  @override
  String toString() => '[$reason] $path ($description)';
}

/// Pure, immutable plan detailing what will and will not be removed for a target plugin.
class RemovalPlan {
  final String pluginId;
  final bool isRegistered;
  final bool hasPersistedState;
  final List<String> attributedFiles;
  final List<ExcludedFileRecord> excludedFiles;
  final List<String> dependentPluginIds;
  final bool isBlockedByDependents;
  final List<String> auditEntries;
  final String summary;
  final DateTime computedAt;

  RemovalPlan({
    required this.pluginId,
    required this.isRegistered,
    required this.hasPersistedState,
    required List<String> attributedFiles,
    required List<ExcludedFileRecord> excludedFiles,
    required List<String> dependentPluginIds,
    required this.isBlockedByDependents,
    required List<String> auditEntries,
    required this.summary,
    DateTime? computedAt,
  })  : attributedFiles = List.unmodifiable(attributedFiles),
        excludedFiles = List.unmodifiable(excludedFiles),
        dependentPluginIds = List.unmodifiable(dependentPluginIds),
        auditEntries = List.unmodifiable(auditEntries),
        computedAt = computedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'isRegistered': isRegistered,
        'hasPersistedState': hasPersistedState,
        'attributedFiles': attributedFiles,
        'excludedFiles': excludedFiles.map((e) => e.toJson()).toList(),
        'dependentPluginIds': dependentPluginIds,
        'isBlockedByDependents': isBlockedByDependents,
        'auditEntries': auditEntries,
        'summary': summary,
        'computedAt': computedAt.toIso8601String(),
      };
}

/// Isolated restorable snapshot of a plugin before removal.
class PluginRemovalBackup {
  final String backupId;
  final String pluginId;
  final String version;
  final DateTime createdAt;
  final Map<String, dynamic>? manifestJson;
  final Map<String, dynamic>? persistedStateJson;
  final Map<String, String> fileSnapshots; // relativePath -> fileContent
  final String checksum;

  PluginRemovalBackup({
    required this.backupId,
    required this.pluginId,
    required this.version,
    required this.createdAt,
    this.manifestJson,
    this.persistedStateJson,
    required this.fileSnapshots,
    String? checksum,
  }) : checksum = checksum ??
            _computeChecksum(
              backupId: backupId,
              pluginId: pluginId,
              version: version,
              manifestJson: manifestJson,
              persistedStateJson: persistedStateJson,
              fileSnapshots: fileSnapshots,
            );

  static String _computeChecksum({
    required String backupId,
    required String pluginId,
    required String version,
    Map<String, dynamic>? manifestJson,
    Map<String, dynamic>? persistedStateJson,
    required Map<String, String> fileSnapshots,
  }) {
    final payload = jsonEncode({
      'backupId': backupId,
      'pluginId': pluginId,
      'version': version,
      'manifest': manifestJson,
      'persistedState': persistedStateJson,
      'fileSnapshots': fileSnapshots,
    });
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// Verifies cryptographic checksum integrity of this backup payload.
  bool verifyIntegrity() {
    final expected = _computeChecksum(
      backupId: backupId,
      pluginId: pluginId,
      version: version,
      manifestJson: manifestJson,
      persistedStateJson: persistedStateJson,
      fileSnapshots: fileSnapshots,
    );
    return checksum == expected;
  }

  Map<String, dynamic> toJson() => {
        'backupId': backupId,
        'pluginId': pluginId,
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        if (manifestJson != null) 'manifest': manifestJson,
        if (persistedStateJson != null) 'persistedState': persistedStateJson,
        'fileSnapshots': fileSnapshots,
        'checksum': checksum,
      };

  factory PluginRemovalBackup.fromJson(Map<String, dynamic> json) {
    return PluginRemovalBackup(
      backupId: json['backupId'] as String,
      pluginId: json['pluginId'] as String,
      version: json['version'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      manifestJson: json['manifest'] as Map<String, dynamic>?,
      persistedStateJson: json['persistedState'] as Map<String, dynamic>?,
      fileSnapshots: Map<String, String>.from(
          json['fileSnapshots'] as Map<dynamic, dynamic>? ?? {}),
      checksum: json['checksum'] as String,
    );
  }
}

/// Execution outcome report for an applied removal operation.
class RemovalExecutionResult {
  final String pluginId;
  final String backupId;
  final String backupPath;
  final List<String> deletedFiles;
  final List<String> auditLog;
  final DateTime executedAt;

  const RemovalExecutionResult({
    required this.pluginId,
    required this.backupId,
    required this.backupPath,
    required this.deletedFiles,
    required this.auditLog,
    required this.executedAt,
  });

  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'backupId': backupId,
        'backupPath': backupPath,
        'deletedFiles': deletedFiles,
        'auditLog': auditLog,
        'executedAt': executedAt.toIso8601String(),
      };
}
