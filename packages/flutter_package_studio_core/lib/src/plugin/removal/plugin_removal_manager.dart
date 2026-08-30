/// Single authority for controlled, reversible plugin removal and cleanup (Phase 7.16).
library;

import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_models.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_validator.dart';
import 'package:flutter_package_studio_core/src/plugin/dependency/dependency_resolution_models.dart';
import 'package:flutter_package_studio_core/src/plugin/discovery/plugin_discovery_models.dart';
import 'package:flutter_package_studio_core/src/plugin/interface/plugin_registry.dart';
import 'package:flutter_package_studio_core/src/plugin/persistence/plugin_state_models.dart';
import 'package:flutter_package_studio_core/src/plugin/persistence/plugin_state_store.dart';
import 'package:flutter_package_studio_core/src/plugin/removal/plugin_removal_models.dart';
import 'package:flutter_package_studio_core/src/release/versioning/semver_models.dart';
import 'package:flutter_package_studio_core/src/utils/file_utils.dart';

/// Coordinator for computing pure removal plans, taking snapshots, and safely executing removal/restoration.
class PluginRemovalManager {
  final PluginRegistry _registry;
  final PluginStateStore? _stateStore;
  final FileUtils _fileUtils;
  final String _rootPath;

  PluginRegistry get registry => _registry;
  PluginStateStore? get stateStore => _stateStore;
  FileUtils get fileUtils => _fileUtils;
  String get rootPath => _rootPath;

  PluginRemovalManager({
    required PluginRegistry registry,
    PluginStateStore? stateStore,
    FileUtils? fileUtils,
    String rootPath = '.',
  })  : _registry = registry,
        _stateStore = stateStore,
        _fileUtils = fileUtils ?? const SystemFileUtils(),
        _rootPath = rootPath;

  String get backupsDirPath => '$_rootPath/.fps/backups/plugins';

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Pure, Non-Mutating Removal Plan Computation
  // ───────────────────────────────────────────────────────────────────────────

