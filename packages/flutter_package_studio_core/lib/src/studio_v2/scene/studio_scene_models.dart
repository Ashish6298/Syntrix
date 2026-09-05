/// Domain models and layer descriptors for Phase 10.7: Scene Builder.
library;

import 'dart:convert';

/// Scene layer type hierarchy.
enum SceneLayerType {
  background,
  primaryLoader,
  particleLayer,
  effectLayer,
  interactionOverlay,
  custom;

  String get id => name;

  String get displayName {
    switch (this) {
      case SceneLayerType.background:
        return 'Background Layer';
      case SceneLayerType.primaryLoader:
        return 'Primary Loader';
      case SceneLayerType.particleLayer:
        return 'Particle Layer';
      case SceneLayerType.effectLayer:
        return 'Effect Layer';
      case SceneLayerType.interactionOverlay:
        return 'Interaction Layer';
      case SceneLayerType.custom:
        return 'Custom Component Layer';
    }
  }
}

/// An individual configurable layer component within a composite scene.
class SceneComponentLayer {
  final String layerId;
  final String name;
  final SceneLayerType layerType;
  final String componentReference; // e.g. 'deep_space', 'galaxy_orbit', 'cosmic_dust'
  final bool isVisible;
  final double opacity;
  final int zIndex;
  final Map<String, dynamic> configuration;

  const SceneComponentLayer({
    required this.layerId,
    required this.name,
    required this.layerType,
    required this.componentReference,
    this.isVisible = true,
    this.opacity = 1.0,
    required this.zIndex,
    this.configuration = const {},
  });

  SceneComponentLayer copyWith({
    String? layerId,
    String? name,
    SceneLayerType? layerType,
    String? componentReference,
    bool? isVisible,
    double? opacity,
    int? zIndex,
    Map<String, dynamic>? configuration,
  }) {
    return SceneComponentLayer(
      layerId: layerId ?? this.layerId,
      name: name ?? this.name,
      layerType: layerType ?? this.layerType,
      componentReference: componentReference ?? this.componentReference,
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
      zIndex: zIndex ?? this.zIndex,
      configuration: configuration ?? this.configuration,
    );
  }

  Map<String, dynamic> toJson() => {
        'layer_id': layerId,
        'name': name,
        'layer_type': layerType.id,
        'component_reference': componentReference,
        'is_visible': isVisible,
        'opacity': opacity,
        'z_index': zIndex,
        'configuration': configuration,
      };

  factory SceneComponentLayer.fromJson(Map<String, dynamic> json) {
    return SceneComponentLayer(
      layerId: json['layer_id'] as String? ?? 'layer_unknown',
      name: json['name'] as String? ?? 'Unnamed Layer',
      layerType: SceneLayerType.values.firstWhere(
        (t) => t.id == json['layer_type'] || t.name == json['layer_type'],
        orElse: () => SceneLayerType.custom,
      ),
      componentReference: json['component_reference'] as String? ?? '',
      isVisible: json['is_visible'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      zIndex: json['z_index'] as int? ?? 0,
      configuration: (json['configuration'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Composite Scene Descriptor containing hierarchical layers and metadata.
class VisualSceneDescriptor {
  final String sceneId;
  final String name;
  final String description;
  final List<SceneComponentLayer> layers;
  final double width;
  final double height;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VisualSceneDescriptor({
    required this.sceneId,
    required this.name,
    this.description = '',
    required this.layers,
    this.width = 400.0,
    this.height = 400.0,
    required this.createdAt,
    required this.updatedAt,
  });

  VisualSceneDescriptor copyWith({
    String? sceneId,
    String? name,
    String? description,
    List<SceneComponentLayer>? layers,
    double? width,
    double? height,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VisualSceneDescriptor(
      sceneId: sceneId ?? this.sceneId,
      name: name ?? this.name,
      description: description ?? this.description,
      layers: layers ?? this.layers,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'scene_id': sceneId,
        'name': name,
        'description': description,
        'layers': layers.map((l) => l.toJson()).toList(),
        'width': width,
        'height': height,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory VisualSceneDescriptor.fromJson(Map<String, dynamic> json) {
    return VisualSceneDescriptor(
      sceneId: json['scene_id'] as String? ?? 'scene_default',
      name: json['name'] as String? ?? 'Default Scene',
      description: json['description'] as String? ?? '',
      layers: (json['layers'] as List<dynamic>?)
              ?.map((l) => SceneComponentLayer.fromJson(l as Map<String, dynamic>))
              .toList() ??
          const [],
      width: (json['width'] as num?)?.toDouble() ?? 400.0,
      height: (json['height'] as num?)?.toDouble() ?? 400.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
