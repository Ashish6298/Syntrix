import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

// ── Helpers ───────────────────────────────────────────────────────────────

RemoteRegistryOptions _opts(String id) => RemoteRegistryOptions(
      id: id,
      baseUrl: 'https://example.com/$id',
    );

TransportResponse _successResponse(String body) =>
    TransportResponse(statusCode: 200, body: body);

TransportResponse _httpError(int code) =>
    TransportResponse(statusCode: code, body: '');

String _validJson({String registryId = 'r', int count = 1}) {
  final templates = List.generate(
    count,
    (i) =>
        '{"id":"tmpl${i + 1}","version":"1.0.0","displayName":"T${i + 1}","description":"d","projectType":"flutter_package","minimumDartSdk":">=3.0.0"}',
  ).join(',');
  return '{"protocolVersion":"1","registryId":"$registryId","templates":[$templates]}';
}

void main() {
  // ── RemoteRegistryClient Tests ────────────────────────────────────────────

  group('RemoteRegistryClient Tests', () {
    test('Successful fetch returns RegistryFetchResult.success', () async {
      final transport = MockRegistryTransport({
        'r1': _successResponse(_validJson(registryId: 'r1', count: 2)),
      });
      final client = RemoteRegistryClient(transport: transport);
      final opts = _opts('r1');
      final result = await client.fetchCatalog(opts);
      expect(result.succeeded, isTrue);
      expect(result.payload, isNotNull);
      expect(result.payload!.templates.length, equals(2));
    });

    test('Disabled registry returns failure without network call', () async {
      final transport = MockRegistryTransport({});
      final client = RemoteRegistryClient(transport: transport);
      final opts = RemoteRegistryOptions(
        id: 'r1',
        baseUrl: 'https://example.com',
        enabled: false,
      );
      final result = await client.fetchCatalog(opts);
      expect(result.succeeded, isFalse);
      expect(transport.callCount, equals(0));
    });

    test('HTTP 401 returns failure with auth message', () async {
      final transport = MockRegistryTransport({'r1': _httpError(401)});
      final client = RemoteRegistryClient(transport: transport);
      final result = await client.fetchCatalog(_opts('r1'));
      expect(result.succeeded, isFalse);
      expect(result.errorMessage, contains('authentication'));
    });

    test('HTTP 403 returns auth failure', () async {
      final transport = MockRegistryTransport({'r1': _httpError(403)});
      final client = RemoteRegistryClient(transport: transport);
      final result = await client.fetchCatalog(_opts('r1'));
      expect(result.succeeded, isFalse);
    });

    test('HTTP 429 returns rate limit failure', () async {
      final transport = MockRegistryTransport({'r1': _httpError(429)});
      final client = RemoteRegistryClient(transport: transport);
      final result = await client.fetchCatalog(_opts('r1'));
      expect(result.succeeded, isFalse);
      expect(result.errorMessage, contains('rate-limit'));
    });

    test('HTTP 500 returns network failure (retried then failed)', () async {
      final transport = MockRegistryTransport({'r1': _httpError(500)});
      final client = RemoteRegistryClient(transport: transport);
      final result = await client.fetchCatalog(_opts('r1'));
      expect(result.succeeded, isFalse);
      // Retried up to maxRetries=2, so 3 total calls (initial + 2 retries)
      expect(transport.callCount, equals(3));
    });

    test('Network failure is retried up to max retries', () async {
      final transport = MutableMockRegistryTransport();
      transport.alwaysFail = true;
      transport.failureReason = 'Connection refused';
      final client = RemoteRegistryClient(transport: transport);
      final result = await client.fetchCatalog(_opts('r1'));
      expect(result.succeeded, isFalse);
      expect(transport.callCount, equals(3)); // 1 initial + 2 retries
    });

    test('Response size limit is enforced', () async {
      final bigBody = _validJson() + ' ' * (6 * 1024 * 1024);
      final transport =
          MockRegistryTransport({'r1': _successResponse(bigBody)});
      final opts = RemoteRegistryOptions(
        id: 'r1',
        baseUrl: 'https://example.com',
        maxResponseBytes: 1024,
      );
      final client = RemoteRegistryClient(transport: transport);
      final result = await client.fetchCatalog(opts);
      expect(result.succeeded, isFalse);
      expect(result.errorMessage, contains('size limit'));
    });

    test('Invalid JSON body returns failure', () async {
      final transport = MockRegistryTransport({
        'r1': TransportResponse(statusCode: 200, body: 'not json'),
      });
      final client = RemoteRegistryClient(transport: transport);
      final result = await client.fetchCatalog(_opts('r1'));
      expect(result.succeeded, isFalse);
    });

    test('HTTP 404 returns failure without retry', () async {
      final transport = MockRegistryTransport({'r1': _httpError(404)});
      final client = RemoteRegistryClient(transport: transport);
      final result = await client.fetchCatalog(_opts('r1'));
      expect(result.succeeded, isFalse);
      // 404 is not retried
      expect(transport.callCount, equals(1));
    });

    test('Source provenance is set on success', () async {
      final transport = MockRegistryTransport({
        'r1': _successResponse(_validJson(registryId: 'r1')),
      });
      final client = RemoteRegistryClient(transport: transport);
      final result = await client.fetchCatalog(_opts('r1'));
      expect(result.source.registryId, equals('r1'));
      expect(result.source.protocolVersion, equals('1'));
      expect(result.source.fromCache, isFalse);
    });
  });

  // ── RegistryMetadataCache Tests ───────────────────────────────────────────

  group('RegistryMetadataCache Tests', () {
    late RegistryMetadataCache cache;
    late RegistrySource source;

    setUp(() {
      cache = RegistryMetadataCache();
      source = RegistrySource(
        registryId: 'r1',
        registryBaseUrl: 'https://example.com',
        protocolVersion: '1',
        fetchedAt: DateTime.now().toUtc(),
      );
    });

    test('has() returns false for empty cache', () {
      expect(cache.has('r1'), isFalse);
    });

    test('put() and has() work correctly', () {
      cache.put('r1', [], source);
      expect(cache.has('r1'), isTrue);
    });

    test('isFresh() returns true within TTL', () {
      cache.put('r1', [], source);
      expect(cache.isFresh('r1', const Duration(minutes: 5)), isTrue);
    });

    test('isFresh() returns false after TTL', () async {
      cache.put('r1', [], source);
      // Wait a tiny bit so the cache age is guaranteed to exceed a 0ms TTL
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(cache.isFresh('r1', Duration.zero), isFalse);
    });

    test('isFresh() returns false for absent key', () {
      expect(cache.isFresh('nonexistent', const Duration(minutes: 5)), isFalse);
    });

    test('get() returns cached records and source with fromCache=true', () {
      final records = [
        RemoteTemplateRecord(
          id: 'tmpl',
          version: '1.0.0',
          displayName: 'T',
          description: '',
          publisher: '',
          projectType: 'flutter_package',
          category: 'community',
          minimumDartSdk: '>=3.0.0',
        ),
      ];
      cache.put('r1', records, source);
      final entry = cache.get('r1');
      expect(entry.records.length, equals(1));
      expect(entry.source.fromCache, isTrue);
    });

    test('get() throws RegistryCacheException for absent key', () {
      expect(
        () => cache.get('nonexistent'),
        throwsA(isA<RegistryCacheException>()),
      );
    });

    test('invalidate() removes entry', () {
      cache.put('r1', [], source);
      cache.invalidate('r1');
      expect(cache.has('r1'), isFalse);
    });

    test('clear() removes all entries', () {
      cache.put('r1', [], source);
      cache.put('r2', [], source);
      cache.clear();
      expect(cache.size, equals(0));
    });

    test('put() overwrites existing entry', () {
      final records1 = [
        RemoteTemplateRecord(
          id: 'a',
          version: '1.0.0',
          displayName: 'A',
          description: '',
          publisher: '',
          projectType: 'flutter_package',
          category: 'community',
          minimumDartSdk: '>=3.0.0',
        ),
      ];
      final records2 = <RemoteTemplateRecord>[];
      cache.put('r1', records1, source);
      cache.put('r1', records2, source);
      final entry = cache.get('r1');
      expect(entry.records, isEmpty);
    });

    test('getSource() returns source for existing entry', () {
      cache.put('r1', [], source);
      expect(cache.getSource('r1'), isNotNull);
      expect(cache.getSource('r1')!.registryId, equals('r1'));
    });

    test('getSource() returns null for absent entry', () {
      expect(cache.getSource('nonexistent'), isNull);
    });
  });
}
