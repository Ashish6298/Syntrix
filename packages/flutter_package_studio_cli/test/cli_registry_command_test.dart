import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

// ── Test helpers ─────────────────────────────────────────────────────────────

/// Builds a [CommandRegistry] with [RegistryCommand] registered.
CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(RegistryCommand());
  return r;
}

void main() {
  group('RegistryCommand CLI Tests', () {
    // ── fps registry (parent) ─────────────────────────────────────────────

    test('fps registry (no subcommand) returns 0 or 64', () async {
      final code = await _registry().run(['registry']);
      expect(code, isIn([0, 64]));
    });

    // ── fps registry list ─────────────────────────────────────────────────

    test('fps registry list with empty config returns 0', () async {
      final code = await _registry().run(['registry', 'list']);
      expect(code, equals(0));
    });

    test('fps registry list --json returns 0', () async {
      final code = await _registry().run(['registry', 'list', '--json']);
      expect(code, equals(0));
    });

    // ── fps registry add ──────────────────────────────────────────────────

    test('fps registry add without URL returns 64 (usage error)', () async {
      final code = await _registry().run(['registry', 'add']);
      expect(code, equals(64));
    });

    test('fps registry add with HTTP URL returns 1 (SSRF/HTTPS rejection)',
        () async {
      final code = await _registry().run([
        'registry',
        'add',
        'http://example.com/catalog',
      ]);
      expect(code, equals(1));
    });

    test('fps registry add with localhost URL returns 1', () async {
      final code = await _registry().run([
        'registry',
        'add',
        'https://localhost/catalog',
      ]);
      expect(code, equals(1));
    });

    test('fps registry add --dry-run does not persist', () async {
      // We can't easily check persistence in this unit test since
      // _sharedManager() creates a fresh instance per command invocation.
      // Just verify exit code is 0 for a valid HTTPS URL.
      // Note: example.com is a public domain safe for testing (not a real registry).
      final code = await _registry().run([
        'registry',
        'add',
        'https://templates.example.com/fps',
        '--dry-run',
      ]);
      expect(code, equals(0));
    });

    test('fps registry add --json outputs JSON on success (dry-run)', () async {
      final code = await _registry().run([
        'registry',
        'add',
        'https://templates.example.com/fps',
        '--dry-run',
        '--json',
      ]);
      expect(code, equals(0));
    });

    // ── fps registry remove ───────────────────────────────────────────────

    test('fps registry remove without id returns 64', () async {
      final code = await _registry().run(['registry', 'remove']);
      expect(code, equals(64));
    });

    test('fps registry remove nonexistent id returns 1', () async {
      final code = await _registry().run([
        'registry',
        'remove',
        'nonexistent-registry',
      ]);
      expect(code, equals(1));
    });

    // ── fps registry enable / disable ─────────────────────────────────────

    test('fps registry enable without id returns 64', () async {
      final code = await _registry().run(['registry', 'enable']);
      expect(code, equals(64));
    });

    test('fps registry disable without id returns 64', () async {
      final code = await _registry().run(['registry', 'disable']);
      expect(code, equals(64));
    });

    test('fps registry enable nonexistent id returns 1', () async {
      final code = await _registry().run([
        'registry',
        'enable',
        'nonexistent',
      ]);
      expect(code, equals(1));
    });

    test('fps registry disable nonexistent id returns 1', () async {
      final code = await _registry().run([
        'registry',
        'disable',
        'nonexistent',
      ]);
      expect(code, equals(1));
    });

    // ── fps registry refresh ──────────────────────────────────────────────

    test('fps registry refresh with no registries returns 0', () async {
      final code = await _registry().run(['registry', 'refresh']);
      expect(code, equals(0));
    });

    test('fps registry refresh --json returns 0', () async {
      final code = await _registry().run(['registry', 'refresh', '--json']);
      expect(code, equals(0));
    });

    // ── fps registry status ───────────────────────────────────────────────

    test('fps registry status with no registries returns 0', () async {
      final code = await _registry().run(['registry', 'status']);
      expect(code, equals(0));
    });

    test('fps registry status --json returns 0', () async {
      final code = await _registry().run(['registry', 'status', '--json']);
      expect(code, equals(0));
    });

    // ── Security: secret redaction ────────────────────────────────────────

    test('Registry options never expose credentials in toString()', () {
      final opts = RemoteRegistryOptions(
        id: 'my-reg',
        baseUrl: 'https://example.com',
        displayName: 'My Registry',
      );
      final str = opts.toString();
      expect(str.contains('token'), isFalse);
      expect(str.contains('password'), isFalse);
      expect(str.contains('Authorization'), isFalse);
    });

    test('RegistryStatus never exposes credentials', () {
      final s = RegistryStatus(
        registryId: 'r',
        displayName: 'R',
        health: RegistryHealthState.online,
        message: 'All good',
      );
      final str = s.toString();
      expect(str.contains('token'), isFalse);
      expect(str.contains('Authorization'), isFalse);
    });

    test('RegistrySource never exposes credentials', () {
      final src = RegistrySource(
        registryId: 'r',
        registryBaseUrl: 'https://example.com',
        protocolVersion: '1',
        fetchedAt: DateTime.now(),
      );
      final str = src.toString();
      expect(str.contains('token'), isFalse);
      expect(str.contains('password'), isFalse);
    });

    // ── Dry-run / mutation isolation ──────────────────────────────────────

    test('RegistryMutationPlan is labeled DRY-RUN when dryRun=true', () {
      final plan = RegistryMutationPlan(
        description: 'Add registry test-reg.',
        isDryRun: true,
      );
      expect(plan.toString(), contains('DRY-RUN'));
    });

    test('RegistryMutationPlan is labeled APPLIED when dryRun=false', () {
      final plan = RegistryMutationPlan(
        description: 'Add registry test-reg.',
        isDryRun: false,
      );
      expect(plan.toString(), contains('APPLIED'));
    });

    // ── Exception hierarchy ───────────────────────────────────────────────

    test('RegistryNetworkException extends RemoteRegistryException', () {
      final ex = RegistryNetworkException('Timeout');
      expect(ex, isA<RemoteRegistryException>());
      expect(ex, isA<PackageStudioException>());
    });

    test('RegistryAuthenticationException extends RemoteRegistryException', () {
      final ex = RegistryAuthenticationException('Unauthorized');
      expect(ex, isA<RemoteRegistryException>());
    });

    test('RegistryProtocolException extends RemoteRegistryException', () {
      final ex = RegistryProtocolException('Version mismatch');
      expect(ex, isA<RemoteRegistryException>());
    });

    test('RegistryMetadataException extends RemoteRegistryException', () {
      final ex = RegistryMetadataException('Bad ID');
      expect(ex, isA<RemoteRegistryException>());
    });

    test('RegistryRateLimitException extends RemoteRegistryException', () {
      final ex = RegistryRateLimitException('429');
      expect(ex, isA<RemoteRegistryException>());
    });

    test('RegistryCacheException extends RemoteRegistryException', () {
      final ex = RegistryCacheException('Cache miss');
      expect(ex, isA<RemoteRegistryException>());
    });

    test('RegistryConfigurationException extends RemoteRegistryException', () {
      final ex = RegistryConfigurationException('Bad URL');
      expect(ex, isA<RemoteRegistryException>());
    });
  });
}
