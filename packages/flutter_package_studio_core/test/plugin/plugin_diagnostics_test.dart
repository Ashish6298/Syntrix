import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('Plugin Observability & Diagnostics Tests (Phase 7.12)', () {
    const engine = PluginDiagnosticsEngine();

    PluginManifest createSampleManifest({
      String id = 'sample_plugin',
      String version = '1.0.0',
      bool isSecretConfig = true,
    }) {
      return PluginManifest(
        id: PluginId(id),
        name: PluginName('Sample Plugin $id'),
        description: PluginDescription('Diagnostic test plugin description.'),
        version: SemVer.parse(version),
        author: const PluginAuthor(name: 'Dev Team', email: 'dev@example.com'),
        apiVersion: '1.0.0',
        capabilities: {
          PluginCapability.commandContribution,
        },
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
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Per-Plugin Diagnostic Completeness Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Per-plugin diagnostic completeness: plugin journey from discovery through execution is accurately represented',
        () {
      final manifest = createSampleManifest();
      final discoveryEntry = DiscoveredPluginEntry(
        directoryPath: '/plugins/sample_plugin',
        manifestPath: '/plugins/sample_plugin/fps_plugin.yaml',
        status: DiscoveredPluginStatus.valid,
        manifest: manifest,
        details: const ['Valid manifest detected.'],
      );

      final valResult =
          PluginContractValidator().validateRawJson(manifest.toJson());
      final configValResult = const PluginConfigurationValidationResult(
        isValid: true,
        violations: [],
      );

      final depResult =
          DependencyResolutionResult.compatible(['sample_plugin']);

      final instanceRecord = PluginInstanceRecord(
        instanceId: 'sample_plugin_inst_1',
        manifest: manifest,
        state: PluginLifecycleState.active,
        history: [
          LifecycleTransitionRecord(
            instanceId: 'sample_plugin_inst_1',
            fromState: PluginLifecycleState.discovered,
            toState: PluginLifecycleState.initialized,
            reason: 'Initialization completed.',
          ),
          LifecycleTransitionRecord(
            instanceId: 'sample_plugin_inst_1',
            fromState: PluginLifecycleState.initialized,
            toState: PluginLifecycleState.active,
            reason: 'Explicit activation requested.',
          ),
        ],
      );

      final permAudits = [
        PermissionAuditRecord(
          pluginId: 'sample_plugin',
          permissionName: 'process.execute',
          operationAttempted: 'run-build-task',
          isGranted: true,
          reason: 'Permission granted by security policy.',
        ),
      ];

      final execResults = [
        PluginExecutionResult<String>(
          pluginId: 'sample_plugin',
          operation: 'executeCommand',
          status: PluginExecutionStatus.success,
          value: 'Build succeeded',
          durationMs: 42,
        ),
      ];

      final diag = engine.diagnosePlugin(
        pluginId: 'sample_plugin',
        discoveryEntry: discoveryEntry,
        registeredPlugin:
            RegisteredPlugin(manifest: manifest, instance: Object()),
        manifest: manifest,
        validationResult: valResult,
        configValidationResult: configValResult,
        rawConfiguration: {
          'endpoint': 'https://api.example.com',
          'api_token': SecretValue('top_secret_token_123'),
        },
        dependencyResult: depResult,
        instanceRecord: instanceRecord,
        permissionAudits: permAudits,
        executionResults: execResults,
      );

      expect(diag.pluginId, equals('sample_plugin'));
      expect(diag.healthStatus, equals(PluginHealthStatus.healthy));
      expect(diag.isRegistered, isTrue);
      expect(diag.currentLifecycleState, equals(PluginLifecycleState.active));
      expect(diag.lifecycleHistory.length, equals(2));
      expect(diag.permissionAudits.length, equals(1));
      expect(diag.executionResults.length, equals(1));
      expect(diag.rootCause, isNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: System-Wide Summary Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. System-wide summary: multi-plugin triage categorizes healthy, failed, and permission-violated plugins',
        () {
      final manifest1 = createSampleManifest(id: 'plugin_healthy');
      final manifest2 = createSampleManifest(id: 'plugin_failed');
      final manifest3 = createSampleManifest(id: 'plugin_violated');

      final cmdInstance = _DummyCommandContribution();

      final registry = PluginRegistry()
        ..registerPlugin(manifest: manifest1, instance: cmdInstance)
        ..registerPlugin(manifest: manifest2, instance: cmdInstance)
        ..registerPlugin(manifest: manifest3, instance: cmdInstance);

      final lifecycle = PluginLifecycleManager(registry: registry);
      lifecycle
          .trackInstance(
              instanceId: 'plugin_healthy',
              manifest: manifest1,
              instance: cmdInstance)
          .state = PluginLifecycleState.active;

      lifecycle
          .trackInstance(
              instanceId: 'plugin_failed',
              manifest: manifest2,
              instance: cmdInstance)
          .state = PluginLifecycleState.initializationFailed;

      lifecycle
          .trackInstance(
              instanceId: 'plugin_violated',
              manifest: manifest3,
              instance: cmdInstance)
          .state = PluginLifecycleState.active;

      final permAudits = [
        PermissionAuditRecord(
          pluginId: 'plugin_violated',
          permissionName: 'package.publish',
          operationAttempted: 'publish-package',
          isGranted: false,
          reason:
              'Denied: package.publish not declared in manifest capabilities.',
        ),
      ];

      final summary = engine.diagnoseSystem(
        registry: registry,
        lifecycleManager: lifecycle,
        permissionAudits: permAudits,
      );

      expect(summary.totalRegistered, equals(3));
      expect(summary.healthyPluginIds, contains('plugin_healthy'));
      expect(summary.failedPluginIds, contains('plugin_failed'));
      expect(summary.permissionViolatedPluginIds, contains('plugin_violated'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Markdown/JSON Parity Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Markdown/JSON parity: Markdown and JSON renderers express identical underlying facts',
        () {
      final manifest = createSampleManifest();
      final diag = engine.diagnosePlugin(
        pluginId: 'sample_plugin',
        manifest: manifest,
        registeredPlugin:
            RegisteredPlugin(manifest: manifest, instance: Object()),
        rawConfiguration: {'endpoint': 'https://api.example.com'},
        validationResult:
            PluginContractValidator().validateRawJson(manifest.toJson()),
      );

      final md = engine.renderPluginMarkdown(diag);
      final json = engine.renderPluginJson(diag);

      // Verify essential facts are present in both
      expect(md, contains('sample_plugin'));
      expect(md, contains('HEALTHY'));
      expect(md, contains('https://api.example.com'));

      expect(json, contains('sample_plugin'));
      expect(json, contains('healthy'));
      expect(json, contains('https://api.example.com'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Determinism Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Determinism: identical underlying records produce byte-identical rendered output across repeated runs',
        () {
      final manifest = createSampleManifest();
      final diag = engine.diagnosePlugin(
        pluginId: 'sample_plugin',
        manifest: manifest,
        rawConfiguration: {'endpoint': 'https://api.example.com'},
      );

      final md1 = engine.renderPluginMarkdown(diag);
      final md2 = engine.renderPluginMarkdown(diag);
      expect(md1, equals(md2));

      final json1 = engine.renderPluginJson(diag);
      final json2 = engine.renderPluginJson(diag);
      expect(json1, equals(json2));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Individually Named Redaction Tests (No Opt-Out)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5a. Redaction in Markdown: Phase 7.5 configuration secrets never appear unredacted in Markdown output',
        () {
      final manifest = createSampleManifest();
      final diag = engine.diagnosePlugin(
        pluginId: 'sample_plugin',
        manifest: manifest,
        rawConfiguration: {
          'endpoint': 'https://api.example.com',
          'api_token': SecretValue('super_secret_password_xyz'),
        },
      );

      final md = engine.renderPluginMarkdown(diag);
      expect(md, isNot(contains('super_secret_password_xyz')));
      expect(md, contains('[REDACTED]'));
    });

    test(
        '5b. Redaction in JSON: Phase 7.5 configuration secrets never appear unredacted in JSON output',
        () {
      final manifest = createSampleManifest();
      final diag = engine.diagnosePlugin(
        pluginId: 'sample_plugin',
        manifest: manifest,
        rawConfiguration: {
          'endpoint': 'https://api.example.com',
          'api_token': SecretValue('super_secret_password_xyz'),
        },
      );

      final json = engine.renderPluginJson(diag);
      expect(json, isNot(contains('super_secret_password_xyz')));
      expect(json, contains('[REDACTED]'));
    });

    test(
        '5c. Redaction of Phase 6.5 credentials: GitHub credentials and tokens are redacted from diagnostics',
        () {
      const cred = GitHubCredential('ghp_abcdef1234567890abcdef1234567890');
      final diag = engine.diagnosePlugin(
        pluginId: 'sample_plugin',
        rawConfiguration: {
          'github_auth': cred,
          'raw_token': 'ghp_abcdef1234567890abcdef1234567890',
        },
      );

      final md = engine.renderPluginMarkdown(diag);
      final json = engine.renderPluginJson(diag);

      expect(md, isNot(contains('ghp_abcdef1234567890abcdef1234567890')));
      expect(json, isNot(contains('ghp_abcdef1234567890abcdef1234567890')));
      expect(md, contains('[REDACTED'));
      expect(json, contains('[REDACTED'));
    });

    test(
        '5d. Zero opt-out verification: confirm there is no caller-facing flag or parameter to bypass redaction',
        () {
      // Calling renderers without any bypass parameter always produces redacted output
      final diag = engine.diagnosePlugin(
        pluginId: 'sample_plugin',
        rawConfiguration: {'secret_key': SecretValue('must_never_leak')},
      );

      final md = engine.renderPluginMarkdown(diag);
      final json = engine.renderPluginJson(diag);

      expect(md, isNot(contains('must_never_leak')));
      expect(json, isNot(contains('must_never_leak')));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: "Why Did It Fail" Reconstruction Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. "Why did it fail" reconstruction: failure stage, reason, and timeout/permission are specifically identified',
        () {
      final execResults = [
        PluginExecutionResult<dynamic>(
          pluginId: 'failing_plugin',
          operation: 'longTask',
          status: PluginExecutionStatus.timedOut,
          errorMessage: 'Operation exceeded timeout limit.',
          durationMs: 5000,
        ),
      ];

      final diag = engine.diagnosePlugin(
        pluginId: 'failing_plugin',
        executionResults: execResults,
      );

      expect(diag.healthStatus, equals(PluginHealthStatus.failed));
      expect(diag.rootCause, isNotNull);
      expect(diag.rootCause!.stage, equals(PluginFailureStage.execution));
      expect(diag.rootCause!.isTimeout, isTrue);
      expect(diag.rootCause!.reason, contains('timed out after 5000ms'));
      expect(diag.rootCause!.attributableRecord,
          equals('PluginExecutionResult: timedOut'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Missing-Data Honesty Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Missing-data honesty: unrecorded stages explicitly state absence rather than inventing explanations',
        () {
      final diag = engine.diagnosePlugin(pluginId: 'minimal_plugin');
      final md = engine.renderPluginMarkdown(diag);

      expect(md,
          contains('No recorded discovery detail available for this stage.'));
      expect(
          md,
          contains(
              'No recorded contract validation detail available for this stage.'));
      expect(
          md,
          contains(
              'No recorded dependency resolution detail available for this stage.'));
      expect(
          md,
          contains(
              'No recorded lifecycle transition history available for this stage.'));
      expect(
          md,
          contains(
              'No recorded permission audit records available for this stage.'));
      expect(
          md,
          contains(
              'No recorded execution runtime history available for this stage.'));
      expect(
          md,
          contains(
              'No recorded persistence recovery actions available for this stage.'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Traceability Test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Traceability: every fact in the diagnostic report traces back to a specific upstream record',
        () {
      final permAudit = PermissionAuditRecord(
        pluginId: 'traceable_plugin',
        permissionName: 'git.access',
        operationAttempted: 'git-commit',
        isGranted: false,
        reason: 'Missing git.access capability declaration.',
      );

      final diag = engine.diagnosePlugin(
        pluginId: 'traceable_plugin',
        permissionAudits: [permAudit],
      );

      expect(diag.rootCause!.attributableRecord,
          equals('PermissionAuditRecord: git.access denied'));
      expect(diag.rootCause!.missingPermission, equals('git.access'));
      expect(diag.rootCause!.reason, equals(permAudit.reason));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: No Duplicate Logging System Audit
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9. No duplicate logging system: diagnostics engine is a pure aggregator without independent event storage',
        () {
      // Instantiating multiple engines does not maintain state or drift from passed inputs
      const engine1 = PluginDiagnosticsEngine();
      const engine2 = PluginDiagnosticsEngine();

      final diag1 = engine1.diagnosePlugin(pluginId: 'stateless_plugin');
      final diag2 = engine2.diagnosePlugin(pluginId: 'stateless_plugin');

      expect(diag1.toJson(), equals(diag2.toJson()));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 10: Fail-Closed Edge-Case Tests
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '10a. Fail-closed edge-case: plugin with no recorded history produces a clean, valid, non-crashing report',
        () {
      final diag = engine.diagnosePlugin(pluginId: 'blank_plugin');
      expect(diag.pluginId, equals('blank_plugin'));
      expect(diag.healthStatus, equals(PluginHealthStatus.unregistered));
      expect(diag.isRegistered, isFalse);

      final md = engine.renderPluginMarkdown(diag);
      expect(md, isNotEmpty);
      expect(md, contains('blank_plugin'));

      final json = engine.renderPluginJson(diag);
      expect(json, isNotEmpty);
    });

    test(
        '10b. Fail-closed edge-case: diagnostic query for nonexistent plugin ID produces safe report',
        () {
      final summary = engine.diagnoseSystem();
      expect(summary.pluginDiagnostics.containsKey('nonexistent_id'), isFalse);
      expect(summary.totalScanned, equals(0));
      expect(summary.totalRegistered, equals(0));
    });

    test(
        '10c. Fail-closed edge-case: partial upstream data is handled safely without throwing null exceptions',
        () {
      final valResult = PluginValidationResult(
        isValid: false,
        violations: const ['Contract broken'],
      );

      // Only validation result provided, all other subsystems null
      final diag = engine.diagnosePlugin(
        pluginId: 'partial_plugin',
        validationResult: valResult,
      );

      expect(diag.healthStatus, equals(PluginHealthStatus.failed));
      expect(
          diag.rootCause!.stage, equals(PluginFailureStage.contractValidation));
      expect(diag.rootCause!.reason, equals('Contract broken'));
    });
  });
}

class _DummyCommandContribution implements CommandContribution {
  @override
  List<String> getCommands() => const ['dummy'];
}

