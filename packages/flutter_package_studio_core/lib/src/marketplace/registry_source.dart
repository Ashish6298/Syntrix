/// Provenance record tracking which remote registry supplied a catalog entry.
///
/// [RegistrySource] is attached to every [TemplateCatalogEntry] fetched from a
/// remote registry. It provides full traceability without exposing credentials
/// or internal authentication details.
class RegistrySource {
  /// Registry identifier from [RemoteRegistryOptions.id].
  final String registryId;

  /// Base URL of the registry (sanitized; no credentials).
  final String registryBaseUrl;

  /// Protocol version string returned by the registry (e.g. `"1"`).
  final String protocolVersion;

  /// Timestamp when the registry response was fetched.
  final DateTime fetchedAt;

  /// Whether this entry was served from the local cache.
  final bool fromCache;

  /// Creates a [RegistrySource] instance.
  const RegistrySource({
    required this.registryId,
    required this.registryBaseUrl,
    required this.protocolVersion,
    required this.fetchedAt,
    this.fromCache = false,
  });

  /// Returns a copy with [fromCache] set to [value].
  RegistrySource withCacheFlag(bool value) => RegistrySource(
        registryId: registryId,
        registryBaseUrl: registryBaseUrl,
        protocolVersion: protocolVersion,
        fetchedAt: fetchedAt,
        fromCache: value,
      );

  @override
  String toString() =>
      'RegistrySource(registry: $registryId, proto: $protocolVersion, '
      'fetched: $fetchedAt, fromCache: $fromCache)';
}
