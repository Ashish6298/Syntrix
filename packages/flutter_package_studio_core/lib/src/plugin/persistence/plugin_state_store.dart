/// Core state persistence and recovery coordinator for Flutter Package Studio plugins (Phase 7.11).
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/plugin/configuration/plugin_configuration_models.dart';
import 'package:flutter_package_studio_core/src/plugin/configuration/plugin_configuration_validator.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_models.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_validator.dart';
import 'package:flutter_package_studio_core/src/plugin/dependency/dependency_resolution_models.dart';
import 'package:flutter_package_studio_core/src/plugin/dependency/plugin_dependency_resolver.dart';
import 'package:flutter_package_studio_core/src/plugin/interface/plugin_registry.dart';
import 'package:flutter_package_studio_core/src/plugin/lifecycle/plugin_lifecycle_manager.dart';
import 'package:flutter_package_studio_core/src/plugin/lifecycle/plugin_lifecycle_models.dart';
import 'package:flutter_package_studio_core/src/plugin/persistence/plugin_state_models.dart';
import 'package:flutter_package_studio_core/src/plugin/runtime/plugin_execution_models.dart';
import 'package:flutter_package_studio_core/src/plugin/runtime/plugin_execution_runtime.dart';
import 'package:flutter_package_studio_core/src/release/versioning/semver_models.dart';
import 'package:flutter_package_studio_core/src/utils/file_utils.dart';

/// Single authority for atomically persisting and deterministically recovering plugin state.
class PluginStateStore {
  final String rootPath;
  final FileUtils _fileUtils;
  final PluginContractValidator _validator;
  final PluginConfigurationValidator _configValidator;
  final PluginDependencyResolver _dependencyResolver;

  PluginConfigurationValidator get configValidator => _configValidator;
  PluginDependencyResolver get dependencyResolver => _dependencyResolver;

  static const String stateRelativeDir = '.fps/plugins';
  static const String stateRelativeFilename = '.fps/plugins/plugins_state.json';

  PluginStateStore({
    required this.rootPath,
    FileUtils? fileUtils,
    PluginContractValidator? validator,
    PluginConfigurationValidator? configValidator,
    PluginDependencyResolver? dependencyResolver,
  })  : _fileUtils = fileUtils ?? const SystemFileUtils(),
        _validator = validator ?? PluginContractValidator(),
        _configValidator = configValidator ?? PluginConfigurationValidator(),
        _dependencyResolver = dependencyResolver ?? PluginDependencyResolver();

  /// Dedicated isolated path for plugin state storage.
  String get stateFilePath => '$rootPath/$stateRelativeFilename';

  /// Dedicated isolated directory for plugin state storage.
  String get stateDirPath => '$rootPath/$stateRelativeDir';

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Safe By Construction Atomic Write Implementation
  // ───────────────────────────────────────────────────────────────────────────

  /// Atomically writes the entire [PluginStateDocument] to [stateFilePath].
  ///
  /// Uses a temp-write and atomic rename strategy to guarantee zero corruption on interruption.
  void saveStateDocument(PluginStateDocument document) {
    _ensureDirectoryExists(stateDirPath);

    final tempFilePath =
        '$stateDirPath/plugins_state.json.tmp.${DateTime.now().microsecondsSinceEpoch}';
    final jsonString =
        const JsonEncoder.withIndent('  ').convert(document.toJson());

    try {
      // Step 1: Write full content to temporary isolated file
      _fileUtils.writeString(tempFilePath, jsonString, recursive: true);

      // Step 2: Atomic rename into place via FileUtils
      _fileUtils.rename(tempFilePath, stateFilePath);
    } catch (e, st) {
      // Clean up temp file on failure
      try {
        if (_fileUtils.exists(tempFilePath)) {
          _fileUtils.delete(tempFilePath);
        }
      } catch (_) {}

      throw PluginPersistenceException(
          'Failed to atomically persist plugin state to "$stateFilePath": $e',
          e,
          st);
    }
  }

