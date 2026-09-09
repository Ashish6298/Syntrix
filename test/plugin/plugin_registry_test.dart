import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:test/test.dart';

class MockLifecyclePlugin implements PluginLifecycleInterface {
  bool initialized = false;
  bool shutdownCalled = false;

  @override
  Future<void> initialize(Map<String, dynamic> context) async {
    initialized = true;
  }

  @override
  Future<void> shutdown() async {
    shutdownCalled = true;
  }
}

class MockCommandValidationPlugin
    implements CommandContribution, ValidationContribution {
  @override
  List<String> getCommands() => ['cmd1'];

  @override
  List<String> getValidationRules() => ['rule1'];
}

void main() {
  group('PluginRegistry Unit Tests (Phase 7.3)', () {
    late PluginRegistry registry;
    late PluginManifest validManifest;

    setUp(() {
      registry = PluginRegistry();
      validManifest = PluginManifest(
        id: PluginId('valid_plugin'),
        name: PluginName('Valid Plugin'),
        description: PluginDescription('Description'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '1.0.0',
        capabilities: {
          PluginCapability.commandContribution,
          PluginCapability.validationContribution
        },
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );
    });

    test(
        '1. Happy-path registration test for fully valid, uniquely-IDed plugin',
        () {
      final plugin = MockCommandValidationPlugin();
      registry.registerPlugin(manifest: validManifest, instance: plugin);

      expect(registry.exists('valid_plugin'), isTrue);
      expect(registry.findPlugin('valid_plugin'), equals(validManifest));
      expect(registry.listPlugins().length, equals(1));
    });

    test(
        '2. Registration-rejection test for plugin that fails 7.1 contract validation',
        () {
      final invalidManifestJson = {
        'id': 'INVALID ID!', // Bad ID format
        'name': 'Invalid Plugin',
        'description': 'Desc',
        'version': '1.0.0',
        'author': {'name': 'A'},
        'apiVersion': '1.0.0',
        'capabilities': ['commandContribution'],
        'compatibility': {'minApiVersion': '1.0.0'},
      };

      expect(
        () => registry.registerPlugin(
          manifest: PluginManifest.fromJson(invalidManifestJson),
          instance: MockCommandValidationPlugin(),
        ),
        throwsA(isA<PluginContractException>()),
      );
    });

    test(
        '3. Registration-rejection test for plugin that fails 7.2 capability-gating',
        () {
      final mismatchedManifest = PluginManifest(
        id: PluginId('mismatch_plugin'),
        name: PluginName('Mismatch Plugin'),
        description: PluginDescription('Desc'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '1.0.0',
        capabilities: {
          PluginCapability.serviceContribution
        }, // Declared service, but instance is command/validation
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );

      expect(
        () => registry.registerPlugin(
            manifest: mismatchedManifest,
            instance: MockCommandValidationPlugin()),
        throwsA(isA<PluginCapabilityException>()),
      );
    });

    test(
        '4. Duplicate-ID rejection test refuses second registration by default',
        () {
      final plugin = MockCommandValidationPlugin();
      registry.registerPlugin(manifest: validManifest, instance: plugin);

      expect(
        () =>
            registry.registerPlugin(manifest: validManifest, instance: plugin),
        throwsA(isA<PluginRegistrationException>()),
      );
    });

    test(
        '5. Distinct explicit-replace/update test succeeds when invoked intentionally',
        () {
      final plugin = MockCommandValidationPlugin();
      registry.registerPlugin(manifest: validManifest, instance: plugin);

      final updatedManifest = PluginManifest(
        id: PluginId('valid_plugin'),
        name: PluginName('Updated Plugin Name'),
        description: PluginDescription('Description'),
        version: SemVer.parse('1.1.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '1.0.0',
        capabilities: {
          PluginCapability.commandContribution,
          PluginCapability.validationContribution
        },
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );

      registry.updatePlugin(manifest: updatedManifest, instance: plugin);

      expect(registry.findPlugin('valid_plugin')!.name.value,
          equals('Updated Plugin Name'));
      expect(registry.findPlugin('valid_plugin')!.version.toString(),
          equals('1.1.0'));
    });

    test('6. Unregistration test removes plugin and capability registrations',
        () {
      final plugin = MockCommandValidationPlugin();
      registry.registerPlugin(manifest: validManifest, instance: plugin);

      expect(registry.exists('valid_plugin'), isTrue);

      final removed = registry.unregisterPlugin('valid_plugin');
      expect(removed, isTrue);
      expect(registry.exists('valid_plugin'), isFalse);
      expect(registry.findPlugin('valid_plugin'), isNull);
      expect(registry.listPlugins(), isEmpty);
    });

    test(
        '7. Unregister-nonexistent-plugin test handles unregistration gracefully without throwing',
        () {
      final removed = registry.unregisterPlugin('nonexistent_id');
      expect(removed, isFalse);
    });

    test('8a. find-by-ID operation test', () {
      final plugin = MockCommandValidationPlugin();
      registry.registerPlugin(manifest: validManifest, instance: plugin);

      expect(registry.findPlugin('valid_plugin'), equals(validManifest));
      expect(registry.findPlugin('unknown'), isNull);
    });

    test('8b. list-all operation test', () {
      final plugin = MockCommandValidationPlugin();
      registry.registerPlugin(manifest: validManifest, instance: plugin);

      final list = registry.listPlugins();
      expect(list.length, equals(1));
      expect(list.first.id.value, equals('valid_plugin'));
    });

    test('8c. exists-check operation test', () {
      final plugin = MockCommandValidationPlugin();
      registry.registerPlugin(manifest: validManifest, instance: plugin);

      expect(registry.exists('valid_plugin'), isTrue);
      expect(registry.exists('unknown'), isFalse);
    });

    test(
        '9. Compatibility-checking test defers to Phase 7.1 PluginCompatibility data',
        () {
      final plugin = MockCommandValidationPlugin();
      registry.registerPlugin(manifest: validManifest, instance: plugin);

      expect(registry.checkCompatibility('valid_plugin', '1.0.0'), isTrue);
      expect(registry.checkCompatibility('valid_plugin', '9.9.9'), isFalse);
    });

    test(
        '10. Capability-query test returns matching plugins and updates after unregistration',
        () {
      final plugin = MockCommandValidationPlugin();
      registry.registerPlugin(manifest: validManifest, instance: plugin);

      final matches = registry
          .queryPluginsByCapability(PluginCapability.commandContribution);
      expect(matches.length, equals(1));
      expect(matches.first.id.value, equals('valid_plugin'));

      registry.unregisterPlugin('valid_plugin');
      final matchesAfter = registry
          .queryPluginsByCapability(PluginCapability.commandContribution);
      expect(matchesAfter, isEmpty);
    });

    test('11. Critical registration-does-not-imply-execution test', () async {
      final lcManifest = PluginManifest(
        id: PluginId('lc_plugin'),
        name: PluginName('N'),
        description: PluginDescription('D'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'A'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.lifecycleManagement},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );
      final lcPlugin = MockLifecyclePlugin();

      // Registering must NOT execute initialize()
      registry.registerPlugin(manifest: lcManifest, instance: lcPlugin);
      expect(lcPlugin.initialized, isFalse);

      // Explicit activation call required to execute initialize()
      await registry.activatePlugin('lc_plugin', {});
      expect(lcPlugin.initialized, isTrue);
    });

    test(
        '12. Single-source-of-truth test confirms registry holds direct reference to manifest',
        () {
      final plugin = MockCommandValidationPlugin();
      registry.registerPlugin(manifest: validManifest, instance: plugin);

      final found = registry.findPlugin('valid_plugin');
      expect(identical(found, validManifest), isTrue);
    });

    test(
        '13. Determinism test confirms identical operations produce identical results',
        () {
      final plugin = MockCommandValidationPlugin();
      registry.registerPlugin(manifest: validManifest, instance: plugin);

      final list1 = registry.listPlugins();
      final list2 = registry.listPlugins();

      expect(list1, equals(list2));
    });

    test('14. Fail-closed edge-case tests for null or invalid inputs', () {
      expect(
        () => registry.getProvidedCapabilities(''),
        throwsA(isA<PluginRegistrationException>()),
      );
    });
  });
}
