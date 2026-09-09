/// Abstract Enterprise Identity Provider and built-in local/mock implementations.
library;

import 'package:flutter_package_studio_core/src/enterprise/identity/enterprise_identity_models.dart';

/// Abstract Enterprise Identity Provider interface.
///
/// Enables pluggable identity resolution (Local, OAuth2/OIDC, SAML, API Token, Mock)
/// without coupling the core system to any specific identity vendor.
abstract class EnterpriseIdentityProvider {
  /// Provider unique identifier (e.g. 'local_auth', 'github_sso', 'mock_idp').
  String get providerId;

  /// Provider human-readable display name.
  String get displayName;

  /// Authenticates credentials and returns a session or failure.
  Future<AuthenticationResult> authenticate(AuthenticationRequest request);

  /// Validates an existing session token or payload.
  Future<bool> validateSession(EnterpriseSession session);

  /// Revokes an active session.
  Future<bool> revokeSession(String sessionId);
}

/// In-memory / Mock Enterprise Identity Provider for deterministic testing and local offline workflows.
class MockEnterpriseIdentityProvider implements EnterpriseIdentityProvider {
  @override
  final String providerId;

  @override
  final String displayName;

  final Map<String, EnterpriseIdentity> _mockUsers = {};
  final Map<String, EnterpriseSession> _activeSessions = {};

  MockEnterpriseIdentityProvider({
    this.providerId = 'mock_idp',
    this.displayName = 'Mock Enterprise Identity Provider',
    Map<String, EnterpriseIdentity>? predefinedUsers,
  }) {
    if (predefinedUsers != null) {
      _mockUsers.addAll(predefinedUsers);
    } else {
      // Setup default mock identities
      _mockUsers['admin@enterprise.internal'] = const EnterpriseIdentity(
        id: 'usr_admin_001',
        displayName: 'Admin User',
        email: 'admin@enterprise.internal',
        type: IdentityType.user,
        organizationId: 'enterprise_corp',
        roles: [EnterpriseRole.administrator],
        directPermissions: {'*'},
      );

      _mockUsers['release@enterprise.internal'] = const EnterpriseIdentity(
        id: 'usr_rel_002',
        displayName: 'Release Manager',
        email: 'release@enterprise.internal',
        type: IdentityType.user,
        organizationId: 'enterprise_corp',
        roles: [EnterpriseRole.releaseManager],
        directPermissions: {'release:publish', 'release:verify'},
      );

      _mockUsers['dev@enterprise.internal'] = const EnterpriseIdentity(
        id: 'usr_dev_003',
        displayName: 'Developer',
        email: 'dev@enterprise.internal',
        type: IdentityType.user,
        organizationId: 'enterprise_corp',
        roles: [EnterpriseRole.developer],
        directPermissions: {'package:modify', 'ai:review'},
      );

      _mockUsers['svc_ci_bot'] = const EnterpriseIdentity(
        id: 'svc_ci_999',
        displayName: 'CI Automation Bot',
        email: 'ci@enterprise.internal',
        type: IdentityType.serviceAccount,
        organizationId: 'enterprise_corp',
        roles: [EnterpriseRole.developer, EnterpriseRole.reviewer],
        directPermissions: {'ci:build', 'test:execute'},
      );
    }
  }

  @override
  Future<AuthenticationResult> authenticate(
      AuthenticationRequest request) async {
    final sw = Stopwatch()..start();
    final now = DateTime.now();

    final username = request.credentials['username']?.toString() ??
        request.credentials['token']?.toString() ??
        request.credentials['key']?.toString();

    if (username == null || username.isEmpty) {
      sw.stop();
      return AuthenticationResult.failure(
        errorMessage:
            'Missing credentials: username, token, or key is required.',
        errorCode: 'MISSING_CREDENTIALS',
        durationMs: sw.elapsedMilliseconds,
        timestamp: now,
      );
    }

    final identity = _mockUsers[username];
    if (identity == null) {
      sw.stop();
      return AuthenticationResult.failure(
        errorMessage: 'Invalid credentials or user not found.',
        errorCode: 'INVALID_CREDENTIALS',
        durationMs: sw.elapsedMilliseconds,
        timestamp: now,
      );
    }

    final session = EnterpriseSession(
      sessionId: 'sess_${DateTime.now().millisecondsSinceEpoch}_${identity.id}',
      identity: identity,
      status: AuthenticationStatus.authenticated,
      issuedAt: now,
      expiresAt: now.add(const Duration(hours: 8)),
      providerId: providerId,
    );

    _activeSessions[session.sessionId] = session;
    sw.stop();

    return AuthenticationResult.success(
      session: session,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
    );
  }

  @override
  Future<bool> validateSession(EnterpriseSession session) async {
    if (session.isExpired) return false;
    final stored = _activeSessions[session.sessionId];
    return stored != null &&
        stored.status == AuthenticationStatus.authenticated;
  }

  @override
  Future<bool> revokeSession(String sessionId) async {
    _activeSessions.remove(sessionId);
    return true;
  }
}
