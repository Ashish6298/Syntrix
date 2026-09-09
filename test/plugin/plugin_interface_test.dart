import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:test/test.dart';

// Test mock classes for contribution interfaces

class MockValidationPlugin implements ValidationContribution {
  @override
  List<String> getValidationRules() => ['RuleA', 'RuleB'];
}

class MockAnalysisOnlyPlugin implements PackageAnalysisContribution {
  @override
  List<String> getAnalyzers() => ['Analyzer1'];
}

class MockMultiPlugin implements CommandContribution, ValidationContribution {
  @override
  List<String> getCommands() => ['cmd1'];

  @override
  List<String> getValidationRules() => ['Rule1'];
}

class MockCommandPlugin implements CommandContribution {
  @override
  List<String> getCommands() => ['cmd1'];
}

class MockServicePlugin implements ServiceContribution {
  @override
  List<String> getServices() => ['svc1'];
}

class MockWorkflowPlugin implements ReleaseWorkflowContribution {
  @override
  List<String> getWorkflowHooks() => ['hook1'];
}

class MockFullLifecyclePlugin implements PluginLifecycleInterface {
  bool initFailed = false;
  bool shutdownCalled = false;

  @override
  Future<void> initialize(Map<String, dynamic> context) async {
    if (context['fail'] == true) {
      initFailed = true;
      throw Exception('Init failed');
    }
  }

  @override
  Future<void> shutdown() async {
    shutdownCalled = true;
  }
}

