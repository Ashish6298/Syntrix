import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  // ── RemoteRegistryOptions Tests ───────────────────────────────────────────

  group('RemoteRegistryOptions Tests', () {
    test('Valid options construct without error', () {
      final opts = RemoteRegistryOptions(
        id: 'my-registry',
        baseUrl: 'https://templates.example.com',
      );
      expect(opts.id, equals('my-registry'));
      expect(opts.baseUrl, equals('https://templates.example.com'));
      expect(opts.enabled, isTrue);
      expect(opts.requestTimeout, equals(const Duration(seconds: 15)));
      expect(opts.cachePolicy, equals(RegistryCachePolicy.normal));
      expect(opts.authMode, equals(RegistryAuthMode.none));
    });

    test('Trailing slash is stripped from baseUrl', () {
      final opts = RemoteRegistryOptions(
        id: 'r1',
        baseUrl: 'https://example.com/registry/',
      );
      expect(opts.baseUrl, equals('https://example.com/registry'));
    });

    test('copyWith overrides enabled', () {
      final opts =
          RemoteRegistryOptions(id: 'r1', baseUrl: 'https://example.com');
      final disabled = opts.copyWith(enabled: false);
      expect(disabled.enabled, isFalse);
      expect(disabled.id, equals('r1'));
    });

    // ── ID validation ────────────────────────────────────────────────────────

    test('Empty ID throws RegistryConfigurationException', () {
      expect(
        () => RemoteRegistryOptions(id: '', baseUrl: 'https://example.com'),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });

    test('ID starting with digit is rejected', () {
      expect(
        () => RemoteRegistryOptions(id: '1bad', baseUrl: 'https://example.com'),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });

    test('ID with uppercase letters is rejected', () {
      expect(
        () => RemoteRegistryOptions(
            id: 'MyRegistry', baseUrl: 'https://example.com'),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });

    test('Valid ID with hyphens and digits is accepted', () {
      final opts = RemoteRegistryOptions(
        id: 'my-registry-2',
        baseUrl: 'https://example.com',
      );
      expect(opts.id, equals('my-registry-2'));
    });

    // ── URL validation ────────────────────────────────────────────────────────

    test('HTTP URL is rejected', () {
      expect(
        () => RemoteRegistryOptions(id: 'r1', baseUrl: 'http://example.com'),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });

    test('File URL is rejected', () {
      expect(
        () => RemoteRegistryOptions(id: 'r1', baseUrl: 'file:///etc/passwd'),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });

    test('Empty URL is rejected', () {
      expect(
        () => RemoteRegistryOptions(id: 'r1', baseUrl: ''),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });

    // ── SSRF protection ───────────────────────────────────────────────────────

    test('Localhost URL is rejected (SSRF protection)', () {
      expect(
        () => RemoteRegistryOptions(id: 'r1', baseUrl: 'https://localhost/api'),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });

    test('Private 10.x range is rejected', () {
      expect(
        () => RemoteRegistryOptions(id: 'r1', baseUrl: 'https://10.0.0.1/api'),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });

    test('Private 192.168.x range is rejected', () {
      expect(
        () =>
            RemoteRegistryOptions(id: 'r1', baseUrl: 'https://192.168.1.1/api'),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });

    test('Private 172.16.x range is rejected', () {
      expect(
        () =>
            RemoteRegistryOptions(id: 'r1', baseUrl: 'https://172.16.0.1/api'),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });

    test('Loopback 127.x range is rejected', () {
      expect(
        () => RemoteRegistryOptions(id: 'r1', baseUrl: 'https://127.0.0.1/api'),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });

    // ── Timeout & size validation ─────────────────────────────────────────────

    test('Timeout of 0 seconds is rejected', () {
      expect(
        () => RemoteRegistryOptions(
          id: 'r1',
          baseUrl: 'https://example.com',
          requestTimeout: Duration.zero,
        ),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });

    test('maxResponseBytes of 512 is rejected (< 1 KiB)', () {
      expect(
        () => RemoteRegistryOptions(
          id: 'r1',
          baseUrl: 'https://example.com',
          maxResponseBytes: 512,
        ),
        throwsA(isA<RegistryConfigurationException>()),
      );
    });
  });

  // ── RegistrySource Tests ──────────────────────────────────────────────────

  group('RegistrySource Tests', () {
    test('Basic properties are set correctly', () {
      final ts = DateTime.utc(2025, 1, 1);
      final src = RegistrySource(
        registryId: 'my-reg',
        registryBaseUrl: 'https://example.com',
        protocolVersion: '1',
        fetchedAt: ts,
      );
      expect(src.registryId, equals('my-reg'));
      expect(src.fromCache, isFalse);
    });

    test('withCacheFlag returns copy with updated flag', () {
      final src = RegistrySource(
        registryId: 'r',
        registryBaseUrl: 'https://x.com',
        protocolVersion: '1',
        fetchedAt: DateTime.now(),
      );
      final cached = src.withCacheFlag(true);
      expect(cached.fromCache, isTrue);
      expect(cached.registryId, equals('r'));
    });
  });

  // ── RegistryStatus Tests ──────────────────────────────────────────────────

  group('RegistryStatus Tests', () {
    test('offline factory sets correct fields', () {
      final s = RegistryStatus.offline('r', 'My Reg', 'Timeout', true);
      expect(s.health, equals(RegistryHealthState.offline));
      expect(s.servingFromCache, isTrue);
      expect(s.message, equals('Timeout'));
    });

    test('disabled factory sets correct fields', () {
      final s = RegistryStatus.disabled('r', 'My Reg');
      expect(s.health, equals(RegistryHealthState.disabled));
      expect(s.servingFromCache, isFalse);
    });

    test('invalid factory sets correct fields', () {
      final s = RegistryStatus.invalid('r', 'My Reg', 'Bad URL');
      expect(s.health, equals(RegistryHealthState.invalid));
      expect(s.message, equals('Bad URL'));
    });
  });
}
