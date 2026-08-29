import 'dart:io' as io;
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('Plugin State, Persistence & Recovery Tests (Phase 7.11)', () {
    late io.Directory tempDir;
    late PluginStateStore store;
    late PluginContractValidator validator;
    late PluginConfigurationValidator configValidator;
    late PluginDependencyResolver dependencyResolver;

    setUp(() {
      tempDir =
          io.Directory.systemTemp.createTempSync('fps_plugin_state_test_');
      validator = PluginContractValidator();
      configValidator = PluginConfigurationValidator();
      dependencyResolver = PluginDependencyResolver();

      store = PluginStateStore(
        rootPath: tempDir.path,
        validator: validator,
        configValidator: configValidator,
        dependencyResolver: dependencyResolver,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    PluginManifest createSampleManifest({
      String id = 'sample_plugin',
      String version = '1.0.0',
      bool isSecretConfig = true,
      List<String> permissions = const ['package.read'],
    }) {
      return PluginManifest(
        id: PluginId(id),
        name: PluginName('Sample Plugin'),
        description: PluginDescription('Sample description.'),
        version: SemVer.parse(version),
        author: const PluginAuthor(name: 'Dev Team'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.commandContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
        configSchema: ConfigurationSchema(properties: [
          const ConfigurationProperty(
            key: 'endpoint',
            type: ConfigPropertyType.string,
            isRequired: true,
          ),
          if (isSecretConfig)
            const ConfigurationProperty(
              key: 'api_token',
              type: ConfigPropertyType.string,
              isRequired: true,
              isSecret: true,
            ),
        ]),
        securityRequirements: SecurityRequirements(
          permissions: permissions,
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Happy-Path Persistence Round-Trip Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Happy-path persistence round-trip: all named state categories correctly written and restored across simulated restart',
        () {
      final manifest = createSampleManifest();
      final config = RuntimeConfiguration({
        'endpoint': 'https://api.example.com',
        'api_token': SecretValue('super_secret_token_123'),
      });

      final validationRes = validator.validateRawJson(manifest.toJson());
      final compatRes = dependencyResolver.resolveDependencies([manifest]);

      final history = [
        LifecycleTransitionRecord(
          instanceId: 'sample_plugin',
          fromState: PluginLifecycleState.discovered,
          toState: PluginLifecycleState.validated,
          reason: 'Passed contract check',
        ),
        LifecycleTransitionRecord(
          instanceId: 'sample_plugin',
          fromState: PluginLifecycleState.validated,
          toState: PluginLifecycleState.active,
          reason: 'Activated',
        ),
      ];

      final failures = [
        ExecutionAuditRecord(
          pluginId: 'sample_plugin',
          operation: 'test_operation',
          status: PluginExecutionStatus.failed,
          durationMs: 42,
          details: 'Non-fatal warning',
        ),
      ];

      // Save state to store
      store.savePluginState(
        pluginId: 'sample_plugin',
        version: manifest.version,
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult: validationRes,
        compatibilityResult: compatRes,
        configuration: config,
        schema: manifest.configSchema,
        lifecycleHistory: history,
        failureRecords: failures,
      );

      // Simulate process restart by creating a new PluginStateStore instance on same root
      final restartedStore = PluginStateStore(
        rootPath: tempDir.path,
        validator: validator,
        configValidator: configValidator,
        dependencyResolver: dependencyResolver,
      );

      final recovery = restartedStore.restoreAndRecover(
        discoveredManifests: [manifest],
      );

      expect(recovery.hasCorruptions, isFalse);
      expect(recovery.healthyStates.containsKey('sample_plugin'), isTrue);

      final restored = recovery.healthyStates['sample_plugin']!;
      expect(restored.pluginId, equals('sample_plugin'));
      expect(restored.version.toString(), equals('1.0.0'));
      expect(restored.isEnabled, isTrue);
      expect(restored.lifecycleState, equals(PluginLifecycleState.active));
      expect(restored.validationResult.isValid, isTrue);
      expect(restored.compatibilityResult.isCompatible, isTrue);
      expect(restored.redactedConfiguration['endpoint'],
          equals('https://api.example.com'));
      expect(restored.redactedConfiguration['api_token'], equals('[REDACTED]'));
      expect(restored.lifecycleHistory.length, equals(2));
      expect(restored.failureRecords.length, equals(1));
      expect(restored.failureRecords.first.operation, equals('test_operation'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Secret-Safety Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Secret-safety: secret-classified configuration values are never persisted as raw plaintext',
        () {
      final manifest = createSampleManifest();
      const rawSecret = 'SUPER_SECRET_PLAINTEXT_PASSWORD_9988';
      final config = RuntimeConfiguration({
        'endpoint': 'https://api.example.com',
        'api_token': SecretValue(rawSecret),
      });

      store.savePluginState(
        pluginId: 'sample_plugin',
        version: manifest.version,
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult: validator.validateRawJson(manifest.toJson()),
        compatibilityResult: dependencyResolver.resolveDependencies([manifest]),
        configuration: config,
        schema: manifest.configSchema,
      );

      final rawFileText = io.File(store.stateFilePath).readAsStringSync();
      expect(rawFileText.contains(rawSecret), isFalse,
          reason: 'Plaintext secret must never appear on disk.');
      expect(rawFileText.contains('[REDACTED]'), isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Structural-Isolation Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Structural-isolation: writing and reading plugin state never touches existing package metadata or core project files',
        () {
      // Simulate existing core metadata and project state files from Milestones 1–6
      final pubspecFile = io.File('${tempDir.path}/pubspec.yaml')
        ..writeAsStringSync('name: my_package\nversion: 0.1.0\n');
      final changelogFile = io.File('${tempDir.path}/CHANGELOG.md')
        ..writeAsStringSync('# Changelog\n');
      final templateMetaDir = io.Directory('${tempDir.path}/.fps')
        ..createSync(recursive: true);
      final templateMetaFile =
          io.File('${templateMetaDir.path}/template_metadata.json')
            ..writeAsStringSync('{"template": "standard"}');

      final pubspecBefore = pubspecFile.readAsStringSync();
      final changelogBefore = changelogFile.readAsStringSync();
      final metaBefore = templateMetaFile.readAsStringSync();

      final manifest = createSampleManifest();
      final config = RuntimeConfiguration({
        'endpoint': 'https://api.example.com',
        'api_token': SecretValue('token123'),
      });

      store.savePluginState(
        pluginId: 'sample_plugin',
        version: manifest.version,
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult: validator.validateRawJson(manifest.toJson()),
        compatibilityResult: dependencyResolver.resolveDependencies([manifest]),
        configuration: config,
        schema: manifest.configSchema,
      );

      final recovery = store.restoreAndRecover(discoveredManifests: [manifest]);
      expect(recovery.healthyStates.length, equals(1));

      // Assert project files and metadata documents are 100% untouched
      expect(pubspecFile.readAsStringSync(), equals(pubspecBefore));
      expect(changelogFile.readAsStringSync(), equals(changelogBefore));
      expect(templateMetaFile.readAsStringSync(), equals(metaBefore));

      // Assert plugin state is strictly in its dedicated path .fps/plugins/plugins_state.json
      expect(store.stateFilePath,
          equals('${tempDir.path}/.fps/plugins/plugins_state.json'));
      expect(io.File(store.stateFilePath).existsSync(), isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Atomic-Write Safety Tests (Write Interruption & Rename Boundary)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4a. Atomic-write safety (temp-write failure): simulated failure during temporary file write leaves previous valid state intact',
        () {
      final manifest = createSampleManifest();
      final config = RuntimeConfiguration({
        'endpoint': 'https://api.v1.example.com',
        'api_token': SecretValue('token123'),
      });

      // Initial valid save
      store.savePluginState(
        pluginId: 'sample_plugin',
        version: manifest.version,
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult: validator.validateRawJson(manifest.toJson()),
        compatibilityResult: dependencyResolver.resolveDependencies([manifest]),
        configuration: config,
        schema: manifest.configSchema,
      );

      final validInitialContent =
          io.File(store.stateFilePath).readAsStringSync();

      // Simulate interrupted atomic write during temp file writing
      final failingFileUtils =
          _SimulatedInterruptedWriteFileUtils(const SystemFileUtils());
      final safeStore = PluginStateStore(
        rootPath: tempDir.path,
        fileUtils: failingFileUtils,
        validator: validator,
        configValidator: configValidator,
        dependencyResolver: dependencyResolver,
      );

      expect(
        () => safeStore.savePluginState(
          pluginId: 'sample_plugin',
          version: manifest.version,
          isEnabled: false,
          lifecycleState: PluginLifecycleState.disabled,
          validationResult: validator.validateRawJson(manifest.toJson()),
          compatibilityResult:
              dependencyResolver.resolveDependencies([manifest]),
          configuration: RuntimeConfiguration({
            'endpoint': 'https://api.v2.broken.example.com',
            'api_token': SecretValue('token123'),
          }),
          schema: manifest.configSchema,
        ),
        throwsA(isA<PluginPersistenceException>()),
      );

      // Verify the target state file still has the initial valid uncorrupted content
      final contentAfterFailure =
          io.File(store.stateFilePath).readAsStringSync();
      expect(contentAfterFailure, equals(validInitialContent));

      final recovery = store.restoreAndRecover(discoveredManifests: [manifest]);
      expect(recovery.healthyStates['sample_plugin']!.isEnabled, isTrue);
    });

    test(
        '4b. Atomic-write safety (rename-boundary interruption): failure occurring after temp file is fully written but during rename leaves original state intact and temp file un-promoted',
        () {
      final manifest = createSampleManifest();
      final config = RuntimeConfiguration({
        'endpoint': 'https://api.v1.example.com',
        'api_token': SecretValue('token123'),
      });

      // Initial valid save establishing canonical state
      store.savePluginState(
        pluginId: 'sample_plugin',
        version: manifest.version,
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult: validator.validateRawJson(manifest.toJson()),
        compatibilityResult: dependencyResolver.resolveDependencies([manifest]),
        configuration: config,
        schema: manifest.configSchema,
      );

      final validInitialContent =
          io.File(store.stateFilePath).readAsStringSync();

      // Simulate failure at the atomic rename boundary (after temp file is written)
      // leaving any temp file behind
      final failingRenameFileUtils = _SimulatedFailedRenameFileUtils(
          const SystemFileUtils(),
          leaveTempFileBehind: true);
      final safeStore = PluginStateStore(
        rootPath: tempDir.path,
        fileUtils: failingRenameFileUtils,
        validator: validator,
        configValidator: configValidator,
        dependencyResolver: dependencyResolver,
      );

      expect(
        () => safeStore.savePluginState(
          pluginId: 'sample_plugin',
          version: manifest.version,
          isEnabled: false,
          lifecycleState: PluginLifecycleState.disabled,
          validationResult: validator.validateRawJson(manifest.toJson()),
          compatibilityResult:
              dependencyResolver.resolveDependencies([manifest]),
          configuration: RuntimeConfiguration({
            'endpoint': 'https://api.v2.interrupted.example.com',
            'api_token': SecretValue('token123'),
          }),
          schema: manifest.configSchema,
        ),
        throwsA(isA<PluginPersistenceException>()),
      );

      // 1. Original state file must remain fully intact and unmodified
      final contentAfterInterruption =
          io.File(store.stateFilePath).readAsStringSync();
      expect(contentAfterInterruption, equals(validInitialContent));

      // 2. Subsequent normal restore must read the last-known-good state
      final recovery = store.restoreAndRecover(discoveredManifests: [manifest]);
      expect(recovery.hasCorruptions, isFalse);
      expect(recovery.healthyStates['sample_plugin']!.isEnabled, isTrue);
      expect(
          recovery.healthyStates['sample_plugin']!
              .redactedConfiguration['endpoint'],
          equals('https://api.v1.example.com'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Individually Named Recovery-Path Tests
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5a. Recovery path: corrupt plugin state store is flagged without crashing core',
        () {
      final manifest = createSampleManifest();
      final stateFile = io.File(store.stateFilePath);
      stateFile.parent.createSync(recursive: true);
      // Write corrupted non-JSON junk
      stateFile.writeAsStringSync('{corrupted_half_written_data::: ???');

      final recovery = store.restoreAndRecover(discoveredManifests: [manifest]);

      expect(recovery.hasCorruptions, isTrue);
      expect(recovery.healthyStates.isEmpty, isTrue);
      expect(
          recovery.recoveryActions
              .any((a) => a.status == PluginRecoveryStatus.corruptState),
          isTrue);
    });

    test(
        '5b. Recovery path: failed initialization state is surfaced without auto-retrying activation',
        () {
      final manifest = createSampleManifest();
      final config = RuntimeConfiguration({
        'endpoint': 'https://api.example.com',
        'api_token': SecretValue('token123'),
      });

      store.savePluginState(
        pluginId: 'sample_plugin',
        version: manifest.version,
        isEnabled: true,
        lifecycleState: PluginLifecycleState.initializationFailed,
        validationResult: validator.validateRawJson(manifest.toJson()),
        compatibilityResult: dependencyResolver.resolveDependencies([manifest]),
        configuration: config,
        schema: manifest.configSchema,
      );

      final recovery = store.restoreAndRecover(discoveredManifests: [manifest]);

      expect(recovery.healthyStates.containsKey('sample_plugin'), isTrue);
      expect(recovery.healthyStates['sample_plugin']!.lifecycleState,
          equals(PluginLifecycleState.initializationFailed));
      expect(
          recovery.recoveryActions.any(
              (a) => a.status == PluginRecoveryStatus.failedInitialization),
          isTrue);
    });

    test(
        '5c. Recovery path: invalid configuration after schema change is detected and marked as requiring reconfiguration',
        () {
      final oldManifest = createSampleManifest();
      final config = RuntimeConfiguration({
        'endpoint': 'https://api.example.com',
        'api_token': SecretValue('token123'),
      });

      store.savePluginState(
        pluginId: 'sample_plugin',
        version: oldManifest.version,
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult: validator.validateRawJson(oldManifest.toJson()),
        compatibilityResult:
            dependencyResolver.resolveDependencies([oldManifest]),
        configuration: config,
        schema: oldManifest.configSchema,
      );

      // New upgraded manifest has a newly added required property "mandatory_region"
      final newManifest = PluginManifest(
        id: PluginId('sample_plugin'),
        name: PluginName('Sample Plugin'),
        description: PluginDescription('Sample description.'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev Team'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.commandContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
        configSchema: ConfigurationSchema(properties: [
          const ConfigurationProperty(
            key: 'endpoint',
            type: ConfigPropertyType.string,
            isRequired: true,
          ),
          const ConfigurationProperty(
            key: 'mandatory_region',
            type: ConfigPropertyType.string,
            isRequired: true,
          ),
        ]),
      );

      final recovery =
          store.restoreAndRecover(discoveredManifests: [newManifest]);

      expect(recovery.healthyStates.containsKey('sample_plugin'), isFalse);
      expect(
          recovery.recoveryActions.any(
              (a) => a.status == PluginRecoveryStatus.invalidConfiguration),
          isTrue);
    });

    test(
        '5d. Recovery path: plugin removal is detected and marked as orphaned/removed rather than dangling',
        () {
      final manifest = createSampleManifest();
      final config = RuntimeConfiguration({
        'endpoint': 'https://api.example.com',
        'api_token': SecretValue('token123'),
      });

      store.savePluginState(
        pluginId: 'sample_plugin',
        version: manifest.version,
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult: validator.validateRawJson(manifest.toJson()),
        compatibilityResult: dependencyResolver.resolveDependencies([manifest]),
        configuration: config,
        schema: manifest.configSchema,
      );

      // Manifest is no longer present on disk during discovery
      final recovery = store.restoreAndRecover(discoveredManifests: const []);

      expect(recovery.healthyStates.containsKey('sample_plugin'), isFalse);
      expect(
          recovery.recoveryActions
              .any((a) => a.status == PluginRecoveryStatus.orphanedRemoved),
          isTrue);
    });

    test(
        '5e. Recovery path: plugin upgrade failure triggers fallback reporting and refuses broken activation',
        () {
      final oldManifest = createSampleManifest(version: '1.0.0');
      final config = RuntimeConfiguration({
        'endpoint': 'https://api.example.com',
        'api_token': SecretValue('token123'),
      });

      store.savePluginState(
        pluginId: 'sample_plugin',
        version: oldManifest.version,
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult: validator.validateRawJson(oldManifest.toJson()),
        compatibilityResult:
            dependencyResolver.resolveDependencies([oldManifest]),
        configuration: config,
        schema: oldManifest.configSchema,
        lastKnownGoodSnapshot: {
          'endpoint': 'https://api.example.com',
          'version': '1.0.0'
        },
      );

      // Upgraded manifest (v2.0.0) has invalid contract (e.g. empty name)
      final brokenUpgradedManifest = PluginManifest(
        id: PluginId('sample_plugin'),
        name: PluginName('Sample Plugin'),
        description: PluginDescription('Sample description.'),
        version: SemVer.parse('2.0.0'),
        author: const PluginAuthor(name: 'Dev Team'),
        apiVersion: '99.0.0', // Unsupported API version
        capabilities: {PluginCapability.commandContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );

      final recovery = store
          .restoreAndRecover(discoveredManifests: [brokenUpgradedManifest]);

      expect(recovery.healthyStates.containsKey('sample_plugin'), isFalse);
      expect(
          recovery.recoveryActions
              .any((a) => a.status == PluginRecoveryStatus.upgradeFallback),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Fail-Closed On Ambiguity Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Fail-closed on ambiguity: uninterpretable or ambiguous state treated as inactive/unsafe',
        () {
      final manifest = createSampleManifest();
      final config = RuntimeConfiguration({
        'endpoint': 'https://api.example.com',
        'api_token': SecretValue('token123'),
      });

      store.savePluginState(
        pluginId: 'sample_plugin',
        version: manifest.version,
        isEnabled: true,
        lifecycleState:
            PluginLifecycleState.invalid, // Ambiguous state for auto-restart
        validationResult: validator.validateRawJson(manifest.toJson()),
        compatibilityResult: dependencyResolver.resolveDependencies([manifest]),
        configuration: config,
        schema: manifest.configSchema,
      );

      final recovery = store.restoreAndRecover(discoveredManifests: [manifest]);

      expect(recovery.healthyStates.containsKey('sample_plugin'), isFalse);
      expect(
          recovery.recoveryActions.any(
              (a) => a.status == PluginRecoveryStatus.unrecognizedAmbiguous),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Determinism Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Determinism: repeatedly loading identical persisted state produces identical in-memory reconstruction',
        () {
      final manifest = createSampleManifest();
      final config = RuntimeConfiguration({
        'endpoint': 'https://api.example.com',
        'api_token': SecretValue('token123'),
      });

      store.savePluginState(
        pluginId: 'sample_plugin',
        version: manifest.version,
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult: validator.validateRawJson(manifest.toJson()),
        compatibilityResult: dependencyResolver.resolveDependencies([manifest]),
        configuration: config,
        schema: manifest.configSchema,
      );

      final recovery1 =
          store.restoreAndRecover(discoveredManifests: [manifest]);
      final recovery2 =
          store.restoreAndRecover(discoveredManifests: [manifest]);

      expect(recovery1.healthyStates.length,
          equals(recovery2.healthyStates.length));
      expect(
          recovery1.healthyStates.keys, equals(recovery2.healthyStates.keys));
      expect(recovery1.healthyStates['sample_plugin']!.pluginId,
          equals(recovery2.healthyStates['sample_plugin']!.pluginId));
      expect(recovery1.healthyStates['sample_plugin']!.isEnabled,
          equals(recovery2.healthyStates['sample_plugin']!.isEnabled));
      expect(recovery1.healthyStates['sample_plugin']!.lifecycleState,
          equals(recovery2.healthyStates['sample_plugin']!.lifecycleState));
      expect(recovery1.recoveryActions.map((a) => a.status),
          equals(recovery2.recoveryActions.map((a) => a.status)));
      expect(recovery1.hasCorruptions, equals(recovery2.hasCorruptions));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Audit Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Audit: every recovery action produces a specific, attributable, logged reason',
        () {
      final recovery = store.restoreAndRecover(discoveredManifests: const []);
      expect(recovery.recoveryActions, isEmpty);

      // Corrupt state audit
      final stateFile = io.File(store.stateFilePath)
        ..parent.createSync(recursive: true);
      stateFile.writeAsStringSync('{invalid_json');

      final corruptRecovery =
          store.restoreAndRecover(discoveredManifests: const []);
      expect(corruptRecovery.recoveryActions.length, equals(1));
      final audit = corruptRecovery.recoveryActions.first;
      expect(audit.status, equals(PluginRecoveryStatus.corruptState));
      expect(audit.reason, isNotEmpty);
      expect(audit.actionTaken, isNotEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: Fail-Closed Edge-Case Tests
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9a. Fail-closed edge-case: empty or nonexistent state store on first run initializes cleanly',
        () {
      expect(io.File(store.stateFilePath).existsSync(), isFalse);
      final recovery = store.restoreAndRecover(discoveredManifests: const []);
      expect(recovery.hasCorruptions, isFalse);
      expect(recovery.healthyStates.isEmpty, isTrue);
      expect(recovery.recoveryActions.isEmpty, isTrue);
    });

    test(
        '9b. Fail-closed edge-case: state store referencing a plugin never registered behaves cleanly',
        () {
      final manifest = createSampleManifest();
      final config = RuntimeConfiguration({
        'endpoint': 'https://api.example.com',
        'api_token': SecretValue('token123'),
      });

      store.savePluginState(
        pluginId: 'unregistered_plugin_id',
        version: manifest.version,
        isEnabled: false,
        lifecycleState: PluginLifecycleState.discovered,
        validationResult: validator.validateRawJson(manifest.toJson()),
        compatibilityResult: dependencyResolver.resolveDependencies([manifest]),
        configuration: config,
        schema: manifest.configSchema,
      );

      // Discovery only discovers sample_plugin, not unregistered_plugin_id
      final recovery = store.restoreAndRecover(discoveredManifests: [manifest]);
      expect(recovery.healthyStates.containsKey('unregistered_plugin_id'),
          isFalse);
      expect(
          recovery.recoveryActions.any((a) =>
              a.pluginId == 'unregistered_plugin_id' &&
              a.status == PluginRecoveryStatus.orphanedRemoved),
          isTrue);
    });

    test(
        '9c. Fail-closed edge-case: concurrent-looking rapid write sequences do not corrupt state',
        () {
      final manifest = createSampleManifest();

      for (var i = 0; i < 25; i++) {
        final config = RuntimeConfiguration({
          'endpoint': 'https://api.v$i.example.com',
          'api_token': SecretValue('token123'),
        });

        store.savePluginState(
          pluginId: 'sample_plugin',
          version: manifest.version,
          isEnabled: i % 2 == 0,
          lifecycleState: PluginLifecycleState.active,
          validationResult: validator.validateRawJson(manifest.toJson()),
          compatibilityResult:
              dependencyResolver.resolveDependencies([manifest]),
          configuration: config,
          schema: manifest.configSchema,
        );
      }

      final recovery = store.restoreAndRecover(discoveredManifests: [manifest]);
      expect(recovery.hasCorruptions, isFalse);
      expect(recovery.healthyStates.containsKey('sample_plugin'), isTrue);
      expect(
          recovery.healthyStates['sample_plugin']!
              .redactedConfiguration['endpoint'],
          equals('https://api.v24.example.com'));
    });
  });
}

class _SimulatedInterruptedWriteFileUtils implements FileUtils {
  final FileUtils _delegate;
  _SimulatedInterruptedWriteFileUtils(this._delegate);

  @override
  bool exists(String path) => _delegate.exists(path);

  @override
  bool isDirectory(String path) => _delegate.isDirectory(path);

  @override
  bool isFile(String path) => _delegate.isFile(path);

  @override
  String readAsString(String path) => _delegate.readAsString(path);

  @override
  void writeString(String path, String content, {bool recursive = true}) {
    if (path.contains('.tmp.')) {
      throw const io.FileSystemException(
          'Simulated disk failure during atomic temp write.');
    }
    _delegate.writeString(path, content, recursive: recursive);
  }

  @override
  void createDirectory(String path, {bool recursive = true}) =>
      _delegate.createDirectory(path, recursive: recursive);

  @override
  void delete(String path, {bool recursive = true}) =>
      _delegate.delete(path, recursive: recursive);

  @override
  void rename(String sourcePath, String targetPath) =>
      _delegate.rename(sourcePath, targetPath);
}

class _SimulatedFailedRenameFileUtils implements FileUtils {
  final FileUtils _delegate;
  final bool leaveTempFileBehind;

  _SimulatedFailedRenameFileUtils(this._delegate,
      {this.leaveTempFileBehind = false});

  @override
  bool exists(String path) => _delegate.exists(path);

  @override
  bool isDirectory(String path) => _delegate.isDirectory(path);

  @override
  bool isFile(String path) => _delegate.isFile(path);

  @override
  String readAsString(String path) => _delegate.readAsString(path);

  @override
  void writeString(String path, String content, {bool recursive = true}) =>
      _delegate.writeString(path, content, recursive: recursive);

  @override
  void createDirectory(String path, {bool recursive = true}) =>
      _delegate.createDirectory(path, recursive: recursive);

  @override
  void delete(String path, {bool recursive = true}) {
    if (leaveTempFileBehind && path.contains('.tmp.')) {
      // Simulate crash before catch block can delete the temp file
      return;
    }
    _delegate.delete(path, recursive: recursive);
  }

  @override
  void rename(String sourcePath, String targetPath) {
    if (sourcePath.contains('.tmp.')) {
      throw const io.FileSystemException(
          'Simulated crash/interruption at the atomic rename/move boundary.');
    }
    _delegate.rename(sourcePath, targetPath);
  }
}
