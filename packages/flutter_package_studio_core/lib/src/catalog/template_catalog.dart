import 'package:flutter_package_studio_core/src/catalog/template_catalog_entry.dart';
import 'package:flutter_package_studio_core/src/catalog/template_catalog_query.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/template/template_semver.dart';

/// Deterministic, searchable, in-memory index of [TemplateCatalogEntry] instances.
///
/// [TemplateCatalog] is immutable once constructed; all mutation returns new
/// instances through [merge] or [add]. The catalog exposes a rich query API
/// backed by deterministic in-memory filtering and sorting — no network calls,
/// no external I/O.
class TemplateCatalog {
  final Logger _logger = Logger('TemplateCatalog');

  /// Internal indexed storage keyed by `id@version`.
  final Map<String, TemplateCatalogEntry> _index;

  /// Creates an empty [TemplateCatalog].
  TemplateCatalog() : _index = {};

  /// Creates a [TemplateCatalog] pre-populated with [entries].
  TemplateCatalog.fromEntries(Iterable<TemplateCatalogEntry> entries)
      : _index = {} {
    for (final entry in entries) {
      _index[_key(entry.id, entry.version)] = entry;
    }
  }

  String _key(String id, String version) => '$id@$version';

  // ── Mutation ──────────────────────────────────────────────────────────────

  /// Adds [entry] to this catalog. Overwrites existing entry with same key.
  void add(TemplateCatalogEntry entry) {
    final key = _key(entry.id, entry.version);
    _logger.debug('Indexing catalog entry: ${entry.id}@${entry.version}');
    _index[key] = entry;
  }

  /// Removes the entry with [id] and optional [version].
  /// If [version] is omitted, all versions of [id] are removed.
  /// Returns the number of entries removed.
  int remove(String id, {String? version}) {
    if (version != null) {
      final removed = _index.remove(_key(id, version));
      return removed != null ? 1 : 0;
    }
    final keys = _index.keys.where((k) => k.startsWith('$id@')).toList();
    for (final k in keys) {
      _index.remove(k);
    }
    return keys.length;
  }

