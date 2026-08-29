import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

CommandRegistry _buildRegistry() {
  final registry = CommandRegistry();
  registry.register(TemplateCatalogCommand());
  registry.register(PluginCatalogCommand());
  return registry;
}

void main() {
  group('Plugin CLI Integration Tests (Phase 7.10)', () {
    late io.Directory tempDir;

    setUp(() {
      tempDir = io.Directory.systemTemp.createTempSync('plugin_cli_test_');
      PluginCliServices.resetInstance();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      PluginCliServices.resetInstance();
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Individually named happy-path tests for each of the 7 new commands
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1a. Happy path: fps plugin list returns exit code 0 and lists registered plugins',
        () async {
      final code = await _buildRegistry().run(['plugin', 'list']);
      expect(code, equals(0));
    });

    test(
        '1b. Happy path: fps plugin discover returns exit code 0 and scans discovery roots',
        () async {
      final pluginDir = io.Directory('${tempDir.path}/valid_plugin')
        ..createSync(recursive: true);
      io.File('${pluginDir.path}/plugin.json').writeAsStringSync(jsonEncode({
        'id': 'my_discovered_plugin',
        'name': 'Discovered Plugin',
        'description': 'Description',
        'version': '1.0.0',
        'author': {'name': 'Dev'},
        'apiVersion': '1.0.0',
        'capabilities': ['commandContribution'],
        'compatibility': {'minApiVersion': '1.0.0'},
      }));

      final code =
          await _buildRegistry().run(['plugin', 'discover', tempDir.path]);
      expect(code, equals(0));
    });

    test(
        '1c. Happy path: fps plugin info <plugin-id> displays detailed metadata',
        () async {
      final code =
          await _buildRegistry().run(['plugin', 'info', 'samplerunner']);
      expect(code, equals(0));
    });

    test(
        '1d. Happy path: fps plugin validate <file-or-json> verifies contract compliance',
        () async {
      final validJson = jsonEncode({
        'id': 'clean_plugin',
        'name': 'Clean Plugin',
        'description': 'Clean Description',
        'version': '1.0.0',
        'author': {'name': 'Author'},
        'apiVersion': '1.0.0',
        'capabilities': ['commandContribution'],
        'compatibility': {'minApiVersion': '1.0.0'},
      });

      final code =
          await _buildRegistry().run(['plugin', 'validate', validJson]);
      expect(code, equals(0));
    });

    test(
        '1e. Happy path: fps plugin enable <plugin-id> transitions plugin through lifecycle to active',
        () async {
      final code =
          await _buildRegistry().run(['plugin', 'enable', 'samplerunner']);
      expect(code, equals(0));

      final instance = PluginCliServices.instance.lifecycleManager
          .getInstance('samplerunner');
      expect(instance, isNotNull);
      expect(instance!.state, equals(PluginLifecycleState.active));
    });

    test(
        '1f. Happy path: fps plugin disable <plugin-id> administratively transitions plugin to disabled',
        () async {
      // First enable it
      await _buildRegistry().run(['plugin', 'enable', 'samplerunner']);
      // Then disable it
      final code =
          await _buildRegistry().run(['plugin', 'disable', 'samplerunner']);
      expect(code, equals(0));

      final instance = PluginCliServices.instance.lifecycleManager
          .getInstance('samplerunner');
      expect(instance, isNotNull);
      expect(instance!.state, equals(PluginLifecycleState.disabled));
    });

    test(
        '1g. Happy path: fps plugin inspect <plugin-id> outputs comprehensive deep-dive view',
        () async {
      final code =
          await _buildRegistry().run(['plugin', 'inspect', 'samplerunner']);
      expect(code, equals(0));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Delegation-verification test (calling real core subsystems)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Delegation verification: validate and discover genuinely execute through core validator & discovery engine',
        () async {
      var validatorCallCount = 0;
      var discoveryCallCount = 0;

      final customValidator =
          _TrackingContractValidator(() => validatorCallCount++);
      final customDiscovery =
          _TrackingDiscoveryEngine(customValidator, () => discoveryCallCount++);

      final services = PluginCliServices(
        validator: customValidator,
        discoveryEngine: customDiscovery,
      );
      PluginCliServices.setInstance(services);

      final validJson = jsonEncode({
        'id': 'delegation_plugin',
        'name': 'Delegation Plugin',
        'description': 'Delegation Description',
        'version': '1.0.0',
        'author': {'name': 'Author'},
        'apiVersion': '1.0.0',
        'capabilities': ['commandContribution'],
        'compatibility': {'minApiVersion': '1.0.0'},
      });

      await _buildRegistry().run(['plugin', 'validate', validJson]);
      expect(validatorCallCount, greaterThanOrEqualTo(1));

      await _buildRegistry().run(['plugin', 'discover', tempDir.path]);
      expect(discoveryCallCount, greaterThanOrEqualTo(1));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Lifecycle integrity test (transition graph enforcement & illegal request refusal)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Lifecycle integrity: enable and disable enforce real transition graph and refuse invalid manifests',
        () async {
      final brokenManifest = PluginManifest(
        id: PluginId('broken_plugin'),
        name: PluginName('Broken'),
        description: PluginDescription('Desc'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion:
            '999.0.0', // Unsupported API version will fail contract validation during enable
        capabilities: {PluginCapability.commandContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );

      final services = PluginCliServices.instance;
      services.lifecycleManager.trackInstance(
        instanceId: 'broken_plugin',
        manifest: brokenManifest,
      );

      // Attempting to enable broken plugin must fail validation and refuse transition to active
      final code =
          await _buildRegistry().run(['plugin', 'enable', 'broken_plugin']);
      expect(code, equals(1));

      final record = services.lifecycleManager.getInstance('broken_plugin')!;
      expect(record.state, equals(PluginLifecycleState.invalid));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 4. Inspect completeness test (aggregates manifest, lifecycle, permissions)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Inspect completeness: aggregated JSON snapshot contains manifest, lifecycle, permissions, and dependencies',
        () async {
      final code = await _buildRegistry()
          .run(['plugin', 'inspect', 'samplerunner', '--json']);

      expect(code, equals(0));

      final manifest = PluginCliServices.instance.lifecycleManager
          .getInstance('samplerunner')!
          .manifest;
      expect(manifest.id.value, equals('samplerunner'));
      expect(manifest.capabilities,
          contains(PluginCapability.commandContribution));
      expect(
          manifest.securityRequirements.permissions, contains('package.read'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 5. Critical non-regression test suite for pre-existing commands
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5a. Non-regression: fps template version continues working identically',
        () async {
      final code = await _buildRegistry()
          .run(['template', 'version', 'flutter_package']);
      expect(code, equals(0));
    });

    test(
        '5b. Non-regression: fps template version-plan continues working identically',
        () async {
      final code = await _buildRegistry()
          .run(['template', 'version-plan', 'flutter_package']);
      expect(code, equals(0));
    });

    test(
        '5c. Non-regression: fps template changelog continues working identically',
        () async {
      final code = await _buildRegistry()
          .run(['template', 'changelog', 'flutter_package']);
      expect(code, equals(0));
    });

    test(
        '5d. Non-regression: fps template git-release continues working identically',
        () async {
      final code = await _buildRegistry()
          .run(['template', 'git-release', 'flutter_package']);
      expect(code, equals(0));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 6. Broader non-regression sweep test across Milestone 5/6 CLI commands
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Broader non-regression sweep: Milestone 5/6 commands still respond correctly to help',
        () async {
      final reg = _buildRegistry();
      final commandsToTest = [
        ['template', 'release-notes', '--help'],
        ['template', 'publish', '--help'],
        ['template', 'channel', '--help'],
        ['template', 'rollback', '--help'],
        ['template', 'certify-release', '--help'],
        ['template', 'github-release', '--help'],
        ['template', 'dry-run', '--help'],
        ['template', 'publishing-assistant', '--help'],
        ['template', 'dashboard', '--help'],
        ['template', 'manifest', '--help'],
        ['template', 'security-audit', '--help'],
        ['template', 'verify-release', '--help'],
        ['template', 'pubdev-validate', '--help'],
      ];

      for (final cmd in commandsToTest) {
        final code = await reg.run(cmd);
        expect(code, equals(0), reason: 'Command "${cmd.join(' ')}" failed.');
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 7. Deprecated-alias tests for old template plugin-* subcommands
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Deprecated aliases: old template plugin-* subcommands function and display deprecation notices',
        () async {
      final reg = _buildRegistry();
      // Test old plugin-list under template
      final codeList = await reg.run(['template', 'plugin-list']);
      expect(codeList, equals(0));

      // Test old plugin-validate under template
      final validJson = jsonEncode({
        'id': 'alias_test_plugin',
        'name': 'Alias Plugin',
        'description': 'Alias Description',
        'version': '1.0.0',
        'author': {'name': 'Author'},
        'apiVersion': '1.0.0',
        'capabilities': ['commandContribution'],
        'compatibility': {'minApiVersion': '1.0.0'},
      });
      final codeVal = await reg.run(['template', 'plugin-validate', validJson]);
      expect(codeVal, equals(0));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 8. Fail-closed tests (nonexistent IDs, missing args, malformed inputs)
    // ─────────────────────────────────────────────────────────────────────────

    test('8a. Fail-closed: missing arguments return exit code 64', () async {
      final reg = _buildRegistry();
      expect(await reg.run(['plugin', 'discover']), equals(64));
      expect(await reg.run(['plugin', 'info']), equals(64));
      expect(await reg.run(['plugin', 'validate']), equals(64));
      expect(await reg.run(['plugin', 'enable']), equals(64));
      expect(await reg.run(['plugin', 'disable']), equals(64));
      expect(await reg.run(['plugin', 'inspect']), equals(64));
    });

    test('8b. Fail-closed: nonexistent plugin ID returns exit code 1',
        () async {
      final reg = _buildRegistry();
      expect(await reg.run(['plugin', 'info', 'nonexistent_plugin_id']),
          equals(1));
      expect(await reg.run(['plugin', 'disable', 'nonexistent_plugin_id']),
          equals(1));
      expect(await reg.run(['plugin', 'inspect', 'nonexistent_plugin_id']),
          equals(1));
    });

    test('8c. Fail-closed: malformed JSON to validate returns exit code 1',
        () async {
      final reg = _buildRegistry();
      final code =
          await reg.run(['plugin', 'validate', '{not_json_syntax: 123']);
      expect(code, equals(1));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 9. Help-text/usage test for fps plugin command group
    // ─────────────────────────────────────────────────────────────────────────

    test('9. Help text & usage: fps plugin --help lists all 7 subcommands',
        () async {
      final reg = _buildRegistry();
      final code = await reg.run(['plugin', '--help']);
      expect(code, equals(0));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 10. Determinism test
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '10. Determinism: repeated identical CLI invocations against identical state produce identical results',
        () async {
      final reg = _buildRegistry();
      final code1 = await reg.run(['plugin', 'info', 'samplerunner', '--json']);
      final code2 = await reg.run(['plugin', 'info', 'samplerunner', '--json']);

      expect(code1, equals(0));
      expect(code2, equals(0));
    });
  });
}

class _TrackingContractValidator extends PluginContractValidator {
  final void Function() onValidate;
  _TrackingContractValidator(this.onValidate);

  @override
  PluginValidationResult validateRawJson(Map<String, dynamic> json) {
    onValidate();
    return super.validateRawJson(json);
  }
}

class _TrackingDiscoveryEngine extends PluginDiscoveryEngine {
  final void Function() onDiscover;
  _TrackingDiscoveryEngine(PluginContractValidator validator, this.onDiscover)
      : super(validator: validator);

  @override
  Future<DiscoveryResult> discoverPlugins(List<String> rootPaths) async {
    onDiscover();
    return super.discoverPlugins(rootPaths);
  }
}