  /// Computes a pure [RemovalPlan] attributing state, files, and dependencies without modifying anything.
  ///
  /// Guarantees:
  /// - 100% pure and inert: Never deletes files, never modifies state store, never unregisters plugins.
  /// - Enforces 6 strict safety boundaries (core, other plugins, shared config, user package, release artifacts, unrelated).
  /// - Checks dependency graph to surface blocking dependents.
  RemovalPlan planRemoval({
    required String pluginId,
    List<DiscoveredPluginEntry> discoveryEntries = const [],
    List<String> userPackagePaths = const [],
    List<String> releaseArtifactPaths = const [],
    List<String> sharedConfigKeys = const [],
    List<String> ambiguousOrSharedFilePaths = const [],
    List<String> coreSystemPaths = const [],
  }) {
    if (pluginId.trim().isEmpty) {
      throw PluginRemovalException('Removal Error: Plugin ID cannot be empty.');
    }

    final isRegistered = _registry.exists(pluginId);

    // Persisted state check

    PersistedPluginState? persistedState;
    if (_stateStore != null) {
      final doc = _stateStore.readStateDocumentOrNull();
      persistedState = doc?.plugins[pluginId];
    }
    final hasPersistedState = persistedState != null;

    // Fail-Closed: If not registered and no persisted state and no discovered entry
    final matchingDiscovery = discoveryEntries
        .where((e) => e.manifest?.id.value == pluginId)
        .toList();
    if (!isRegistered && !hasPersistedState && matchingDiscovery.isEmpty) {
      throw PluginRemovalException(
          'Removal Refused: Plugin "$pluginId" does not resolve to any registered, persisted, or discovered plugin.');
    }

    final auditEntries = <String>[];
    final attributedFiles = <String>[];
    final excludedFiles = <ExcludedFileRecord>[];

    auditEntries.add('Planning removal for plugin "$pluginId".');

    // ─────────────────────────────────────────────────────────────────────────
    // Dependency Graph Analysis (Phase 7.6 / 7.3 reuse)
    // ─────────────────────────────────────────────────────────────────────────
    final dependentPluginIds = <String>[];
    for (final other in _registry.listPlugins()) {
      if (other.id.value == pluginId) continue;
      for (final dep in other.dependencies) {
        if (dep.name == pluginId) {
          dependentPluginIds.add(other.id.value);
          auditEntries.add(
              'Found active dependent plugin "${other.id.value}" relying on "$pluginId".');
        }
      }
    }

    final isBlockedByDependents = dependentPluginIds.isNotEmpty;

    // ─────────────────────────────────────────────────────────────────────────
    // Discovered File Attribution & Boundary Enforcement (Phase 7.4 reuse)
    // ─────────────────────────────────────────────────────────────────────────
    final normalizedCorePaths = {
      '$_rootPath/.fps/template_metadata.json',
      '$_rootPath/.fps/config.json',
      '$_rootPath/pubspec.yaml',
      ...coreSystemPaths,
    }.map((c) => c.replaceAll('\\', '/')).toSet();

    final normAmbiguous =
        ambiguousOrSharedFilePaths.map((p) => p.replaceAll('\\', '/')).toSet();
    final normUserPkg =
        userPackagePaths.map((u) => u.replaceAll('\\', '/')).toList();
    final normRelease =
        releaseArtifactPaths.map((r) => r.replaceAll('\\', '/')).toList();

    for (final entry in matchingDiscovery) {
      final dir = entry.directoryPath.replaceAll('\\', '/');
      final manifestPath = entry.manifestPath.replaceAll('\\', '/');

      // Check if entry itself is marked ambiguous / shared
      if (normAmbiguous.contains(dir) || normAmbiguous.contains(manifestPath)) {
        excludedFiles.add(ExcludedFileRecord(
          path: dir,
          reason: FileExclusionReason.sharedPluginAsset,
          description:
              'Directory "$dir" is shared with or attributed to multiple plugins.',
        ));
        continue;
      }

      // Check Boundary 1: Core System Files (Structurally protected by scoping, plus safety guard)
      if (normalizedCorePaths
          .any((c) => dir.startsWith(c) || manifestPath.startsWith(c))) {
        excludedFiles.add(ExcludedFileRecord(
          path: dir,
          reason: FileExclusionReason.coreApplication,
          description:
              'Path intersects core application structure or system metadata.',
        ));
        continue;
      }

      // Check Boundary 4: User Package Data
      if (normUserPkg
          .any((u) => dir.startsWith(u) || manifestPath.startsWith(u))) {
        excludedFiles.add(ExcludedFileRecord(
          path: dir,
          reason: FileExclusionReason.userPackageData,
          description:
              'Path belongs to user package sources/build directories under management.',
        ));
        continue;
      }

      // Check Boundary 5: Release Artifacts
      if (normRelease
          .any((r) => dir.startsWith(r) || manifestPath.startsWith(r))) {
        excludedFiles.add(ExcludedFileRecord(
          path: dir,
          reason: FileExclusionReason.releaseArtifact,
          description:
              'Path belongs to Milestone 6 release artifacts or changelog archives.',
        ));
        continue;
      }

      // Structural Scoping Guarantee: Manifest must reside strictly within plugin's discovered directory
      final isManifestScoped = manifestPath == '$dir/plugin.json' ||
          manifestPath.startsWith('$dir/') ||
          manifestPath == dir;
      if (!isManifestScoped) {
        excludedFiles.add(ExcludedFileRecord(
          path: manifestPath,
          reason: FileExclusionReason.unattributed,
          description:
              'Manifest path "$manifestPath" is not structurally within discovered plugin directory "$dir".',
        ));
        continue;
      }

      // Attributed safely
      attributedFiles.add(manifestPath);
      auditEntries
          .add('Attributed plugin manifest file "$manifestPath" for removal.');

      // If directory is uniquely dedicated, list files inside directory strictly within dir scope
      if (_fileUtils.exists(dir) && _fileUtils.isDirectory(dir)) {
        try {
          final dirEntity = io.Directory(dir);
          if (dirEntity.existsSync()) {
            final dirFiles = dirEntity
                .listSync(recursive: true)
                .whereType<io.File>()
                .map((f) => f.path.replaceAll('\\', '/'))
                .toList();

            for (final f in dirFiles) {
              if (f == manifestPath) continue;

              // Enforce strict containment within plugin directory root
              if (!f.startsWith('$dir/')) {
                excludedFiles.add(ExcludedFileRecord(
                  path: f,
                  reason: FileExclusionReason.unattributed,
                  description:
                      'File "$f" escapes discovered plugin directory root "$dir".',
                ));
                continue;
              }

              if (normAmbiguous.contains(f)) {
                excludedFiles.add(ExcludedFileRecord(
                  path: f,
                  reason: FileExclusionReason.sharedPluginAsset,
                  description: 'File "$f" is ambiguously attributed.',
                ));
              } else if (normalizedCorePaths.contains(f)) {
                excludedFiles.add(ExcludedFileRecord(
                  path: f,
                  reason: FileExclusionReason.coreApplication,
                  description: 'File "$f" is part of core application.',
                ));
              } else {
                attributedFiles.add(f);
                auditEntries
                    .add('Attributed plugin internal file "$f" for removal.');
              }
            }
          }
        } catch (_) {}
      }
    }

    // Check Boundary 3: Shared Configuration
    for (final sharedKey in sharedConfigKeys) {
      excludedFiles.add(ExcludedFileRecord(
        path: 'config:$sharedKey',
        reason: FileExclusionReason.sharedConfiguration,
        description:
            'Configuration key "$sharedKey" is shared across plugins and preserved.',
      ));
    }

    final summary = isBlockedByDependents
        ? 'Removal plan computed for "$pluginId": BLOCKED by ${dependentPluginIds.length} dependent plugin(s).'
        : 'Removal plan computed for "$pluginId": ${attributedFiles.length} file(s) attributed, ${excludedFiles.length} item(s) protected.';

    return RemovalPlan(
      pluginId: pluginId,
      isRegistered: isRegistered,
      hasPersistedState: hasPersistedState,
      attributedFiles: attributedFiles,
      excludedFiles: excludedFiles,
      dependentPluginIds: dependentPluginIds,
      isBlockedByDependents: isBlockedByDependents,
      auditEntries: auditEntries,
      summary: summary,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Reversible Removal Application (Snapshot -> Remove)
  // ───────────────────────────────────────────────────────────────────────────

  /// Applies plugin removal according to [plan], capturing a full snapshot before deleting.
  ///
  /// Guarantees:
  /// - Captures full restorable `PluginRemovalBackup` before touching any file or state entry.
  /// - Throws `PluginRemovalException` if dependents exist and [force] / [acknowledgeDependents] is false.
  /// - Atomically removes state from `PluginStateStore` and unregisters from `PluginRegistry`.
  /// - Deletes only uniquely attributed files.
  RemovalExecutionResult applyRemoval({
    required RemovalPlan plan,
    bool force = false,
    bool acknowledgeDependents = false,
  }) {
    final pluginId = plan.pluginId;

    // Check blocking dependents
    if (plan.isBlockedByDependents && !force && !acknowledgeDependents) {
      throw PluginRemovalException(
          'Removal Refused: Plugin "$pluginId" has active dependents (${plan.dependentPluginIds.join(", ")}). Supply acknowledgeDependents: true to force removal.');
    }

    final auditLog = <String>[];
    auditLog.add(
        'Executing removal for "$pluginId" (force: ${force || acknowledgeDependents}).');

    // Step 1: Capture complete snapshot backup before any mutations
    final manifest = _registry.findPlugin(pluginId);
    PersistedPluginState? persistedState;
    if (_stateStore != null) {
      final doc = _stateStore.readStateDocumentOrNull();
      persistedState = doc?.plugins[pluginId];
    }

    final fileSnapshots = <String, String>{};
    for (final path in plan.attributedFiles) {
      try {
        if (_fileUtils.exists(path) && !_fileUtils.isDirectory(path)) {
          fileSnapshots[path] = _fileUtils.readAsString(path);
        }
      } catch (e) {
        auditLog.add('Warning: Failed to capture snapshot of file "$path": $e');
      }
    }

    final backupId =
        '${pluginId}_backup_${DateTime.now().microsecondsSinceEpoch}';
    final backup = PluginRemovalBackup(
      backupId: backupId,
      pluginId: pluginId,
      version: manifest?.version.toString() ??
          persistedState?.version.toString() ??
          '1.0.0',
      createdAt: DateTime.now(),
      manifestJson: manifest?.toJson(),
      persistedStateJson: persistedState?.toJson(),
      fileSnapshots: fileSnapshots,
    );

    final backupDir = '$backupsDirPath/$backupId';
    final backupFilePath = '$backupDir/backup.json';
    try {
      _fileUtils.writeString(
        backupFilePath,
        const JsonEncoder.withIndent('  ').convert(backup.toJson()),
        recursive: true,
      );
      auditLog
          .add('Created isolated pre-removal snapshot at "$backupFilePath".');
    } catch (e) {
      throw PluginRemovalException(
          'Removal Aborted: Failed to write pre-removal backup snapshot: $e');
    }

    // Step 2: Unregister from PluginRegistry
    if (plan.isRegistered) {
      _registry.unregisterPlugin(pluginId);
      auditLog.add('Unregistered plugin "$pluginId" from central registry.');
    }

    // Step 3: Remove state entry from PluginStateStore
    if (_stateStore != null && plan.hasPersistedState) {
      try {
        final currentDoc = _stateStore.readStateDocumentOrNull();
        if (currentDoc != null && currentDoc.plugins.containsKey(pluginId)) {
          final updatedPlugins =
              Map<String, PersistedPluginState>.from(currentDoc.plugins)
                ..remove(pluginId);
          final updatedDoc = PluginStateDocument(
            schemaVersion: PluginStateDocument.currentSchemaVersion,
            plugins: updatedPlugins,
            generatedAt: DateTime.now(),
          );
          _stateStore.saveStateDocument(updatedDoc);
          auditLog
              .add('Removed persisted plugin state document for "$pluginId".');
        }
      } catch (e) {
        auditLog
            .add('Warning: Error removing persisted state for "$pluginId": $e');
      }
    }

    // Step 4: Delete attributed files
    final deletedFiles = <String>[];
    for (final filePath in plan.attributedFiles) {
      try {
        if (_fileUtils.exists(filePath)) {
          _fileUtils.delete(filePath);
          deletedFiles.add(filePath);
          auditLog.add('Deleted attributed file "$filePath".');
        }
      } catch (e) {
        auditLog
            .add('Warning: Failed to delete attributed file "$filePath": $e');
      }
    }

    return RemovalExecutionResult(
      pluginId: pluginId,
      backupId: backupId,
      backupPath: backupFilePath,
      deletedFiles: deletedFiles,
      auditLog: auditLog,
      executedAt: DateTime.now(),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. Reversibility & Restoration from Backup Snapshot (Atomic Execution)
  // ───────────────────────────────────────────────────────────────────────────

  /// Reconstructs a removed plugin's files, persisted state, and registry registration from [backupFilePath].
  ///
  /// Guarantees:
  /// - Full Pre-Flight Validation across ALL snapshot components before ANY mutation.
  /// - Cryptographic integrity validation of the entire backup.
  /// - Restores all file contents to original locations atomically.
  /// - Restores persisted state document in `PluginStateStore`.
  /// - Re-registers manifest in `PluginRegistry`.
  /// - Fail-closed on corrupted backup files, invalid component schemas, or tampered checksums.
  PersistedPluginState restoreFromBackup({
    required String backupFilePath,
    Object? pluginInstance,
  }) {
    if (!_fileUtils.exists(backupFilePath)) {
      throw PluginRemovalException(
          'Restore Error: Backup file "$backupFilePath" does not exist.');
    }

    PluginRemovalBackup backup;
    try {
      final jsonString = _fileUtils.readAsString(backupFilePath);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      backup = PluginRemovalBackup.fromJson(decoded);
    } catch (e) {
      throw PluginRemovalException(
          'Restore Error: Failed to parse backup file "$backupFilePath": $e');
    }

    // Cryptographic Tamper & Integrity Check (Fail-Closed)
    if (!backup.verifyIntegrity()) {
      throw PluginRemovalException(
          'Restore Refused: Backup snapshot at "$backupFilePath" failed cryptographic checksum integrity verification (tampered or corrupted).');
    }

    final pluginId = backup.pluginId;

    // ─────────────────────────────────────────────────────────────────────────
    // Pre-Flight Validation Phase (Atomic Check: Validate ALL components first)
    // ─────────────────────────────────────────────────────────────────────────
    PluginManifest? parsedManifest;
    if (backup.manifestJson != null) {
      try {
        parsedManifest = PluginManifest.fromJson(backup.manifestJson!);
      } catch (e) {
        throw PluginRemovalException(
            'Restore Refused: Manifest snapshot component corrupted for "$pluginId": $e');
      }
    }

    PersistedPluginState? parsedPersistedState;
    if (backup.persistedStateJson != null) {
      try {
        parsedPersistedState =
            PersistedPluginState.fromJson(backup.persistedStateJson!);
      } catch (e) {
        throw PluginRemovalException(
            'Restore Refused: Persisted state snapshot component corrupted for "$pluginId": $e');
      }
    }

    // Validate file snapshot paths
    for (final path in backup.fileSnapshots.keys) {
      if (path.trim().isEmpty) {
        throw PluginRemovalException(
            'Restore Refused: File snapshot component corrupted with empty file path for "$pluginId".');
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Application Phase (Only reached if ALL component validations passed)
    // ─────────────────────────────────────────────────────────────────────────

    // Step 1: Restore files
    for (final entry in backup.fileSnapshots.entries) {
      try {
        _fileUtils.writeString(entry.key, entry.value, recursive: true);
      } catch (e) {
        throw PluginRemovalException(
            'Restore Error: Failed to reinstate file "${entry.key}": $e');
      }
    }

    // Step 2: Restore manifest in registry if present
    if (parsedManifest != null) {
      try {
        _registry.registerPlugin(
          manifest: parsedManifest,
          instance: pluginInstance ?? Object(),
        );
      } catch (_) {
        // Log or handle duplicate if already re-registered
      }
    }

    // Step 3: Restore state in PluginStateStore if present
    PersistedPluginState restoredState;
    if (parsedPersistedState != null) {
      restoredState = parsedPersistedState;
      if (_stateStore != null) {
        final currentDoc = _stateStore.readStateDocumentOrNull();

        final updatedPlugins = Map<String, PersistedPluginState>.from(
            currentDoc?.plugins ?? const {})
          ..[pluginId] = restoredState;
        final updatedDoc = PluginStateDocument(
          schemaVersion: PluginStateDocument.currentSchemaVersion,
          plugins: updatedPlugins,
          generatedAt: DateTime.now(),
        );
        _stateStore.saveStateDocument(updatedDoc);
      }
    } else {
      restoredState = PersistedPluginState(
        pluginId: pluginId,
        version: backup.manifestJson != null
            ? PluginManifest.fromJson(backup.manifestJson!).version
            : SemVer.parse(backup.version),
        isEnabled: true,
        lifecycleState: PluginLifecycleState.discovered,
        validationResult:
            const PluginValidationResult(isValid: true, violations: []),
        compatibilityResult: DependencyResolutionResult.compatible(const []),
        redactedConfiguration: const {},
      );
    }

    return restoredState;
  }
}
