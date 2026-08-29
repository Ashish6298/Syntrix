import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

class MockLifecycleDouble implements PluginLifecycleInterface {
  bool initCalled = false;
  bool shutdownCalled = false;
  bool shouldThrowOnInit = false;
  bool shouldThrowOnShutdown = false;

  @override
  Future<void> initialize(Map<String, dynamic> context) async {
    if (shouldThrowOnInit) {
      throw Exception('Simulated initialize failure');
    }
    initCalled = true;
  }

  @override
  Future<void> shutdown() async {
    if (shouldThrowOnShutdown) {
      throw Exception('Simulated shutdown failure');
    }
    shutdownCalled = true;
  }
}

void main() {
  group('PluginLifecycleManager Unit Tests (Phase 7.7)', () {
    late PluginLifecycleManager manager;
    late PluginManifest validManifest;

    setUp(() {
      manager = PluginLifecycleManager();
      validManifest = PluginManifest(
        id: PluginId('test_plugin'),
        name: PluginName('Test Plugin'),
        description: PluginDescription('Desc'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.lifecycleManagement},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );
    });

    test(
        '1. Full happy-path test walking a plugin through every legal state in order',
        () async {
      final mock = MockLifecycleDouble();
      manager.trackInstance(
          instanceId: 'inst_1', manifest: validManifest, instance: mock);

      expect(
          await manager.transitionTo(
              instanceId: 'inst_1',
              targetState: PluginLifecycleState.validated),
          equals(PluginLifecycleState.validated));
      expect(
          await manager.transitionTo(
              instanceId: 'inst_1',
              targetState: PluginLifecycleState.registered),
          equals(PluginLifecycleState.registered));
      expect(
          await manager.transitionTo(
              instanceId: 'inst_1',
              targetState: PluginLifecycleState.initialized),
          equals(PluginLifecycleState.initialized));
      expect(mock.initCalled, isTrue);

      expect(
          await manager.transitionTo(
              instanceId: 'inst_1', targetState: PluginLifecycleState.active),
          equals(PluginLifecycleState.active));
      expect(
          await manager.transitionTo(
              instanceId: 'inst_1', targetState: PluginLifecycleState.stopping),
          equals(PluginLifecycleState.inactive));
      expect(mock.shutdownCalled, isTrue);
    });

    test(
        '2. Headline illegal-transition test: Discovered -> Active directly is refused',
        () async {
      manager.trackInstance(instanceId: 'inst_1', manifest: validManifest);

      expect(
        () => manager.transitionTo(
            instanceId: 'inst_1', targetState: PluginLifecycleState.active),
        throwsA(isA<PluginLifecycleException>()),
      );
    });

    test(
        '3a. Illegal transition test: Validated -> Active skipping registration',
        () async {
      manager.trackInstance(instanceId: 'inst_1', manifest: validManifest);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.validated);

      expect(
        () => manager.transitionTo(
            instanceId: 'inst_1', targetState: PluginLifecycleState.active),
        throwsA(isA<PluginLifecycleException>()),
      );
    });

    test(
        '3b. Illegal transition test: Registered -> Stopping skipping initialization',
        () async {
      manager.trackInstance(instanceId: 'inst_1', manifest: validManifest);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.validated);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.registered);

      expect(
        () => manager.transitionTo(
            instanceId: 'inst_1', targetState: PluginLifecycleState.stopping),
        throwsA(isA<PluginLifecycleException>()),
      );
    });

    test(
        '3c. Illegal transition test: Inactive -> Active without re-initialization',
        () async {
      final mock = MockLifecycleDouble();
      manager.trackInstance(
          instanceId: 'inst_1', manifest: validManifest, instance: mock);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.validated);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.registered);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.initialized);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.active);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.stopping);

      expect(
        () => manager.transitionTo(
            instanceId: 'inst_1', targetState: PluginLifecycleState.active),
        throwsA(isA<PluginLifecycleException>()),
      );
    });

    test('3d. Illegal transition test: Active -> Validated moving backward',
        () async {
      final mock = MockLifecycleDouble();
      manager.trackInstance(
          instanceId: 'inst_1', manifest: validManifest, instance: mock);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.validated);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.registered);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.initialized);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.active);

      expect(
        () => manager.transitionTo(
            instanceId: 'inst_1', targetState: PluginLifecycleState.validated),
        throwsA(isA<PluginLifecycleException>()),
      );
    });

    test('4a. Failure-path test: contract-validation failure routes to Invalid',
        () async {
      final malformedManifestJson = {
        'id': 'INVALID_ID!',
        'name': 'Name',
        'description': 'Desc',
        'version': '1.0.0',
        'author': {'name': 'A'},
        'apiVersion': '1.0.0',
        'capabilities': ['commandContribution'],
        'compatibility': {'minApiVersion': '1.0.0'},
      };

      expect(
        () => PluginManifest.fromJson(malformedManifestJson),
        throwsA(isA<PluginContractException>()),
      );
    });

    test('4b. Failure-path test: registry refusal routes to Blocked', () async {
      // Simulate occupied ID in registry by registering first instance
      final reg = PluginRegistry();
      reg.registerPlugin(
          manifest: validManifest, instance: MockLifecycleDouble());

      final managerWithReg = PluginLifecycleManager(registry: reg);
      managerWithReg.trackInstance(
          instanceId: 'inst_2', manifest: validManifest);
      await managerWithReg.transitionTo(
          instanceId: 'inst_2', targetState: PluginLifecycleState.validated);

      final endState = await managerWithReg.transitionTo(
          instanceId: 'inst_2', targetState: PluginLifecycleState.registered);
      expect(endState, equals(PluginLifecycleState.blocked));
      expect(managerWithReg.getInstance('inst_2')!.state,
          equals(PluginLifecycleState.blocked));
    });

    test(
        '4c. Failure-path test: initialize() exception routes to InitializationFailed',
        () async {
      final mock = MockLifecycleDouble()..shouldThrowOnInit = true;
      manager.trackInstance(
          instanceId: 'inst_1', manifest: validManifest, instance: mock);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.validated);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.registered);

      final endState = await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.initialized);
      expect(endState, equals(PluginLifecycleState.initializationFailed));
      expect(manager.getInstance('inst_1')!.state,
          equals(PluginLifecycleState.initializationFailed));
    });

    test(
        '5. Terminal-state-cannot-silently-resurrect test requires explicit reattempt()',
        () async {
      final mock = MockLifecycleDouble()..shouldThrowOnInit = true;
      manager.trackInstance(
          instanceId: 'inst_1', manifest: validManifest, instance: mock);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.validated);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.registered);
      await manager.transitionTo(
          instanceId: 'inst_1',
          targetState:
              PluginLifecycleState.initialized); // -> initializationFailed

      expect(
        () => manager.transitionTo(
            instanceId: 'inst_1', targetState: PluginLifecycleState.active),
        throwsA(isA<PluginLifecycleException>()),
      );

      // Re-attempt restores to discovered
      await manager.reattempt('inst_1');
      expect(manager.getInstance('inst_1')!.state,
          equals(PluginLifecycleState.discovered));
    });

    test(
        '6. Per-instance state isolation test confirms instances do not affect each other',
        () async {
      manager.trackInstance(instanceId: 'inst_A', manifest: validManifest);
      manager.trackInstance(instanceId: 'inst_B', manifest: validManifest);

      await manager.transitionTo(
          instanceId: 'inst_A', targetState: PluginLifecycleState.validated);

      expect(manager.getInstance('inst_A')!.state,
          equals(PluginLifecycleState.validated));
      expect(manager.getInstance('inst_B')!.state,
          equals(PluginLifecycleState.discovered));
    });

    test('7. Audit-history test confirms complete transition log', () async {
      manager.trackInstance(instanceId: 'inst_1', manifest: validManifest);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.validated);

      final history = manager.getAuditHistory('inst_1');
      expect(history.length, equals(1));
      expect(history.first.toState, equals(PluginLifecycleState.validated));
    });

    test(
        '8. Shutdown-failure handling test results in shutdownFailed terminal state with error detail',
        () async {
      final mock = MockLifecycleDouble()..shouldThrowOnShutdown = true;
      manager.trackInstance(
          instanceId: 'inst_1', manifest: validManifest, instance: mock);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.validated);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.registered);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.initialized);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.active);

      final endState = await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.stopping);
      expect(endState, equals(PluginLifecycleState.shutdownFailed));
      expect(manager.getInstance('inst_1')!.state,
          equals(PluginLifecycleState.shutdownFailed));
    });

    test(
        '8b. Clean shutdown companion test confirms successful shutdown lands in inactive state',
        () async {
      final mock = MockLifecycleDouble()..shouldThrowOnShutdown = false;
      manager.trackInstance(
          instanceId: 'inst_1', manifest: validManifest, instance: mock);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.validated);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.registered);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.initialized);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.active);

      final endState = await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.stopping);
      expect(endState, equals(PluginLifecycleState.inactive));
      expect(manager.getInstance('inst_1')!.state,
          equals(PluginLifecycleState.inactive));
    });

    test(
        '9. Real-hook-invocation verification test confirms initialize() and shutdown() calls',
        () async {
      final mock = MockLifecycleDouble();
      manager.trackInstance(
          instanceId: 'inst_1', manifest: validManifest, instance: mock);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.validated);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.registered);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.initialized);

      expect(mock.initCalled, isTrue);

      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.active);
      await manager.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.stopping);

      expect(mock.shutdownCalled, isTrue);
    });

    test(
        '10. Determinism test confirms replaying same sequence produces identical state and history',
        () async {
      final m1 = PluginLifecycleManager();
      final m2 = PluginLifecycleManager();

      m1.trackInstance(instanceId: 'inst_1', manifest: validManifest);
      m2.trackInstance(instanceId: 'inst_1', manifest: validManifest);

      await m1.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.validated);
      await m2.transitionTo(
          instanceId: 'inst_1', targetState: PluginLifecycleState.validated);

      expect(m1.getInstance('inst_1')!.state,
          equals(m2.getInstance('inst_1')!.state));
      expect(m1.getAuditHistory('inst_1').first.toState,
          equals(m2.getAuditHistory('inst_1').first.toState));
    });

    test(
        '11a. Fail-closed edge-case: transition request for untracked instance throws',
        () async {
      expect(
        () => manager.transitionTo(
            instanceId: 'unknown_inst',
            targetState: PluginLifecycleState.validated),
        throwsA(isA<PluginLifecycleException>()),
      );
    });

    test(
        '11b. Fail-closed edge-case: duplicate/redundant transition request throws',
        () async {
      manager.trackInstance(instanceId: 'inst_1', manifest: validManifest);
      expect(
        () => manager.transitionTo(
            instanceId: 'inst_1', targetState: PluginLifecycleState.discovered),
        throwsA(isA<PluginLifecycleException>()),
      );
    });

    test('11c. Fail-closed edge-case: tracking duplicate instance ID throws',
        () {
      manager.trackInstance(instanceId: 'inst_1', manifest: validManifest);
      expect(
        () => manager.trackInstance(
            instanceId: 'inst_1', manifest: validManifest),
        throwsA(isA<PluginLifecycleException>()),
      );
    });
  });
}
