import 'package:flutter_package_studio_core/src/catalog/template_catalog.dart';
import 'package:flutter_package_studio_core/src/catalog/template_catalog_entry.dart';
import 'package:flutter_package_studio_core/src/catalog/template_catalog_provider.dart';
import 'package:flutter_package_studio_core/src/catalog/template_catalog_query.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';

/// Result of a catalog rebuild operation.
class CatalogBuildResult {
  /// The fully built [TemplateCatalog].
  final TemplateCatalog catalog;

  /// Provider keys that succeeded during build.
  final List<String> successfulProviders;

  /// Provider keys that failed during build along with their error messages.
  final Map<String, String> failedProviders;

  /// Total entries contributed across all providers.
  final int totalEntries;

  /// Creates a [CatalogBuildResult] instance.
  const CatalogBuildResult({
    required this.catalog,
    required this.successfulProviders,
    required this.failedProviders,
    required this.totalEntries,
  });

  /// Whether all providers succeeded.
  bool get allSucceeded => failedProviders.isEmpty;

  @override
  String toString() => 'CatalogBuildResult(entries: $totalEntries, '
      'ok: ${successfulProviders.length}, failed: ${failedProviders.length})';
}

/// Orchestrates multiple [TemplateCatalogProvider] instances into a unified,
/// searchable [TemplateCatalog].
///
/// [TemplateDiscoveryService] is the primary entry point for any code that needs
/// to discover, list, search, or inspect templates. It is responsible for:
/// - Registering and validating providers.
/// - Rebuilding the merged catalog when providers change.
/// - Caching the built catalog to avoid redundant recomputation.
/// - Exposing a concise discovery API on top of [TemplateCatalog].
///
/// No network or disk I/O is performed — all data comes from in-memory
/// [TemplateCatalogProvider] implementations.
class TemplateDiscoveryService {
  final Logger _logger = Logger('TemplateDiscoveryService');

  final List<TemplateCatalogProvider> _providers = [];
  TemplateCatalog? _cachedCatalog;
  bool _dirty = true;

  /// Creates a [TemplateDiscoveryService] with zero or more initial [providers].
  TemplateDiscoveryService({List<TemplateCatalogProvider>? providers}) {
    if (providers != null) {
      for (final p in providers) {
        registerProvider(p);
      }
    }
  }

  // ── Provider management ───────────────────────────────────────────────────

  /// Registers a [provider]. Throws [CatalogException] on duplicate key.
  void registerProvider(TemplateCatalogProvider provider) {
    if (_providers.any((p) => p.providerKey == provider.providerKey)) {
      throw CatalogException(
          'Catalog provider with key "${provider.providerKey}" is already registered.');
    }
    _logger.debug(
        'Registering catalog provider: ${provider.providerKey} (${provider.displayName})');
    _providers.add(provider);
    _invalidate();
  }

  /// Removes the provider with [providerKey]. Returns true if found.
  bool removeProvider(String providerKey) {
    final before = _providers.length;
    _providers.removeWhere((p) => p.providerKey == providerKey);
    if (_providers.length < before) {
      _invalidate();
      return true;
    }
    return false;
  }

  /// Returns all registered provider keys.
  List<String> get providerKeys =>
      List.unmodifiable(_providers.map((p) => p.providerKey));

  /// Returns the count of registered providers.
  int get providerCount => _providers.length;

  // ── Catalog building ──────────────────────────────────────────────────────

  /// Builds or returns the cached [TemplateCatalog], merging all enabled providers.
  TemplateCatalog get catalog {
    if (!_dirty && _cachedCatalog != null) return _cachedCatalog!;
    _cachedCatalog = _buildCatalog().catalog;
    _dirty = false;
    return _cachedCatalog!;
  }

  /// Explicitly rebuilds the catalog from all providers, bypassing cache.
  /// Returns a [CatalogBuildResult] with per-provider success/failure details.
  CatalogBuildResult rebuild() {
    final result = _buildCatalog();
    _cachedCatalog = result.catalog;
    _dirty = false;
    return result;
  }

  /// Forces the next [catalog] access to rebuild.
  void invalidate() => _invalidate();

  // ── Discovery API ─────────────────────────────────────────────────────────

  /// Returns all catalog entries (from all providers, merged).
  List<TemplateCatalogEntry> listAll() => catalog.listAll();

  /// Executes a [query] against the merged catalog.
  List<TemplateCatalogEntry> query(TemplateCatalogQuery q) => catalog.query(q);

  /// Searches catalog entries by free text.
  List<TemplateCatalogEntry> search(String text, {int? limit}) =>
      catalog.search(text, limit: limit);

  /// Looks up a single entry by [id] and optional [version].
  TemplateCatalogEntry? get(String id, {String? version}) =>
      catalog.get(id, version: version);

  /// Returns true if an entry with [id] exists in the catalog.
  bool contains(String id, {String? version}) =>
      catalog.contains(id, version: version);

  /// Filters entries by [projectType].
  List<TemplateCatalogEntry> filterByProjectType(String projectType) =>
      catalog.filterByProjectType(projectType);

  /// Returns all unique project types available in the catalog.
  Set<String> get availableProjectTypes => catalog.projectTypes;

  /// Returns all unique tags across all catalog entries.
  Set<String> get availableTags => catalog.allTags;

  /// Total entries in the merged catalog.
  int get length => catalog.length;

  // ── Internal ──────────────────────────────────────────────────────────────

  void _invalidate() {
    _dirty = true;
    _cachedCatalog = null;
  }

  CatalogBuildResult _buildCatalog() {
    _logger.info(
        'Building template catalog from ${_providers.length} provider(s).');
    final merged = TemplateCatalog();
    final successfulProviders = <String>[];
    final failedProviders = <String, String>{};

    for (final provider in _providers) {
      if (!provider.isEnabled) {
        _logger.debug('Skipping disabled provider: ${provider.providerKey}');
        continue;
      }

      final validationError = provider.validate();
      if (validationError != null) {
        _logger.warning(
            'Provider "${provider.providerKey}" failed validation: $validationError');
        failedProviders[provider.providerKey] = validationError;
        continue;
      }

      try {
        final entries = provider.fetchEntries();
        _logger.debug(
            'Provider "${provider.providerKey}" contributed ${entries.length} entries.');
        for (final entry in entries) {
          merged.add(entry);
        }
        successfulProviders.add(provider.providerKey);
      } catch (e, st) {
        final msg = 'Unexpected error fetching entries: $e';
        _logger.error(
            'Provider "${provider.providerKey}" threw during fetchEntries: $e',
            e,
            st);
        failedProviders[provider.providerKey] = msg;
      }
    }

    _logger.info('Catalog build complete: ${merged.length} entries from '
        '${successfulProviders.length} provider(s).');

    return CatalogBuildResult(
      catalog: merged,
      successfulProviders: successfulProviders,
      failedProviders: failedProviders,
      totalEntries: merged.length,
    );
  }
}
