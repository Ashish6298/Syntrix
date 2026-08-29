/// Core diagnostics engine for Plugin Observability & Diagnostics (Phase 7.12).
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/plugin/configuration/plugin_configuration_models.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_models.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_validator.dart';
import 'package:flutter_package_studio_core/src/plugin/dependency/dependency_resolution_models.dart';
import 'package:flutter_package_studio_core/src/plugin/diagnostics/plugin_diagnostic_models.dart';
import 'package:flutter_package_studio_core/src/plugin/discovery/plugin_discovery_models.dart';
import 'package:flutter_package_studio_core/src/plugin/interface/plugin_registry.dart';
import 'package:flutter_package_studio_core/src/plugin/lifecycle/plugin_lifecycle_manager.dart';
import 'package:flutter_package_studio_core/src/plugin/lifecycle/plugin_lifecycle_models.dart';
import 'package:flutter_package_studio_core/src/plugin/permission/plugin_permission_models.dart';
import 'package:flutter_package_studio_core/src/plugin/persistence/plugin_state_models.dart';
import 'package:flutter_package_studio_core/src/plugin/runtime/plugin_execution_models.dart';
import 'package:flutter_package_studio_core/src/plugin/runtime/plugin_execution_runtime.dart';

/// Single authority for aggregating, correlating, and rendering plugin diagnostic data.
class PluginDiagnosticsEngine {
  const PluginDiagnosticsEngine();

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Aggregation & Root-Cause Correlation (Zero Recomputation)
  // ───────────────────────────────────────────────────────────────────────────

  /// Diagnoses a single plugin instance using provided upstream subsystem records.
  PluginInstanceDiagnostic diagnosePlugin({
    required String pluginId,
    DiscoveredPluginEntry? discoveryEntry,
    RegisteredPlugin? registeredPlugin,
    PluginManifest? manifest,
    PluginValidationResult? validationResult,
    PluginConfigurationValidationResult? configValidationResult,
    Map<String, dynamic>? rawConfiguration,
    DependencyResolutionResult? dependencyResult,
    PluginInstanceRecord? instanceRecord,
    List<PermissionAuditRecord>? permissionAudits,
    List<ExecutionAuditRecord>? executionAudits,
    List<PluginExecutionResult<dynamic>>? executionResults,
    PersistedPluginState? persistedState,
    List<PluginRecoveryActionRecord>? recoveryActions,
  }) {
    final effectiveManifest =
        manifest ?? registeredPlugin?.manifest ?? discoveryEntry?.manifest;
    final isRegistered = registeredPlugin != null;
    final currentLifecycleState =
        instanceRecord?.state ?? persistedState?.lifecycleState;
    final history =
        instanceRecord?.history ?? persistedState?.lifecycleHistory ?? const [];
    final permAudits = permissionAudits ?? const [];
    final execAudits =
        executionAudits ?? persistedState?.failureRecords ?? const [];
    final execResults = executionResults ?? const [];
    final recActions = recoveryActions ?? const [];

    // Root cause diagnosis using ONLY already-recorded upstream data
    final rootCause = _deriveRootCause(
      pluginId: pluginId,
      discoveryEntry: discoveryEntry,
      validationResult: validationResult,
      configValidationResult: configValidationResult,
      dependencyResult: dependencyResult,
      currentLifecycleState: currentLifecycleState,
      permissionAudits: permAudits,
      executionAudits: execAudits,
      executionResults: execResults,
      recoveryActions: recActions,
    );

    // Derive overall health status
    final healthStatus = _deriveHealthStatus(
      isRegistered: isRegistered,
      currentLifecycleState: currentLifecycleState,
      rootCause: rootCause,
      permissionAudits: permAudits,
      recoveryActions: recActions,
    );

    return PluginInstanceDiagnostic(
      pluginId: pluginId,
      healthStatus: healthStatus,
      discoveryEntry: discoveryEntry,
      isRegistered: isRegistered,
      manifest: effectiveManifest,
      validationResult: validationResult,
      configValidationResult: configValidationResult,
      rawConfiguration: rawConfiguration,
      dependencyResult: dependencyResult,
      currentLifecycleState: currentLifecycleState,
      lifecycleHistory: history,
      permissionAudits: permAudits,
      executionAudits: execAudits,
      executionResults: execResults,
      persistedState: persistedState,
      recoveryActions: recActions,
      rootCause: rootCause,
    );
  }

