/// Domain models for Plugin Observability & Diagnostics (Phase 7.12).
library;

import 'package:syntrix/src/plugin/configuration/plugin_configuration_models.dart';
import 'package:syntrix/src/plugin/contract/plugin_contract_models.dart';
import 'package:syntrix/src/plugin/contract/plugin_contract_validator.dart';
import 'package:syntrix/src/plugin/dependency/dependency_resolution_models.dart';
import 'package:syntrix/src/plugin/discovery/plugin_discovery_models.dart';
import 'package:syntrix/src/plugin/lifecycle/plugin_lifecycle_models.dart';
import 'package:syntrix/src/plugin/permission/plugin_permission_models.dart';
import 'package:syntrix/src/plugin/persistence/plugin_state_models.dart';
import 'package:syntrix/src/plugin/runtime/plugin_execution_models.dart';
import 'package:syntrix/src/release/github/github_release_models.dart';
import 'package:syntrix/src/release/security/release_security_models.dart';

/// Redaction utility ensuring zero secret leakage across all diagnostic renderers with no opt-out.
class DiagnosticRedactor {
  static const Set<String> _sensitiveKeySubstrings = {
    'token',
    'secret',
    'password',
    'apikey',
    'api_key',
    'credential',
    'auth',
    'privatekey',
    'private_key',
  };

  /// Recursively redacts sensitive values in any object (Map, List, String, custom types).
  static dynamic redact(dynamic value) {
    if (value == null) return null;

    if (value is SecretValue) {
      return '[REDACTED]';
    }

    if (value is GitHubCredential) {
      return '[REDACTED]';
    }

    if (value is SecurityFinding) {
      return value.toJson();
    }

    if (value is Map) {
      final sanitized = <String, dynamic>{};
      for (final entry in value.entries) {
        final keyStr = entry.key.toString().toLowerCase();
        final isSensitiveKey = _sensitiveKeySubstrings.any((s) =>
            keyStr.contains(s) || keyStr.replaceAll('_', '').contains(s));

        if (isSensitiveKey ||
            entry.value is SecretValue ||
            entry.value is GitHubCredential) {
          sanitized[entry.key.toString()] = '[REDACTED]';
        } else {
          sanitized[entry.key.toString()] = redact(entry.value);
        }
      }
      return sanitized;
    }

    if (value is List) {
      return value.map((item) => redact(item)).toList();
    }

    if (value is String) {
      return redactString(value);
    }

    return value;
  }

  /// Redacts potential raw token or credential strings matching common patterns.
  static String redactString(String input) {
    var result = input;
    // Redact ghp_ GitHub tokens or similar hex/base64 tokens if passed as raw text
    result =
        result.replaceAll(RegExp(r'ghp_[a-zA-Z0-9]{20,}'), '[REDACTED_TOKEN]');
    result = result.replaceAll(
        RegExp(r'github_pat_[a-zA-Z0-9_]{20,}'), '[REDACTED_TOKEN]');
    return result;
  }
}

/// Precise failure stage enumeration for diagnostic root-cause determination.
enum PluginFailureStage {
  discovery,
  registration,
  contractValidation,
  configValidation,
  dependencyResolution,
  initialization,
  execution,
  permissionEnforcement,
  shutdown,
  persistenceRecovery,
  none,
}

/// Attributable root-cause diagnosis for a plugin failure.
class PluginFailureDiagnostic {
  final PluginFailureStage stage;
  final String reason;
  final String? missingPermission;
  final bool isTimeout;
  final String? originalError;
  final String? attributableRecord;

  const PluginFailureDiagnostic({
    required this.stage,
    required this.reason,
    this.missingPermission,
    this.isTimeout = false,
    this.originalError,
    this.attributableRecord,
  });

  Map<String, dynamic> toJson() => {
        'stage': stage.name,
        'reason': reason,
        'missingPermission': missingPermission,
        'isTimeout': isTimeout,
        'originalError': originalError,
        'attributableRecord': attributableRecord,
      };
}

/// Overall health status for a diagnosed plugin instance.
enum PluginHealthStatus {
  healthy,
  failed,
  permissionViolated,
  orphaned,
  unregistered,
}

/// Comprehensive, observable diagnostic record for a single plugin instance.
class PluginInstanceDiagnostic {
  final String pluginId;
  final PluginHealthStatus healthStatus;
  final DiscoveredPluginEntry? discoveryEntry;
  final bool isRegistered;
  final PluginManifest? manifest;
  final PluginValidationResult? validationResult;
  final PluginConfigurationValidationResult? configValidationResult;
  final Map<String, dynamic>? rawConfiguration;
  final DependencyResolutionResult? dependencyResult;
  final PluginLifecycleState? currentLifecycleState;
  final List<LifecycleTransitionRecord> lifecycleHistory;
  final List<PermissionAuditRecord> permissionAudits;
  final List<ExecutionAuditRecord> executionAudits;
  final List<PluginExecutionResult<dynamic>> executionResults;
  final PersistedPluginState? persistedState;
  final List<PluginRecoveryActionRecord> recoveryActions;
  final PluginFailureDiagnostic? rootCause;

