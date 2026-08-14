import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

// ── Helpers ───────────────────────────────────────────────────────────────

RemoteRegistryOptions _opts(String id, {bool enabled = true}) =>
    RemoteRegistryOptions(
      id: id,
      baseUrl: 'https://example.com/$id',
      enabled: enabled,
    );

String _json(String registryId, List<String> ids) {
  final templates = ids.map((id) => '''
    {"id":"$id","version":"1.0.0","displayName":"${id.toUpperCase()}","description":"d",
     "projectType":"flutter_package","category":"community","minimumDartSdk":">=3.0.0",
     "tags":["flutter"],"maturity":"stable"}
  ''').join(',');
  return '{"protocolVersion":"1","registryId":"$registryId","templates":[$templates]}';
}

RegistryManager _managerWith(Map<String, String> registryJsonMap) {
  final responses = {
    for (final e in registryJsonMap.entries)
      e.key: TransportResponse(statusCode: 200, body: e.value),
  };
  final transport = MockRegistryTransport(responses);
  final client = RemoteRegistryClient(transport: transport);
  return RegistryManager.withClient(client: client);
}

void main() {
  // ── Registry lifecycle ────────────────────────────────────────────────────

  group('RegistryManager — lifecycle', () {
    test('Add registry returns plan and adds to list', () {
      final manager = _managerWith({});
      manager.add(_opts('r1'));
      expect(manager.listAll().length, equals(1));
      expect(manager.listAll().first.id, equals('r1'));
    });

    test('Add duplicate id throws RegistryConfigurationException', () {
      final manager = _managerWith({});
      manager.add(_opts('r1'));
      expect(
        () => manager.add(_opts('r1')),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });

    test('Dry-run add does not persist registry', () {
      final manager = _managerWith({});
      manager.add(_opts('r1'), dryRun: true);
      expect(manager.listAll(), isEmpty);
    });

    test('Remove deletes registry from list', () {
      final manager = _managerWith({});
      manager.add(_opts('r1'));
      manager.remove('r1');
      expect(manager.listAll(), isEmpty);
    });

    test('Remove non-existent throws RegistryConfigurationException', () {
      final manager = _managerWith({});
      expect(
        () => manager.remove('nonexistent'),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });

    test('Dry-run remove does not actually remove', () {
      final manager = _managerWith({});
      manager.add(_opts('r1'));
      manager.remove('r1', dryRun: true);
      expect(manager.listAll().length, equals(1));
    });

    test('Enable changes registry to enabled=true', () {
      final manager = _managerWith({});
      manager.add(_opts('r1', enabled: false));
      expect(manager.listAll().first.enabled, isFalse);
      manager.enable('r1');
      expect(manager.listAll().first.enabled, isTrue);
    });

    test('Disable changes registry to enabled=false', () {
      final manager = _managerWith({});
      manager.add(_opts('r1'));
      manager.disable('r1');
      expect(manager.listAll().first.enabled, isFalse);
    });

    test('Enable non-existent throws RegistryConfigurationException', () {
      final manager = _managerWith({});
      expect(
        () => manager.enable('nonexistent'),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });
  });

  // ── Refresh & fetch ────────────────────────────────────────────────────────

  group('RegistryManager — refresh', () {
    test('Successful refresh returns accepted records', () async {
      final manager = _managerWith({
        'r1': _json('r1', ['tmpl_a', 'tmpl_b'])
      });
      manager.add(_opts('r1'));
      final results = await manager.refresh();
      expect(results.length, equals(1));
      expect(results.first.succeeded, isTrue);
      expect(results.first.recordsAccepted, equals(2));
      expect(results.first.recordsRejected, equals(0));
    });

    test('allValidatedRecords returns fetched records after refresh', () async {
      final manager = _managerWith({
        'r1': _json('r1', ['tmpl_x'])
      });
      manager.add(_opts('r1'));
      await manager.refresh();
      final records = manager.allValidatedRecords();
      expect(records.length, equals(1));
      expect(records.first.id, equals('tmpl_x'));
    });

    test('Disabled registry is skipped during refresh', () async {
      final manager = _managerWith({
        'r1': _json('r1', ['t'])
      });
      manager.add(_opts('r1', enabled: false));
      final results = await manager.refresh();
      expect(results, isEmpty);
    });

    test('Network failure returns failure result', () async {
      final transport = MockRegistryTransport.alwaysFail();
      final client = RemoteRegistryClient(transport: transport);
      final manager = RegistryManager.withClient(client: client);
      manager.add(_opts('r1'));
      final results = await manager.refresh();
      expect(results.first.succeeded, isFalse);
    });

    test('Stale cache is used on network failure', () async {
      final transport = MutableMockRegistryTransport();
      transport.responses['r1'] = TransportResponse(
          statusCode: 200, body: _json('r1', ['cached_tmpl']));
      final client = RemoteRegistryClient(transport: transport);
      final manager = RegistryManager.withClient(client: client);
      manager.add(_opts('r1'));

      // First refresh — populates cache
      await manager.refresh();
      expect(manager.allValidatedRecords().length, equals(1));

      // Make network fail
      transport.alwaysFail = true;
      transport.failureReason = 'Network down';

      // Second refresh — should fall back to cache
      final results = await manager.refresh(force: true);
      expect(results.first.succeeded, isTrue);
      expect(manager.allValidatedRecords().length, equals(1));
    });

    test('Fresh cache is used without re-fetching (TTL not expired)', () async {
      final transport = MutableMockRegistryTransport();
      transport.responses['r1'] =
          TransportResponse(statusCode: 200, body: _json('r1', ['t']));
      final client = RemoteRegistryClient(transport: transport);
      final cache = RegistryMetadataCache();
      final manager = RegistryManager.withClient(client: client, cache: cache);
      manager.add(_opts('r1'));

      await manager.refresh(); // populates cache, 1 call
      final callsBefore = transport.callCount;

      await manager.refresh(); // should use fresh cache, no network call
      expect(transport.callCount, equals(callsBefore));
    });

    test('force=true bypasses cache', () async {
      final transport = MutableMockRegistryTransport();
      transport.responses['r1'] =
          TransportResponse(statusCode: 200, body: _json('r1', ['t']));
      final client = RemoteRegistryClient(transport: transport);
      final manager = RegistryManager.withClient(client: client);
      manager.add(_opts('r1'));

      await manager.refresh(); // first call
      final callsBefore = transport.callCount;
      await manager.refresh(force: true); // should bypass cache
      expect(transport.callCount, greaterThan(callsBefore));
    });
  });

  // ── Conflict resolution ───────────────────────────────────────────────────

  group('RegistryManager — conflict resolution (first-wins)', () {
    test('Same id@version from two registries: first-registered wins',
        () async {
      final r1Json = _json('r1', ['shared_tmpl']);
      final r2Json = _json('r2', ['shared_tmpl']); // same id
      final transport = MutableMockRegistryTransport();
      transport.responses['r1'] =
          TransportResponse(statusCode: 200, body: r1Json);
      transport.responses['r2'] =
          TransportResponse(statusCode: 200, body: r2Json);
      final client = RemoteRegistryClient(transport: transport);
      final manager = RegistryManager.withClient(client: client);

      manager.add(_opts('r1'));
      manager.add(_opts('r2'));
      await manager.refresh();

      // Only one record should exist for the shared id
      final records = manager.allValidatedRecords();
      final sharedRecords =
          records.where((r) => r.id == 'shared_tmpl').toList();
      expect(sharedRecords.length, equals(1));
    });

    test('Different ids from multiple registries are all returned', () async {
      final transport = MutableMockRegistryTransport();
      transport.responses['r1'] =
          TransportResponse(statusCode: 200, body: _json('r1', ['a', 'b']));
      transport.responses['r2'] =
          TransportResponse(statusCode: 200, body: _json('r2', ['c', 'd']));
      final client = RemoteRegistryClient(transport: transport);
      final manager = RegistryManager.withClient(client: client);
      manager.add(_opts('r1'));
      manager.add(_opts('r2'));
      await manager.refresh();
      expect(manager.allValidatedRecords().length, equals(4));
    });
  });

  // ── Offline mode ──────────────────────────────────────────────────────────

  group('RegistryManager — offline mode', () {
    test('Offline mode with no cache returns failure', () async {
      final transport = MockRegistryTransport.alwaysFail();
      final client = RemoteRegistryClient(transport: transport);
      final manager = RegistryManager.withClient(client: client);
      manager.add(_opts('r1'));
      manager.setOfflineMode(true);
      final results = await manager.refresh();
      expect(results.first.succeeded, isFalse);
      expect(results.first.errorMessage, contains('Offline mode'));
    });

    test('Offline mode with cached data serves stale records', () async {
      final transport = MutableMockRegistryTransport();
      transport.responses['r1'] =
          TransportResponse(statusCode: 200, body: _json('r1', ['t']));
      final client = RemoteRegistryClient(transport: transport);
      final manager = RegistryManager.withClient(client: client);
      manager.add(_opts('r1'));

      // Populate cache first
      await manager.refresh();
      transport.alwaysFail = true;

      // Now go offline
      manager.setOfflineMode(true);
      final results = await manager.refresh(force: true);
      expect(results.first.succeeded, isTrue);
      expect(manager.allValidatedRecords().length, equals(1));
    });
  });

  // ── Status ────────────────────────────────────────────────────────────────

  group('RegistryManager — status', () {
    test('Disabled registry reports disabled health', () {
      final manager = _managerWith({});
      manager.add(_opts('r1', enabled: false));
      final statuses = manager.status();
      expect(statuses.first.health, equals(RegistryHealthState.disabled));
    });

    test('Online registry reports online health after refresh', () async {
      final manager = _managerWith({
        'r1': _json('r1', ['t'])
      });
      manager.add(_opts('r1'));
      await manager.refresh();
      final statuses = manager.status();
      expect(statuses.first.health, equals(RegistryHealthState.online));
    });

    test('Unknown health before any refresh', () {
      final manager = _managerWith({});
      manager.add(_opts('r1'));
      final statuses = manager.status();
      expect(statuses.first.health, equals(RegistryHealthState.unknown));
    });

    test('Status by specific id filters correctly', () {
      final manager = _managerWith({});
      manager.add(_opts('r1'));
      manager.add(_opts('r2'));
      final statuses = manager.status(registryId: 'r1');
      expect(statuses.length, equals(1));
      expect(statuses.first.registryId, equals('r1'));
    });
  });

  // ── Security: malformed records rejected ──────────────────────────────────

  group('RegistryManager — malformed record rejection', () {
    test('Records with invalid IDs are rejected before entering records',
        () async {
      final badJson = '''
      {"protocolVersion":"1","registryId":"r1","templates":[
        {"id":"INVALID-ID","version":"1.0.0","displayName":"Bad","description":"",
         "projectType":"flutter_package","category":"community","minimumDartSdk":">=3.0.0"}
      ]}''';
      final transport = MockRegistryTransport({
        'r1': TransportResponse(statusCode: 200, body: badJson),
      });
      final client = RemoteRegistryClient(transport: transport);
      final manager = RegistryManager.withClient(client: client);
      manager.add(_opts('r1'));
      final results = await manager.refresh();
      expect(results.first.recordsRejected, equals(1));
      expect(manager.allValidatedRecords(), isEmpty);
    });

    test('Records claiming builtin category are rejected', () async {
      final badJson = '''
      {"protocolVersion":"1","registryId":"r1","templates":[
        {"id":"legit_tmpl","version":"1.0.0","displayName":"L","description":"",
         "projectType":"flutter_package","category":"builtin","minimumDartSdk":">=3.0.0"}
      ]}''';
      final transport = MockRegistryTransport({
        'r1': TransportResponse(statusCode: 200, body: badJson),
      });
      final client = RemoteRegistryClient(transport: transport);
      final manager = RegistryManager.withClient(client: client);
      manager.add(_opts('r1'));
      await manager.refresh();
      expect(manager.allValidatedRecords(), isEmpty);
    });
  });
}
