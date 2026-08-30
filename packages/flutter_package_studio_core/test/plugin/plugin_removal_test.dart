import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

class MockCommandPlugin implements CommandContribution {
  @override
  List<String> getCommands() => ['test-command'];
}

void main() {
  group('Plugin Removal & Cleanup Manager Tests (Phase 7.16)', () {
    late io.Directory tempDir;
    late PluginRegistry registry;
    late PluginStateStore stateStore;
    late PluginRemovalManager removalManager;

    setUp(() {
      tempDir = io.Directory.systemTemp.createTempSync('plugin_removal_test_');
      final validator = PluginContractValidator();
      final configValidator = PluginConfigurationValidator();
      registry = PluginRegistry(validator: validator);
      stateStore = PluginStateStore(
        rootPath: tempDir.path,
        validator: validator,
        configValidator: configValidator,
      );
      removalManager = PluginRemovalManager(
        registry: registry,
        stateStore: stateStore,
        rootPath: tempDir.path,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    PluginManifest createManifest({
      String id = 'sample_plugin',
      String version = '1.0.0',
      List<PluginDependency> dependencies = const [],
    }) {
      return PluginManifest(
        id: PluginId(id),
        name: PluginName('Plugin $id'),
        description: PluginDescription('Plugin $id description.'),
        version: SemVer.parse(version),
        author: const PluginAuthor(name: 'FPS Core Team'),
        apiVersion: '1.0.0',
        capabilities: const {PluginCapability.commandContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
        dependencies: dependencies,
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Happy-path removal plan & execution test
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '1. Happy path: cleanly-attributed dependency-free plugin removal plan and execution succeeds completely',
        () {
      final manifest = createManifest(id: 'clean_plugin');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      // Save persisted state
      stateStore.savePluginState(
        pluginId: 'clean_plugin',
        version: SemVer.parse('1.0.0'),
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult:
            const PluginValidationResult(isValid: true, violations: []),
        compatibilityResult: DependencyResolutionResult.compatible(const []),
        configuration: RuntimeConfiguration({'setting': 'val'}),
      );

      // Create discovered files
      final pluginDir = io.Directory('${tempDir.path}/plugins/clean_plugin')
        ..createSync(recursive: true);
      final manifestFile = io.File('${pluginDir.path}/plugin.json')
        ..writeAsStringSync(jsonEncode(manifest.toJson()));
      final helperFile = io.File('${pluginDir.path}/lib/helper.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('void help() {}');

      final discoveryEntry = DiscoveredPluginEntry(
        directoryPath: pluginDir.path,
        manifestPath: manifestFile.path,
        status: DiscoveredPluginStatus.valid,
        manifest: manifest,
        details: const [],
      );

      // 1. Plan removal
      final plan = removalManager.planRemoval(
        pluginId: 'clean_plugin',
        discoveryEntries: [discoveryEntry],
      );

      expect(plan.pluginId, equals('clean_plugin'));
      expect(plan.isRegistered, isTrue);
      expect(plan.hasPersistedState, isTrue);
      expect(plan.isBlockedByDependents, isFalse);
      expect(plan.attributedFiles,
          contains(manifestFile.path.replaceAll('\\', '/')));
      expect(plan.attributedFiles,
          contains(helperFile.path.replaceAll('\\', '/')));

      // 2. Apply removal
      final result = removalManager.applyRemoval(plan: plan);
      expect(result.pluginId, equals('clean_plugin'));
      expect(result.deletedFiles,
          contains(manifestFile.path.replaceAll('\\', '/')));
      expect(
          result.deletedFiles, contains(helperFile.path.replaceAll('\\', '/')));

      // 3. Verify side-effects
      expect(manifestFile.existsSync(), isFalse);
      expect(helperFile.existsSync(), isFalse);
      expect(registry.exists('clean_plugin'), isFalse);

      final docAfter = stateStore.readStateDocumentOrNull()!;
      expect(docAfter.plugins.containsKey('clean_plugin'), isFalse);
      expect(io.File(result.backupPath).existsSync(), isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: 6 Named Adversarial Boundary Tests
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2a. Adversarial Boundary: Shared/ambiguous directory or file with another plugin is excluded from deletion',
        () {
      final manifest = createManifest(id: 'plugin_a');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      final sharedDir = io.Directory('${tempDir.path}/shared_bundle')
        ..createSync(recursive: true);
      final sharedManifestFile = io.File('${sharedDir.path}/plugin.json')
        ..writeAsStringSync(jsonEncode(manifest.toJson()));

      final discoveryEntry = DiscoveredPluginEntry(
        directoryPath: sharedDir.path,
        manifestPath: sharedManifestFile.path,
        status: DiscoveredPluginStatus.valid,
        manifest: manifest,
        details: const [],
      );

      final plan = removalManager.planRemoval(
        pluginId: 'plugin_a',
        discoveryEntries: [discoveryEntry],
        ambiguousOrSharedFilePaths: [sharedDir.path, sharedManifestFile.path],
      );

      expect(plan.attributedFiles, isEmpty);
      expect(
          plan.excludedFiles
              .any((e) => e.reason == FileExclusionReason.sharedPluginAsset),
          isTrue);
    });

    test(
        '2b. Adversarial Boundary: Shared configuration key used by another plugin/core is excluded from deletion',
        () {
      final manifest = createManifest(id: 'configured_plugin');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      final plan = removalManager.planRemoval(
        pluginId: 'configured_plugin',
        sharedConfigKeys: ['globalRegistryUrl', 'loggingLevel'],
      );

      expect(
          plan.excludedFiles.any((e) =>
              e.reason == FileExclusionReason.sharedConfiguration &&
              e.path == 'config:globalRegistryUrl'),
          isTrue);
      expect(
          plan.excludedFiles.any((e) =>
              e.reason == FileExclusionReason.sharedConfiguration &&
              e.path == 'config:loggingLevel'),
          isTrue);
    });

    test(
        '2c. Adversarial Boundary: Core application files and metadata (.fps/template_metadata.json) are structurally impossible to remove',
        () {
      final manifest = createManifest(id: 'rogue_core_plugin');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      final coreMetaPath = '${tempDir.path}/.fps/template_metadata.json';
      final coreConfigPath = '${tempDir.path}/.fps/config.json';

      final rogueDiscovery = DiscoveredPluginEntry(
        directoryPath: '${tempDir.path}/.fps',
        manifestPath: coreMetaPath,
        status: DiscoveredPluginStatus.valid,
        manifest: manifest,
        details: const [],
      );

      final plan = removalManager.planRemoval(
        pluginId: 'rogue_core_plugin',
        discoveryEntries: [rogueDiscovery],
        coreSystemPaths: [coreMetaPath, coreConfigPath],
      );

      expect(plan.attributedFiles, isEmpty);
      expect(
          plan.excludedFiles
              .any((e) => e.reason == FileExclusionReason.coreApplication),
          isTrue);
    });

    test(
        '2d. Adversarial Boundary: User package files under management (pubspec.yaml, lib/, test/) are never included in removal plan',
        () {
      final manifest = createManifest(id: 'rogue_user_pkg_plugin');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      final userPkgLib = '${tempDir.path}/lib/my_package.dart';
      final userPubspec = '${tempDir.path}/pubspec.yaml';

      final rogueDiscovery = DiscoveredPluginEntry(
        directoryPath: '${tempDir.path}/lib',
        manifestPath: userPkgLib,
        status: DiscoveredPluginStatus.valid,
        manifest: manifest,
        details: const [],
      );

      final plan = removalManager.planRemoval(
        pluginId: 'rogue_user_pkg_plugin',
        discoveryEntries: [rogueDiscovery],
        userPackagePaths: [userPkgLib, userPubspec],
      );

      expect(plan.attributedFiles, isEmpty);
      expect(
          plan.excludedFiles
              .any((e) => e.reason == FileExclusionReason.userPackageData),
          isTrue);
    });

    test(
        '2e. Adversarial Boundary: Milestone 6 release artifacts (changelogs, git tags, GitHub releases) are never touched by removal',
        () {
      final manifest = createManifest(id: 'release_encroaching_plugin');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      final changelogPath = '${tempDir.path}/doc/release/CHANGELOG.md';
      final releaseManifestPath =
          '${tempDir.path}/doc/release/release_manifest.json';

      final releaseDiscovery = DiscoveredPluginEntry(
        directoryPath: '${tempDir.path}/doc/release',
        manifestPath: releaseManifestPath,
        status: DiscoveredPluginStatus.valid,
        manifest: manifest,
        details: const [],
      );

      final plan = removalManager.planRemoval(
        pluginId: 'release_encroaching_plugin',
        discoveryEntries: [releaseDiscovery],
        releaseArtifactPaths: [changelogPath, releaseManifestPath],
      );

      expect(plan.attributedFiles, isEmpty);
      expect(
          plan.excludedFiles
              .any((e) => e.reason == FileExclusionReason.releaseArtifact),
          isTrue);
    });

    test(
        '2f. Adversarial Boundary: Unrelated unattributed files are excluded by default (fail-closed)',
        () {
      final manifest = createManifest(id: 'unrelated_test_plugin');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      final plan = removalManager.planRemoval(
        pluginId: 'unrelated_test_plugin',
        discoveryEntries: const [], // Zero discovery matches
      );

      expect(plan.attributedFiles, isEmpty);
      expect(plan.summary, contains('0 file(s) attributed'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Blocking-dependents enforcement tests
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '3a. Blocking dependents: applyRemoval refuses by default when another registered plugin depends on target',
        () {
      final targetManifest = createManifest(id: 'target_base_plugin');
      final dependentManifest = createManifest(
        id: 'consumer_plugin',
        dependencies: [
          PluginDependency(
              name: 'target_base_plugin', versionConstraint: '^1.0.0'),
        ],
      );

      registry.registerPlugin(
          manifest: targetManifest, instance: MockCommandPlugin());
      registry.registerPlugin(
          manifest: dependentManifest, instance: MockCommandPlugin());

      final plan = removalManager.planRemoval(pluginId: 'target_base_plugin');
      expect(plan.isBlockedByDependents, isTrue);
      expect(plan.dependentPluginIds, contains('consumer_plugin'));

      // Refuses by default
      expect(
        () => removalManager.applyRemoval(plan: plan),
        throwsA(isA<PluginRemovalException>().having(
          (e) => e.message,
          'message',
          contains('has active dependents (consumer_plugin)'),
        )),
      );
    });

    test(
        '3b. Blocking dependents: applyRemoval proceeds when explicit acknowledgeDependents/force flag is supplied',
        () {
      final targetManifest = createManifest(id: 'target_base_plugin');
      final dependentManifest = createManifest(
        id: 'consumer_plugin',
        dependencies: [
          PluginDependency(
              name: 'target_base_plugin', versionConstraint: '^1.0.0'),
        ],
      );

      registry.registerPlugin(
          manifest: targetManifest, instance: MockCommandPlugin());
      registry.registerPlugin(
          manifest: dependentManifest, instance: MockCommandPlugin());

      final plan = removalManager.planRemoval(pluginId: 'target_base_plugin');
      final result =
          removalManager.applyRemoval(plan: plan, acknowledgeDependents: true);

      expect(result.pluginId, equals('target_base_plugin'));
      expect(registry.exists('target_base_plugin'), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Plan-is-inert-data test
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '4. Plan-is-inert-data: computing RemovalPlan never deletes files, mutates state store, or unregisters plugins',
        () {
      final manifest = createManifest(id: 'inert_test_plugin');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      stateStore.savePluginState(
        pluginId: 'inert_test_plugin',
        version: SemVer.parse('1.0.0'),
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult:
            const PluginValidationResult(isValid: true, violations: []),
        compatibilityResult: DependencyResolutionResult.compatible(const []),
        configuration: RuntimeConfiguration({'key': 'val'}),
      );

      final pluginDir =
          io.Directory('${tempDir.path}/plugins/inert_test_plugin')
            ..createSync(recursive: true);
      final file = io.File('${pluginDir.path}/plugin.json')
        ..writeAsStringSync(jsonEncode(manifest.toJson()));

      final discoveryEntry = DiscoveredPluginEntry(
        directoryPath: pluginDir.path,
        manifestPath: file.path,
        status: DiscoveredPluginStatus.valid,
        manifest: manifest,
        details: const [],
      );

      // Compute plan
      final plan = removalManager.planRemoval(
        pluginId: 'inert_test_plugin',
        discoveryEntries: [discoveryEntry],
      );
      expect(plan, isNotNull);

      // Verify ZERO side-effects
      expect(file.existsSync(), isTrue);
      expect(registry.exists('inert_test_plugin'), isTrue);
      expect(
          stateStore
              .readStateDocumentOrNull()!
              .plugins
              .containsKey('inert_test_plugin'),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Reversibility & restoreFromBackup test
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '5. Reversibility: full restorable snapshot created upon removal, restoreFromBackup reconstructs registration, state, and files',
        () {
      final manifest = createManifest(id: 'reversible_plugin');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      stateStore.savePluginState(
        pluginId: 'reversible_plugin',
        version: SemVer.parse('1.0.0'),
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult:
            const PluginValidationResult(isValid: true, violations: []),
        compatibilityResult: DependencyResolutionResult.compatible(const []),
        configuration: RuntimeConfiguration({'key': 'val'}),
      );

      final pluginDir =
          io.Directory('${tempDir.path}/plugins/reversible_plugin')
            ..createSync(recursive: true);
      final file = io.File('${pluginDir.path}/plugin.json')
        ..writeAsStringSync(jsonEncode(manifest.toJson()));

      final discoveryEntry = DiscoveredPluginEntry(
        directoryPath: pluginDir.path,
        manifestPath: file.path,
        status: DiscoveredPluginStatus.valid,
        manifest: manifest,
        details: const [],
      );

      final plan = removalManager.planRemoval(
        pluginId: 'reversible_plugin',
        discoveryEntries: [discoveryEntry],
      );

      // 1. Remove
      final execResult = removalManager.applyRemoval(plan: plan);
      expect(file.existsSync(), isFalse);
      expect(registry.exists('reversible_plugin'), isFalse);

      // 2. Restore
      final restoredState = removalManager.restoreFromBackup(
        backupFilePath: execResult.backupPath,
        pluginInstance: MockCommandPlugin(),
      );

      expect(restoredState.pluginId, equals('reversible_plugin'));
      expect(file.existsSync(), isTrue);
      expect(registry.exists('reversible_plugin'), isTrue);
      expect(
          stateStore
              .readStateDocumentOrNull()!
              .plugins
              .containsKey('reversible_plugin'),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Audit test
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '6. Audit: every file, state entry, and dependent is individually attributable and logged in removal plan and execution',
        () {
      final manifest = createManifest(id: 'audit_test_plugin');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      final pluginDir =
          io.Directory('${tempDir.path}/plugins/audit_test_plugin')
            ..createSync(recursive: true);
      final file = io.File('${pluginDir.path}/plugin.json')
        ..writeAsStringSync(jsonEncode(manifest.toJson()));

      final discoveryEntry = DiscoveredPluginEntry(
        directoryPath: pluginDir.path,
        manifestPath: file.path,
        status: DiscoveredPluginStatus.valid,
        manifest: manifest,
        details: const [],
      );

      final plan = removalManager.planRemoval(
        pluginId: 'audit_test_plugin',
        discoveryEntries: [discoveryEntry],
      );

      expect(
          plan.auditEntries
              .any((a) => a.contains('Attributed plugin manifest file')),
          isTrue);

      final result = removalManager.applyRemoval(plan: plan);
      expect(
          result.auditLog
              .any((a) => a.contains('Created isolated pre-removal snapshot')),
          isTrue);
      expect(
          result.auditLog.any(
              (a) => a.contains('Unregistered plugin "audit_test_plugin"')),
          isTrue);
      expect(result.auditLog.any((a) => a.contains('Deleted attributed file')),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Determinism test
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '7. Determinism: identical plugin and system state produces identical removal plans',
        () {
      final manifest = createManifest(id: 'deterministic_plugin');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      final plan1 =
          removalManager.planRemoval(pluginId: 'deterministic_plugin');
      final plan2 =
          removalManager.planRemoval(pluginId: 'deterministic_plugin');

      expect(plan1.pluginId, equals(plan2.pluginId));
      expect(plan1.isRegistered, equals(plan2.isRegistered));
      expect(plan1.attributedFiles, equals(plan2.attributedFiles));
      expect(plan1.isBlockedByDependents, equals(plan2.isBlockedByDependents));
      expect(plan1.summary, equals(plan2.summary));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Fail-Closed Edge-Case Tests (Individually Named)
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '8a. Fail-closed edge-case: removal request for nonexistent or unresolved plugin ID is refused',
        () {
      expect(
        () => removalManager.planRemoval(
            pluginId: 'completely_nonexistent_plugin'),
        throwsA(isA<PluginRemovalException>().having(
          (e) => e.message,
          'message',
          contains(
              'does not resolve to any registered, persisted, or discovered plugin'),
        )),
      );
    });

    test(
        '8b. Fail-closed edge-case: partially attributable discovered files exclude unattributable portion',
        () {
      final manifest = createManifest(id: 'partial_plugin');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      final pluginDir = io.Directory('${tempDir.path}/plugins/partial_plugin')
        ..createSync(recursive: true);
      final manifestFile = io.File('${pluginDir.path}/plugin.json')
        ..writeAsStringSync(jsonEncode(manifest.toJson()));
      final ambiguousFile = io.File('${pluginDir.path}/ambiguous_helper.dart')
        ..writeAsStringSync('void amb() {}');

      final discoveryEntry = DiscoveredPluginEntry(
        directoryPath: pluginDir.path,
        manifestPath: manifestFile.path,
        status: DiscoveredPluginStatus.valid,
        manifest: manifest,
        details: const [],
      );

      final plan = removalManager.planRemoval(
        pluginId: 'partial_plugin',
        discoveryEntries: [discoveryEntry],
        ambiguousOrSharedFilePaths: [ambiguousFile.path],
      );

      expect(plan.attributedFiles,
          contains(manifestFile.path.replaceAll('\\', '/')));
      expect(plan.attributedFiles,
          isNot(contains(ambiguousFile.path.replaceAll('\\', '/'))));
      expect(
          plan.excludedFiles.any((e) =>
              e.path == ambiguousFile.path.replaceAll('\\', '/') &&
              e.reason == FileExclusionReason.sharedPluginAsset),
          isTrue);
    });

    test(
        '2g. Structural Scoping: Newly-introduced core/system paths not in any exclusion list are protected automatically by discovery directory scoping',
        () {
      final manifest = createManifest(id: 'hypothetical_core_plugin');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      // Hypothetical newly-introduced core file completely unlisted in denylists
      final hypotheticalCoreFile =
          io.File('${tempDir.path}/system/core_kernel.bin')
            ..createSync(recursive: true)
            ..writeAsStringSync('binary_kernel');

      // Manipulated discovery entry attributing plugin to dedicated directory but pointing to outside core file
      final pluginDir =
          io.Directory('${tempDir.path}/plugins/hypothetical_core_plugin')
            ..createSync(recursive: true);

      final rogueDiscovery = DiscoveredPluginEntry(
        directoryPath: pluginDir.path,
        manifestPath: hypotheticalCoreFile.path, // Outside pluginDir
        status: DiscoveredPluginStatus.valid,
        manifest: manifest,
        details: const [],
      );

      final plan = removalManager.planRemoval(
        pluginId: 'hypothetical_core_plugin',
        discoveryEntries: [rogueDiscovery],
      );

      // Core file is excluded by structural scoping despite not being on any coreSystemPaths denylist
      expect(plan.attributedFiles, isEmpty);
      expect(
          plan.excludedFiles.any((e) =>
              e.path == hypotheticalCoreFile.path.replaceAll('\\', '/') &&
              e.reason == FileExclusionReason.unattributed),
          isTrue);
      expect(hypotheticalCoreFile.existsSync(), isTrue);
    });

    test(
        '8c. Fail-closed edge-case: attempted restore from corrupted or tampered backup fails closed',
        () {
      final manifest = createManifest(id: 'tampered_backup_plugin');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      final plan =
          removalManager.planRemoval(pluginId: 'tampered_backup_plugin');
      final execResult = removalManager.applyRemoval(plan: plan);

      // Intentionally tamper with backup content
      final backupFile = io.File(execResult.backupPath);
      final backupMap =
          jsonDecode(backupFile.readAsStringSync()) as Map<String, dynamic>;
      backupMap['version'] =
          '99.99.99'; // Tampered payload without updated checksum
      backupFile.writeAsStringSync(jsonEncode(backupMap));

      expect(
        () => removalManager.restoreFromBackup(
            backupFilePath: execResult.backupPath),
        throwsA(isA<PluginRemovalException>().having(
          (e) => e.message,
          'message',
          contains('failed cryptographic checksum integrity verification'),
        )),
      );
    });

    test(
        '8d. Fail-closed edge-case: restore atomicity under partial backup component corruption',
        () {
      final manifest = createManifest(id: 'partial_corrupt_plugin');
      registry.registerPlugin(
          manifest: manifest, instance: MockCommandPlugin());

      stateStore.savePluginState(
        pluginId: 'partial_corrupt_plugin',
        version: SemVer.parse('1.0.0'),
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult:
            const PluginValidationResult(isValid: true, violations: []),
        compatibilityResult: DependencyResolutionResult.compatible(const []),
        configuration: RuntimeConfiguration({'key': 'val'}),
      );

      final pluginDir =
          io.Directory('${tempDir.path}/plugins/partial_corrupt_plugin')
            ..createSync(recursive: true);
      final manifestFile = io.File('${pluginDir.path}/plugin.json')
        ..writeAsStringSync(jsonEncode(manifest.toJson()));

      final discoveryEntry = DiscoveredPluginEntry(
        directoryPath: pluginDir.path,
        manifestPath: manifestFile.path,
        status: DiscoveredPluginStatus.valid,
        manifest: manifest,
        details: const [],
      );

      final plan = removalManager.planRemoval(
        pluginId: 'partial_corrupt_plugin',
        discoveryEntries: [discoveryEntry],
      );

      final execResult = removalManager.applyRemoval(plan: plan);

      // Construct backup with VALID files component but INVALID persistedState schema (malformed type),
      // with recalculated checksum matching raw JSON so it passes raw payload hash but fails pre-flight component parsing.
      final backupFile = io.File(execResult.backupPath);
      final backupMap =
          jsonDecode(backupFile.readAsStringSync()) as Map<String, dynamic>;
      final corruptedPersistedState =
          Map<String, dynamic>.from(backupMap['persistedState'] as Map);
      corruptedPersistedState['version'] = {
        'invalid': 'structure_instead_of_string'
      };
      backupMap['persistedState'] = corruptedPersistedState;

      // Recompute valid checksum for this payload to test component pre-flight parsing
      final backupObj = PluginRemovalBackup(
        backupId: backupMap['backupId'] as String,
        pluginId: backupMap['pluginId'] as String,
        version: backupMap['version'] as String,
        createdAt: DateTime.parse(backupMap['createdAt'] as String),
        manifestJson: backupMap['manifest'] as Map<String, dynamic>?,
        persistedStateJson: corruptedPersistedState,
        fileSnapshots:
            Map<String, String>.from(backupMap['fileSnapshots'] as Map),
      );
      backupFile.writeAsStringSync(jsonEncode(backupObj.toJson()));

      // Attempt restore: Pre-flight validation must fail closed BEFORE writing files or updating state
      expect(
        () => removalManager.restoreFromBackup(
          backupFilePath: execResult.backupPath,
          pluginInstance: MockCommandPlugin(),
        ),
        throwsA(isA<PluginRemovalException>().having(
          (e) => e.message,
          'message',
          contains('Persisted state snapshot component corrupted'),
        )),
      );

      // Verify ATOMICITY: No partial files were written back to disk
      expect(manifestFile.existsSync(), isFalse);
      expect(registry.exists('partial_corrupt_plugin'), isFalse);
      expect(
          stateStore
                  .readStateDocumentOrNull()
                  ?.plugins
                  .containsKey('partial_corrupt_plugin') ??
              false,
          isFalse);
    });
  });
}
