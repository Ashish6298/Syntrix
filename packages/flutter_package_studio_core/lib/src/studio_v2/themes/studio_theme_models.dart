/// Domain models and theme palette descriptors for Phase 10.6: Theme & Visual System Studio.
library;

import 'dart:convert';

/// Representation of a color in HEX format for theme palettes.
class ThemeColorDefinition {
  final String role; // primary, accent, background, glow, particle
  final String hex;

  const ThemeColorDefinition({
    required this.role,
    required this.hex,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'hex': hex,
      };

  factory ThemeColorDefinition.fromJson(Map<String, dynamic> json) {
    return ThemeColorDefinition(
      role: json['role'] as String? ?? 'primary',
      hex: json['hex'] as String? ?? '#FFFFFF',
    );
  }
}

/// Detailed descriptor of a package theme.
class StudioThemeDescriptor {
  final String id;
  final String name;
  final String description;
  final List<ThemeColorDefinition> palette;
  final String backgroundColor;
  final String particleGlowColor;
  final double defaultParticleSize;
  final double defaultParticleOpacity;
  final List<String> supportedLoaderIds;
  final Map<String, dynamic> visualProperties;
  final bool isCustom;

  const StudioThemeDescriptor({
    required this.id,
    required this.name,
    required this.description,
    required this.palette,
    required this.backgroundColor,
    required this.particleGlowColor,
    this.defaultParticleSize = 2.0,
    this.defaultParticleOpacity = 0.8,
    this.supportedLoaderIds = const [
      'infinite_universe',
      'galaxy_orbit',
      'nebula_storm',
      'quantum_void',
      'pulsar_wave',
      'cyber_matrix',
    ],
    this.visualProperties = const {},
    this.isCustom = false,
  });

  StudioThemeDescriptor copyWith({
    String? id,
    String? name,
    String? description,
    List<ThemeColorDefinition>? palette,
    String? backgroundColor,
    String? particleGlowColor,
    double? defaultParticleSize,
    double? defaultParticleOpacity,
    List<String>? supportedLoaderIds,
    Map<String, dynamic>? visualProperties,
    bool? isCustom,
  }) {
    return StudioThemeDescriptor(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      palette: palette ?? this.palette,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      particleGlowColor: particleGlowColor ?? this.particleGlowColor,
      defaultParticleSize: defaultParticleSize ?? this.defaultParticleSize,
      defaultParticleOpacity: defaultParticleOpacity ?? this.defaultParticleOpacity,
      supportedLoaderIds: supportedLoaderIds ?? this.supportedLoaderIds,
      visualProperties: visualProperties ?? this.visualProperties,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'palette': palette.map((c) => c.toJson()).toList(),
        'background_color': backgroundColor,
        'particle_glow_color': particleGlowColor,
        'default_particle_size': defaultParticleSize,
        'default_particle_opacity': defaultParticleOpacity,
        'supported_loader_ids': supportedLoaderIds,
        'visual_properties': visualProperties,
        'is_custom': isCustom,
      };

  factory StudioThemeDescriptor.fromJson(Map<String, dynamic> json) {
    return StudioThemeDescriptor(
      id: json['id'] as String? ?? 'deep_space',
      name: json['name'] as String? ?? 'Unnamed Theme',
      description: json['description'] as String? ?? '',
      palette: (json['palette'] as List<dynamic>?)
              ?.map((c) => ThemeColorDefinition.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      backgroundColor: json['background_color'] as String? ?? '#0B0D1B',
      particleGlowColor: json['particle_glow_color'] as String? ?? '#4F46E5',
      defaultParticleSize: (json['default_particle_size'] as num?)?.toDouble() ?? 2.0,
      defaultParticleOpacity: (json['default_particle_opacity'] as num?)?.toDouble() ?? 0.8,
      supportedLoaderIds: (json['supported_loader_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      visualProperties: (json['visual_properties'] as Map<String, dynamic>?) ?? const {},
      isCustom: json['is_custom'] as bool? ?? false,
    );
  }
}
