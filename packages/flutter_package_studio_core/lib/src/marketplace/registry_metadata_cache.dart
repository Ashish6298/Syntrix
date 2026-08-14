import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/marketplace/registry_source.dart';
import 'package:flutter_package_studio_core/src/marketplace/remote_template_record.dart';

/// Cache entry stored per registry.
class _CacheEntry {
  final List<RemoteTemplateRecord> records;
  final RegistrySource source;
  final DateTime storedAt;

  _CacheEntry({
    required this.records,
    required this.source,
    required this.storedAt,
  });
}

/// TTL-based in-memory cache for remote registry metadata.
///
/// ## Behavior
///
/// - Cache is keyed by **registry id** (unique per [RemoteRegistryOptions.id]).
/// - Each entry has an explicit TTL determined by [RemoteRegistryOptions.cacheTtl].
/// - A "fresh" entry (age < TTL) is returned without contacting the registry.
/// - A "stale" entry (age >= TTL) triggers a background refresh; the stale data
///   is still returned with a [RegistrySource.fromCache] flag set.
/// - A missing entry triggers an immediate fetch.
///
/// ## Memory-only
///
/// Phase 2.3 uses memory-only caching. Disk caching is intentionally deferred.
/// Extend [RegistryMetadataCache] with a storage backend in a future phase.
///
/// ## Credentials
///
/// No credentials are stored in the cache under any circumstances.
///
/// ## Corruption Handling
///
/// Because this is in-memory only, corruption is limited to programmer error.
/// [invalidate] and [clear] can reset state if needed.
class RegistryMetadataCache {
  final Map<String, _CacheEntry> _store = {};

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Stores [records] for [registryId] with provenance [source].
  ///
  /// Replaces any existing entry for the same registry.
  void put(
    String registryId,
    List<RemoteTemplateRecord> records,
    RegistrySource source,
  ) {
    _store[registryId] = _CacheEntry(
      records: List.unmodifiable(records),
      source: source.withCacheFlag(true),
      storedAt: DateTime.now().toUtc(),
    );
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  /// Returns true if a (possibly stale) cache entry exists for [registryId].
  bool has(String registryId) => _store.containsKey(registryId);

  /// Returns true if the cache entry for [registryId] is still within [ttl].
  bool isFresh(String registryId, Duration ttl) {
    final entry = _store[registryId];
    if (entry == null) return false;
    final age = DateTime.now().toUtc().difference(entry.storedAt);
    return age <= ttl;
  }

  /// Returns the cached [RemoteTemplateRecord] list for [registryId].
  ///
  /// Throws [RegistryCacheException] if no entry exists.
  /// The returned [RegistrySource] has [RegistrySource.fromCache] == `true`.
  ({List<RemoteTemplateRecord> records, RegistrySource source}) get(
      String registryId) {
    final entry = _store[registryId];
    if (entry == null) {
      throw RegistryCacheException(
          'No cache entry found for registry "$registryId".');
    }
    return (records: entry.records, source: entry.source);
  }

  /// Returns the [RegistrySource] for [registryId] without returning records.
  ///
  /// Returns null if no entry exists.
  RegistrySource? getSource(String registryId) => _store[registryId]?.source;

  // ── Invalidation ──────────────────────────────────────────────────────────

  /// Removes the cache entry for [registryId]. No-op if absent.
  void invalidate(String registryId) {
    _store.remove(registryId);
  }

  /// Removes all cache entries.
  void clear() {
    _store.clear();
  }

  /// Number of registries with cached entries.
  int get size => _store.length;
}
