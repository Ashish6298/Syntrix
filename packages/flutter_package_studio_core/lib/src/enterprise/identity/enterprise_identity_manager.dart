/// Central Identity Resolution, Session Management, and Authentication Manager.
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/enterprise/identity/enterprise_identity_models.dart';
import 'package:flutter_package_studio_core/src/enterprise/identity/enterprise_identity_provider.dart';

/// Central Enterprise Authentication and Identity Manager.
///
/// Responsible for:
/// 1. Managing identity providers.
/// 2. Authenticating users and issuing enterprise sessions.
/// 3. Resolving active identity from current process environment, token headers, or session cache.
/// 4. Identity validation for security-sensitive operations.
class EnterpriseIdentityManager {
  final Logger _logger = Logger('EnterpriseIdentityManager');
  final String _projectRoot;
  final Map<String, EnterpriseIdentityProvider> _providers = {};
  EnterpriseSession? _currentSession;

  String get projectRoot => _projectRoot;
  EnterpriseSession? get currentSession => _currentSession;
  EnterpriseIdentity get currentIdentity => _currentSession?.identity ?? EnterpriseIdentity.anonymous;

  EnterpriseIdentityManager({
    required String projectRoot,
    EnterpriseIdentityProvider? defaultProvider,
  }) : _projectRoot = p.normalize(projectRoot) {
    final provider = defaultProvider ?? MockEnterpriseIdentityProvider();
    registerProvider(provider);
  }

  /// Registers an enterprise identity provider.
  void registerProvider(EnterpriseIdentityProvider provider) {
    _providers[provider.providerId] = provider;
    _logger.info('Registered identity provider: ${provider.providerId} (${provider.displayName})');
  }

  /// Authenticates using a registered provider.
  Future<AuthenticationResult> login({
    required String providerId,
    required Map<String, dynamic> credentials,
    Map<String, dynamic> context = const {},
  }) async {
    final provider = _providers[providerId];
    if (provider == null) {
      return AuthenticationResult.failure(
        errorMessage: 'Identity provider "$providerId" is not registered.',
        errorCode: 'PROVIDER_NOT_FOUND',
        durationMs: 0,
        timestamp: DateTime.now(),
      );
    }

    final result = await provider.authenticate(
      AuthenticationRequest(
        providerId: providerId,
        credentials: credentials,
        context: context,
      ),
    );

    if (result.isSuccess && result.session != null) {
      _currentSession = result.session;
      _saveSessionCache(result.session!);
      _logger.info('Successfully authenticated identity: ${result.session!.identity.displayName} (${result.session!.identity.email})');
    }

    return result;
  }

  /// Logs out and invalidates the current session.
  Future<void> logout() async {
    if (_currentSession != null) {
      final provider = _providers[_currentSession!.providerId];
      if (provider != null) {
        await provider.revokeSession(_currentSession!.sessionId);
      }
      _currentSession = null;
      _clearSessionCache();
      _logger.info('Logged out active enterprise session.');
    }
  }

  /// Resolves identity from environment variables (e.g. CI/CD or CLI flags) or cached session.
  Future<EnterpriseIdentity> resolveIdentity({
    Map<String, String>? environmentOverride,
  }) async {
    final env = environmentOverride ?? Platform.environment;

    // 1. Check CI/Service Account Token environment variables
    final ciToken = env['FPS_ENTERPRISE_TOKEN'] ?? env['FPS_SERVICE_TOKEN'];
    if (ciToken != null && ciToken.isNotEmpty) {
      final authRes = await login(
        providerId: 'mock_idp',
        credentials: {'token': ciToken},
      );
      if (authRes.isSuccess && authRes.session != null) {
        return authRes.session!.identity;
      }
    }

    // 2. Check active in-memory session
    if (_currentSession != null && _currentSession!.isValid) {
      return _currentSession!.identity;
    }

    // 3. Check persistent session cache in .fps/session.json
    final cached = _loadSessionCache();
    if (cached != null && cached.isValid) {
      _currentSession = cached;
      return cached.identity;
    }

    // 4. Fallback to anonymous identity
    return EnterpriseIdentity.anonymous;
  }

  File get _sessionCacheFile => File(p.join(_projectRoot, '.fps', 'session.json'));

  void _saveSessionCache(EnterpriseSession session) {
    try {
      final dir = _sessionCacheFile.parent;
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      _sessionCacheFile.writeAsStringSync(jsonEncode(session.toJson()));
    } catch (e) {
      _logger.warning('Failed to write session cache: $e');
    }
  }

  EnterpriseSession? _loadSessionCache() {
    try {
      if (_sessionCacheFile.existsSync()) {
        final content = _sessionCacheFile.readAsStringSync();
        final jsonMap = jsonDecode(content) as Map<String, dynamic>;
        final session = EnterpriseSession.fromJson(jsonMap);
        if (session.isValid) {
          return session;
        }
      }
    } catch (_) {}
    return null;
  }

  void _clearSessionCache() {
    try {
      if (_sessionCacheFile.existsSync()) {
        _sessionCacheFile.deleteSync();
      }
    } catch (_) {}
  }
}