  /// Merges all entries from [other] into this catalog.
  /// Existing entries are overwritten when the same `id@version` key is found.
  void merge(TemplateCatalog other) {
    _logger.debug(
        'Merging ${other.length} entries into catalog (current: $length).');
    _index.addAll(other._index);
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Returns all entries as an unmodifiable list in the default sort order.
  List<TemplateCatalogEntry> listAll() {
    final all = List<TemplateCatalogEntry>.from(_index.values);
    all.sort(_byName);
    return List.unmodifiable(all);
  }

  /// Looks up a single entry by [id] and optional [version].
  /// When [version] is omitted, returns the highest registered version.
  TemplateCatalogEntry? get(String id, {String? version}) {
    if (version != null) {
      return _index[_key(id, version)];
    }
    final all = _index.values.where((e) => e.id == id).toList();
    if (all.isEmpty) return null;
    all.sort((a, b) => TemplateSemVer.parse(b.version)
        .compareTo(TemplateSemVer.parse(a.version)));
    return all.first;
  }

  /// Returns true if an entry with [id] exists (any version).
  bool contains(String id, {String? version}) {
    if (version != null) return _index.containsKey(_key(id, version));
    return _index.keys.any((k) => k.startsWith('$id@'));
  }

  /// Executes a [query] and returns the filtered, sorted, optionally limited
  /// list of matching entries.
  List<TemplateCatalogEntry> query(TemplateCatalogQuery query) {
    _logger.debug('Executing catalog query: $query');
    Iterable<TemplateCatalogEntry> results = _index.values;

    // Text search
    final searchText = query.searchText?.trim().toLowerCase();
    if (searchText != null && searchText.isNotEmpty) {
      results = results.where((e) => _matchesText(e, searchText));
    }

    // Project type filter
    if (query.projectType != null) {
      results = results.where((e) => e.projectType == query.projectType);
    }

    // Category filter
    if (query.category != null) {
      results = results.where((e) => e.category.name == query.category);
    }

    // Maturity filter
    if (query.maturity != null) {
      results = results.where((e) => e.maturity == query.maturity);
    }

    // Required tags (ALL must match)
    if (query.requiredTags.isNotEmpty) {
      results = results
          .where((e) => query.requiredTags.every((t) => e.allTags.contains(t)));
    }

    // Any tags (at least one must match)
    if (query.anyTags.isNotEmpty) {
      results =
          results.where((e) => query.anyTags.any((t) => e.allTags.contains(t)));
    }

    // Version constraint filter
    if (query.versionConstraint != null) {
      results = results.where((e) {
        try {
          return TemplateSemVer.parse(e.version)
              .satisfies(query.versionConstraint!);
        } catch (_) {
          return false;
        }
      });
    }

    // Provider filter
    if (query.providerKey != null) {
      results = results.where((e) => e.providerKey == query.providerKey);
    }

    // Sort
    final sorted = List<TemplateCatalogEntry>.from(results);
    sorted.sort(_comparatorFor(query.sortOrder));

    // Limit
    final limited =
        query.limit != null ? sorted.take(query.limit!).toList() : sorted;

    return List.unmodifiable(limited);
  }

  /// Convenience search by free-text query string.
  List<TemplateCatalogEntry> search(String text,
      {TemplateCatalogSortOrder sortOrder =
          TemplateCatalogSortOrder.nameAscending,
      int? limit}) {
    return query(TemplateCatalogQuery(
      searchText: text,
      sortOrder: sortOrder,
      limit: limit,
    ));
  }

  /// Filters entries by [projectType].
  List<TemplateCatalogEntry> filterByProjectType(String projectType) {
    return query(TemplateCatalogQuery(projectType: projectType));
  }

  /// Returns all unique project types present in the catalog.
  Set<String> get projectTypes =>
      _index.values.map((e) => e.projectType).toSet();

  /// Returns all unique tags across all catalog entries.
  Set<String> get allTags => _index.values.expand((e) => e.allTags).toSet();

  /// Returns all unique provider keys present in the catalog.
  Set<String> get providerKeys =>
      _index.values.map((e) => e.providerKey).toSet();

  /// Total count of entries in this catalog.
  int get length => _index.length;

  /// Whether this catalog has no entries.
  bool get isEmpty => _index.isEmpty;

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _matchesText(TemplateCatalogEntry e, String lower) {
    return e.id.toLowerCase().contains(lower) ||
        e.displayName.toLowerCase().contains(lower) ||
        e.description.toLowerCase().contains(lower) ||
        e.allTags.any((t) => t.toLowerCase().contains(lower)) ||
        (e.publisher?.toLowerCase().contains(lower) ?? false);
  }

  int _byName(TemplateCatalogEntry a, TemplateCatalogEntry b) =>
      a.displayName.compareTo(b.displayName);

  Comparator<TemplateCatalogEntry> _comparatorFor(
      TemplateCatalogSortOrder order) {
    switch (order) {
      case TemplateCatalogSortOrder.nameAscending:
        return (a, b) => a.displayName.compareTo(b.displayName);
      case TemplateCatalogSortOrder.nameDescending:
        return (a, b) => b.displayName.compareTo(a.displayName);
      case TemplateCatalogSortOrder.versionNewest:
        return (a, b) {
          try {
            return TemplateSemVer.parse(b.version)
                .compareTo(TemplateSemVer.parse(a.version));
          } catch (_) {
            return 0;
          }
        };
      case TemplateCatalogSortOrder.versionOldest:
        return (a, b) {
          try {
            return TemplateSemVer.parse(a.version)
                .compareTo(TemplateSemVer.parse(b.version));
          } catch (_) {
            return 0;
          }
        };
      case TemplateCatalogSortOrder.mostDownloaded:
        return (a, b) => b.downloadCount.compareTo(a.downloadCount);
      case TemplateCatalogSortOrder.topRated:
        return (a, b) => b.rating.compareTo(a.rating);
      case TemplateCatalogSortOrder.recentlyAdded:
        return (a, b) => b.indexedAt.compareTo(a.indexedAt);
    }
  }

  @override
  String toString() => 'TemplateCatalog(length: $length)';
}
