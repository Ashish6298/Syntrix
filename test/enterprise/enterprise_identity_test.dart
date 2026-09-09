import 'dart:io';
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 9.2 — Enterprise Authentication & Identity Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('fps_enterprise_identity_test_');
      rootPath = tempDir.path;

      // Scaffold project workspace
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: identity_sample_pkg
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
    // Test 1: Identity Model Conformance & Role Representations
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Model Conformance: Supports all 6 enterprise roles and identity types',
        () {
      final roles = [
        EnterpriseRole.administrator,
        EnterpriseRole.releaseManager,
        EnterpriseRole.developer,
        EnterpriseRole.reviewer,
        EnterpriseRole.securityAuditor,
        EnterpriseRole.readOnly,
      ];

      for (final role in roles) {
        final identity = EnterpriseIdentity(
          id: 'usr_${role.id}_001',
          displayName: '${role.displayName} User',
          email: '${role.id}@enterprise.corp',
          type: IdentityType.user,
          organizationId: 'enterprise_corp',
          roles: [role],
        );

        expect(identity.hasRole(role), isTrue);

        // JSON serialization roundtrip
        final json = identity.toJson();
        final roundtrip = EnterpriseIdentity.fromJson(json);
        expect(roundtrip.id, equals(identity.id));
        expect(roundtrip.roles.first, equals(role));
        expect(roundtrip.type, equals(IdentityType.user));
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Pluggable Identity Provider Authentication (Mock Provider)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Provider Authentication: authenticates valid users and rejects invalid ones',
        () async {
      final idp = MockEnterpriseIdentityProvider();

      // 1. Success authentication
      final successResult = await idp.authenticate(
        const AuthenticationRequest(
          providerId: 'mock_idp',
          credentials: {'username': 'admin@enterprise.internal'},
        ),
      );

      expect(successResult.isSuccess, isTrue);
      expect(successResult.session, isNotNull);
      expect(successResult.session!.identity.roles,
          contains(EnterpriseRole.administrator));
      expect(successResult.session!.status,
          equals(AuthenticationStatus.authenticated));

      // 2. Failure authentication
      final failResult = await idp.authenticate(
        const AuthenticationRequest(
          providerId: 'mock_idp',
          credentials: {'username': 'non_existent@enterprise.internal'},
        ),
      );

      expect(failResult.isSuccess, isFalse);
      expect(failResult.errorMessage,
          contains('Invalid credentials or user not found'));
      expect(failResult.session, isNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Session Validation & Revocation
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Session Lifecycle: validates active sessions and supports revocation',
        () async {
      final idp = MockEnterpriseIdentityProvider();
      final authResult = await idp.authenticate(
        const AuthenticationRequest(
          providerId: 'mock_idp',
          credentials: {'username': 'release@enterprise.internal'},
        ),
      );

      final session = authResult.session!;
      expect(await idp.validateSession(session), isTrue);

      // Revoke session
      final revoked = await idp.revokeSession(session.sessionId);
      expect(revoked, isTrue);
      expect(await idp.validateSession(session), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Identity Manager Resolution (Environment Token vs. Anonymous)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Identity Resolution: resolves service token from environment or falls back to anonymous',
        () async {
      final manager = EnterpriseIdentityManager(projectRoot: rootPath);

      // 1. Unauthenticated workspace resolves to Anonymous
      final initialIdentity = await manager.resolveIdentity();
      expect(initialIdentity.id, equals('anonymous'));
      expect(initialIdentity.type, equals(IdentityType.anonymous));
      expect(initialIdentity.roles, contains(EnterpriseRole.readOnly));

      // 2. Resolves token from environment
      final serviceIdentity = await manager.resolveIdentity(
        environmentOverride: {'FPS_ENTERPRISE_TOKEN': 'svc_ci_bot'},
      );
      expect(serviceIdentity.id, equals('svc_ci_999'));
      expect(serviceIdentity.type, equals(IdentityType.serviceAccount));
      expect(serviceIdentity.displayName, equals('CI Automation Bot'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Session Persistence & Logout
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Session Persistence: persists session in .fps/session.json and clears on logout',
        () async {
      final manager = EnterpriseIdentityManager(projectRoot: rootPath);

      final auth = await manager.login(
        providerId: 'mock_idp',
        credentials: {'username': 'dev@enterprise.internal'},
      );
      expect(auth.isSuccess, isTrue);

      final sessionFile = File(p.join(rootPath, '.fps', 'session.json'));
      expect(sessionFile.existsSync(), isTrue);

      // Reloading manager resolves cached session
      final manager2 = EnterpriseIdentityManager(projectRoot: rootPath);
      final resolved = await manager2.resolveIdentity();
      expect(resolved.id, equals('usr_dev_003'));
      expect(resolved.displayName, equals('Developer'));

      // Logout clears cache
      await manager2.logout();
      expect(sessionFile.existsSync(), isFalse);
      expect(manager2.currentIdentity.id, equals('anonymous'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Pure Identity Renderer Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Renderer Conformance: generates deterministic JSON and Markdown user profiles',
        () async {
      final manager = EnterpriseIdentityManager(projectRoot: rootPath);
      final auth = await manager.login(
        providerId: 'mock_idp',
        credentials: {'username': 'admin@enterprise.internal'},
      );

      const renderer = EnterpriseIdentityRenderer();
      final identity = auth.session!.identity;

      final json1 = renderer.renderJson(identity);
      final json2 = renderer.renderJson(identity);
      expect(json1, equals(json2));

      final md = renderer.renderMarkdown(identity, session: auth.session);
      expect(md, contains('# Enterprise Identity Profile'));
      expect(md, contains('**Display Name**: `Admin User`'));
      expect(md, contains('**Assigned Roles**: `Administrator`'));
      expect(md, contains('## Active Session Info'));
    });
  });
}
