/// Health / availability status of a remote registry.
enum RegistryHealthState {
  /// Registry is reachable and metadata is fresh.
  online,

  /// Registry was reachable but metadata is older than its configured TTL.
  stale,

  /// Registry is unreachable; stale cached data may be available.
  offline,

  /// Registry has been administratively disabled.
  disabled,

  /// Registry configuration is invalid (bad URL, id, etc.).
  invalid,

  /// Registry has not been contacted yet.
  unknown,
}

/// Snapshot of a registry's current health and cache state.
///
/// No sensitive information (credentials, tokens) appears in this class.
/// All fields are safe to display to end users.
class RegistryStatus {
  /// Registry identifier.
  final String registryId;

  /// Human-readable display name (or id if not configured).
  final String displayName;

  /// Current health state.
  final RegistryHealthState health;

  /// Number of templates available in the last successful fetch.
  final int? templateCount;

  /// Timestamp of last successful fetch (null if never fetched).
  final DateTime? lastFetchedAt;

  /// Human-readable message explaining the current status.
  final String? message;

  /// Whether cached metadata is currently being served.
  final bool servingFromCache;

  /// Creates a [RegistryStatus] instance.
  const RegistryStatus({
    required this.registryId,
    required this.displayName,
    required this.health,
    this.templateCount,
    this.lastFetchedAt,
    this.message,
    this.servingFromCache = false,
  });

  /// Convenience constructor for an offline registry.
  factory RegistryStatus.offline(
      String id, String name, String reason, bool hasCache) {
    return RegistryStatus(
      registryId: id,
      displayName: name,
      health: RegistryHealthState.offline,
      message: reason,
      servingFromCache: hasCache,
    );
  }

  /// Convenience constructor for a disabled registry.
  factory RegistryStatus.disabled(String id, String name) {
    return RegistryStatus(
      registryId: id,
      displayName: name,
      health: RegistryHealthState.disabled,
    );
  }

  /// Convenience constructor for an invalid-configuration registry.
  factory RegistryStatus.invalid(String id, String name, String reason) {
    return RegistryStatus(
      registryId: id,
      displayName: name,
      health: RegistryHealthState.invalid,
      message: reason,
    );
  }

  @override
  String toString() =>
      'RegistryStatus(id: $registryId, health: ${health.name}, '
      'templates: $templateCount)';
}
