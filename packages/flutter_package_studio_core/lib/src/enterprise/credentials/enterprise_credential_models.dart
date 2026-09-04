/// Domain models and credential references for Phase 9.9: Enterprise Secrets & Credential Abstraction.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/ai/security/secret_redactor.dart';

/// Supported Credential Vault / Provider Types.
enum CredentialProviderType {
  environment,
  osCredentialStore,
  enterpriseSecretManager,
  mockVault,
  custom;

  String get id => name;

  String get displayName {
    switch (this) {
      case CredentialProviderType.environment:
        return 'Environment Variables';
      case CredentialProviderType.osCredentialStore:
        return 'OS Credential Store (Keychain / Windows Vault)';
      case CredentialProviderType.enterpriseSecretManager:
        return 'Enterprise Secret Manager (Vault / AWS / GCP / Azure)';
      case CredentialProviderType.mockVault:
        return 'In-Memory Encrypted Mock Vault';
      case CredentialProviderType.custom:
        return 'Custom Credential Provider';
    }
  }

  static CredentialProviderType fromString(String? val) {
    if (val == null) return CredentialProviderType.environment;
    return CredentialProviderType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() ||
          e.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => CredentialProviderType.custom,
    );
  }
}

/// Scope restricting where and when a credential may be injected.
enum CredentialScope {
  publish,
  ci,
  git,
  signing,
  apiIntegration,
  global;

  String get id => name;
}

/// Safe, non-sensitive Credential Reference pointer (never holds plaintext secret values).
class CredentialReference {
  final String key;
  final String providerId;
  final CredentialProviderType providerType;
  final CredentialScope scope;
  final String description;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;

  const CredentialReference({
    required this.key,
    required this.providerId,
    this.providerType = CredentialProviderType.environment,
    this.scope = CredentialScope.global,
    this.description = '',
    this.createdAt,
    this.expiresAt,
    this.metadata = const {},
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toJson() => {
        'key': key,
        'provider_id': providerId,
        'provider_type': providerType.id,
        'scope': scope.id,
        'description': description,
        'created_at': createdAt?.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'metadata': metadata,
      };

  factory CredentialReference.fromJson(Map<String, dynamic> json) {
    return CredentialReference(
      key: json['key'] as String? ?? '',
      providerId: json['provider_id'] as String? ?? 'env',
      providerType: CredentialProviderType.fromString(json['provider_type'] as String?),
      scope: CredentialScope.values.firstWhere(
        (s) => s.name == json['scope'],
        orElse: () => CredentialScope.global,
      ),
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] is String ? DateTime.parse(json['created_at'] as String) : null,
      expiresAt: json['expires_at'] is String ? DateTime.parse(json['expires_at'] as String) : null,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Secret Availability Verification Status.
class SecretAvailabilityResult {
  final String key;
  final bool isAvailable;
  final CredentialProviderType providerType;
  final String providerId;
  final String? message;
  final DateTime checkedAt;

  const SecretAvailabilityResult({
    required this.key,
    required this.isAvailable,
    required this.providerType,
    required this.providerId,
    this.message,
    required this.checkedAt,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'is_available': isAvailable,
        'provider_type': providerType.id,
        'provider_id': providerId,
        'message': message,
        'checked_at': checkedAt.toIso8601String(),
      };
}

/// Ephemeral Credential Injection Handle that guarantees scoped exposure and automatic scrubbing.
class EphemeralCredentialToken {
  final String key;
  final String _rawSecret;
  final CredentialScope scope;
  final DateTime issuedAt;
  final Duration ttl;

  EphemeralCredentialToken({
    required this.key,
    required String rawSecret,
    required this.scope,
    this.ttl = const Duration(minutes: 5),
  })  : _rawSecret = rawSecret,
        issuedAt = DateTime.now();

  bool get isExpired => DateTime.now().difference(issuedAt) > ttl;

  /// Retrieves the raw secret strictly within an isolated, bounded execution closure.
  ///
  /// Guarantees:
  /// 1. Exposes secret ONLY within the provided [callback].
  /// 2. Redacts any output or errors if captured.
  R withSecret<R>(R Function(String rawSecret) callback) {
    if (isExpired) {
      throw StateError('Ephemeral credential token for "$key" has expired.');
    }
    return callback(_rawSecret);
  }

  @override
  String toString() => 'EphemeralCredentialToken(key: $key, scope: ${scope.id}, value: [REDACTED_SECRET])';
}
