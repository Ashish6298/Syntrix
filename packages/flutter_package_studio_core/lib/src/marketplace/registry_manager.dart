import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/marketplace/http_registry_transport.dart';
import 'package:flutter_package_studio_core/src/marketplace/registry_metadata_cache.dart';
import 'package:flutter_package_studio_core/src/marketplace/registry_response_parser.dart';
import 'package:flutter_package_studio_core/src/marketplace/registry_source.dart';
import 'package:flutter_package_studio_core/src/marketplace/registry_status.dart';
import 'package:flutter_package_studio_core/src/marketplace/remote_metadata_validator.dart';
import 'package:flutter_package_studio_core/src/marketplace/remote_registry_client.dart';
import 'package:flutter_package_studio_core/src/marketplace/remote_registry_options.dart';
import 'package:flutter_package_studio_core/src/marketplace/remote_template_record.dart';

/// A plan produced by a registry mutation operation in dry-run mode.
class RegistryMutationPlan {
  /// Human-readable description of the planned change.
  final String description;

  /// Whether this is a dry-run (no actual change made).
  final bool isDryRun;

  const RegistryMutationPlan({
    required this.description,
    required this.isDryRun,
  });

  @override
  String toString() => '[${isDryRun ? "DRY-RUN" : "APPLIED"}] $description';
}

/// Result of a registry refresh operation.
class RegistryRefreshResult {
  final String registryId;
  final bool succeeded;
  final int? recordsFetched;
  final int? recordsAccepted;
  final int? recordsRejected;
  final String? errorMessage;

  const RegistryRefreshResult._({
    required this.registryId,
    required this.succeeded,
    this.recordsFetched,
    this.recordsAccepted,
    this.recordsRejected,
    this.errorMessage,
  });

  factory RegistryRefreshResult.success(
    String id, {
    required int fetched,
    required int accepted,
    required int rejected,
  }) =>
      RegistryRefreshResult._(
        registryId: id,
        succeeded: true,
        recordsFetched: fetched,
        recordsAccepted: accepted,
        recordsRejected: rejected,
      );

  factory RegistryRefreshResult.failure(String id, String error) =>
      RegistryRefreshResult._(
        registryId: id,
        succeeded: false,
        errorMessage: error,
      );
}

/// Central manager for multiple remote template registries.
///
/// [RegistryManager] provides:
/// - Add/remove/enable/disable registry lifecycle management.
/// - On-demand and cached metadata fetching.
/// - Deterministic stale-cache fallback when the network is unavailable.
/// - Per-registry status reporting (no credentials exposed).
/// - Offline-mode enforcement to prevent all network access.
///
/// ## Conflict Resolution
///
/// When multiple registries supply the same `id@version`, the first registry
/// to contribute that entry wins (registration order). Builtin/local providers
/// (managed separately in [TemplateDiscoveryService]) always have higher
/// priority than remote entries.
///
/// This strategy is **explicit, deterministic, and documented**.
class RegistryManager {
  final Logger _logger = Logger('RegistryManager');
  final RegistryMetadataCache _cache;
  final RemoteMetadataValidator _validator;
  final RemoteRegistryClient _client;
  bool _offlineMode = false;

  /// Ordered list of configured registries.
  final List<RemoteRegistryOptions> _registries = [];

  /// Cached validated records per registry (after validation, order matters).
  final Map<String, List<RemoteTemplateRecord>> _validatedRecords = {};
  final Map<String, RegistrySource> _sources = {};
  final Map<String, RegistryStatus> _statusCache = {};

  /// Creates a [RegistryManager].
  RegistryManager({
    RegistryTransport? transport,
    RegistryMetadataCache? cache,
    RemoteMetadataValidator? validator,
  })  : _cache = cache ?? RegistryMetadataCache(),
        _validator = validator ?? const RemoteMetadataValidator(),
        _client = RemoteRegistryClient(
          transport: transport ??
              MockRegistryTransport(
                  const {}), // No-op default; caller should inject real transport
          parser: const RegistryResponseParser(),
        );

  /// Creates a [RegistryManager] with an injected [client] (for testing).
  RegistryManager.withClient({
    required RemoteRegistryClient client,
    RegistryMetadataCache? cache,
    RemoteMetadataValidator? validator,
  })  : _client = client,
        _cache = cache ?? RegistryMetadataCache(),
        _validator = validator ?? const RemoteMetadataValidator();

  // ── Registry Lifecycle ────────────────────────────────────────────────────