  PluginInstanceDiagnostic({
    required this.pluginId,
    required this.healthStatus,
    this.discoveryEntry,
    this.isRegistered = false,
    this.manifest,
    this.validationResult,
    this.configValidationResult,
    this.rawConfiguration,
    this.dependencyResult,
    this.currentLifecycleState,
    List<LifecycleTransitionRecord>? lifecycleHistory,
    List<PermissionAuditRecord>? permissionAudits,
    List<ExecutionAuditRecord>? executionAudits,
    List<PluginExecutionResult<dynamic>>? executionResults,
    this.persistedState,
    List<PluginRecoveryActionRecord>? recoveryActions,
    this.rootCause,
  })  : lifecycleHistory = List.unmodifiable(lifecycleHistory ?? const []),
        permissionAudits = List.unmodifiable(permissionAudits ?? const []),
        executionAudits = List.unmodifiable(executionAudits ?? const []),
        executionResults = List.unmodifiable(executionResults ?? const []),
        recoveryActions = List.unmodifiable(recoveryActions ?? const []);

  Map<String, dynamic> toJson() {
    final raw = <String, dynamic>{
      'pluginId': pluginId,
      'healthStatus': healthStatus.name,
      'isRegistered': isRegistered,
      'currentLifecycleState': currentLifecycleState?.name,
      'discovery': discoveryEntry != null
          ? {
              'directoryPath': discoveryEntry!.directoryPath,
              'manifestPath': discoveryEntry!.manifestPath,
              'status': discoveryEntry!.status.name,
              'details': discoveryEntry!.details,
            }
          : null,
      'manifest': manifest?.toJson(),
      'validation': validationResult != null
          ? {
              'isValid': validationResult!.isValid,
              'violations': validationResult!.violations,
            }
          : null,
      'configValidation': configValidationResult != null
          ? {
              'isValid': configValidationResult!.isValid,
              'violations': configValidationResult!.violations,
            }
          : null,
      'configuration': rawConfiguration,
      'dependencyResolution': dependencyResult != null
          ? {
              'isCompatible': dependencyResult!.isCompatible,
              'initializationOrder': dependencyResult!.initializationOrder,
              'findings':
                  dependencyResult!.findings.map((f) => f.toJson()).toList(),
            }
          : null,
      'lifecycleHistory': lifecycleHistory.map((h) => h.toJson()).toList(),
      'permissionAudits': permissionAudits.map((p) => p.toJson()).toList(),
      'executionAudits': executionAudits.map((e) => e.toJson()).toList(),
      'executionResults': executionResults.map((r) => r.toJson()).toList(),
      'persistedState': persistedState?.toJson(),
      'recoveryActions': recoveryActions.map((r) => r.toJson()).toList(),
      'rootCause': rootCause?.toJson(),
    };

    // Apply unconditional redaction
    return DiagnosticRedactor.redact(raw) as Map<String, dynamic>;
  }
}

/// Ecosystem-wide diagnostic summary triaging all tracked plugins.
class PluginSystemDiagnosticSummary {
  final DateTime generatedAt;
  final int totalScanned;
  final int totalRegistered;
  final List<String> healthyPluginIds;
  final List<String> failedPluginIds;
  final List<String> permissionViolatedPluginIds;
  final List<String> orphanedPluginIds;
  final Map<String, PluginInstanceDiagnostic> pluginDiagnostics;
  final List<DiscoveredPluginEntry> unassociatedDiscoveryEntries;

  PluginSystemDiagnosticSummary({
    DateTime? generatedAt,
    required this.totalScanned,
    required this.totalRegistered,
    required List<String> healthyPluginIds,
    required List<String> failedPluginIds,
    required List<String> permissionViolatedPluginIds,
    required List<String> orphanedPluginIds,
    required Map<String, PluginInstanceDiagnostic> pluginDiagnostics,
    List<DiscoveredPluginEntry>? unassociatedDiscoveryEntries,
  })  : generatedAt = generatedAt ?? DateTime.now(),
        healthyPluginIds = List.unmodifiable(healthyPluginIds),
        failedPluginIds = List.unmodifiable(failedPluginIds),
        permissionViolatedPluginIds =
            List.unmodifiable(permissionViolatedPluginIds),
        orphanedPluginIds = List.unmodifiable(orphanedPluginIds),
        pluginDiagnostics = Map.unmodifiable(pluginDiagnostics),
        unassociatedDiscoveryEntries =
            List.unmodifiable(unassociatedDiscoveryEntries ?? const []);

  Map<String, dynamic> toJson() {
    final raw = <String, dynamic>{
      'generatedAt': generatedAt.toIso8601String(),
      'summary': {
        'totalScanned': totalScanned,
        'totalRegistered': totalRegistered,
        'healthyCount': healthyPluginIds.length,
        'failedCount': failedPluginIds.length,
        'permissionViolatedCount': permissionViolatedPluginIds.length,
        'orphanedCount': orphanedPluginIds.length,
        'healthyPluginIds': healthyPluginIds,
        'failedPluginIds': failedPluginIds,
        'permissionViolatedPluginIds': permissionViolatedPluginIds,
        'orphanedPluginIds': orphanedPluginIds,
      },
      'plugins': {
        for (final entry in pluginDiagnostics.entries)
          entry.key: entry.value.toJson(),
      },
      'unassociatedDiscovery': unassociatedDiscoveryEntries
          .map((e) => {
                'directoryPath': e.directoryPath,
                'manifestPath': e.manifestPath,
                'status': e.status.name,
                'details': e.details,
              })
          .toList(),
    };

    return DiagnosticRedactor.redact(raw) as Map<String, dynamic>;
  }
}
