/// Pluggable Credential Provider interfaces and built-in implementations for Phase 9.9.
library;

import 'dart:io';
import 'package:syntrix/src/enterprise/credentials/enterprise_credential_models.dart';

/// Pluggable Credential Provider interface.
abstract class CredentialProvider {
  String get providerId;
  CredentialProviderType get providerType;
  String get displayName;

  /// Checks if a credential key is available without exposing its plaintext value.
  Future<bool> hasSecret(String key);

  /// Retrieves an ephemeral token for secret injection at execution boundary.
  Future<EphemeralCredentialToken?> getEphemeralCredential({
    required String key,
    required CredentialScope scope,
  });

  /// Lists non-sensitive credential reference metadata.
  Future<List<CredentialReference>> listReferences();
}

/// Environment Variable Credential Provider.
class EnvironmentCredentialProvider implements CredentialProvider {
  @override
  final String providerId;

  @override
  final CredentialProviderType providerType =
      CredentialProviderType.environment;

  @override
  final String displayName = 'Environment Variable Credential Provider';

  final Map<String, String>? _envOverride;

  EnvironmentCredentialProvider({
    this.providerId = 'env_provider',
    Map<String, String>? envOverride,
  }) : _envOverride = envOverride;

  Map<String, String> get _environment => _envOverride ?? Platform.environment;

  @override
  Future<bool> hasSecret(String key) async {
    final val = _environment[key];
    return val != null && val.isNotEmpty;
  }

  @override
  Future<EphemeralCredentialToken?> getEphemeralCredential({
    required String key,
    required CredentialScope scope,
  }) async {
    final val = _environment[key];
    if (val == null || val.isEmpty) return null;

    return EphemeralCredentialToken(
      key: key,
      rawSecret: val,
      scope: scope,
    );
  }

  @override
  Future<List<CredentialReference>> listReferences() async {
    final refs = <CredentialReference>[];
    for (final k in _environment.keys) {
      if (k.startsWith('FPS_') ||
          k.startsWith('PUB_') ||
          k.startsWith('GITHUB_') ||
          k.contains('TOKEN') ||
          k.contains('SECRET')) {
        refs.add(CredentialReference(
          key: k,
          providerId: providerId,
          providerType: providerType,
          description: 'Environment variable reference: $k',
        ));
      }
    }
    return refs;
  }
}

/// Mock / In-Memory Encrypted Vault Provider for testing and local simulation.
class MockEnterpriseSecretManager implements CredentialProvider {
  @override
  final String providerId;

  @override
  final CredentialProviderType providerType = CredentialProviderType.mockVault;

  @override
  final String displayName;

  final Map<String, String> _secretsVault = {};
  final Map<String, CredentialReference> _references = {};

  MockEnterpriseSecretManager({
    this.providerId = 'mock_vault',
    this.displayName = 'Mock Enterprise Secret Vault',
    Map<String, String>? initialSecrets,
  }) {
    if (initialSecrets != null) {
      for (final entry in initialSecrets.entries) {
        registerSecret(
          key: entry.key,
          secretValue: entry.value,
          description: 'Mock vault secret for ${entry.key}',
        );
      }
    }
  }

  /// Registers a secret into the vault.
  void registerSecret({
    required String key,
    required String secretValue,
    CredentialScope scope = CredentialScope.global,
    String description = '',
    Duration? ttl,
  }) {
    _secretsVault[key] = secretValue;
    _references[key] = CredentialReference(
      key: key,
      providerId: providerId,
      providerType: providerType,
      scope: scope,
      description: description,
      createdAt: DateTime.now(),
      expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
    );
  }

  @override
  Future<bool> hasSecret(String key) async {
    final ref = _references[key];
    if (ref != null && ref.isExpired) return false;
    return _secretsVault.containsKey(key);
  }

  @override
  Future<EphemeralCredentialToken?> getEphemeralCredential({
    required String key,
    required CredentialScope scope,
  }) async {
    final ref = _references[key];
    if (ref != null && ref.isExpired) return null;

    final val = _secretsVault[key];
    if (val == null) return null;

    return EphemeralCredentialToken(
      key: key,
      rawSecret: val,
      scope: scope,
    );
  }

  @override
  Future<List<CredentialReference>> listReferences() async {
    return _references.values.where((r) => !r.isExpired).toList();
  }
}