  /// Adds [options] to the managed set.
  ///
  /// Throws [RegistryConfigurationException] if the id is already registered.
  /// Returns a [RegistryMutationPlan] describing the change.
  RegistryMutationPlan add(RemoteRegistryOptions options,
      {bool dryRun = false}) {
    if (_registries.any((r) => r.id == options.id)) {
      throw RegistryConfigurationException(
          'A registry with ID "${options.id}" is already configured.');
    }
    final plan = RegistryMutationPlan(
      description:
          'Add registry "${options.id}" pointing to ${options.baseUrl}.',
      isDryRun: dryRun,
    );
    if (!dryRun) {
      _registries.add(options);
      _logger.info('Registry "${options.id}" added (${options.baseUrl}).');
    }
    return plan;
  }

  /// Removes the registry with [registryId].
  ///
  /// Returns [RegistryMutationPlan] or throws [RegistryConfigurationException]
  /// if [registryId] is not found.
  RegistryMutationPlan remove(String registryId, {bool dryRun = false}) {
    _requireExists(registryId);
    final plan = RegistryMutationPlan(
      description: 'Remove registry "$registryId".',
      isDryRun: dryRun,
    );
    if (!dryRun) {
      _registries.removeWhere((r) => r.id == registryId);
      _cache.invalidate(registryId);
      _validatedRecords.remove(registryId);
      _sources.remove(registryId);
      _statusCache.remove(registryId);
      _logger.info('Registry "$registryId" removed.');
    }
    return plan;
  }

  /// Enables the registry with [registryId].
  RegistryMutationPlan enable(String registryId, {bool dryRun = false}) {
    _requireExists(registryId);
    final plan = RegistryMutationPlan(
      description: 'Enable registry "$registryId".',
      isDryRun: dryRun,
    );
    if (!dryRun) {
      _mutateRegistry(registryId, (r) => r.copyWith(enabled: true));
      _logger.info('Registry "$registryId" enabled.');
    }
    return plan;
  }

  /// Disables the registry with [registryId].
  RegistryMutationPlan disable(String registryId, {bool dryRun = false}) {
    _requireExists(registryId);
    final plan = RegistryMutationPlan(
      description: 'Disable registry "$registryId".',
      isDryRun: dryRun,
    );
    if (!dryRun) {
      _mutateRegistry(registryId, (r) => r.copyWith(enabled: false));
      _logger.info('Registry "$registryId" disabled.');
    }
    return plan;
  }

  /// Returns an unmodifiable snapshot of all configured registries.
  List<RemoteRegistryOptions> listAll() =>
      List.unmodifiable(List.of(_registries));

  // ── Offline Mode ──────────────────────────────────────────────────────────

  /// When true, all network fetches are prevented. Stale cache is used instead.
  bool get isOffline => _offlineMode;

  /// Enables or disables offline mode.
  void setOfflineMode(bool value) {
    _offlineMode = value;
    _logger.info('Registry offline mode: ${value ? "ON" : "OFF"}');
  }

  // ── Fetching / Refresh ────────────────────────────────────────────────────

  /// Refreshes metadata for [registryId] (or all enabled registries if null).
  ///
  /// Uses cached data when:
  /// - [isOffline] is true AND valid cached data exists.
  /// - Cache is fresh (within TTL) and [force] is false.
  ///
  /// Returns one [RegistryRefreshResult] per refreshed registry.
  Future<List<RegistryRefreshResult>> refresh({
    String? registryId,
    bool force = false,
  }) async {
    final targets = registryId != null
        ? _registries.where((r) => r.id == registryId).toList()
        : _registries.where((r) => r.enabled).toList();

    final results = <RegistryRefreshResult>[];
    for (final opts in targets) {
      results.add(await _refreshOne(opts, force: force));
    }
    return results;
  }