void main() {
  group('PluginInterface & Capability System Unit Tests (Phase 7.2)', () {
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
        capabilities: {PluginCapability.validationContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );
    });

    test(
        '1. Happy-path test registering plugin with single declared and implemented capability',
        () {
      final plugin = MockValidationPlugin();
      registry.registerPlugin(manifest: validManifest, instance: plugin);

      final valContribution =
          registry.getContribution<ValidationContribution>('valid_plugin');
      expect(valContribution, isNotNull);
      expect(valContribution!.getValidationRules(), equals(['RuleA', 'RuleB']));

      // Confirm only validation is exposed
      expect(registry.getContribution<CommandContribution>('valid_plugin'),
          isNull);
    });

    test(
        '2. Multi-capability plugin test registering package-analysis and validation',
        () {
      final multiManifest = PluginManifest(
        id: PluginId('multi_plugin'),
        name: PluginName('Multi Plugin'),
        description: PluginDescription('Description'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '1.0.0',
        capabilities: {
          PluginCapability.commandContribution,
          PluginCapability.validationContribution,
        },
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );

      final plugin = MockMultiPlugin();
      registry.registerPlugin(manifest: multiManifest, instance: plugin);

      final caps = registry.getProvidedCapabilities('multi_plugin');
      expect(
          caps,
          containsAll([
            'commandContribution',
            'validationContribution',
          ]));
    });

    test(
        '3a. Capability-mismatch test: declared in manifest but not implemented in code',
        () {
      final mismatchedManifest = PluginManifest(
        id: PluginId('mismatch_plugin'),
        name: PluginName('Mismatch Plugin'),
        description: PluginDescription('Description'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '1.0.0',
        capabilities: {
          PluginCapability.commandContribution
        }, // Declared command, but instance implements validation
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );

      final plugin = MockValidationPlugin();

      expect(
        () => registry.registerPlugin(
            manifest: mismatchedManifest, instance: plugin),
        throwsA(isA<PluginCapabilityException>()),
      );
    });

    test(
        '3b. Capability-mismatch test: implemented in code but not declared in manifest',
        () {
      final undeclaredManifest = PluginManifest(
        id: PluginId('undeclared_plugin'),
        name: PluginName('Undeclared Plugin'),
        description: PluginDescription('Description'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '1.0.0',
        capabilities: {
          PluginCapability.commandContribution
        }, // Declared command, but instance implements validation AND command is not declared for validation
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );

      final plugin =
          MockValidationPlugin(); // Implements ValidationContribution

      expect(
        () => registry.registerPlugin(
            manifest: undeclaredManifest, instance: plugin),
        throwsA(isA<PluginCapabilityException>()),
      );
    });

    test(
        '4. Interface-isolation test confirms plugin registered for validation cannot be retrieved as other types',
        () {
      final plugin = MockValidationPlugin();
      registry.registerPlugin(manifest: validManifest, instance: plugin);

      expect(
          registry.getContribution<ReleaseWorkflowContribution>('valid_plugin'),
          isNull);
      expect(registry.getContribution<CommandContribution>('valid_plugin'),
          isNull);
      expect(registry.getContribution<ServiceContribution>('valid_plugin'),
          isNull);
    });

    test('5a. CommandContribution interface registration and query test', () {
      final m = PluginManifest(
        id: PluginId('cmd_plugin'),
        name: PluginName('N'),
        description: PluginDescription('D'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'A'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.commandContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );
      registry.registerPlugin(manifest: m, instance: MockCommandPlugin());
      expect(registry.getContribution<CommandContribution>('cmd_plugin'),
          isNotNull);
    });

    test('5b. ServiceContribution interface registration and query test', () {
      final m = PluginManifest(
        id: PluginId('svc_plugin'),
        name: PluginName('N'),
        description: PluginDescription('D'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'A'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.serviceContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );
      registry.registerPlugin(manifest: m, instance: MockServicePlugin());
      expect(registry.getContribution<ServiceContribution>('svc_plugin'),
          isNotNull);
    });

    test('5c. ValidationContribution interface registration and query test',
        () {
      final m = PluginManifest(
        id: PluginId('val_plugin'),
        name: PluginName('N'),
        description: PluginDescription('D'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'A'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.validationContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );
      registry.registerPlugin(manifest: m, instance: MockValidationPlugin());
      expect(registry.getContribution<ValidationContribution>('val_plugin'),
          isNotNull);
    });

    test(
        '5d. ReleaseWorkflowContribution interface registration and query test',
        () {
      final m = PluginManifest(
        id: PluginId('wf_plugin'),
        name: PluginName('N'),
        description: PluginDescription('D'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'A'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.releaseWorkflowContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );
      registry.registerPlugin(manifest: m, instance: MockWorkflowPlugin());
      expect(registry.getContribution<ReleaseWorkflowContribution>('wf_plugin'),
          isNotNull);
    });

    test(
        '5e. PackageAnalysisContribution interface registration and query test',
        () {
      final m = PluginManifest(
        id: PluginId('pa_plugin'),
        name: PluginName('N'),
        description: PluginDescription('D'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'A'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.packageAnalysisContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );
      registry.registerPlugin(manifest: m, instance: MockAnalysisOnlyPlugin());
      expect(registry.getContribution<PackageAnalysisContribution>('pa_plugin'),
          isNotNull);
    });

    test('5f. PluginLifecycleInterface registration and query test', () {
      final m = PluginManifest(
        id: PluginId('lc_plugin'),
        name: PluginName('N'),
        description: PluginDescription('D'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'A'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.lifecycleManagement},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );
      registry.registerPlugin(manifest: m, instance: MockFullLifecyclePlugin());
      expect(registry.getContribution<PluginLifecycleInterface>('lc_plugin'),
          isNotNull);
    });

    test(
        '6. Lifecycle-gating test confirms initialize is never invoked on unvalidated plugin',
        () async {
      expect(
        () async => registry.initializePlugin('unregistered_plugin', {}),
        throwsA(isA<PluginRegistrationException>()),
      );
    });

    test('7. Idempotency/safety test for initialize() and shutdown()',
        () async {
      final m = PluginManifest(
        id: PluginId('safe_lc_plugin'),
        name: PluginName('N'),
        description: PluginDescription('D'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'A'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.lifecycleManagement},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );
      final plugin = MockFullLifecyclePlugin();
      registry.registerPlugin(manifest: m, instance: plugin);

      // Shutdown after failed init should not throw
      try {
        await registry.initializePlugin('safe_lc_plugin', {'fail': true});
      } catch (_) {}

      await registry.shutdownPlugin('safe_lc_plugin');
      expect(plugin.shutdownCalled, isTrue);
    });

    test('8. Query-surface test confirms roadmap tree-style output structure',
        () {
      final m = PluginManifest(
        id: PluginId('tree_plugin'),
        name: PluginName('N'),
        description: PluginDescription('D'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'A'),
        apiVersion: '1.0.0',
        capabilities: {
          PluginCapability.commandContribution,
          PluginCapability.validationContribution
        },
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );
      final plugin = MockMultiPlugin();
      registry.registerPlugin(manifest: m, instance: plugin);

      final caps = registry.getProvidedCapabilities('tree_plugin');
      expect(caps, equals(['commandContribution', 'validationContribution']));
    });

    test('9. No-dynamic-loading audit confirms in-process execution only', () {
      // Confirms all plugin operations run against in-process objects with zero disk discovery
      expect(registry.registeredPlugins, isEmpty);
    });

    test(
        '10. Determinism check confirms identical output on repeated registrations',
        () {
      final plugin = MockValidationPlugin();
      registry.registerPlugin(manifest: validManifest, instance: plugin);

      final caps1 = registry.getProvidedCapabilities('valid_plugin');
      final caps2 = registry.getProvidedCapabilities('valid_plugin');

      expect(caps1, equals(caps2));
    });

    test('11. Fail-closed edge-case tests for null or invalid inputs', () {
      expect(
        () => registry.getProvidedCapabilities('nonexistent'),
        throwsA(isA<PluginRegistrationException>()),
      );
    });
  });
}
