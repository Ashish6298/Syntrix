import 'dart:io' as io;
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('Plugin Testing & Sandbox Framework Tests (Phase 7.13)', () {
    late PluginTestHarness harness;

    setUp(() {
      harness = PluginTestHarness.create();
    });

    tearDown(() {
      harness.dispose();
    });

    PluginManifest createSampleManifest({
      String id = 'sample_plugin',
      String version = '1.0.0',
      Set<PluginCapability> capabilities = const {
        PluginCapability.commandContribution
      },
    }) {
      return PluginManifest(
        id: PluginId(id),
        name: PluginName('Sample Plugin $id'),
        description: PluginDescription('Harness test plugin description.'),
        version: SemVer.parse(version),
        author: const PluginAuthor(name: 'Dev Team', email: 'dev@example.com'),
        apiVersion: '1.0.0',
        capabilities: capabilities,
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
        configSchema: ConfigurationSchema(properties: const [
          ConfigurationProperty(
            key: 'endpoint',
            type: ConfigPropertyType.string,
            isRequired: true,
          ),
        ]),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Real Subsystem Invocation Tests (Phases 7.1–7.9)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1a. Subsystem: discovery harness genuinely invokes real PluginDiscoveryEngine',
        () async {
      await harness.runInSandbox((ctx) async {
        // Write a valid plugin into the sandbox as plugin.json
        ctx.writePluginManifest(
          pluginDirectoryName: 'test_plugin',
          manifestContent: '''
{
  "id": "test_plugin",
  "name": "Test Plugin",
  "description": "Discovered inside sandbox.",
  "version": "1.0.0",
  "author": {
    "name": "Dev Team"
  },
  "apiVersion": "1.0.0",
  "capabilities": [
    "commandContribution"
  ],
  "compatibility": {
    "minApiVersion": "1.0.0"
  }
}
''',
        );

        final result =
            await harness.discoveryHarness.discoverPlugins([ctx.path('.')]);
        expect(result.validEntries.length, equals(1));
        expect(result.validEntries.first.manifest!.id.value,
            equals('test_plugin'));
      });
    });

    test(
        '1b. Subsystem: validator harness genuinely invokes real PluginContractValidator',
        () {
      final manifest = createSampleManifest();
      final result =
          harness.validatorHarness.validateRawJson(manifest.toJson());
      expect(result.isValid, isTrue);
      expect(result.violations, isEmpty);

      // Verify invalid contract triggers real validator violations
      final badResult =
          harness.validatorHarness.validateRawJson({'id': 'INVALID_ID_CAPS'});
      expect(badResult.isValid, isFalse);
      expect(badResult.violations, isNotEmpty);
    });

    test(
        '1c. Subsystem: registry harness genuinely invokes real PluginRegistry',
        () {
      final manifest = createSampleManifest(id: 'reg_plugin');
      final dummy = _TestCommandContribution();

      harness.registryHarness
          .registerPlugin(manifest: manifest, instance: dummy);
      expect(harness.registryHarness.exists('reg_plugin'), isTrue);
      expect(harness.registryHarness.findPlugin('reg_plugin'), isNotNull);

      // Verify duplicate registration rejection from real registry
      expect(
        () => harness.registryHarness
            .registerPlugin(manifest: manifest, instance: dummy),
        throwsA(isA<PluginRegistrationException>()),
      );
    });

    test(
        '1d. Subsystem: lifecycle harness genuinely invokes real PluginLifecycleManager',
        () async {
      final manifest = createSampleManifest(
        id: 'lifecycle_plugin',
        capabilities: {
          PluginCapability.commandContribution,
          PluginCapability.lifecycleManagement,
        },
      );
      final dummy = _TestLifecyclePlugin();

      harness.registryHarness
          .registerPlugin(manifest: manifest, instance: dummy);
      harness.lifecycleHarness.trackInstance(
        instanceId: 'lifecycle_plugin',
        manifest: manifest,
        instance: dummy,
      );

      final state = await harness.lifecycleHarness.transitionTo(
        instanceId: 'lifecycle_plugin',
        targetState: PluginLifecycleState.validated,
      );

      expect(state, equals(PluginLifecycleState.validated));
      expect(harness.lifecycleHarness.getInstance('lifecycle_plugin')!.state,
          equals(PluginLifecycleState.validated));
    });

    test(
        '1e. Subsystem: dependency harness genuinely invokes real PluginDependencyResolver',
        () {
      final m1 = createSampleManifest(id: 'plugin_a');
      final m2 = createSampleManifest(id: 'plugin_b');

      final result = harness.dependencyHarness.resolveDependencies([m1, m2]);
      expect(result.isCompatible, isTrue);
      expect(result.initializationOrder,
          containsAllInOrder(['plugin_a', 'plugin_b']));
    });

    test(
        '1f. Subsystem: permission harness genuinely invokes real PluginPermissionGate',
        () {
      final manifest = PluginManifest(
        id: PluginId('perm_plugin'),
        name: PluginName('Perm Plugin'),
        description: PluginDescription('Description'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev Team'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.commandContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
        securityRequirements: const SecurityRequirements(
          permissions: ['process.execute'],
        ),
      );

      // Denied initially because not approved
      final denied = harness.permissionHarness.check(
        manifest: manifest,
        permission: PluginPermission.processExecute,
        operationAttempted: 'exec-proc',
      );
      expect(denied, isFalse);

      // Approve permission
      harness.permissionHarness
          .approvePermission('perm_plugin', PluginPermission.processExecute);
      final granted = harness.permissionHarness.check(
        manifest: manifest,
        permission: PluginPermission.processExecute,
        operationAttempted: 'exec-proc',
      );
      expect(granted, isTrue);
    });

    test(
        '1g. Subsystem: runtime execution harness genuinely invokes real PluginExecutionRuntime',
        () async {
      final manifest = createSampleManifest(id: 'runtime_plugin');
      final dummy = _TestCommandContribution();

      harness.registryHarness
          .registerPlugin(manifest: manifest, instance: dummy);
      harness.lifecycleHarness.trackInstance(
        instanceId: 'runtime_plugin',
        manifest: manifest,
        instance: dummy,
      )..state = PluginLifecycleState.active;

      final result = await harness.runtimeHarness.executeContribution<String>(
        instanceId: 'runtime_plugin',
        operation: 'run',
        action: (ctx) => 'Executed successfully',
      );

      expect(result.isSuccess, isTrue);
      expect(result.value, equals('Executed successfully'));
      expect(harness.runtimeHarness.auditLog.length, equals(1));
    });

    test(
        '1h. Subsystem: configuration validation harness genuinely invokes real PluginConfigurationValidator',
        () {
      final schema = ConfigurationSchema(properties: const [
        ConfigurationProperty(
            key: 'host', type: ConfigPropertyType.string, isRequired: true),
      ]);

      final validConfig = RuntimeConfiguration({'host': '127.0.0.1'});
      final validRes = harness.configValidatorHarness.validateConfiguration(
        schema: schema,
        config: validConfig,
      );
      expect(validRes.isValid, isTrue);

      final invalidConfig = RuntimeConfiguration({'host': 12345});
      final invalidRes = harness.configValidatorHarness.validateConfiguration(
        schema: schema,
        config: invalidConfig,
      );
      expect(invalidRes.isValid, isFalse);
      expect(invalidRes.violations, isNotEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Adversarial "Must Not Accidentally" Safety Tests
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2a. Must not accidentally: cannot modify or traverse outside sandboxed temp directory',
        () async {
      await harness.runInSandbox((ctx) async {
        expect(
          () => ctx.fileSystem.resolveSafePath('../../escaped_file.txt'),
          throwsA(isA<PluginSandboxSecurityException>()),
        );

        expect(
          () =>
              ctx.fileSystem.writeSafeFile('/etc/unauthorized.conf', 'payload'),
          throwsA(isA<PluginSandboxSecurityException>()),
        );
      });
    });

    test(
        '2b. Must not accidentally: cannot publish real package to pub.dev registry',
        () async {
      await harness.runInSandbox((ctx) async {
        // Construct a plugin execution that deliberately attempts an actual publish call
        final manifest = createSampleManifest(id: 'publish_attacker');
        final dummy = _TestCommandContribution();
        harness.registryHarness
            .registerPlugin(manifest: manifest, instance: dummy);
        harness.lifecycleHarness.trackInstance(
          instanceId: 'publish_attacker',
          manifest: manifest,
          instance: dummy,
        )..state = PluginLifecycleState.active;

        const options = PublishingOptions(
          packageName: 'malicious_pkg',
          version: '1.0.0',
          outputDir: 'doc/release',
        );

        // 1. Direct publish plan & execution attempt through harness publishing manager
        final plan = harness.publishingManager.planPublishing(options);
        expect(plan.target.url, equals('https://pub.dev'));

        // When executePublishing is invoked with dry-run (publish: false)
        final dryRunRes =
            harness.publishingManager.executePublishing(plan, publish: false);
        expect(dryRunRes.isSuccess, isTrue);
        expect(dryRunRes.status, equals(PublishingStatus.dryRunSuccess));
        expect(dryRunRes.details, contains('Zero publication executed'));

        // 2. If a plugin attempts an actual raw HTTP POST / socket call to pub.dev publish endpoint
        expect(
          () => ctx.network
              .sendRequest('https://pub.dev/api/packages/versions/new'),
          throwsA(isA<PluginSandboxSecurityException>()),
        );

        // 3. Execution runtime safety: verify contribution attempting raw publish cannot bypass sandbox
        final execRes =
            await harness.runtimeHarness.executeContribution<String>(
          instanceId: 'publish_attacker',
          operation: 'attempt_publish',
          action: (runCtx) {
            ctx.network
                .sendRequest('https://pub.dev/api/packages/versions/new');
          },
        );
        expect(execRes.isSuccess, isFalse);
        expect(execRes.errorMessage, contains('Sandbox Violation'));
      });
    });

    test(
        '2c. Must not accidentally: cannot mutate real Git repository history or tags',
        () async {
      await harness.runInSandbox((ctx) async {
        // Construct an adversarial scenario where a plugin attempts real Git tagging/branching
        final manifest = createSampleManifest(id: 'git_mutator');
        final dummy = _TestCommandContribution();
        harness.registryHarness
            .registerPlugin(manifest: manifest, instance: dummy);
        harness.lifecycleHarness.trackInstance(
          instanceId: 'git_mutator',
          manifest: manifest,
          instance: dummy,
        )..state = PluginLifecycleState.active;

        const options = GitReleaseOptions(
          packageName: 'git_mutator_pkg',
          version: '2.0.0',
          tagName: 'v2.0.0-injected',
          branchName: 'release/v2.0.0-injected',
          execute: true,
        );

        // Plan and execute release via harness's GitReleaseManager
        final plan = await harness.gitReleaseManager.planRelease(options);
        expect(plan.tagName, equals('v2.0.0-injected'));

        final result =
            await harness.gitReleaseManager.executeRelease(plan, execute: true);
        expect(result.isExecuted, isTrue);

        // Verify that operations were structurally captured by MockGitProcessRunner
        // and that NO real OS process or host git repository tags/branches were mutated
        expect(ctx.gitRunner.createdTags, contains('v2.0.0-injected'));
        expect(
            ctx.gitRunner.createdBranches, contains('release/v2.0.0-injected'));

        // Verify runtime contribution attempting un-sandboxed process / file escapes is blocked
        final execRes = await harness.runtimeHarness.executeContribution(
          instanceId: 'git_mutator',
          operation: 'escape_git',
          action: (runCtx) {
            ctx.fileSystem.resolveSafePath('../../.git/HEAD');
          },
        );
        expect(execRes.isSuccess, isFalse);
        expect(execRes.errorMessage, contains('Sandbox Violation'));
      });
    });

    test(
        '2d. Must not accidentally: cannot read or require real system credentials',
        () {
      // Mock credentials wrapper guarantees zero exposure
      const cred = GitHubCredential('test_token_123');
      expect(cred.toString(), equals('[REDACTED_GITHUB_TOKEN]'));
      expect(cred.toJson(), equals({'token': '[REDACTED]'}));

      final secret = SecretValue('local_secret');
      expect(secret.toString(), equals('[REDACTED]'));
    });

    test(
        '2e. Must not accidentally: cannot make outbound network requests (hard-blocked transport)',
        () async {
      await harness.runInSandbox((ctx) async {
        expect(
          () => ctx.network.sendRequest('https://api.github.com/releases'),
          throwsA(isA<PluginSandboxSecurityException>()),
        );
      });
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: No-Escape-Hatch Audit
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. No-escape-hatch audit: harness public API contains no parameter to enable real backends',
        () {
      // PluginTestHarness.create() takes only sandboxRoot and timing parameters; zero options for real backends
      final freshHarness = PluginTestHarness.create();
      expect(freshHarness.gitRunner, isA<MockGitProcessRunner>());
      expect(freshHarness.gitHubClient, isA<MockGitHubApiClient>());
      expect(freshHarness.network, isA<MockNetworkTransport>());
      freshHarness.dispose();
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Isolation-Per-Test Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Isolation-per-test: sequential harness instances do not leak state',
        () {
      final h1 = PluginTestHarness.create();
      final h2 = PluginTestHarness.create();

      final manifest = createSampleManifest(id: 'isolated_plugin');
      h1.registryHarness.registerPlugin(
          manifest: manifest, instance: _TestCommandContribution());

      expect(h1.registryHarness.exists('isolated_plugin'), isTrue);
      expect(h2.registryHarness.exists('isolated_plugin'), isFalse);

      expect(h1.fileSystem.sandboxRoot.path,
          isNot(equals(h2.fileSystem.sandboxRoot.path)));

      h1.dispose();
      h2.dispose();
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Failure Attribution Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Failure attribution: plugin errors clearly distinguished from harness setup errors',
        () async {
      final manifest = createSampleManifest(id: 'failing_plugin');
      final dummy = _TestCommandContribution();

      harness.registryHarness
          .registerPlugin(manifest: manifest, instance: dummy);
      harness.lifecycleHarness.trackInstance(
        instanceId: 'failing_plugin',
        manifest: manifest,
        instance: dummy,
      )..state = PluginLifecycleState.active;

      // 1. Plugin failure during execution
      final pluginRes = await harness.runtimeHarness.executeContribution(
        instanceId: 'failing_plugin',
        operation: 'faultyOp',
        action: (ctx) => throw StateError('Plugin internal crash!'),
      );

      expect(pluginRes.isSuccess, isFalse);
      expect(pluginRes.errorMessage, contains('Plugin internal crash!'));

      // 2. Harness setup error (e.g. invalid existing populated directory)
      final existingDir =
          io.Directory.systemTemp.createTempSync('existing_sandbox_');
      io.File('${existingDir.path}/some_file.txt')
          .writeAsStringSync('existing');

      expect(
        () => PluginTestHarness.create(customSandboxRoot: existingDir.path),
        throwsA(isA<PluginHarnessException>()),
      );

      existingDir.deleteSync(recursive: true);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Determinism Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Determinism: identical harness setup produces identical execution outcomes',
        () async {
      final m = createSampleManifest(id: 'det_plugin');
      final dummy = _TestCommandContribution();

      harness.registryHarness.registerPlugin(manifest: m, instance: dummy);
      harness.lifecycleHarness.trackInstance(
        instanceId: 'det_plugin',
        manifest: m,
        instance: dummy,
      )..state = PluginLifecycleState.active;

      final res1 = await harness.runtimeHarness.executeContribution(
        instanceId: 'det_plugin',
        operation: 'op',
        action: (ctx) => 100,
      );

      final res2 = await harness.runtimeHarness.executeContribution(
        instanceId: 'det_plugin',
        operation: 'op',
        action: (ctx) => 100,
      );

      expect(res1.status, equals(res2.status));
      expect(res1.value, equals(res2.value));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Reused Mock Verification
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Reused mock verification: GitHub client test double is genuinely Phase 6.5 MockGitHubApiClient',
        () {
      expect(harness.gitHubClient, isA<MockGitHubApiClient>());
      expect(harness.gitHubClient.createdReleases, isEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Fail-Closed Edge-Case Tests
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8a. Fail-closed edge-case: populated sandbox path refuses silent pollution',
        () {
      final tempPopulated =
          io.Directory.systemTemp.createTempSync('populated_sandbox_');
      io.File('${tempPopulated.path}/data.json').writeAsStringSync('{}');

      expect(
        () => PluginTestHarness.create(customSandboxRoot: tempPopulated.path),
        throwsA(isA<PluginHarnessException>()),
      );

      tempPopulated.deleteSync(recursive: true);
    });

    test(
        '8b. Fail-closed edge-case: reading nonexistent file inside sandbox throws security exception',
        () {
      expect(
        () => harness.fileSystem.readSafeFile('nonexistent_file.yaml'),
        throwsA(isA<PluginSandboxSecurityException>()),
      );
    });

    test(
        '8c. Fail-closed edge-case: sandbox temp directory is deleted on dispose()',
        () {
      final h = PluginTestHarness.create();
      final dirPath = h.fileSystem.sandboxRoot.path;
      expect(io.Directory(dirPath).existsSync(), isTrue);

      h.dispose();
      expect(io.Directory(dirPath).existsSync(), isFalse);
    });
  });
}

class _TestCommandContribution implements CommandContribution {
  @override
  List<String> getCommands() => const ['sample-cmd'];
}

class _TestLifecyclePlugin
    implements PluginLifecycleInterface, CommandContribution {
  @override
  List<String> getCommands() => const ['sample-cmd'];

  @override
  Future<void> initialize(Map<String, dynamic> context) async {}

  @override
  Future<void> shutdown() async {}
}