  Future<RegistryRefreshResult> _refreshOne(
    RemoteRegistryOptions opts, {
    bool force = false,
  }) async {
    // Respect cache TTL
    if (!force && _cache.isFresh(opts.id, opts.cacheTtl)) {
      final cached = _cache.get(opts.id);
      _validatedRecords[opts.id] = cached.records;
      _sources[opts.id] = cached.source;
      _logger.debug('Registry "${opts.id}": using fresh cache '
          '(${cached.records.length} records).');
      return RegistryRefreshResult.success(
        opts.id,
        fetched: cached.records.length,
        accepted: cached.records.length,
        rejected: 0,
      );
    }

    // Offline mode — use stale cache if available
    if (_offlineMode) {
      if (_cache.has(opts.id)) {
        final cached = _cache.get(opts.id);
        _validatedRecords[opts.id] = cached.records;
        _sources[opts.id] = cached.source;
        _logger.warning('Registry "${opts.id}": offline mode, serving '
            '${cached.records.length} stale cached records.');
        _statusCache[opts.id] = RegistryStatus(
          registryId: opts.id,
          displayName: opts.displayName ?? opts.id,
          health: RegistryHealthState.stale,
          templateCount: cached.records.length,
          servingFromCache: true,
          message: 'Offline mode; serving stale cached data.',
        );
        return RegistryRefreshResult.success(
          opts.id,
          fetched: cached.records.length,
          accepted: cached.records.length,
          rejected: 0,
        );
      }
      _logger
          .error('Registry "${opts.id}": offline mode and no cache available.');
      return RegistryRefreshResult.failure(
          opts.id, 'Offline mode and no cached data available.');
    }

    // Fetch from remote
    final fetchResult = await _client.fetchCatalog(opts);
    if (!fetchResult.succeeded) {
      // Fallback to stale cache on failure
      if (_cache.has(opts.id)) {
        final cached = _cache.get(opts.id);
        _validatedRecords[opts.id] = cached.records;
        _sources[opts.id] = cached.source;
        _logger.warning(
            'Registry "${opts.id}": fetch failed (${fetchResult.errorMessage}); '
            'serving ${cached.records.length} stale cached records.');
        _statusCache[opts.id] = RegistryStatus.offline(
          opts.id,
          opts.displayName ?? opts.id,
          fetchResult.errorMessage ?? 'Unknown error',
          true,
        );
        return RegistryRefreshResult.success(
          opts.id,
          fetched: cached.records.length,
          accepted: cached.records.length,
          rejected: 0,
        );
      }
      _statusCache[opts.id] = RegistryStatus.offline(
        opts.id,
        opts.displayName ?? opts.id,
        fetchResult.errorMessage ?? 'Unknown error',
        false,
      );
      return RegistryRefreshResult.failure(
          opts.id, fetchResult.errorMessage ?? 'Fetch failed');
    }

    // Validate records
    final raw = fetchResult.payload!.templates;
    int rejected = 0;
    final validated = _validator.validateAll(
      raw,
      onRejected: (record, reason) {
        rejected++;
        _logger.warning(
            'Registry "${opts.id}": rejected record "${record.id}@${record.version}": $reason');
      },
    );

    // Store in cache and memory
    _cache.put(opts.id, validated, fetchResult.source);
    _validatedRecords[opts.id] = validated;
    _sources[opts.id] = fetchResult.source;

    _statusCache[opts.id] = RegistryStatus(
      registryId: opts.id,
      displayName: opts.displayName ?? opts.id,
      health: RegistryHealthState.online,
      templateCount: validated.length,
      lastFetchedAt: fetchResult.source.fetchedAt,
      message: rejected > 0
          ? '$rejected record(s) rejected during validation.'
          : null,
    );

    _logger.info('Registry "${opts.id}": ${validated.length} accepted, '
        '$rejected rejected.');
    return RegistryRefreshResult.success(
      opts.id,
      fetched: raw.length,
      accepted: validated.length,
      rejected: rejected,
    );
  }

  // ── Status ────────────────────────────────────────────────────────────────

  /// Returns [RegistryStatus] for [registryId] (or all if null).
  List<RegistryStatus> status({String? registryId}) {
    final targets = registryId != null
        ? _registries.where((r) => r.id == registryId)
        : _registries;

    return targets.map((opts) {
      if (!opts.enabled)
        return RegistryStatus.disabled(opts.id, opts.displayName ?? opts.id);
      return _statusCache[opts.id] ??
          RegistryStatus(
            registryId: opts.id,
            displayName: opts.displayName ?? opts.id,
            health: RegistryHealthState.unknown,
          );
    }).toList();
  }

  // ── Data Access ───────────────────────────────────────────────────────────

  /// Returns all validated [RemoteTemplateRecord] records from all enabled
  /// registries, with duplicate `id@version` de-duplication using first-wins.
  List<RemoteTemplateRecord> allValidatedRecords() {
    final seen = <String>{};
    final result = <RemoteTemplateRecord>[];

    for (final opts in _registries) {
      if (!opts.enabled) continue;
      final records = _validatedRecords[opts.id] ?? [];
      for (final record in records) {
        final key = '${record.id}@${record.version}';
        if (!seen.contains(key)) {
          seen.add(key);
          result.add(record);
        }
      }
    }
    return result;
  }

  /// Returns the [RegistrySource] for [registryId] (null if unknown).
  RegistrySource? sourceFor(String registryId) => _sources[registryId];

  // ── Internals ─────────────────────────────────────────────────────────────

  void _requireExists(String id) {
    if (!_registries.any((r) => r.id == id)) {
      throw RegistryConfigurationException(
          'No registry configured with ID "$id".');
    }
  }

  void _mutateRegistry(
      String id, RemoteRegistryOptions Function(RemoteRegistryOptions) fn) {
    final idx = _registries.indexWhere((r) => r.id == id);
    if (idx < 0) return;
    _registries[idx] = fn(_registries[idx]);
  }
}
