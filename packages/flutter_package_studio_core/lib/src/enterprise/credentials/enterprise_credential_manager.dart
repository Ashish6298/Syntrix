/// Central Enterprise Credential Manager for Phase 9.9.
library;

import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/ai/security/secret_redactor.dart';
import 'package:flutter_package_studio_core/src/enterprise/credentials/enterprise_credential_models.dart';
import 'package:flutter_package_studio_core/src/enterprise/credentials/enterprise_credential_provider.dart';

/// Central Enterprise Credential Manager.
///
/// Features:
/// 1. Manages multi-provider credential resolution (Environment -> OS Store -> Secret Manager -> Vault).
/// 2. Zero Secret Leaks: Never exposes plaintext secrets in toString, JSON logs, or AI context.
/// 3. Ephemeral Bounded Injection: Secrets are injected strictly within `executeWithScopedCredential()` closures.
/// 4. Checks secret availability non-intrusively (`checkAvailability()`).
class EnterpriseCredentialManager {
  final Logger _logger = Logger('EnterpriseCredentialManager');
  final String _projectRoot;
  final Map<String, CredentialProvider> _providers = {};

  String get projectRoot => _projectRoot;

  EnterpriseCredentialManager({
    required String projectRoot,
    List<CredentialProvider>? initialProviders,
  }) : _projectRoot = p.normalize(projectRoot) {
    if (initialProviders != null && initialProviders.isNotEmpty) {
      for (final p in initialProviders) {
        registerProvider(p);
      }
    } else {
      registerProvider(EnvironmentCredentialProvider());
      registerProvider(MockEnterpriseSecretManager());
    }
  }

  /// Registers a credential provider.
  void registerProvider(CredentialProvider provider) {
    _providers[provider.providerId] = provider;
    _logger.info(
        'Registered credential provider: ${provider.providerId} (${provider.displayName})');
  }

  /// Checks if a credential key exists across registered providers.
  Future<SecretAvailabilityResult> checkAvailability(String key) async {
    final now = DateTime.now();
    for (final provider in _providers.values) {
      final exists = await provider.hasSecret(key);
      if (exists) {
        return SecretAvailabilityResult(
          key: key,
          isAvailable: true,
          providerType: provider.providerType,
          providerId: provider.providerId,
          message:
              'Credential key "$key" is securely available via ${provider.displayName}.',
          checkedAt: now,
        );
      }
    }

    return SecretAvailabilityResult(
      key: key,
      isAvailable: false,
      providerType: CredentialProviderType.environment,
      providerId: 'none',
      message:
          'Credential key "$key" was not found in any registered provider.',
      checkedAt: now,
    );
  }

  /// Executes an operation strictly within an ephemeral, secret-injected boundary.
  ///
  /// The secret is NEVER stored in the manager, never logged, and never passed to AI systems.
  Future<R> executeWithScopedCredential<R>({
    required String key,
    required CredentialScope scope,
    required Future<R> Function(String rawSecret) executionClosure,
  }) async {
    EphemeralCredentialToken? token;

    for (final provider in _providers.values) {
      token = await provider.getEphemeralCredential(key: key, scope: scope);
      if (token != null) break;
    }

    if (token == null) {
      throw StateError(
          'Cannot execute: Credential key "$key" is not available in registered providers.');
    }

    _logger.info(
        'Injecting scoped credential "$key" into isolated execution boundary (Scope: ${scope.id}).');

    return token.withSecret((rawSecret) async {
      try {
        return await executionClosure(rawSecret);
      } catch (e) {
        final sanitizedError = SecretRedactor.redact(e.toString());
        _logger.error(
            'Execution error inside credential boundary: $sanitizedError');
        throw StateError('Execution failed: $sanitizedError');
      }
    });
  }

  /// Lists all non-sensitive credential references available.
  Future<List<CredentialReference>> listAllReferences() async {
    final all = <CredentialReference>[];
    for (final provider in _providers.values) {
      all.addAll(await provider.listReferences());
    }
    return all;
  }
}