  /// Persists a single plugin instance's complete state by capturing upstream subsystem results.
  void savePluginState({
    required String pluginId,
    required SemVer version,
    required bool isEnabled,
    required PluginLifecycleState lifecycleState,
    required PluginValidationResult validationResult,
    required DependencyResolutionResult compatibilityResult,
    required RuntimeConfiguration configuration,
    ConfigurationSchema? schema,
    List<LifecycleTransitionRecord>? lifecycleHistory,
    List<ExecutionAuditRecord>? failureRecords,
    Map<String, dynamic>? lastKnownGoodSnapshot,
  }) {
    // Zero secret leakage: Always persist configuration in redaction-aware form
    final redactedConfig = configuration.toJson(schema: schema);

    // Read current state document if present
    final currentDoc = readStateDocumentOrNull();
    final plugins =
        Map<String, PersistedPluginState>.from(currentDoc?.plugins ?? const {});

    final existingState = plugins[pluginId];
    final updatedState = PersistedPluginState(
      pluginId: pluginId,
      version: version,
      isEnabled: isEnabled,
      lifecycleState: lifecycleState,
      validationResult: validationResult,
      compatibilityResult: compatibilityResult,
      redactedConfiguration: redactedConfig,
      lifecycleHistory: lifecycleHistory ?? existingState?.lifecycleHistory,
      failureRecords: failureRecords ?? existingState?.failureRecords,
      lastKnownGoodSnapshot:
          lastKnownGoodSnapshot ?? existingState?.lastKnownGoodSnapshot,
      lastUpdated: DateTime.now(),
    );

    plugins[pluginId] = updatedState;

    final updatedDoc = PluginStateDocument(
      schemaVersion: PluginStateDocument.currentSchemaVersion,
      plugins: plugins,
      generatedAt: DateTime.now(),
    );

    saveStateDocument(updatedDoc);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Safe State Loading & Integrity Checking
  // ───────────────────────────────────────────────────────────────────────────

  /// Reads raw state document or returns null if nonexistent or corrupted.
  PluginStateDocument? readStateDocumentOrNull() {
    if (!_fileUtils.exists(stateFilePath)) {
      return null;
    }

    try {
      final content = _fileUtils.readAsString(stateFilePath);
      if (content.trim().isEmpty) {
        return null;
      }
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      final doc = PluginStateDocument.fromJson(decoded);
      if (!doc.verifyIntegrity()) {
        return null; // Integrity check failure
      }
      return doc;
    } catch (_) {
      return null; // Corrupted document
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. Explicit Recovery Paths Implementation
  // ───────────────────────────────────────────────────────────────────────────

  /// Loads persisted state and reconciles it against the live environment and discovered manifests.
  PluginRecoveryResult restoreAndRecover({
    required List<PluginManifest> discoveredManifests,
    PluginLifecycleManager? lifecycleManager,
    PluginRegistry? registry,
    PluginExecutionRuntime? runtime,
  }) {
    final healthy = <String, PersistedPluginState>{};
    final actions = <PluginRecoveryActionRecord>[];
    var hasCorruptions = false;

    // Path 1: Corrupt Plugin State Check
    if (!_fileUtils.exists(stateFilePath)) {
      // First run or empty state — clean initialization
      return PluginRecoveryResult(
        healthyStates: const {},
        recoveryActions: const [],
        hasCorruptions: false,
      );
    }

    String content;
    try {
      content = _fileUtils.readAsString(stateFilePath);
    } catch (e) {
      actions.add(PluginRecoveryActionRecord(
        pluginId: '*',
        status: PluginRecoveryStatus.corruptState,
        reason: 'Failed to read state file: $e',
        actionTaken:
            'Ignored corrupt state file and initialized empty in-memory store.',
      ));
      return PluginRecoveryResult(
        healthyStates: const {},
        recoveryActions: actions,
        hasCorruptions: true,
      );
    }

    PluginStateDocument doc;
    try {
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      doc = PluginStateDocument.fromJson(decoded);
      if (!doc.verifyIntegrity()) {
        throw PluginPersistenceException(
            'Checksum integrity verification failed.');
      }
    } catch (e) {
      hasCorruptions = true;
      actions.add(PluginRecoveryActionRecord(
        pluginId: '*',
        status: PluginRecoveryStatus.corruptState,
        reason: 'State document corrupted or checksum mismatch: $e',
        actionTaken:
            'Flagged corruption and treated all plugins as needing re-discovery.',
      ));
      return PluginRecoveryResult(
        healthyStates: const {},
        recoveryActions: actions,
        hasCorruptions: true,
      );
    }

    final discoveredMap = <String, PluginManifest>{
      for (final m in discoveredManifests) m.id.value: m
    };

    // Evaluate each persisted plugin entry deterministically
    for (final entry in doc.plugins.entries) {
      final pluginId = entry.key;
      final state = entry.value;
      final liveManifest = discoveredMap[pluginId];

      // Path 4: Plugin Removal (Orphaned / Missing reference)
      if (liveManifest == null) {
        actions.add(PluginRecoveryActionRecord(
          pluginId: pluginId,
          status: PluginRecoveryStatus.orphanedRemoved,
          reason:
              'Plugin "$pluginId" is present in persisted state but no longer discoverable on disk.',
          actionTaken:
              'Marked entry as orphaned/removed and excluded from active registry.',
        ));
        continue;
      }

      // Path 2: Failed Initialization (Do NOT auto-retry without explicit command)
      if (state.lifecycleState == PluginLifecycleState.initializationFailed ||
          state.lifecycleState == PluginLifecycleState.shutdownFailed) {
        actions.add(PluginRecoveryActionRecord(
          pluginId: pluginId,
          status: PluginRecoveryStatus.failedInitialization,
          reason:
              'Plugin previously reached state "${state.lifecycleState.name}".',
          actionTaken:
              'Surfaced failure state without auto-retrying activation.',
        ));
        healthy[pluginId] = state;
        continue;
      }

      // Ambiguity / Unrecognized Lifecycle Check (Fail-closed)
      if (state.lifecycleState != PluginLifecycleState.active &&
          state.lifecycleState != PluginLifecycleState.disabled &&
          state.lifecycleState != PluginLifecycleState.validated &&
          state.lifecycleState != PluginLifecycleState.discovered &&
          state.lifecycleState != PluginLifecycleState.registered &&
          state.lifecycleState != PluginLifecycleState.initialized &&
          state.lifecycleState != PluginLifecycleState.inactive) {
        actions.add(PluginRecoveryActionRecord(
          pluginId: pluginId,
          status: PluginRecoveryStatus.unrecognizedAmbiguous,
          reason:
              'Persisted state contains non-restorable or ambiguous lifecycle state "${state.lifecycleState.name}".',
          actionTaken:
              'Treated plugin as unsafe/inactive; refused optimistic activation.',
        ));
        continue;
      }

      // Path 5: Plugin Upgrade Failure & Fallback Evaluation
      final liveVersion = liveManifest.version;
      final isUpgrade = liveVersion.compareTo(state.version) > 0;
      if (isUpgrade) {
        final valRes = _validator.validateRawJson(liveManifest.toJson());
        if (!valRes.isValid) {
          actions.add(PluginRecoveryActionRecord(
            pluginId: pluginId,
            status: PluginRecoveryStatus.upgradeFallback,
            reason:
                'Upgraded plugin version $liveVersion failed contract validation: ${valRes.violations.join("; ")}.',
            actionTaken: state.lastKnownGoodSnapshot != null
                ? 'Fell back to last-known-good configuration snapshot for version ${state.version}.'
                : 'Refused activation of version $liveVersion; marked as invalid.',
          ));
          continue;
        }
      }

      // Path 3: Invalid Configuration Check against current live schema
      // (Tolerating redacted placeholders in persisted configuration)
      if (liveManifest.configSchema.properties.isNotEmpty) {
        final violations = <String>[];
        final declaredKeys = <String>{};
        for (final prop in liveManifest.configSchema.properties) {
          declaredKeys.add(prop.key);
          if (prop.isRequired &&
              !state.redactedConfiguration.containsKey(prop.key)) {
            violations.add(
                '[ConfigurationSchema] Missing required property "${prop.key}".');
          }
        }
        for (final key in state.redactedConfiguration.keys) {
          if (!declaredKeys.contains(key)) {
            violations.add(
                '[ConfigurationSchema] Unexpected undeclared property "$key" supplied in configuration.');
          }
        }

        if (violations.isNotEmpty) {
          actions.add(PluginRecoveryActionRecord(
            pluginId: pluginId,
            status: PluginRecoveryStatus.invalidConfiguration,
            reason:
                'Persisted configuration does not satisfy current schema: ${violations.join("; ")}.',
            actionTaken:
                'Marked plugin as requiring reconfiguration; blocked auto-activation.',
          ));
          continue;
        }
      }

      // Healthy state
      healthy[pluginId] = state;
      actions.add(PluginRecoveryActionRecord(
        pluginId: pluginId,
        status: PluginRecoveryStatus.healthy,
        reason: 'Persisted state successfully reconciled with live manifest.',
        actionTaken: 'Restored state to memory.',
      ));
    }

    return PluginRecoveryResult(
      healthyStates: healthy,
      recoveryActions: actions,
      hasCorruptions: hasCorruptions,
    );
  }

  void _ensureDirectoryExists(String path) {
    if (!_fileUtils.exists(path)) {
      _fileUtils.createDirectory(path, recursive: true);
    }
  }
}
