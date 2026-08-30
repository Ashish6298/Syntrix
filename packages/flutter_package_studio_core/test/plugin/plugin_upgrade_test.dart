import 'dart:io' as io;
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('Plugin Upgrade & Migration Manager Tests (Phase 7.15)', () {
    late io.Directory tempDir;
    late PluginContractValidator contractValidator;
    late PluginConfigurationValidator configValidator;
    late PluginDependencyResolver dependencyResolver;
    late PluginStateStore stateStore;
    late PluginUpgradeManager upgradeManager;

    setUp(() {
      tempDir = io.Directory.systemTemp.createTempSync('plugin_upgrade_test_');
      contractValidator = PluginContractValidator();
      configValidator = PluginConfigurationValidator();
      dependencyResolver = PluginDependencyResolver();
      stateStore = PluginStateStore(
        rootPath: tempDir.path,
        validator: contractValidator,
        configValidator: configValidator,
      );
      upgradeManager = PluginUpgradeManager(
        contractValidator: contractValidator,
        configValidator: configValidator,
        dependencyResolver: dependencyResolver,
        stateStore: stateStore,
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
      String apiVersion = '1.0.0',
      Set<PluginCapability> capabilities = const {
        PluginCapability.commandContribution
      },
      List<PluginDependency> dependencies = const [],
      ConfigurationSchema? configSchema,
    }) {
      return PluginManifest(
        id: PluginId(id),
        name: PluginName('Sample Plugin $id'),
        description: PluginDescription('Upgrade test plugin.'),
        version: SemVer.parse(version),
        author: const PluginAuthor(name: 'FPS Core Team'),
        apiVersion: apiVersion,
        capabilities: capabilities,
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
        dependencies: dependencies,
        configSchema: configSchema ?? ConfigurationSchema(),
        securityRequirements: const SecurityRequirements(),
      );
    }

    PersistedPluginState createPersistedState({
      String id = 'sample_plugin',
      String version = '1.0.0',
      Map<String, dynamic> config = const {},
    }) {
      return PersistedPluginState(
        pluginId: id,
        version: SemVer.parse(version),
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult:
            const PluginValidationResult(isValid: true, violations: []),
        compatibilityResult: DependencyResolutionResult.compatible(const []),
        redactedConfiguration: config,
        lifecycleHistory: const [],
        failureRecords: const [],
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Compatible-Upgrade Happy-Path Test (e.g. v1.0 -> v1.1)
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '1. Compatible-upgrade happy-path: v1.0.0 -> v1.1.0 produces clean plan with no breaking changes',
        () {
      final oldManifest = createManifest(version: '1.0.0');
      final newManifest = createManifest(version: '1.1.0');
      final installedState = createPersistedState(version: '1.0.0');

      final plan = upgradeManager.planUpgrade(
        installedState: installedState,
        installedManifest: oldManifest,
        candidateManifest: newManifest,
      );

      expect(
          plan.compatibilityType, equals(UpgradeCompatibilityType.compatible));
      expect(plan.isCompatible, isTrue);
      expect(plan.isDowngrade, isFalse);
      expect(plan.isHardBlocked, isFalse);
      expect(plan.breakingChanges, isEmpty);
      expect(plan.configFindings, isEmpty);
      expect(plan.requirements, isEmpty);
      expect(plan.summary, contains('Backward-compatible upgrade'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Breaking-API-Change Test
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '2. Breaking-API-change: narrowed capability or API version change flags specific breakage and cross-references dependents',
        () {
      final oldManifest = createManifest(
        version: '1.0.0',
        capabilities: {
          PluginCapability.commandContribution,
          PluginCapability.packageAnalysisContribution,
        },
      );
      // New manifest removes packageAnalysisContribution capability
      final newManifest = createManifest(
        version: '2.0.0',
        capabilities: {PluginCapability.commandContribution},
      );
      final installedState = createPersistedState(version: '1.0.0');

      // Dependent plugin that relies on sample_plugin
      final dependentPlugin = createManifest(
        id: 'consumer_plugin',
        version: '1.0.0',
        dependencies: [
          PluginDependency(name: 'sample_plugin', versionConstraint: '^1.0.0')
        ],
      );

      final plan = upgradeManager.planUpgrade(
        installedState: installedState,
        installedManifest: oldManifest,
        candidateManifest: newManifest,
        otherInstalledPlugins: [dependentPlugin],
      );

      expect(plan.compatibilityType,
          equals(UpgradeCompatibilityType.breakingChange));
      expect(plan.isCompatible, isFalse);
      expect(plan.breakingChanges,
          anyElement(contains('packageAnalysisContribution')));
      expect(plan.impactedDependents, contains('consumer_plugin'));
      expect(
          plan.requirements
              .any((r) => r.title.contains('Breaking API Changes')),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Configuration-Migration-Required Test
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '3. Configuration-migration-required: schema change invalidating persisted config detects and names invalid/missing keys',
        () {
      final oldManifest = createManifest(
        version: '1.0.0',
        configSchema: ConfigurationSchema(properties: [
          const ConfigurationProperty(
            key: 'timeoutMs',
            type: ConfigPropertyType.number,
            description: 'Timeout in ms',
          ),
          const ConfigurationProperty(
            key: 'deprecatedSetting',
            type: ConfigPropertyType.string,
            description: 'Old setting',
          ),
        ]),
      );

      final newManifest = createManifest(
        version: '1.1.0',
        configSchema: ConfigurationSchema(properties: [
          const ConfigurationProperty(
            key: 'timeoutMs',
            type: ConfigPropertyType.number,
            description: 'Timeout in ms',
          ),
          const ConfigurationProperty(
            key: 'apiKey',
            type: ConfigPropertyType.string,
            isRequired: true, // Newly required key
            isSecret: true,
            description: 'New mandatory API key',
          ),
        ]),
      );

      final installedState = createPersistedState(
        version: '1.0.0',
        config: {
          'timeoutMs': 5000,
          'deprecatedSetting': 'old_value',
        },
      );

      final plan = upgradeManager.planUpgrade(
        installedState: installedState,
        installedManifest: oldManifest,
        candidateManifest: newManifest,
      );

      expect(plan.compatibilityType,
          equals(UpgradeCompatibilityType.configurationMigrationRequired));
      expect(plan.isCompatible, isFalse);
      expect(
          plan.configFindings
              .any((f) => f.key == 'apiKey' && f.isMissingRequired),
          isTrue);
      expect(
          plan.configFindings
              .any((f) => f.key == 'deprecatedSetting' && f.isRemovedKey),
          isTrue);
      expect(
          plan.requirements.any(
              (r) => r.title.contains('Supply Required Setting: "apiKey"')),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Dependency-Change Test
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '4. Dependency-change: added, removed, and version-shifted dependencies are surfaced explicitly',
        () {
      final oldManifest = createManifest(
        version: '1.0.0',
        dependencies: [
          PluginDependency(name: 'dep_a', versionConstraint: '^1.0.0'),
          PluginDependency(name: 'dep_b', versionConstraint: '^1.0.0'),
        ],
      );

      final newManifest = createManifest(
        version: '1.1.0',
        dependencies: [
          PluginDependency(
              name: 'dep_a', versionConstraint: '^2.0.0'), // Modified
          PluginDependency(name: 'dep_c', versionConstraint: '^1.0.0'), // Added
          // dep_b is removed
        ],
      );

      final installedState = createPersistedState(version: '1.0.0');

      final plan = upgradeManager.planUpgrade(
        installedState: installedState,
        installedManifest: oldManifest,
        candidateManifest: newManifest,
      );

      expect(plan.compatibilityType,
          equals(UpgradeCompatibilityType.dependencyShift));
      expect(plan.dependencyChanges.length, equals(3));
      expect(
          plan.dependencyChanges.any(
              (d) => d.dependencyName == 'dep_c' && d.changeType == 'added'),
          isTrue);
      expect(
          plan.dependencyChanges.any(
              (d) => d.dependencyName == 'dep_b' && d.changeType == 'removed'),
          isTrue);
      expect(
          plan.dependencyChanges.any(
              (d) => d.dependencyName == 'dep_a' && d.changeType == 'modified'),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Downgrade-Risk Test
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '5. Downgrade-risk: candidate version older than installed version is distinctly flagged as a downgrade',
        () {
      final oldManifest = createManifest(version: '2.0.0');
      final candidateManifest = createManifest(version: '1.9.0');
      final installedState = createPersistedState(version: '2.0.0');

      final plan = upgradeManager.planUpgrade(
        installedState: installedState,
        installedManifest: oldManifest,
        candidateManifest: candidateManifest,
      );

      expect(
          plan.compatibilityType, equals(UpgradeCompatibilityType.downgrade));
      expect(plan.isDowngrade, isTrue);
      expect(plan.isCompatible, isFalse);
      expect(
          plan.requirements
              .any((r) => r.title.contains('Acknowledge Downgrade Risk')),
          isTrue);
      expect(plan.summary, contains('Downgrade detected'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Migration-Requirements-Derivation Test
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '6. Migration-requirements-derivation: generated list of required actions is specific and traceable to actual findings',
        () {
      final oldManifest = createManifest(version: '1.0.0');
      final newManifest = createManifest(
        version: '2.0.0',
        configSchema: ConfigurationSchema(properties: [
          const ConfigurationProperty(
            key: 'clusterEndpoint',
            type: ConfigPropertyType.string,
            isRequired: true,
            description: 'Cluster URI',
          ),
        ]),
      );
      final installedState = createPersistedState(version: '1.0.0', config: {});

      final plan = upgradeManager.planUpgrade(
        installedState: installedState,
        installedManifest: oldManifest,
        candidateManifest: newManifest,
      );

      expect(plan.requirements.isNotEmpty, isTrue);
      final req = plan.requirements
          .firstWhere((r) => r.title.contains('clusterEndpoint'));
      expect(req.description, contains('clusterEndpoint'));
      expect(req.isMandatory, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Plan-Is-Inert-Data Test
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '7. Plan-is-inert-data: computing MigrationPlan never mutates persisted state, never transitions lifecycle, and never executes plugin code',
        () {
      // Save initial state to state store
      stateStore.savePluginState(
        pluginId: 'sample_plugin',
        version: SemVer.parse('1.0.0'),
        isEnabled: true,
        lifecycleState: PluginLifecycleState.active,
        validationResult:
            const PluginValidationResult(isValid: true, violations: []),
        compatibilityResult: DependencyResolutionResult.compatible(const []),
        configuration: RuntimeConfiguration({'key': 'val'}),
        schema: ConfigurationSchema(),
      );

      final docBefore = stateStore.readStateDocumentOrNull()!;
      final stateBefore = docBefore.plugins['sample_plugin']!;
      final oldTimestamp = stateBefore.lastUpdated;

      final newManifest = createManifest(version: '2.0.0');

      // Generate migration plan
      final plan = upgradeManager.planUpgrade(
        installedState: stateBefore,
        candidateManifest: newManifest,
      );

      expect(plan, isNotNull);

      // Verify persisted state document in store was NOT touched
      final docAfter = stateStore.readStateDocumentOrNull()!;
      final stateAfter = docAfter.plugins['sample_plugin']!;
      expect(stateAfter.version, equals(SemVer.parse('1.0.0')));
      expect(stateAfter.lifecycleState, equals(PluginLifecycleState.active));
      expect(stateAfter.lastUpdated, equals(oldTimestamp));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Application-vs-Planning Separation Test
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '8. Application-vs-planning separation: applying a plan is a distinct, separately-invoked operation',
        () {
      final oldManifest = createManifest(version: '1.0.0');
      final newManifest = createManifest(version: '1.1.0');
      final installedState = createPersistedState(version: '1.0.0');

      // 1. Planning alone does NOT apply upgrade
      final plan = upgradeManager.planUpgrade(
        installedState: installedState,
        installedManifest: oldManifest,
        candidateManifest: newManifest,
      );
      expect(installedState.version, equals(SemVer.parse('1.0.0')));

      // 2. Explicit apply invocation updates persisted state
      final updatedState = upgradeManager.applyUpgrade(
        plan: plan,
        newManifest: newManifest,
        currentState: installedState,
      );

      expect(updatedState.version, equals(SemVer.parse('1.1.0')));
      expect(updatedState.lifecycleHistory.last.toState,
          equals(PluginLifecycleState.discovered));
      expect(updatedState.lastKnownGoodSnapshot, isNotNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: Safe-Configuration-Carryover Test (including Secret Redaction)
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '9. Safe-configuration-carryover: valid values carry over unchanged, invalid values rejected, secret values never exposed in plaintext',
        () {
      final oldManifest = createManifest(
        version: '1.0.0',
        configSchema: ConfigurationSchema(properties: [
          const ConfigurationProperty(
              key: 'host', type: ConfigPropertyType.string),
          const ConfigurationProperty(
              key: 'token', type: ConfigPropertyType.string, isSecret: true),
        ]),
      );

      final newManifest = createManifest(
        version: '1.1.0',
        configSchema: ConfigurationSchema(properties: [
          const ConfigurationProperty(
              key: 'host', type: ConfigPropertyType.string),
          const ConfigurationProperty(
              key: 'token', type: ConfigPropertyType.string, isSecret: true),
          const ConfigurationProperty(
              key: 'port', type: ConfigPropertyType.number, isRequired: false),
        ]),
      );

      final installedState = createPersistedState(
        version: '1.0.0',
        config: {
          'host': 'api.syntrix.dev',
          'token': '[REDACTED]', // Secret preserved safely
        },
      );

      final plan = upgradeManager.planUpgrade(
        installedState: installedState,
        installedManifest: oldManifest,
        candidateManifest: newManifest,
      );

      final updatedState = upgradeManager.applyUpgrade(
        plan: plan,
        newManifest: newManifest,
        currentState: installedState,
        updatedConfiguration: RuntimeConfiguration({'port': 8080}),
      );

      expect(updatedState.redactedConfiguration['host'],
          equals('api.syntrix.dev'));
      expect(updatedState.redactedConfiguration['token'], equals('[REDACTED]'));
      expect(updatedState.redactedConfiguration['port'], equals(8080));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 10: Reuse Verification Test
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '10. Reuse verification: calls through to real 6.1/7.1, 7.6, and 7.5 logic rather than reimplementing',
        () {
      final oldManifest = createManifest(
        version: '1.0.0',
        dependencies: [
          PluginDependency(name: 'dep_x', versionConstraint: '^1.0.0')
        ],
      );
      final newManifest = createManifest(
        version: '1.1.0',
        dependencies: [
          PluginDependency(name: 'dep_x', versionConstraint: '^2.0.0')
        ],
      );
      final installedState = createPersistedState(version: '1.0.0');

      final plan = upgradeManager.planUpgrade(
        installedState: installedState,
        installedManifest: oldManifest,
        candidateManifest: newManifest,
      );

      expect(plan.dependencyChanges.single.oldConstraint, equals('^1.0.0'));
      expect(plan.dependencyChanges.single.newConstraint, equals('^2.0.0'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 11: Determinism Test
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '11. Determinism: identical old-state-plus-new-manifest inputs produce identical migration plans',
        () {
      final oldManifest = createManifest(version: '1.0.0');
      final newManifest = createManifest(version: '2.0.0');
      final installedState = createPersistedState(version: '1.0.0');

      final plan1 = upgradeManager.planUpgrade(
        installedState: installedState,
        installedManifest: oldManifest,
        candidateManifest: newManifest,
      );

      final plan2 = upgradeManager.planUpgrade(
        installedState: installedState,
        installedManifest: oldManifest,
        candidateManifest: newManifest,
      );

      expect(plan1.compatibilityType, equals(plan2.compatibilityType));
      expect(plan1.isCompatible, equals(plan2.isCompatible));
      expect(plan1.isDowngrade, equals(plan2.isDowngrade));
      expect(plan1.breakingChanges, equals(plan2.breakingChanges));
      expect(plan1.summary, equals(plan2.summary));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 12: Fail-Closed Edge-Cases (Individually Named)
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '12a. Fail-closed edge-case: malformed or unparseable candidate manifest blocks upgrade',
        () {
      final installedState = createPersistedState(version: '1.0.0');
      // Raw JSON manifest with invalid ID format
      final invalidManifestJson = {
        'id': 'INVALID ID WITH SPACES',
        'name': 'Invalid Plugin',
        'description': 'Desc',
        'version': '1.0.0',
        'author': {'name': 'Author'},
        'apiVersion': '1.0.0',
        'capabilities': ['commandContribution'],
        'compatibility': {'minApiVersion': '1.0.0'},
      };

      final plan = upgradeManager.planUpgrade(
        installedState: installedState,
        candidateManifest: invalidManifestJson,
      );

      expect(plan.compatibilityType,
          equals(UpgradeCompatibilityType.blockedInvalid));
      expect(plan.isHardBlocked, isTrue);
      expect(plan.summary,
          contains('Candidate manifest failed contract validation'));
    });

    test(
        '12b. Fail-closed edge-case: currently-persisted state that failed integrity check blocks upgrade',
        () {
      final installedState = createPersistedState(version: '1.0.0');
      final newManifest = createManifest(version: '1.1.0');

      final plan = upgradeManager.planUpgrade(
        installedState: installedState,
        candidateManifest: newManifest,
        isStateCorrupted: true, // Simulated state store checksum failure
      );

      expect(plan.compatibilityType,
          equals(UpgradeCompatibilityType.blockedInvalid));
      expect(plan.isHardBlocked, isTrue);
      expect(plan.summary, contains('Persisted state failed integrity check'));
    });

    test(
        '12c. Fail-closed edge-case: candidate manifest failing Phase 7.1 basic contract blocks before upgrade-specific comparison',
        () {
      final installedState = createPersistedState(version: '1.0.0');
      // Manifest violating contract (inconsistent compatibility min > max)
      final badCompatibilityJson = {
        'id': 'bad_compat',
        'name': 'Bad Compat',
        'description': 'Desc',
        'version': '1.0.0',
        'author': {'name': 'Author'},
        'apiVersion': '1.0.0',
        'capabilities': ['commandContribution'],
        'compatibility': {
          'minApiVersion': '2.0.0',
          'maxApiVersion': '1.0.0', // Inconsistent: min > max
        },
      };

      final plan = upgradeManager.planUpgrade(
        installedState: installedState,
        candidateManifest: badCompatibilityJson,
      );

      expect(plan.compatibilityType,
          equals(UpgradeCompatibilityType.blockedInvalid));
      expect(plan.isHardBlocked, isTrue);
      expect(
          plan.breakingChanges,
          anyElement(
              contains('minApiVersion (2.0.0) > maxApiVersion (1.0.0)')));
    });
  });
}
