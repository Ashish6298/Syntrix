/// Central Explorer Engine for Phase 10.3: Advanced Loader Explorer.
library;

import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/studio_v2/studio_v2_controller.dart';
import 'package:syntrix/src/studio_v2/explorer/studio_explorer_models.dart';

/// Central Loader Explorer Engine providing discovery, search, filtering, and comparison.
class StudioLoaderExplorerEngine {
  final Logger _logger = Logger('StudioLoaderExplorerEngine');
  final StudioV2Controller controller;
  final Map<String, LoaderMetadataEntry> _catalog = {};

  List<LoaderMetadataEntry> get allLoaders => _catalog.values.toList();

  StudioLoaderExplorerEngine({
    required this.controller,
    List<LoaderMetadataEntry>? customLoaders,
  }) {
    if (customLoaders != null && customLoaders.isNotEmpty) {
      for (final loader in customLoaders) {
        registerLoader(loader);
      }
    } else {
      _registerDefaultPackageLoaders();
    }
  }

  void _registerDefaultPackageLoaders() {
    registerLoader(const LoaderMetadataEntry(
      id: 'infinite_universe',
      name: 'Infinite Universe',
      description:
          'Cosmic particle swirling vortex with dynamic gravitational physics and shader glow.',
      category: LoaderCategory.cosmic,
      complexity: LoaderComplexity.highPerformance,
      hasParticles: true,
      hasPhysics: true,
      hasShaders: true,
      isInteractive: true,
      supportedThemes: ['deep_space', 'solar_flare', 'milky_way'],
    ));

    registerLoader(const LoaderMetadataEntry(
      id: 'galaxy_orbit',
      name: 'Galaxy Orbit',
      description:
          'Multi-ring planetary orbit loader with synchronized orbital resonance and trails.',
      category: LoaderCategory.cosmic,
      complexity: LoaderComplexity.standard,
      hasParticles: true,
      hasPhysics: true,
      hasShaders: false,
      isInteractive: true,
      supportedThemes: ['milky_way', 'cyber_galaxy'],
    ));

    registerLoader(const LoaderMetadataEntry(
      id: 'nebula_storm',
      name: 'Nebula Storm',
      description:
          'Volumetric fluid cosmic dust storm with turbulent particle physics.',
      category: LoaderCategory.fluid,
      complexity: LoaderComplexity.advanced,
      hasParticles: true,
      hasPhysics: true,
      hasShaders: true,
      isInteractive: true,
      supportedThemes: ['nebula_storm', 'aurora_cosmos'],
    ));

    registerLoader(const LoaderMetadataEntry(
      id: 'quantum_void',
      name: 'Quantum Void',
      description:
          'Geometric atomic orbital lattice with mathematical probability wave oscillation.',
      category: LoaderCategory.quantum,
      complexity: LoaderComplexity.advanced,
      hasParticles: true,
      hasPhysics: false,
      hasShaders: true,
      isInteractive: true,
      supportedThemes: ['quantum_void', 'cyber_galaxy'],
    ));

    registerLoader(const LoaderMetadataEntry(
      id: 'pulsar_wave',
      name: 'Pulsar Wave',
      description:
          'Minimalist radial pulse ring with rhythmic easing and glowing wavefront.',
      category: LoaderCategory.minimal,
      complexity: LoaderComplexity.lightweight,
      hasParticles: false,
      hasPhysics: false,
      hasShaders: false,
      isInteractive: false,
      supportedThemes: ['deep_space', 'solar_flare'],
    ));

    registerLoader(const LoaderMetadataEntry(
      id: 'cyber_matrix',
      name: 'Cyber Matrix',
      description:
          'Retro cyberpunk digital rain loader with scanline shader passes.',
      category: LoaderCategory.retro,
      complexity: LoaderComplexity.standard,
      hasParticles: true,
      hasPhysics: false,
      hasShaders: true,
      isInteractive: true,
      supportedThemes: ['cyber_galaxy'],
    ));
  }

  /// Register a loader into the Explorer Catalog.
  void registerLoader(LoaderMetadataEntry loader) {
    _catalog[loader.id] = loader;
    _logger.info(
        'Registered loader in explorer catalog: ${loader.id} (${loader.name})');
  }

  /// Look up a single loader by ID.
  LoaderMetadataEntry? getLoader(String loaderId) => _catalog[loaderId];

  /// Query the catalog using [LoaderExplorerQuery].
  List<LoaderMetadataEntry> queryLoaders(LoaderExplorerQuery query) {
    final favorites = controller.state.favoriteLoaderIds.toSet();
    return _catalog.values.where((loader) {
      final isFav = favorites.contains(loader.id);
      return query.matches(loader, isFavorite: isFav);
    }).toList();
  }

  /// Toggle favorite status of a loader via controller.
  void toggleFavorite(String loaderId) {
    controller.toggleFavoriteLoader(loaderId);
  }

  /// Select a loader and apply its defaults to the active Studio workspace.
  void selectAndApplyLoader(String loaderId) {
    final loader = _catalog[loaderId];
    if (loader != null) {
      controller.updateConfiguration((cfg) => cfg.copyWith(
            targetLoaderId: loader.id,
            selectedThemeId: loader.supportedThemes.isNotEmpty
                ? loader.supportedThemes.first
                : cfg.selectedThemeId,
            shadersEnabled: loader.hasShaders,
            isInteractive: loader.isInteractive,
          ));
      _logger
          .info('Applied loader "${loader.name}" to workspace configuration.');
    }
  }

  /// Compare two loaders side-by-side.
  Map<String, dynamic> compareLoaders(String loaderIdA, String loaderIdB) {
    final a = _catalog[loaderIdA];
    final b = _catalog[loaderIdB];

    if (a == null || b == null) {
      return {'error': 'One or both loaders not found'};
    }

    return {
      'loader_a': a.toJson(),
      'loader_b': b.toJson(),
      'comparison': {
        'both_have_particles': a.hasParticles && b.hasParticles,
        'both_have_physics': a.hasPhysics && b.hasPhysics,
        'both_have_shaders': a.hasShaders && b.hasShaders,
        'both_interactive': a.isInteractive && b.isInteractive,
        'shared_themes': a.supportedThemes
            .toSet()
            .intersection(b.supportedThemes.toSet())
            .toList(),
      },
    };
  }
}
