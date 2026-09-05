/// Domain models and query criteria for Phase 10.3: Advanced Loader Explorer.
library;

import 'dart:convert';

/// Loader categorization groupings.
enum LoaderCategory {
  cosmic,
  geometric,
  fluid,
  minimal,
  quantum,
  retro,
  organic,
  custom;

  String get id => name;

  String get displayName {
    switch (this) {
      case LoaderCategory.cosmic:
        return 'Cosmic & Space';
      case LoaderCategory.geometric:
        return 'Geometric & Mathematical';
      case LoaderCategory.fluid:
        return 'Fluid & Particle Waves';
      case LoaderCategory.minimal:
        return 'Minimalist & Clean';
      case LoaderCategory.quantum:
        return 'Quantum & Atomic';
      case LoaderCategory.retro:
        return 'Retro & Cyberpunk';
      case LoaderCategory.organic:
        return 'Organic & Bio-Form';
      case LoaderCategory.custom:
        return 'Custom User Loader';
    }
  }

  static LoaderCategory fromString(String? val) {
    if (val == null) return LoaderCategory.cosmic;
    return LoaderCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == val.toLowerCase() ||
          c.displayName.toLowerCase() == val.toLowerCase(),
      orElse: () => LoaderCategory.cosmic,
    );
  }
}

/// Rendering complexity level.
enum LoaderComplexity {
  lightweight,
  standard,
  advanced,
  highPerformance;

  String get id => name;

  String get label => name.toUpperCase();
}

/// Metadata descriptor for an explored loader component.
class LoaderMetadataEntry {
  final String id;
  final String name;
  final String description;
  final LoaderCategory category;
  final LoaderComplexity complexity;
  final bool hasParticles;
  final bool hasPhysics;
  final bool hasShaders;
  final bool isInteractive;
  final List<String> supportedThemes;
  final List<String> supportedFeatures;
  final Map<String, dynamic> defaultParameters;

  const LoaderMetadataEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.complexity = LoaderComplexity.standard,
    this.hasParticles = false,
    this.hasPhysics = false,
    this.hasShaders = false,
    this.isInteractive = true,
    this.supportedThemes = const ['deep_space', 'solar_flare'],
    this.supportedFeatures = const ['animation_speed', 'intensity', 'scale'],
    this.defaultParameters = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.id,
        'complexity': complexity.id,
        'has_particles': hasParticles,
        'has_physics': hasPhysics,
        'has_shaders': hasShaders,
        'is_interactive': isInteractive,
        'supported_themes': supportedThemes,
        'supported_features': supportedFeatures,
        'default_parameters': defaultParameters,
      };

  factory LoaderMetadataEntry.fromJson(Map<String, dynamic> json) {
    return LoaderMetadataEntry(
      id: json['id'] as String? ?? 'unknown_loader',
      name: json['name'] as String? ?? 'Unnamed Loader',
      description: json['description'] as String? ?? '',
      category: LoaderCategory.fromString(json['category'] as String?),
      complexity: LoaderComplexity.values.firstWhere(
        (c) => c.id == json['complexity'] || c.name == json['complexity'],
        orElse: () => LoaderComplexity.standard,
      ),
      hasParticles: json['has_particles'] as bool? ?? false,
      hasPhysics: json['has_physics'] as bool? ?? false,
      hasShaders: json['has_shaders'] as bool? ?? false,
      isInteractive: json['is_interactive'] as bool? ?? true,
      supportedThemes: (json['supported_themes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['deep_space'],
      supportedFeatures: (json['supported_features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      defaultParameters: (json['default_parameters'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Filter and search criteria for querying the Loader Explorer.
class LoaderExplorerQuery {
  final String? searchQuery;
  final LoaderCategory? category;
  final LoaderComplexity? complexity;
  final bool? requiresParticles;
  final bool? requiresPhysics;
  final bool? requiresShaders;
  final bool? requiresInteractive;
  final bool? onlyFavorites;

  const LoaderExplorerQuery({
    this.searchQuery,
    this.category,
    this.complexity,
    this.requiresParticles,
    this.requiresPhysics,
    this.requiresShaders,
    this.requiresInteractive,
    this.onlyFavorites,
  });

  bool matches(LoaderMetadataEntry loader, {bool isFavorite = false}) {
    if (onlyFavorites == true && !isFavorite) return false;

    if (searchQuery != null && searchQuery!.trim().isNotEmpty) {
      final q = searchQuery!.toLowerCase().trim();
      final inName = loader.name.toLowerCase().contains(q);
      final inId = loader.id.toLowerCase().contains(q);
      final inDesc = loader.description.toLowerCase().contains(q);
      if (!inName && !inId && !inDesc) return false;
    }

    if (category != null && loader.category != category) return false;
    if (complexity != null && loader.complexity != complexity) return false;
    if (requiresParticles != null && loader.hasParticles != requiresParticles) return false;
    if (requiresPhysics != null && loader.hasPhysics != requiresPhysics) return false;
    if (requiresShaders != null && loader.hasShaders != requiresShaders) return false;
    if (requiresInteractive != null && loader.isInteractive != requiresInteractive) return false;

    return true;
  }
}
