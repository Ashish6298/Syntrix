import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  // ── Helper factories ───────────────────────────────────────────────────────

  TemplateCatalogEntry _makeEntry({
    required String id,
    String version = '1.0.0',
    String projectType = 'flutter_package',
    TemplateCatalogCategory category = TemplateCatalogCategory.builtin,
    String? maturity,
    List<String> tags = const [],
    List<String> discoveryTags = const [],
    double rating = 0.0,
    int downloadCount = 0,
    String? description,
    DateTime? indexedAt,
  }) {
    final manifest = TemplateManifest(
      id: id,
      name: id,
      displayName: 'Display: $id',
      description: description ?? 'Description for $id',
      version: version,
      projectType: projectType,
      minimumDartSdk: '>=3.5.0 <4.0.0',
      tags: tags,
    );
    return TemplateCatalogEntry(
      template: Template(manifest: manifest),
      category: category,
      providerKey: 'test',
      maturity: maturity,
      discoveryTags: discoveryTags,
      rating: rating,
      downloadCount: downloadCount,
      indexedAt: indexedAt ?? DateTime.utc(2025, 1, 1),
    );
  }

  // ── TemplateCatalogEntry Tests ─────────────────────────────────────────────

  group('TemplateCatalogEntry Tests', () {
    test('Basic properties are delegated from template', () {
      final entry = _makeEntry(
        id: 'my_pkg',
        version: '2.0.0',
        projectType: 'dart_package',
      );
      expect(entry.id, equals('my_pkg'));
      expect(entry.version, equals('2.0.0'));
      expect(entry.projectType, equals('dart_package'));
      expect(entry.displayName, equals('Display: my_pkg'));
    });

    test('allTags merges manifest tags and discoveryTags', () {
      final entry = _makeEntry(
        id: 'tagged',
        tags: const ['a', 'b'],
        discoveryTags: const ['c', 'd'],
      );
      expect(entry.allTags, containsAll(['a', 'b', 'c', 'd']));
    });

    test('copyWith overrides selected fields', () {
      final original = _makeEntry(id: 'orig', maturity: 'preview');
      final copy = original.copyWith(maturity: 'stable', rating: 4.5);
      expect(copy.maturity, equals('stable'));
      expect(copy.rating, equals(4.5));
      expect(copy.id, equals('orig')); // unchanged
    });
  });

  // ── TemplateCatalogQuery Tests ─────────────────────────────────────────────

  group('TemplateCatalogQuery Tests', () {
    test('isEmpty returns true for default query', () {
      const q = TemplateCatalogQuery();
      expect(q.isEmpty, isTrue);
    });

    test('isEmpty returns false when searchText is set', () {
      const q = TemplateCatalogQuery(searchText: 'flutter');
      expect(q.isEmpty, isFalse);
    });

    test('copyWith overrides selected fields', () {
      const q = TemplateCatalogQuery(searchText: 'x', limit: 5);
      final q2 = q.copyWith(limit: 10);
      expect(q2.limit, equals(10));
      expect(q2.searchText, equals('x')); // unchanged
    });
  });

  // ── TemplateCatalog Tests ──────────────────────────────────────────────────

  group('TemplateCatalog Tests', () {
    late TemplateCatalog catalog;

    setUp(() {
      catalog = TemplateCatalog();
    });

    test('Starts empty', () {
      expect(catalog.isEmpty, isTrue);
      expect(catalog.length, equals(0));
    });

    test('add() inserts entry and contains() returns true', () {
      final e = _makeEntry(id: 'pkg_a');
      catalog.add(e);
      expect(catalog.contains('pkg_a'), isTrue);
      expect(catalog.length, equals(1));
    });

    test('add() overwrites same id@version', () {
      final e1 = _makeEntry(id: 'pkg_a', maturity: 'preview');
      final e2 = _makeEntry(id: 'pkg_a', maturity: 'stable');
      catalog.add(e1);
      catalog.add(e2);
      expect(catalog.length, equals(1));
      expect(catalog.get('pkg_a')!.maturity, equals('stable'));
    });

    test('remove() by id+version removes specific entry', () {
      catalog.add(_makeEntry(id: 'x', version: '1.0.0'));
      catalog.add(_makeEntry(id: 'x', version: '2.0.0'));
      final removed = catalog.remove('x', version: '1.0.0');
      expect(removed, equals(1));
      expect(catalog.length, equals(1));
      expect(catalog.contains('x', version: '1.0.0'), isFalse);
      expect(catalog.contains('x', version: '2.0.0'), isTrue);
    });

    test('remove() without version removes all versions', () {
      catalog.add(_makeEntry(id: 'y', version: '1.0.0'));
      catalog.add(_makeEntry(id: 'y', version: '2.0.0'));
      final removed = catalog.remove('y');
      expect(removed, equals(2));
      expect(catalog.contains('y'), isFalse);
    });

    test('get() returns highest version when version omitted', () {
      catalog.add(_makeEntry(id: 'z', version: '1.0.0'));
      catalog.add(_makeEntry(id: 'z', version: '2.0.0'));
      catalog.add(_makeEntry(id: 'z', version: '1.5.0'));
      final entry = catalog.get('z');
      expect(entry?.version, equals('2.0.0'));
    });

    test('get() with exact version returns that version', () {
      catalog.add(_makeEntry(id: 'z', version: '1.0.0'));
      catalog.add(_makeEntry(id: 'z', version: '2.0.0'));
      expect(catalog.get('z', version: '1.0.0')?.version, equals('1.0.0'));
    });

    test('fromEntries() pre-populates catalog', () {
      final entries = [
        _makeEntry(id: 'a'),
        _makeEntry(id: 'b'),
        _makeEntry(id: 'c'),
      ];
      final cat = TemplateCatalog.fromEntries(entries);
      expect(cat.length, equals(3));
    });

    test('merge() combines two catalogs', () {
      final cat1 = TemplateCatalog.fromEntries([_makeEntry(id: 'a')]);
      final cat2 = TemplateCatalog.fromEntries([_makeEntry(id: 'b')]);
      cat1.merge(cat2);
      expect(cat1.length, equals(2));
      expect(cat1.contains('b'), isTrue);
    });

    test('listAll() returns entries sorted by name', () {
      catalog.add(_makeEntry(id: 'z_pkg'));
      catalog.add(_makeEntry(id: 'a_pkg'));
      catalog.add(_makeEntry(id: 'm_pkg'));
      final all = catalog.listAll();
      expect(all.map((e) => e.id).toList(),
          orderedEquals(['a_pkg', 'm_pkg', 'z_pkg']));
    });

    test('projectTypes returns distinct set', () {
      catalog.add(_makeEntry(id: 'f', projectType: 'flutter_package'));
      catalog.add(_makeEntry(id: 'd', projectType: 'dart_package'));
      catalog.add(_makeEntry(id: 'f2', projectType: 'flutter_package'));
      expect(catalog.projectTypes,
          containsAll(['flutter_package', 'dart_package']));
      expect(catalog.projectTypes.length, equals(2));
    });

    // ── Query: text search ────────────────────────────────────────────────

    test('query() text search matches ID', () {
      catalog.add(_makeEntry(id: 'state_management'));
      catalog.add(_makeEntry(id: 'network_utils'));
      final results =
          catalog.query(const TemplateCatalogQuery(searchText: 'state'));
      expect(results.length, equals(1));
      expect(results.first.id, equals('state_management'));
    });

    test('query() text search matches description', () {
      catalog.add(
          _makeEntry(id: 'auth_pkg', description: 'Authentication library'));
      catalog.add(_makeEntry(id: 'other', description: 'Just another package'));
      final results = catalog
          .query(const TemplateCatalogQuery(searchText: 'authentication'));
      expect(results.length, equals(1));
      expect(results.first.id, equals('auth_pkg'));
    });

    test('query() text search matches discovery tags', () {
      catalog.add(_makeEntry(
          id: 'ui_kit', discoveryTags: const ['widgets', 'material']));
      catalog.add(_makeEntry(id: 'data_pkg', discoveryTags: const ['json']));
      final results =
          catalog.query(const TemplateCatalogQuery(searchText: 'widgets'));
      expect(results.length, equals(1));
    });

    // ── Query: filtering ─────────────────────────────────────────────────

    test('query() filters by projectType', () {
      catalog.add(_makeEntry(id: 'f1', projectType: 'flutter_package'));
      catalog.add(_makeEntry(id: 'd1', projectType: 'dart_package'));
      catalog.add(_makeEntry(id: 'f2', projectType: 'flutter_package'));
      final results = catalog
          .query(const TemplateCatalogQuery(projectType: 'dart_package'));
      expect(results.length, equals(1));
      expect(results.first.id, equals('d1'));
    });

    test('query() filters by category', () {
      catalog
          .add(_makeEntry(id: 'a', category: TemplateCatalogCategory.builtin));
      catalog.add(
          _makeEntry(id: 'b', category: TemplateCatalogCategory.community));
      final results =
          catalog.query(const TemplateCatalogQuery(category: 'community'));
      expect(results.length, equals(1));
      expect(results.first.id, equals('b'));
    });

    test('query() filters by maturity', () {
      catalog.add(_makeEntry(id: 'stable_pkg', maturity: 'stable'));
      catalog.add(_makeEntry(id: 'preview_pkg', maturity: 'preview'));
      final results =
          catalog.query(const TemplateCatalogQuery(maturity: 'stable'));
      expect(results.length, equals(1));
      expect(results.first.maturity, equals('stable'));
    });

    test('query() filters by requiredTags (ALL must match)', () {
      catalog.add(_makeEntry(
          id: 'a', tags: const ['flutter', 'state'], discoveryTags: const []));
      catalog.add(_makeEntry(
          id: 'b', tags: const ['flutter'], discoveryTags: const []));
      final results = catalog.query(
          const TemplateCatalogQuery(requiredTags: ['flutter', 'state']));
      expect(results.length, equals(1));
      expect(results.first.id, equals('a'));
    });

    test('query() filters by anyTags (at least one must match)', () {
      catalog.add(_makeEntry(id: 'a', tags: const ['state']));
      catalog.add(_makeEntry(id: 'b', tags: const ['network']));
      catalog.add(_makeEntry(id: 'c', tags: const ['storage']));
      final results = catalog
          .query(const TemplateCatalogQuery(anyTags: ['state', 'storage']));
      expect(results.length, equals(2));
    });

    test('query() filters by versionConstraint', () {
      catalog.add(_makeEntry(id: 'a', version: '1.0.0'));
      catalog.add(_makeEntry(id: 'b', version: '2.0.0'));
      catalog.add(_makeEntry(id: 'c', version: '1.5.0'));
      final results = catalog.query(
          const TemplateCatalogQuery(versionConstraint: '>=1.0.0 <2.0.0'));
      expect(results.length, equals(2));
      expect(results.map((e) => e.id), containsAll(['a', 'c']));
    });

    // ── Query: sorting ────────────────────────────────────────────────────

    test('query() sorts by nameDescending', () {
      catalog.add(_makeEntry(id: 'z_pkg'));
      catalog.add(_makeEntry(id: 'a_pkg'));
      final results = catalog.query(const TemplateCatalogQuery(
          sortOrder: TemplateCatalogSortOrder.nameDescending));
      expect(results.first.id, equals('z_pkg'));
    });

    test('query() sorts by mostDownloaded', () {
      catalog.add(_makeEntry(id: 'low', downloadCount: 10));
      catalog.add(_makeEntry(id: 'high', downloadCount: 999));
      catalog.add(_makeEntry(id: 'mid', downloadCount: 50));
      final results = catalog.query(const TemplateCatalogQuery(
          sortOrder: TemplateCatalogSortOrder.mostDownloaded));
      expect(results.first.id, equals('high'));
    });

    test('query() sorts by topRated', () {
      catalog.add(_makeEntry(id: 'ok', rating: 3.0));
      catalog.add(_makeEntry(id: 'best', rating: 5.0));
      final results = catalog.query(const TemplateCatalogQuery(
          sortOrder: TemplateCatalogSortOrder.topRated));
      expect(results.first.id, equals('best'));
    });

    test('query() sorts by recentlyAdded', () {
      final older = DateTime.utc(2024, 1, 1);
      final newer = DateTime.utc(2025, 6, 1);
      catalog.add(_makeEntry(id: 'old_entry', indexedAt: older));
      catalog.add(_makeEntry(id: 'new_entry', indexedAt: newer));
      final results = catalog.query(const TemplateCatalogQuery(
          sortOrder: TemplateCatalogSortOrder.recentlyAdded));
      expect(results.first.id, equals('new_entry'));
    });

    test('query() respects limit', () {
      for (var i = 0; i < 10; i++) {
        catalog.add(_makeEntry(id: 'pkg_$i'));
      }
      final results = catalog.query(const TemplateCatalogQuery(limit: 3));
      expect(results.length, equals(3));
    });

    // ── Convenience methods ───────────────────────────────────────────────

    test('search() convenience method works', () {
      catalog.add(_makeEntry(id: 'flutter_widgets'));
      catalog.add(_makeEntry(id: 'dart_utils'));
      final results = catalog.search('flutter');
      expect(results.length, equals(1));
    });

    test('filterByProjectType() convenience method works', () {
      catalog.add(_makeEntry(id: 'fp', projectType: 'flutter_package'));
      catalog.add(_makeEntry(id: 'dp', projectType: 'dart_package'));
      expect(catalog.filterByProjectType('flutter_package').length, equals(1));
    });
  });

  // ── BuiltinCatalogProvider Tests ───────────────────────────────────────────

  group('BuiltinCatalogProvider Tests', () {
    test('fetchEntries includes flutter_package builtin template', () {
      final provider = BuiltinCatalogProvider();
      final entries = provider.fetchEntries();
      expect(entries.isNotEmpty, isTrue);
      expect(entries.any((e) => e.id == 'flutter_package'), isTrue);
    });

    test('providerKey is "builtin"', () {
      expect(BuiltinCatalogProvider().providerKey, equals('builtin'));
    });

    test('isEnabled is true', () {
      expect(BuiltinCatalogProvider().isEnabled, isTrue);
    });

    test('validate() returns null (healthy)', () {
      expect(BuiltinCatalogProvider().validate(), isNull);
    });

    test('buildCatalog() returns populated catalog', () {
      final catalog = BuiltinCatalogProvider().buildCatalog();
      expect(catalog.length, greaterThanOrEqualTo(1));
      expect(catalog.contains('flutter_package'), isTrue);
    });

    test('fetchEntries includes templates from registry', () {
      final registry = TemplateRegistry();
      BuiltinTemplates.registerDefaultTemplates(registry);
      final provider = BuiltinCatalogProvider(registry: registry);
      final entries = provider.fetchEntries();
      expect(entries.any((e) => e.id == 'flutter_package'), isTrue);
    });

    test('entries have correct category and maturity', () {
      final provider = BuiltinCatalogProvider();
      final entries = provider.fetchEntries();
      final flutterEntry = entries.firstWhere((e) => e.id == 'flutter_package');
      expect(flutterEntry.category, equals(TemplateCatalogCategory.builtin));
      expect(flutterEntry.maturity, equals('stable'));
      expect(flutterEntry.rating, equals(5.0));
    });
  });

  // ── TemplateDiscoveryService Tests ────────────────────────────────────────

  group('TemplateDiscoveryService Tests', () {
    test('Starts with zero providers and empty catalog', () {
      final service = TemplateDiscoveryService();
      expect(service.providerCount, equals(0));
      expect(service.length, equals(0));
    });

    test('registerProvider() adds provider', () {
      final service = TemplateDiscoveryService();
      service.registerProvider(BuiltinCatalogProvider());
      expect(service.providerCount, equals(1));
    });

    test('registerProvider() throws CatalogException on duplicate key', () {
      final service = TemplateDiscoveryService();
      service.registerProvider(BuiltinCatalogProvider());
      expect(
        () => service.registerProvider(BuiltinCatalogProvider()),
        throwsA(isA<CatalogException>()),
      );
    });

    test('removeProvider() removes registered provider', () {
      final service = TemplateDiscoveryService();
      service.registerProvider(BuiltinCatalogProvider());
      final removed = service.removeProvider('builtin');
      expect(removed, isTrue);
      expect(service.providerCount, equals(0));
    });

    test('catalog property returns merged entries from all providers', () {
      final service = TemplateDiscoveryService(
        providers: [BuiltinCatalogProvider()],
      );
      expect(service.length, greaterThanOrEqualTo(1));
      expect(service.contains('flutter_package'), isTrue);
    });

    test('get() returns entry from catalog', () {
      final service = TemplateDiscoveryService(
        providers: [BuiltinCatalogProvider()],
      );
      final entry = service.get('flutter_package');
      expect(entry, isNotNull);
      expect(entry!.id, equals('flutter_package'));
    });

    test('search() finds entries by text', () {
      final service = TemplateDiscoveryService(
        providers: [BuiltinCatalogProvider()],
      );
      final results = service.search('flutter');
      expect(results.isNotEmpty, isTrue);
    });

    test('filterByProjectType() returns type-filtered entries', () {
      final service = TemplateDiscoveryService(
        providers: [BuiltinCatalogProvider()],
      );
      final results = service.filterByProjectType('flutter_package');
      expect(results.isNotEmpty, isTrue);
      expect(results.every((e) => e.projectType == 'flutter_package'), isTrue);
    });

    test('rebuild() returns CatalogBuildResult with success details', () {
      final service = TemplateDiscoveryService(
        providers: [BuiltinCatalogProvider()],
      );
      final result = service.rebuild();
      expect(result.allSucceeded, isTrue);
      expect(result.successfulProviders, contains('builtin'));
      expect(result.totalEntries, greaterThanOrEqualTo(1));
    });

    test('invalidate() forces catalog rebuild on next access', () {
      final service = TemplateDiscoveryService(
        providers: [BuiltinCatalogProvider()],
      );
      final first = service.catalog;
      service.invalidate();
      // Should not throw and should return a valid catalog
      final second = service.catalog;
      expect(second.length, equals(first.length));
    });

    test('availableProjectTypes returns non-empty set', () {
      final service = TemplateDiscoveryService(
        providers: [BuiltinCatalogProvider()],
      );
      expect(service.availableProjectTypes.isNotEmpty, isTrue);
    });

    test('availableTags returns non-empty set', () {
      final service = TemplateDiscoveryService(
        providers: [BuiltinCatalogProvider()],
      );
      expect(service.availableTags.isNotEmpty, isTrue);
    });

    test('query() correctly passes through to catalog', () {
      final service = TemplateDiscoveryService(
        providers: [BuiltinCatalogProvider()],
      );
      final results = service.query(const TemplateCatalogQuery(
        projectType: 'flutter_package',
      ));
      expect(results.isNotEmpty, isTrue);
    });
  });
}
