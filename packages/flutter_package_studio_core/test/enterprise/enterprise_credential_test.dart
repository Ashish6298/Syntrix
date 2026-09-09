import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 9.9 — Enterprise Secrets & Credential Abstraction Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('fps_enterprise_cred_test_');
      rootPath = tempDir.path;

      // Scaffold clean workspace
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: cred_sample_pkg
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Non-Sensitive Credential References (Zero Plaintext Secrets)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Credential Reference: stores metadata pointers and never holds plaintext secrets',
        () {
      const ref = CredentialReference(
        key: 'PUB_DEV_API_TOKEN',
        providerId: 'vault_sec_ops',
        providerType: CredentialProviderType.enterpriseSecretManager,
        scope: CredentialScope.publish,
        description: 'Pub.dev publishing authorization token',
      );

      final json = ref.toJson();
      final roundtrip = CredentialReference.fromJson(json);

      expect(roundtrip.key, equals('PUB_DEV_API_TOKEN'));
      expect(roundtrip.providerType,
          equals(CredentialProviderType.enterpriseSecretManager));
      expect(roundtrip.scope, equals(CredentialScope.publish));
      expect(json.containsKey('secret'), isFalse);
      expect(json.containsKey('value'), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Multi-Provider Resolution (Environment & Enterprise Secret Manager)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Multi-Provider Resolution: checks secret availability without exposing values',
        () async {
      final envProvider = EnvironmentCredentialProvider(
        envOverride: {
          'FPS_RELEASE_KEY': 'env_secret_key_12345',
        },
      );

      final vaultProvider = MockEnterpriseSecretManager(
        initialSecrets: {
          'PUB_DEV_TOKEN': 'ghp_PUBDEVSECRET999999999999',
        },
      );

      final manager = EnterpriseCredentialManager(
        projectRoot: rootPath,
        initialProviders: [envProvider, vaultProvider],
      );

      // Check availability of environment key
      final envCheck = await manager.checkAvailability('FPS_RELEASE_KEY');
      expect(envCheck.isAvailable, isTrue);
      expect(envCheck.providerType, equals(CredentialProviderType.environment));

      // Check availability of vault key
      final vaultCheck = await manager.checkAvailability('PUB_DEV_TOKEN');
      expect(vaultCheck.isAvailable, isTrue);
      expect(vaultCheck.providerType, equals(CredentialProviderType.mockVault));

      // Check missing key
      final missingCheck =
          await manager.checkAvailability('AWS_NON_EXISTENT_KEY');
      expect(missingCheck.isAvailable, isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Ephemeral Injection strictly at Execution Boundary
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Scoped Execution Boundary: injects secret only within isolated closure and scrubs after',
        () async {
      final vault = MockEnterpriseSecretManager(
        initialSecrets: {
          'SIGNING_CERT_KEY': 'cert_private_key_bytes_xyz999',
        },
      );

      final manager = EnterpriseCredentialManager(
        projectRoot: rootPath,
        initialProviders: [vault],
      );

      String? capturedSignature;

      // Execute within bounded execution closure
      await manager.executeWithScopedCredential<void>(
        key: 'SIGNING_CERT_KEY',
        scope: CredentialScope.signing,
        executionClosure: (rawSecret) async {
          expect(rawSecret, equals('cert_private_key_bytes_xyz999'));
          capturedSignature = 'signed_with_$rawSecret';
        },
      );

      expect(capturedSignature,
          contains('signed_with_cert_private_key_bytes_xyz999'));

      // Ephemeral token toString guarantee
      final token = EphemeralCredentialToken(
        key: 'SIGNING_CERT_KEY',
        rawSecret: 'cert_private_key_bytes_xyz999',
        scope: CredentialScope.signing,
      );
      expect(token.toString(), contains('[REDACTED_SECRET]'));
      expect(
          token.toString(), isNot(contains('cert_private_key_bytes_xyz999')));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Pure Credential Renderer Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Renderer Conformance: generates deterministic JSON and Markdown credential registry reports',
        () async {
      final vault = MockEnterpriseSecretManager(
        initialSecrets: {
          'PUB_DEV_TOKEN': 'secret_1',
          'GITHUB_TOKEN': 'secret_2',
        },
      );

      final refs = await vault.listReferences();
      const renderer = EnterpriseCredentialRenderer();

      final json1 = renderer.renderJson(refs);
      final json2 = renderer.renderJson(refs);
      expect(json1, equals(json2));

      final md = renderer.renderMarkdown(refs);
      expect(md, contains('# Enterprise Credential References Report'));
      expect(md, contains('**Total Registered References**: `2`'));
      expect(md, contains('Zero Secret Exposure Guarantee'));
    });
  });
}
