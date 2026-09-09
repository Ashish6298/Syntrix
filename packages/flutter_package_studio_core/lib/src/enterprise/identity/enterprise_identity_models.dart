/// Domain models and abstractions for Phase 9.2: Enterprise Authentication & Identity.
library;

/// Type of principal identity performing an operation.
enum IdentityType {
  user,
  serviceAccount,
  apiToken,
  anonymous;

  String get id => name;

  static IdentityType fromString(String? val) {
    if (val == null) return IdentityType.user;
    return IdentityType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => IdentityType.user,
    );
  }
}

/// Standardized Enterprise Roles.
enum EnterpriseRole {
  administrator,
  releaseManager,
  developer,
  reviewer,
  securityAuditor,
  readOnly,
  custom;

  String get id => name;

  String get displayName {
    switch (this) {
      case EnterpriseRole.administrator:
        return 'Administrator';
      case EnterpriseRole.releaseManager:
        return 'Release Manager';
      case EnterpriseRole.developer:
        return 'Developer';
      case EnterpriseRole.reviewer:
        return 'Reviewer';
      case EnterpriseRole.securityAuditor:
        return 'Security Auditor';
      case EnterpriseRole.readOnly:
        return 'Read Only';
      case EnterpriseRole.custom:
        return 'Custom Role';
    }
  }

  static EnterpriseRole fromString(String? val) {
    if (val == null) return EnterpriseRole.developer;
    return EnterpriseRole.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == val.toLowerCase() ||
          e.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => EnterpriseRole.custom,
    );
  }
}

/// Authentication state status.
enum AuthenticationStatus {
  authenticated,
  unauthenticated,
  expired,
  revoked,
  anonymous;

  bool get isAuthenticated => this == AuthenticationStatus.authenticated;
}

/// Represents an authenticated enterprise subject (User, Service Account, or API Principal).
class EnterpriseIdentity {
  final String id;
  final String displayName;
  final String email;
  final IdentityType type;
  final String organizationId;
  final List<EnterpriseRole> roles;
  final Set<String> directPermissions;
  final Map<String, dynamic> claims;
  final Map<String, dynamic> metadata;

  const EnterpriseIdentity({
    required this.id,
    required this.displayName,
    this.email = '',
    this.type = IdentityType.user,
    this.organizationId = 'default_org',
    this.roles = const [EnterpriseRole.developer],
    this.directPermissions = const {},
    this.claims = const {},
    this.metadata = const {},
  });

  /// Represents an unauthenticated anonymous principal.
  static const EnterpriseIdentity anonymous = EnterpriseIdentity(
    id: 'anonymous',
    displayName: 'Anonymous Principal',
    email: '',
    type: IdentityType.anonymous,
    organizationId: 'none',
    roles: [EnterpriseRole.readOnly],
    directPermissions: {},
  );

  /// Helper to check role membership.
  bool hasRole(EnterpriseRole role) =>
      roles.contains(role) || roles.contains(EnterpriseRole.administrator);

  /// Helper to check permission existence.
  bool hasDirectPermission(String permission) =>
      directPermissions.contains(permission) || directPermissions.contains('*');

  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'email': email,
        'type': type.id,
        'organization_id': organizationId,
        'roles': roles.map((r) => r.id).toList(),
        'direct_permissions': directPermissions.toList(),
        'claims': claims,
        'metadata': metadata,
      };

  factory EnterpriseIdentity.fromJson(Map<String, dynamic> json) {
    return EnterpriseIdentity(
      id: json['id'] as String? ?? 'unknown',
      displayName: json['display_name'] as String? ?? 'Unknown User',
      email: json['email'] as String? ?? '',
      type: IdentityType.fromString(json['type'] as String?),
      organizationId: json['organization_id'] as String? ?? 'default_org',
      roles: (json['roles'] as List<dynamic>?)
              ?.map((r) => EnterpriseRole.fromString(r.toString()))
              .toList() ??
          const [EnterpriseRole.developer],
      directPermissions: (json['direct_permissions'] as List<dynamic>?)
              ?.map((p) => p.toString())
              .toSet() ??
          const {},
      claims: (json['claims'] as Map<String, dynamic>?) ?? const {},
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Enterprise Session Token & Information.
class EnterpriseSession {
  final String sessionId;
  final EnterpriseIdentity identity;
  final AuthenticationStatus status;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String providerId;
  final String? ipAddress;
  final String? userAgent;

  const EnterpriseSession({
    required this.sessionId,
    required this.identity,
    required this.status,
    required this.issuedAt,
    required this.expiresAt,
    required this.providerId,
    this.ipAddress,
    this.userAgent,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid =>
      status == AuthenticationStatus.authenticated && !isExpired;

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'identity': identity.toJson(),
        'status': status.name,
        'issued_at': issuedAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'provider_id': providerId,
        'ip_address': ipAddress,
        'user_agent': userAgent,
      };

  factory EnterpriseSession.fromJson(Map<String, dynamic> json) {
    return EnterpriseSession(
      sessionId: json['session_id'] as String? ?? '',
      identity:
          EnterpriseIdentity.fromJson(json['identity'] as Map<String, dynamic>),
      status: AuthenticationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => AuthenticationStatus.unauthenticated,
      ),
      issuedAt: DateTime.parse(json['issued_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      providerId: json['provider_id'] as String? ?? 'unknown',
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
    );
  }
}

/// Authentication Request Payload.
class AuthenticationRequest {
  final String providerId;
  final Map<String, dynamic> credentials;
  final Map<String, dynamic> context;

  const AuthenticationRequest({
    required this.providerId,
    required this.credentials,
    this.context = const {},
  });
}

/// Authentication Response Payload.
class AuthenticationResult {
  final bool isSuccess;
  final EnterpriseSession? session;
  final String? errorMessage;
  final String? errorCode;
  final int durationMs;
  final DateTime timestamp;

  const AuthenticationResult.success({
    required this.session,
    required this.durationMs,
    required this.timestamp,
  })  : isSuccess = true,
        errorMessage = null,
        errorCode = null;

  const AuthenticationResult.failure({
    required this.errorMessage,
    this.errorCode = 'AUTH_FAILED',
    required this.durationMs,
    required this.timestamp,
  })  : isSuccess = false,
        session = null;

  Map<String, dynamic> toJson() => {
        'is_success': isSuccess,
        'session': session?.toJson(),
        'error_message': errorMessage,
        'error_code': errorCode,
        'duration_ms': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };
}
