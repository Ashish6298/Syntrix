import 'package:flutter_package_studio_core/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.3: Advanced Loader Explorer Models', () {
    test('LoaderMetadataEntry serialization and deserialization', () {
      const entry = LoaderMetadataEntry(
        id: 'infinite_universe',
        name: 'Infinite Universe',
        description: 'Cosmic particle swirling vortex',
        category: LoaderCategory.cosmic,
        complexity: LoaderComplexity.highPerformance,
        hasParticles: true,
        hasPhysics: true,
        hasShaders: true,
        isInteractive: true,
        supportedThemes: ['deep_space', 'solar_flare'],
      );

      final json = entry.toJson();
      final restored = LoaderMetadataEntry.fromJson(json);

      expect(restored.id, equals('infinite_universe'));
      expect(restored.name, equals('Infinite Universe'));
      expect(restored.category, equals(LoaderCategory.cosmic));
      expect(restored.complexity, equals(LoaderComplexity.highPerformance));
      expect(restored.hasParticles, isTrue);
      expect(restored.hasPhysics, isTrue);
      expect(restored.hasShaders, isTrue);
      expect(restored.isInteractive, isTrue);
      expect(restored.supportedThemes.length, equals(2));
    });

    test('LoaderExplorerQuery filtering criteria', () {
      const entryA = LoaderMetadataEntry(
        id: 'loader_a',
        name: 'Cosmic Nebula',
        description: 'Vibrant stellar cloud',
        category: LoaderCategory.cosmic,
        complexity: LoaderComplexity.advanced,
        hasParticles: true,
        hasPhysics: true,
        hasShaders: true,
      );

      const entryB = LoaderMetadataEntry(
        id: 'loader_b',
        name: 'Minimal Pulse',
        description: 'Simple radial pulse',
        category: LoaderCategory.minimal,
        complexity: LoaderComplexity.lightweight,
        hasParticles: false,
        hasPhysics: false,
        hasShaders: false,
      );

      // Search match
      const querySearch = LoaderExplorerQuery(searchQuery: 'nebula');
      expect(querySearch.matches(entryA), isTrue);
      expect(querySearch.matches(entryB), isFalse);

      // Category match
      const queryCategory =
          LoaderExplorerQuery(category: LoaderCategory.minimal);
      expect(queryCategory.matches(entryA), isFalse);
      expect(queryCategory.matches(entryB), isTrue);

      // Shaders match
      const queryShaders = LoaderExplorerQuery(requiresShaders: true);
      expect(queryShaders.matches(entryA), isTrue);
      expect(queryShaders.matches(entryB), isFalse);

      // Favorites filter
      const queryFav = LoaderExplorerQuery(onlyFavorites: true);
      expect(queryFav.matches(entryA, isFavorite: true), isTrue);
      expect(queryFav.matches(entryA, isFavorite: false), isFalse);
    });
  });

  group('Phase 10.3: Studio Loader Explorer Engine Operations', () {
    test('Queries catalog with search and multi-criteria filters', () {
      final controller = StudioV2Controller();
      final explorer = StudioLoaderExplorerEngine(controller: controller);

      expect(explorer.allLoaders.length, greaterThanOrEqualTo(6));

      // 1. Search query
      final cosmicLoaders = explorer.queryLoaders(
          const LoaderExplorerQuery(category: LoaderCategory.cosmic));
      expect(cosmicLoaders.length, greaterThanOrEqualTo(2));
      expect(cosmicLoaders.every((l) => l.category == LoaderCategory.cosmic),
          isTrue);

      // 2. Filter by shaders & physics
      final gpuPhysicsLoaders = explorer.queryLoaders(const LoaderExplorerQuery(
        requiresShaders: true,
        requiresPhysics: true,
      ));
      expect(gpuPhysicsLoaders.length, greaterThanOrEqualTo(2));
      expect(gpuPhysicsLoaders.any((l) => l.id == 'infinite_universe'), isTrue);

      // 3. Filter by favorites
      controller.toggleFavoriteLoader('infinite_universe');
      final favs =
          explorer.queryLoaders(const LoaderExplorerQuery(onlyFavorites: true));
      expect(favs.length, equals(1));
      expect(favs.first.id, equals('infinite_universe'));
    });

    test('selectAndApplyLoader updates controller workspace configuration', () {
      final controller = StudioV2Controller();
      final explorer = StudioLoaderExplorerEngine(controller: controller);

      explorer.selectAndApplyLoader('nebula_storm');

      expect(controller.state.activeConfiguration.targetLoaderId,
          equals('nebula_storm'));
      expect(controller.state.activeConfiguration.selectedThemeId,
          equals('nebula_storm'));
      expect(controller.state.activeConfiguration.shadersEnabled, isTrue);
      expect(controller.state.activeConfiguration.isInteractive, isTrue);
    });

    test('compareLoaders generates structured comparison payload', () {
      final controller = StudioV2Controller();
      final explorer = StudioLoaderExplorerEngine(controller: controller);

      final comparison =
          explorer.compareLoaders('infinite_universe', 'pulsar_wave');
      expect(comparison.containsKey('error'), isFalse);
      expect(comparison['comparison']['both_have_particles'], isFalse);
      expect(comparison['comparison']['both_have_physics'], isFalse);
      expect(comparison['comparison']['shared_themes'], contains('deep_space'));
    });
  });

  group('Phase 10.3: Studio Explorer Renderer', () {
    test('Renders ASCII Loader Card, Markdown Catalog, and Comparison Matrix',
        () {
      final controller = StudioV2Controller();
      final explorer = StudioLoaderExplorerEngine(controller: controller);

      final loader = explorer.getLoader('infinite_universe')!;

      // 1. ASCII Card
      final card = StudioExplorerRenderer.renderLoaderCardAscii(loader,
          isFavorite: true);
      expect(card, contains('Infinite Universe'));
      expect(card, contains('FAVORITE'));
      expect(card, contains('Category:    Cosmic & Space'));
      expect(card, contains('Particles:   ✓ Enabled'));
      expect(
          card, contains('[Preview]  [Configure]  [Generate Code] [Export]'));

      // 2. Markdown Catalog
      final catalogMd =
          StudioExplorerRenderer.renderMarkdownCatalog(explorer.allLoaders);
      expect(catalogMd, contains('# Loader Explorer Catalog'));
      expect(catalogMd, contains('Infinite Universe'));
      expect(catalogMd, contains('Galaxy Orbit'));

      // 3. Comparison Matrix
      final comp = explorer.compareLoaders('infinite_universe', 'galaxy_orbit');
      final compMd = StudioExplorerRenderer.renderComparisonMarkdown(comp);
      expect(compMd, contains('# Loader Comparison Matrix'));
      expect(compMd, contains('Infinite Universe'));
      expect(compMd, contains('Galaxy Orbit'));

      // 4. JSON
      final json = StudioExplorerRenderer.renderJson(explorer.allLoaders);
      expect(json, contains('"id": "infinite_universe"'));
    });
  });
}