  /// Diagnoses the entire plugin ecosystem across all provided subsystems.
  PluginSystemDiagnosticSummary diagnoseSystem({
    DiscoveryResult? discoveryResult,
    PluginRegistry? registry,
    PluginLifecycleManager? lifecycleManager,
    PluginExecutionRuntime? runtime,
    PluginRecoveryResult? recoveryResult,
    Map<String, PluginValidationResult>? validationResults,
    Map<String, PluginConfigurationValidationResult>? configValidationResults,
    Map<String, Map<String, dynamic>>? rawConfigurations,
    DependencyResolutionResult? dependencyResult,
    List<PermissionAuditRecord>? permissionAudits,
  }) {
    final allKnownIds = <String>{};

    // Collect from discovery
    final discoveryMap = <String, DiscoveredPluginEntry>{};
    final unassociatedDiscovery = <DiscoveredPluginEntry>[];
    if (discoveryResult != null) {
      for (final entry in discoveryResult.entries) {
        if (entry.manifest != null) {
          final id = entry.manifest!.id.value;
          discoveryMap[id] = entry;
          allKnownIds.add(id);
        } else {
          unassociatedDiscovery.add(entry);
        }
      }
    }

    // Collect from registry
    final registeredPlugins = registry?.registeredPlugins ?? const {};
    allKnownIds.addAll(registeredPlugins.keys);

    // Collect from lifecycle manager
    final trackedMap = <String, PluginInstanceRecord>{};
    if (lifecycleManager != null) {
      for (final inst in lifecycleManager.instances) {
        trackedMap[inst.instanceId] = inst;
        allKnownIds.add(inst.instanceId);
      }
    }

    // Collect from recovery result
    final persistedStates = recoveryResult?.healthyStates ?? const {};
    allKnownIds.addAll(persistedStates.keys);

    // Group permission audits by plugin ID
    final permAuditsByPlugin = <String, List<PermissionAuditRecord>>{};
    if (permissionAudits != null) {
      for (final audit in permissionAudits) {
        permAuditsByPlugin.putIfAbsent(audit.pluginId, () => []).add(audit);
        allKnownIds.add(audit.pluginId);
      }
    }

    // Group execution audits from runtime
    final execAuditsByPlugin = <String, List<ExecutionAuditRecord>>{};
    if (runtime != null) {
      for (final audit in runtime.auditLog) {
        execAuditsByPlugin.putIfAbsent(audit.pluginId, () => []).add(audit);
        allKnownIds.add(audit.pluginId);
      }
    }

    // Group recovery actions by plugin ID
    final recoveryActionsByPlugin =
        <String, List<PluginRecoveryActionRecord>>{};
    if (recoveryResult != null) {
      for (final action in recoveryResult.recoveryActions) {
        if (action.pluginId != '*') {
          recoveryActionsByPlugin
              .putIfAbsent(action.pluginId, () => [])
              .add(action);
          allKnownIds.add(action.pluginId);
        }
      }
    }

    final pluginDiagnostics = <String, PluginInstanceDiagnostic>{};
    final healthy = <String>[];
    final failed = <String>[];
    final permissionViolated = <String>[];
    final orphaned = <String>[];

    final sortedIds = allKnownIds.toList()..sort();
    for (final id in sortedIds) {
      final diag = diagnosePlugin(
        pluginId: id,
        discoveryEntry: discoveryMap[id],
        registeredPlugin: registeredPlugins[id],
        validationResult: validationResults?[id],
        configValidationResult: configValidationResults?[id],
        rawConfiguration: rawConfigurations?[id],
        dependencyResult: dependencyResult,
        instanceRecord: trackedMap[id],
        permissionAudits: permAuditsByPlugin[id],
        executionAudits: execAuditsByPlugin[id],
        persistedState: persistedStates[id],
        recoveryActions: recoveryActionsByPlugin[id],
      );

      pluginDiagnostics[id] = diag;

      switch (diag.healthStatus) {
        case PluginHealthStatus.healthy:
          healthy.add(id);
          break;
        case PluginHealthStatus.failed:
          failed.add(id);
          break;
        case PluginHealthStatus.permissionViolated:
          permissionViolated.add(id);
          break;
        case PluginHealthStatus.orphaned:
          orphaned.add(id);
          break;
        case PluginHealthStatus.unregistered:
          // Kept in map, but not in healthy/failed triage lists
          break;
      }
    }

    return PluginSystemDiagnosticSummary(
      totalScanned: discoveryResult?.entries.length ?? 0,
      totalRegistered: registeredPlugins.length,
      healthyPluginIds: healthy,
      failedPluginIds: failed,
      permissionViolatedPluginIds: permissionViolated,
      orphanedPluginIds: orphaned,
      pluginDiagnostics: pluginDiagnostics,
      unassociatedDiscoveryEntries: unassociatedDiscovery,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Deterministic Root-Cause Analysis
  // ───────────────────────────────────────────────────────────────────────────

  PluginFailureDiagnostic? _deriveRootCause({
    required String pluginId,
    DiscoveredPluginEntry? discoveryEntry,
    PluginValidationResult? validationResult,
    PluginConfigurationValidationResult? configValidationResult,
    DependencyResolutionResult? dependencyResult,
    PluginLifecycleState? currentLifecycleState,
    required List<PermissionAuditRecord> permissionAudits,
    required List<ExecutionAuditRecord> executionAudits,
    required List<PluginExecutionResult<dynamic>> executionResults,
    required List<PluginRecoveryActionRecord> recoveryActions,
  }) {
    // 1. Recovery action failures
    for (final rec in recoveryActions) {
      if (rec.status == PluginRecoveryStatus.failedInitialization) {
        return PluginFailureDiagnostic(
          stage: PluginFailureStage.initialization,
          reason: rec.reason,
          attributableRecord: 'PluginRecoveryActionRecord: ${rec.status.name}',
        );
      }
      if (rec.status == PluginRecoveryStatus.invalidConfiguration) {
        return PluginFailureDiagnostic(
          stage: PluginFailureStage.configValidation,
          reason: rec.reason,
          attributableRecord: 'PluginRecoveryActionRecord: ${rec.status.name}',
        );
      }
      if (rec.status == PluginRecoveryStatus.upgradeFallback) {
        return PluginFailureDiagnostic(
          stage: PluginFailureStage.contractValidation,
          reason: rec.reason,
          attributableRecord: 'PluginRecoveryActionRecord: ${rec.status.name}',
        );
      }
      if (rec.status == PluginRecoveryStatus.orphanedRemoved) {
        return PluginFailureDiagnostic(
          stage: PluginFailureStage.persistenceRecovery,
          reason: rec.reason,
          attributableRecord: 'PluginRecoveryActionRecord: ${rec.status.name}',
        );
      }
    }

    // 2. Lifecycle failures (initializationFailed / shutdownFailed / invalid)
    if (currentLifecycleState == PluginLifecycleState.initializationFailed) {
      return const PluginFailureDiagnostic(
        stage: PluginFailureStage.initialization,
        reason: 'Plugin initialization hook failed during activation.',
        attributableRecord: 'PluginLifecycleState: initializationFailed',
      );
    }
    if (currentLifecycleState == PluginLifecycleState.shutdownFailed) {
      return const PluginFailureDiagnostic(
        stage: PluginFailureStage.shutdown,
        reason: 'Plugin shutdown hook failed during disposal.',
        attributableRecord: 'PluginLifecycleState: shutdownFailed',
      );
    }
    if (currentLifecycleState == PluginLifecycleState.invalid) {
      return const PluginFailureDiagnostic(
        stage: PluginFailureStage.contractValidation,
        reason: 'Plugin is in invalid lifecycle state.',
        attributableRecord: 'PluginLifecycleState: invalid',
      );
    }

    // 3. Execution runtime failure / timeout / permission denied
    for (final exec in executionResults.reversed) {
      if (exec.status == PluginExecutionStatus.timedOut) {
        return PluginFailureDiagnostic(
          stage: PluginFailureStage.execution,
          reason: 'Plugin invocation timed out after ${exec.durationMs}ms.',
          isTimeout: true,
          originalError: exec.errorMessage,
          attributableRecord: 'PluginExecutionResult: timedOut',
        );
      }
      if (exec.status == PluginExecutionStatus.permissionDenied) {
        return PluginFailureDiagnostic(
          stage: PluginFailureStage.permissionEnforcement,
          reason:
              'Plugin execution rejected due to missing permission for operation "${exec.operation}".',
          originalError: exec.errorMessage,
          attributableRecord: 'PluginExecutionResult: permissionDenied',
        );
      }
      if (exec.status == PluginExecutionStatus.failed) {
        return PluginFailureDiagnostic(
          stage: PluginFailureStage.execution,
          reason: exec.errorMessage ??
              'Plugin execution failed during operation "${exec.operation}".',
          originalError: exec.errorMessage,
          attributableRecord: 'PluginExecutionResult: failed',
        );
      }
    }

    // 4. Permission denial records
    for (final audit in permissionAudits.reversed) {
      if (!audit.isGranted) {
        return PluginFailureDiagnostic(
          stage: PluginFailureStage.permissionEnforcement,
          reason: audit.reason,
          missingPermission: audit.permissionName,
          attributableRecord:
              'PermissionAuditRecord: ${audit.permissionName} denied',
        );
      }
    }

    // 5. Dependency resolution failures
    if (dependencyResult != null && !dependencyResult.isCompatible) {
      final finding = dependencyResult.findings
          .where((f) => f.sourcePluginId == pluginId)
          .firstOrNull;
      if (finding != null) {
        return PluginFailureDiagnostic(
          stage: PluginFailureStage.dependencyResolution,
          reason: finding.message,
          attributableRecord: 'DependencyProblemFinding: ${finding.type.name}',
        );
      }
    }

    // 6. Configuration validation violations
    if (configValidationResult != null && !configValidationResult.isValid) {
      return PluginFailureDiagnostic(
        stage: PluginFailureStage.configValidation,
        reason: configValidationResult.violations.join('; '),
        attributableRecord: 'PluginConfigurationValidationResult: invalid',
      );
    }

    // 7. Contract validation violations
    if (validationResult != null && !validationResult.isValid) {
      return PluginFailureDiagnostic(
        stage: PluginFailureStage.contractValidation,
        reason: validationResult.violations.join('; '),
        attributableRecord: 'PluginValidationResult: invalid',
      );
    }

    // 8. Discovery errors
    if (discoveryEntry != null &&
        discoveryEntry.status != DiscoveredPluginStatus.valid) {
      return PluginFailureDiagnostic(
        stage: PluginFailureStage.discovery,
        reason: discoveryEntry.details.join('; '),
        attributableRecord:
            'DiscoveredPluginEntry: ${discoveryEntry.status.name}',
      );
    }

    return null;
  }

  PluginHealthStatus _deriveHealthStatus({
    required bool isRegistered,
    required PluginLifecycleState? currentLifecycleState,
    required PluginFailureDiagnostic? rootCause,
    required List<PermissionAuditRecord> permissionAudits,
    required List<PluginRecoveryActionRecord> recoveryActions,
  }) {
    if (recoveryActions
        .any((a) => a.status == PluginRecoveryStatus.orphanedRemoved)) {
      return PluginHealthStatus.orphaned;
    }
    if (rootCause?.stage == PluginFailureStage.permissionEnforcement ||
        permissionAudits.any((p) => !p.isGranted)) {
      return PluginHealthStatus.permissionViolated;
    }
    if (rootCause != null ||
        currentLifecycleState == PluginLifecycleState.initializationFailed ||
        currentLifecycleState == PluginLifecycleState.shutdownFailed ||
        currentLifecycleState == PluginLifecycleState.invalid) {
      return PluginHealthStatus.failed;
    }
    if (!isRegistered) {
      return PluginHealthStatus.unregistered;
    }
    return PluginHealthStatus.healthy;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. Rendering Layers (Pure Formatter with Unconditional Redaction)
  // ───────────────────────────────────────────────────────────────────────────

  /// Renders a per-plugin diagnostic report to human-readable Markdown.
  String renderPluginMarkdown(PluginInstanceDiagnostic diag) {
    final jsonMap = diag.toJson(); // Automatically applies redaction

    final buf = StringBuffer();
    buf.writeln('# Plugin Diagnostic Report: `${diag.pluginId}`');
    buf.writeln();
    buf.writeln(
        '**Health Status**: `${diag.healthStatus.name.toUpperCase()}`  ');
    buf.writeln('**Registered**: `${diag.isRegistered}`  ');
    buf.writeln(
        '**Current Lifecycle State**: `${diag.currentLifecycleState?.name ?? "none"}`');
    buf.writeln();

    // Section 1: Root Cause & Failure Analysis
    buf.writeln('## 1. Failure & Root Cause Diagnosis');
    if (diag.rootCause != null) {
      final rc = jsonMap['rootCause'] as Map<String, dynamic>;
      buf.writeln('- **Failed Stage**: `${rc["stage"]}`');
      buf.writeln('- **Reason**: ${rc["reason"]}');
      if (rc['missingPermission'] != null) {
        buf.writeln('- **Missing Permission**: `${rc["missingPermission"]}`');
      }
      if (rc['isTimeout'] == true) {
        buf.writeln('- **Timeout Encountered**: `true`');
      }
      if (rc['originalError'] != null) {
        buf.writeln('- **Original Error**: `${rc["originalError"]}`');
      }
      if (rc['attributableRecord'] != null) {
        buf.writeln('- **Attributable Record**: `${rc["attributableRecord"]}`');
      }
    } else {
      buf.writeln('No active failure or root-cause detected for this plugin.');
    }
    buf.writeln();

    // Section 2: Discovery & Registration
    buf.writeln('## 2. Discovery & Registration');
    if (diag.discoveryEntry != null) {
      final disc = jsonMap['discovery'] as Map<String, dynamic>;
      buf.writeln('- **Status**: `${disc["status"]}`');
      buf.writeln('- **Directory**: `${disc["directoryPath"]}`');
      buf.writeln('- **Manifest Path**: `${disc["manifestPath"]}`');
      if ((disc['details'] as List).isNotEmpty) {
        buf.writeln('- **Details**: ${(disc["details"] as List).join("; ")}');
      }
    } else {
      buf.writeln('No recorded discovery detail available for this stage.');
    }
    buf.writeln();

    // Section 3: Contract & Configuration Validation
    buf.writeln('## 3. Contract & Configuration Validation');
    if (diag.validationResult != null) {
      final val = jsonMap['validation'] as Map<String, dynamic>;
      buf.writeln('- **Contract Valid**: `${val["isValid"]}`');
      if ((val['violations'] as List).isNotEmpty) {
        buf.writeln('- **Contract Violations**:');
        for (final v in val['violations'] as List) {
          buf.writeln('  - $v');
        }
      }
    } else {
      buf.writeln(
          'No recorded contract validation detail available for this stage.');
    }

    if (diag.configValidationResult != null) {
      final cVal = jsonMap['configValidation'] as Map<String, dynamic>;
      buf.writeln('- **Configuration Valid**: `${cVal["isValid"]}`');
      if ((cVal['violations'] as List).isNotEmpty) {
        buf.writeln('- **Configuration Violations**:');
        for (final v in cVal['violations'] as List) {
          buf.writeln('  - $v');
        }
      }
    }

    if (jsonMap['configuration'] != null) {
      buf.writeln('- **Configuration (Redacted)**:');
      final configMap = jsonMap['configuration'] as Map<String, dynamic>;
      for (final entry in configMap.entries) {
        buf.writeln('  - `${entry.key}`: `${entry.value}`');
      }
    }
    buf.writeln();

    // Section 4: Dependency & Compatibility Resolution
    buf.writeln('## 4. Dependency & Compatibility Resolution');
    if (diag.dependencyResult != null) {
      final dep = jsonMap['dependencyResolution'] as Map<String, dynamic>;
      buf.writeln('- **Ecosystem Compatible**: `${dep["isCompatible"]}`');
      buf.writeln(
          '- **Topological Order**: ${(dep["initializationOrder"] as List).join(" -> ")}');
      if ((dep['findings'] as List).isNotEmpty) {
        buf.writeln('- **Findings**:');
        for (final f in dep['findings'] as List) {
          buf.writeln('  - [${f["type"]}] ${f["message"]}');
        }
      }
    } else {
      buf.writeln(
          'No recorded dependency resolution detail available for this stage.');
    }
    buf.writeln();

    // Section 5: Lifecycle Transition History
    buf.writeln('## 5. Lifecycle Transition History');
    final history = jsonMap['lifecycleHistory'] as List;
    if (history.isNotEmpty) {
      for (final h in history) {
        buf.writeln(
            '- `${h["timestamp"]}`: `${h["fromState"]}` -> `${h["toState"]}` (Reason: ${h["reason"]})');
      }
    } else {
      buf.writeln(
          'No recorded lifecycle transition history available for this stage.');
    }
    buf.writeln();

    // Section 6: Permissions & Security Audits
    buf.writeln('## 6. Permission & Security Audits');
    final perms = jsonMap['permissionAudits'] as List;
    if (perms.isNotEmpty) {
      for (final p in perms) {
        final status = p['isGranted'] == true ? 'GRANTED' : 'DENIED';
        buf.writeln(
            '- `${p["timestamp"]}` [$status] `${p["permissionName"]}` for `${p["operationAttempted"]}` (Reason: ${p["reason"]})');
      }
    } else {
      buf.writeln(
          'No recorded permission audit records available for this stage.');
    }
    buf.writeln();

    // Section 7: Execution Runtime History
    buf.writeln('## 7. Execution Runtime History');
    final execResults = jsonMap['executionResults'] as List;
    if (execResults.isNotEmpty) {
      for (final e in execResults) {
        buf.writeln(
            '- `${e["timestamp"]}` [${e["status"]}] `${e["operation"]}` in ${e["durationMs"]}ms${e["errorMessage"] != null ? " (Error: " + e["errorMessage"].toString() + ")" : ""}');
      }
    } else {
      buf.writeln(
          'No recorded execution runtime history available for this stage.');
    }
    buf.writeln();

    // Section 8: Persistence & Recovery State
    buf.writeln('## 8. Persistence & Recovery State');
    final recActions = jsonMap['recoveryActions'] as List;
    if (recActions.isNotEmpty) {
      buf.writeln('### Recovery Actions:');
      for (final r in recActions) {
        buf.writeln(
            '- `${r["timestamp"]}` [${r["status"]}]: ${r["actionTaken"]} (Reason: ${r["reason"]})');
      }
    } else {
      buf.writeln(
          'No recorded persistence recovery actions available for this stage.');
    }

    return buf.toString();
  }

  /// Renders a per-plugin diagnostic report to machine-readable JSON.
  String renderPluginJson(PluginInstanceDiagnostic diag) {
    return const JsonEncoder.withIndent('  ').convert(diag.toJson());
  }

  /// Renders a system-wide diagnostic summary to human-readable Markdown.
  String renderSystemMarkdown(PluginSystemDiagnosticSummary summary) {
    final jsonMap = summary.toJson();
    final s = jsonMap['summary'] as Map<String, dynamic>;

    final buf = StringBuffer();
    buf.writeln('# Plugin Ecosystem Diagnostic Summary');
    buf.writeln();
    buf.writeln('**Generated At**: `${jsonMap["generatedAt"]}`  ');
    buf.writeln('**Total Scanned**: `${s["totalScanned"]}`  ');
    buf.writeln('**Total Registered**: `${s["totalRegistered"]}`  ');
    buf.writeln();
    buf.writeln('## Triage Overview');
    buf.writeln('| Category | Count | Plugin IDs |');
    buf.writeln('|---|---|---|');
    buf.writeln(
        '| **Healthy** | ${s["healthyCount"]} | ${(s["healthyPluginIds"] as List).join(", ")} |');
    buf.writeln(
        '| **Failed** | ${s["failedCount"]} | ${(s["failedPluginIds"] as List).join(", ")} |');
    buf.writeln(
        '| **Permission Violated** | ${s["permissionViolatedCount"]} | ${(s["permissionViolatedPluginIds"] as List).join(", ")} |');
    buf.writeln(
        '| **Orphaned** | ${s["orphanedCount"]} | ${(s["orphanedPluginIds"] as List).join(", ")} |');
    buf.writeln();

    buf.writeln('## Detailed Plugin Status');
    final plugins = jsonMap['plugins'] as Map<String, dynamic>;
    if (plugins.isNotEmpty) {
      for (final entry in plugins.entries) {
        final p = entry.value as Map<String, dynamic>;
        buf.writeln('### `${entry.key}`');
        buf.writeln('- **Health**: `${p["healthStatus"]}`');
        buf.writeln(
            '- **Lifecycle**: `${p["currentLifecycleState"] ?? "none"}`');
        if (p['rootCause'] != null) {
          final rc = p['rootCause'] as Map<String, dynamic>;
          buf.writeln('- **Root Cause**: [${rc["stage"]}] ${rc["reason"]}');
        }
      }
    } else {
      buf.writeln('No plugins detected in the system.');
    }
    buf.writeln();

    if ((jsonMap['unassociatedDiscovery'] as List).isNotEmpty) {
      buf.writeln('## Unassociated / Invalid Discovery Entries');
      for (final u in jsonMap['unassociatedDiscovery'] as List) {
        buf.writeln(
            '- `${u["directoryPath"]}`: [${u["status"]}] ${(u["details"] as List).join("; ")}');
      }
    }

    return buf.toString();
  }

  /// Renders a system-wide diagnostic summary to machine-readable JSON.
  String renderSystemJson(PluginSystemDiagnosticSummary summary) {
    return const JsonEncoder.withIndent('  ').convert(summary.toJson());
  }
}
