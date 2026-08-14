import 'package:flutter_package_studio_core/src/error/exceptions.dart';

/// Authentication mode for a remote registry.
enum RegistryAuthMode {
  /// No authentication required (public registry).
  none,

  /// Bearer token supplied via environment variable.
  bearerToken,
}

/// Cache policy for a remote registry.
enum RegistryCachePolicy {
  /// Use cached data when available and not expired (default).
  normal,

  /// Always re-fetch; never use cached data.
  noCache,

  /// Always use cache even when stale; never fetch.
  cacheOnly,
}

/// Immutable configuration options for a single remote template registry.
///
/// [RemoteRegistryOptions] describes how [RemoteRegistryClient] should connect
/// to a specific registry endpoint. All fields are validated on construction;
/// invalid values throw [RegistryConfigurationException].
///
/// Security: credentials must never be stored in this object. Use
/// [RegistryAuthMode.bearerToken] with a separately injected credential
/// provider.
class RemoteRegistryOptions {
  /// Unique identifier for this registry within FPS configuration.
  ///
  /// Must match `^[a-z][a-z0-9_-]{0,63}$`.
  final String id;

  /// Base URL of the registry endpoint.
  ///
  /// Must use `https://` scheme. `http://` and `file://` are rejected.
  final String baseUrl;

  /// Whether this registry is active.
  final bool enabled;

  /// Maximum request timeout duration.
  final Duration requestTimeout;

  /// Cache policy controlling when cached data is used.
  final RegistryCachePolicy cachePolicy;

  /// TTL for cached registry metadata.
  final Duration cacheTtl;

  /// Authentication mode.
  final RegistryAuthMode authMode;

  /// Optional human-readable display name.
  final String? displayName;

  /// Maximum allowed response body size in bytes (default 5 MiB).
  final int maxResponseBytes;

  RemoteRegistryOptions._({
    required this.id,
    required this.baseUrl,
    required this.enabled,
    required this.requestTimeout,
    required this.cachePolicy,
    required this.cacheTtl,
    required this.authMode,
    required this.maxResponseBytes,
    this.displayName,
  });

  /// Creates validated [RemoteRegistryOptions].
  ///
  /// Throws [RegistryConfigurationException] if any value is invalid.
  factory RemoteRegistryOptions({
    required String id,
    required String baseUrl,
    bool enabled = true,
    Duration requestTimeout = const Duration(seconds: 15),
    RegistryCachePolicy cachePolicy = RegistryCachePolicy.normal,
    Duration cacheTtl = const Duration(minutes: 5),
    RegistryAuthMode authMode = RegistryAuthMode.none,
    int maxResponseBytes = 5 * 1024 * 1024, // 5 MiB
    String? displayName,
  }) {
    _validateId(id);
    _validateUrl(baseUrl);
    if (requestTimeout.inSeconds < 1 || requestTimeout.inSeconds > 120) {
      throw RegistryConfigurationException(
          'requestTimeout must be between 1 and 120 seconds (got ${requestTimeout.inSeconds}s).');
    }
    if (maxResponseBytes < 1024 || maxResponseBytes > 50 * 1024 * 1024) {
      throw RegistryConfigurationException(
          'maxResponseBytes must be between 1 KiB and 50 MiB.');
    }
    return RemoteRegistryOptions._(
      id: id,
      baseUrl: baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl,
      enabled: enabled,
      requestTimeout: requestTimeout,
      cachePolicy: cachePolicy,
      cacheTtl: cacheTtl,
      authMode: authMode,
      maxResponseBytes: maxResponseBytes,
      displayName: displayName,
    );
  }

  /// Returns a copy with selected fields overridden.
  RemoteRegistryOptions copyWith({
    bool? enabled,
    Duration? requestTimeout,
    RegistryCachePolicy? cachePolicy,
    Duration? cacheTtl,
    RegistryAuthMode? authMode,
    String? displayName,
    int? maxResponseBytes,
  }) {
    return RemoteRegistryOptions._(
      id: id,
      baseUrl: baseUrl,
      enabled: enabled ?? this.enabled,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      cachePolicy: cachePolicy ?? this.cachePolicy,
      cacheTtl: cacheTtl ?? this.cacheTtl,
      authMode: authMode ?? this.authMode,
      displayName: displayName ?? this.displayName,
      maxResponseBytes: maxResponseBytes ?? this.maxResponseBytes,
    );
  }

  static final _idPattern = RegExp(r'^[a-z][a-z0-9_-]{0,63}$');

  /// Validates that [id] is a safe registry identifier.
  static void _validateId(String id) {
    if (id.isEmpty) {
      throw RegistryConfigurationException('Registry ID must not be empty.');
    }
    if (!_idPattern.hasMatch(id)) {
      throw RegistryConfigurationException(
          'Registry ID "$id" is invalid. Must match [a-z][a-z0-9_-]{0,63}.');
    }
  }

  /// Validates that [url] is a safe HTTPS registry URL.
  static void _validateUrl(String url) {
    if (url.isEmpty) {
      throw RegistryConfigurationException('Registry URL must not be empty.');
    }
    Uri parsed;
    try {
      parsed = Uri.parse(url);
    } catch (_) {
      throw RegistryConfigurationException(
          'Registry URL "$url" is not a valid URI.');
    }
    if (parsed.scheme != 'https') {
      throw RegistryConfigurationException(
          'Registry URL must use HTTPS scheme. Got: "${parsed.scheme}". '
          'Insecure schemes (http, file, javascript) are not permitted.');
    }
    if (!parsed.hasAuthority || parsed.host.isEmpty) {
      throw RegistryConfigurationException(
          'Registry URL "$url" must include a valid hostname.');
    }
    _rejectPrivateRanges(parsed.host);
  }

  /// Rejects URLs targeting private/loopback IP ranges (SSRF protection).
  static void _rejectPrivateRanges(String host) {
    if (host == 'localhost') {
      throw RegistryConfigurationException(
          'Registry URL must not target localhost (SSRF protection).');
    }
    // IPv4 private ranges
    final privatePatterns = [
      RegExp(r'^127\.'),
      RegExp(r'^10\.'),
      RegExp(r'^192\.168\.'),
      RegExp(r'^172\.(1[6-9]|2[0-9]|3[01])\.'),
      RegExp(r'^0\.'),
    ];
    for (final pattern in privatePatterns) {
      if (pattern.hasMatch(host)) {
        throw RegistryConfigurationException(
            'Registry URL must not target private IP ranges (SSRF protection).');
      }
    }
  }

  @override
  String toString() =>
      'RemoteRegistryOptions(id: $id, url: $baseUrl, enabled: $enabled)';
}
