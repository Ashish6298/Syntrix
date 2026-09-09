/// Domain models and structured records for Plugin State Persistence and Recovery (Phase 7.11).
library;

import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:syntrix/src/error/exceptions.dart';
import 'package:syntrix/src/plugin/contract/plugin_contract_models.dart';
import 'package:syntrix/src/plugin/contract/plugin_contract_validator.dart';
import 'package:syntrix/src/plugin/dependency/dependency_resolution_models.dart';
import 'package:syntrix/src/plugin/lifecycle/plugin_lifecycle_models.dart';
import 'package:syntrix/src/plugin/runtime/plugin_execution_models.dart';
import 'package:syntrix/src/release/versioning/semver_models.dart';

/// Categorized recovery status for a loaded plugin entry.
enum PluginRecoveryStatus {
  healthy,
  corruptState,
  failedInitialization,
  invalidConfiguration,
  orphanedRemoved,
  upgradeFallback,
  unrecognizedAmbiguous,
}

/// Immutable record capturing a specific recovery action taken on plugin load.
class PluginRecoveryActionRecord {
  final String pluginId;
  final PluginRecoveryStatus status;
  final String reason;
  final String actionTaken;
  final DateTime timestamp;

  PluginRecoveryActionRecord({
    required this.pluginId,
    required this.status,
    required this.reason,
    required this.actionTaken,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'status': status.name,
        'reason': reason,
        'actionTaken': actionTaken,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() =>
      '[$pluginId] ${status.name}: $actionTaken (Reason: $reason)';
}

/// Immutable persisted state snapshot for a single plugin instance.
class PersistedPluginState {
  final String pluginId;
  final SemVer version;
  final bool isEnabled;
  final PluginLifecycleState lifecycleState;
  final PluginValidationResult validationResult;
  final DependencyResolutionResult compatibilityResult;
  final Map<String, dynamic> redactedConfiguration;
  final List<LifecycleTransitionRecord> lifecycleHistory;
  final List<ExecutionAuditRecord> failureRecords;
  final Map<String, dynamic>? lastKnownGoodSnapshot;
  final DateTime lastUpdated;

  PersistedPluginState({
    required this.pluginId,
    required this.version,
    required this.isEnabled,
    required this.lifecycleState,
    required this.validationResult,
    required this.compatibilityResult,
    required this.redactedConfiguration,
    List<LifecycleTransitionRecord>? lifecycleHistory,
    List<ExecutionAuditRecord>? failureRecords,
    this.lastKnownGoodSnapshot,
    DateTime? lastUpdated,
  })  : lifecycleHistory = List.unmodifiable(lifecycleHistory ?? const []),
        failureRecords = List.unmodifiable(failureRecords ?? const []),
        lastUpdated = lastUpdated ?? DateTime.now();

  /// Converts this state record to a serializable JSON map.
  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'version': version.toString(),
        'isEnabled': isEnabled,
        'lifecycleState': lifecycleState.name,
        'validationResult': validationResult.toJson(),
        'compatibilityResult': compatibilityResult.toJson(),
        'redactedConfiguration': redactedConfiguration,
        'lifecycleHistory': lifecycleHistory.map((h) => h.toJson()).toList(),
        'failureRecords': failureRecords.map((f) => f.toJson()).toList(),
        if (lastKnownGoodSnapshot != null)
          'lastKnownGoodSnapshot': lastKnownGoodSnapshot,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  /// Constructs [PersistedPluginState] from a JSON map with strict schema enforcement.
  factory PersistedPluginState.fromJson(Map<String, dynamic> json) {
    final pluginId = json['pluginId'] as String?;
    final versionStr = json['version'] as String?;
    final isEnabled = json['isEnabled'] as bool?;
    final lifecycleStateStr = json['lifecycleState'] as String?;
    final validationMap = json['validationResult'] as Map<String, dynamic>?;
    final compatibilityMap =
        json['compatibilityResult'] as Map<String, dynamic>?;
    final configMap = json['redactedConfiguration'] as Map<String, dynamic>?;

    if (pluginId == null ||
        versionStr == null ||
        isEnabled == null ||
        lifecycleStateStr == null ||
        validationMap == null ||
        compatibilityMap == null ||
        configMap == null) {
      throw PluginPersistenceException(
          'Malformed PersistedPluginState JSON: missing required category fields.');
    }

    final semver = SemVer.parse(versionStr);

    final matchState = PluginLifecycleState.values
        .where((s) => s.name == lifecycleStateStr.trim());
    if (matchState.isEmpty) {
      throw PluginPersistenceException(
          'Unrecognized lifecycleState "$lifecycleStateStr" for plugin "$pluginId".');
    }
    final lifecycleState = matchState.first;

    // Phase 7.1 validation result
    final isValid = validationMap['isValid'] as bool? ?? false;
    final rawViolations = validationMap['violations'] as List<dynamic>? ?? [];
    final violations = rawViolations.map((v) => v.toString()).toList();
    final validationResult = PluginValidationResult(
      isValid: isValid,
      violations: violations,
    );

    // Phase 7.6 compatibility result
    final isCompatible = compatibilityMap['isCompatible'] as bool? ?? false;
    final rawInitOrder =
        compatibilityMap['initializationOrder'] as List<dynamic>?;
    final initOrder =
        rawInitOrder?.map((item) => item.toString()).toList() ?? [];
    final rawFindings =
        compatibilityMap['findings'] as List<dynamic>? ?? const [];
    final findings = rawFindings.map((f) {
      if (f is Map<String, dynamic>) {
        final typeStr = f['type'] as String? ?? 'missingDependency';
        final type = DependencyProblemType.values.firstWhere(
          (t) => t.name == typeStr,
          orElse: () => DependencyProblemType.missingDependency,
        );
        return DependencyProblemFinding(
          type: type,
          sourcePluginId: f['sourcePluginId'] as String? ?? pluginId,
          targetPluginId: f['targetPluginId'] as String?,
          message: f['message'] as String? ?? '',
          details: f['details'] as String?,
        );
      }
      return DependencyProblemFinding(
        type: DependencyProblemType.missingDependency,
        sourcePluginId: pluginId,
        message: f.toString(),
      );
    }).toList();

    final compatibilityResult = isCompatible
        ? DependencyResolutionResult.compatible(initOrder)
        : DependencyResolutionResult.blocked(findings);

    // History & failure records
    final rawHistory = json['lifecycleHistory'] as List<dynamic>? ?? const [];
    final history = rawHistory.map((h) {
      if (h is Map<String, dynamic>) {
        final fStr = h['fromState'] as String? ?? 'discovered';
        final tStr = h['toState'] as String? ?? 'discovered';
        final fromS = PluginLifecycleState.values.firstWhere(
            (s) => s.name == fStr,
            orElse: () => PluginLifecycleState.discovered);
        final toS = PluginLifecycleState.values.firstWhere(
            (s) => s.name == tStr,
            orElse: () => PluginLifecycleState.discovered);
        return LifecycleTransitionRecord(
          instanceId: h['instanceId'] as String? ?? pluginId,
          fromState: fromS,
          toState: toS,
          reason: h['reason'] as String? ?? '',
          timestamp: h['timestamp'] != null
              ? DateTime.tryParse(h['timestamp'].toString())
              : null,
        );
      }
      return LifecycleTransitionRecord(
        instanceId: pluginId,
        fromState: PluginLifecycleState.discovered,
        toState: PluginLifecycleState.discovered,
        reason: h.toString(),
      );
    }).toList();

    final rawFailures = json['failureRecords'] as List<dynamic>? ?? const [];
    final failures = rawFailures.map((f) {
      if (f is Map<String, dynamic>) {
        final statStr = f['status'] as String? ?? 'failed';
        final status = PluginExecutionStatus.values.firstWhere(
            (s) => s.name == statStr,
            orElse: () => PluginExecutionStatus.failed);
        return ExecutionAuditRecord(
          pluginId: f['pluginId'] as String? ?? pluginId,
          operation: f['operation'] as String? ?? 'unknown',
          status: status,
          durationMs: f['durationMs'] as int? ?? 0,
          details: f['details'] as String? ?? f['errorMessage'] as String?,
          timestamp: f['timestamp'] != null
              ? DateTime.tryParse(f['timestamp'].toString())
              : null,
        );
      }
      return ExecutionAuditRecord(
        pluginId: pluginId,
        operation: 'unknown',
        status: PluginExecutionStatus.failed,
        durationMs: 0,
        details: f.toString(),
      );
    }).toList();

    final lastKnownGood =
        json['lastKnownGoodSnapshot'] as Map<String, dynamic>?;
    final lastUpdated = json['lastUpdated'] != null
        ? DateTime.tryParse(json['lastUpdated'].toString())
        : null;

    return PersistedPluginState(
      pluginId: pluginId,
      version: semver,
      isEnabled: isEnabled,
      lifecycleState: lifecycleState,
      validationResult: validationResult,
      compatibilityResult: compatibilityResult,
      redactedConfiguration: configMap,
      lifecycleHistory: history,
      failureRecords: failures,
      lastKnownGoodSnapshot: lastKnownGood,
      lastUpdated: lastUpdated,
    );
  }
}

/// Complete root document serialized to `.fps/plugins/plugins_state.json`.
class PluginStateDocument {
  final int schemaVersion;
  final Map<String, PersistedPluginState> plugins;
  final DateTime generatedAt;
  final String checksum;

  static const int currentSchemaVersion = 1;

  PluginStateDocument({
    this.schemaVersion = currentSchemaVersion,
    required Map<String, PersistedPluginState> plugins,
    DateTime? generatedAt,
    String? checksum,
  })  : plugins = Map.unmodifiable(plugins),
        generatedAt = generatedAt ?? DateTime.now(),
        checksum = checksum ?? _computeChecksum(plugins);

  static String _computeChecksum(Map<String, PersistedPluginState> plugins) {
    final sortedKeys = plugins.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final k in sortedKeys) {
      final p = plugins[k]!;
      buffer.write('$k:${p.version}:${p.isEnabled}:${p.lifecycleState.name};');
    }
    return crypto.sha256.convert(utf8.encode(buffer.toString())).toString();
  }

  /// Verifies internal structural cryptographic checksum integrity.
  bool verifyIntegrity() {
    final expected = _computeChecksum(plugins);
    return checksum == expected;
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'generatedAt': generatedAt.toIso8601String(),
        'checksum': checksum,
        'plugins': plugins.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory PluginStateDocument.fromJson(Map<String, dynamic> json) {
    final schemaVer = json['schemaVersion'] as int?;
    final pluginsMap = json['plugins'] as Map<String, dynamic>?;
    final checksum = json['checksum'] as String?;

    if (schemaVer == null || pluginsMap == null || checksum == null) {
      throw PluginPersistenceException(
          'Malformed PluginStateDocument: missing schemaVersion, plugins, or checksum.');
    }

    final parsedPlugins = <String, PersistedPluginState>{};
    for (final entry in pluginsMap.entries) {
      if (entry.value is Map<String, dynamic>) {
        parsedPlugins[entry.key] =
            PersistedPluginState.fromJson(entry.value as Map<String, dynamic>);
      } else {
        throw PluginPersistenceException(
            'Malformed entry for plugin "${entry.key}".');
      }
    }

    final genAt = json['generatedAt'] != null
        ? DateTime.tryParse(json['generatedAt'].toString())
        : null;

    return PluginStateDocument(
      schemaVersion: schemaVer,
      plugins: parsedPlugins,
      generatedAt: genAt,
      checksum: checksum,
    );
  }
}

/// Structured outcome of a plugin state restore and recovery operation.
class PluginRecoveryResult {
  final Map<String, PersistedPluginState> healthyStates;
  final List<PluginRecoveryActionRecord> recoveryActions;
  final bool hasCorruptions;

  const PluginRecoveryResult({
    required this.healthyStates,
    required this.recoveryActions,
    required this.hasCorruptions,
  });

  Map<String, dynamic> toJson() => {
        'healthyStates': healthyStates.map((k, v) => MapEntry(k, v.toJson())),
        'recoveryActions': recoveryActions.map((a) => a.toJson()).toList(),
        'hasCorruptions': hasCorruptions,
      };
}
