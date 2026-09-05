/// Central Scene Builder Engine for Phase 10.7.
library;

import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_controller.dart';
import 'package:flutter_package_studio_core/src/studio_v2/scene/studio_scene_models.dart';

/// Central Scene Builder Engine orchestrating visual scene composition, layer reordering, and state persistence.
class StudioSceneBuilderEngine {
  final Logger _logger = Logger('StudioSceneBuilderEngine');
  final StudioV2Controller controller;

  VisualSceneDescriptor _activeScene;
  final Map<String, VisualSceneDescriptor> _savedScenes = {};
  final List<void Function(VisualSceneDescriptor)> _listeners = [];

  VisualSceneDescriptor get activeScene => _activeScene;
  List<VisualSceneDescriptor> get savedScenes => _savedScenes.values.toList();

  StudioSceneBuilderEngine({
    required this.controller,
    VisualSceneDescriptor? initialScene,
  }) : _activeScene = initialScene ?? _createDefaultScene() {
    _savedScenes[_activeScene.sceneId] = _activeScene;
  }

  static VisualSceneDescriptor _createDefaultScene() {
    final now = DateTime.now();
    return VisualSceneDescriptor(
      sceneId: 'scene_default',
      name: 'Deep Space Galaxy Scene',
      description: 'Default composite scene containing Background, Galaxy Orbit, Cosmic Dust, and Gesture Overlay.',
      layers: const [
        SceneComponentLayer(
          layerId: 'layer_bg_01',
          name: 'Deep Space Background',
          layerType: SceneLayerType.background,
          componentReference: 'deep_space',
          zIndex: 0,
        ),
        SceneComponentLayer(
          layerId: 'layer_loader_01',
          name: 'Galaxy Orbit Loader',
          layerType: SceneLayerType.primaryLoader,
          componentReference: 'galaxy_orbit',
          zIndex: 10,
        ),
        SceneComponentLayer(
          layerId: 'layer_particles_01',
          name: 'Cosmic Dust Particles',
          layerType: SceneLayerType.particleLayer,
          componentReference: 'cosmic_dust',
          zIndex: 20,
          opacity: 0.85,
        ),
        SceneComponentLayer(
          layerId: 'layer_effect_01',
          name: 'Nebula Glow Effect',
          layerType: SceneLayerType.effectLayer,
          componentReference: 'nebula_glow',
          zIndex: 30,
          opacity: 0.5,
        ),
        SceneComponentLayer(
          layerId: 'layer_interaction_01',
          name: 'Touch & Drag Gestures',
          layerType: SceneLayerType.interactionOverlay,
          componentReference: 'gesture_enabled',
          zIndex: 40,
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  void addSceneListener(void Function(VisualSceneDescriptor) listener) {
    _listeners.add(listener);
  }

  void removeSceneListener(void Function(VisualSceneDescriptor) listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in _listeners) {
      listener(_activeScene);
    }
  }

  /// Add a component layer to the active scene.
  void addLayer(SceneComponentLayer layer) {
    final updatedLayers = List<SceneComponentLayer>.from(_activeScene.layers)..add(layer);
    _sortLayersByZIndex(updatedLayers);

    _activeScene = _activeScene.copyWith(
      layers: updatedLayers,
      updatedAt: DateTime.now(),
    );
    _logger.info('Added layer "${layer.name}" (ID: ${layer.layerId}) to scene.');
    _notify();
  }

  /// Remove a component layer from the active scene.
  bool removeLayer(String layerId) {
    final updatedLayers = _activeScene.layers.where((l) => l.layerId != layerId).toList();
    if (updatedLayers.length != _activeScene.layers.length) {
      _activeScene = _activeScene.copyWith(
        layers: updatedLayers,
        updatedAt: DateTime.now(),
      );
      _logger.info('Removed layer "$layerId" from scene.');
      _notify();
      return true;
    }
    return false;
  }

  /// Reorder layer Z-indices.
  void reorderLayer(String layerId, int newZIndex) {
    final updatedLayers = _activeScene.layers.map((l) {
      if (l.layerId == layerId) {
        return l.copyWith(zIndex: newZIndex);
      }
      return l;
    }).toList();

    _sortLayersByZIndex(updatedLayers);
    _activeScene = _activeScene.copyWith(
      layers: updatedLayers,
      updatedAt: DateTime.now(),
    );
    _logger.info('Reordered layer "$layerId" to z-index: $newZIndex');
    _notify();
  }

  /// Update individual layer configuration.
  void configureLayer(String layerId, {bool? isVisible, double? opacity, Map<String, dynamic>? config}) {
    final updatedLayers = _activeScene.layers.map((l) {
      if (l.layerId == layerId) {
        return l.copyWith(
          isVisible: isVisible ?? l.isVisible,
          opacity: opacity ?? l.opacity,
          configuration: config ?? l.configuration,
        );
      }
      return l;
    }).toList();

    _activeScene = _activeScene.copyWith(
      layers: updatedLayers,
      updatedAt: DateTime.now(),
    );
    _notify();
  }

  void _sortLayersByZIndex(List<SceneComponentLayer> layers) {
    layers.sort((a, b) => a.zIndex.compareTo(b.zIndex));
  }

  /// Save current scene to internal persistence memory.
  void saveScene() {
    _savedScenes[_activeScene.sceneId] = _activeScene;
    _logger.info('Saved scene: ${_activeScene.sceneId} ("${_activeScene.name}")');
  }

  /// Restore a saved scene by ID.
  bool restoreScene(String sceneId) {
    final scene = _savedScenes[sceneId];
    if (scene != null) {
      _activeScene = scene;
      _logger.info('Restored scene: $sceneId');
      _notify();
      return true;
    }
    return false;
  }

  /// Generate production-ready Flutter composition widget code.
  String generateSceneFlutterCode() {
    final buffer = StringBuffer();
    buffer.writeln('// Production-ready Flutter Stack Scene generated by Syntrix Scene Builder');
    buffer.writeln('import \'package:flutter/material.dart\';');
    buffer.writeln();
    buffer.writeln('Widget buildCompositeScene() {');
    buffer.writeln('  return SizedBox(');
    buffer.writeln('    width: ${_activeScene.width},');
    buffer.writeln('    height: ${_activeScene.height},');
    buffer.writeln('    child: Stack(');
    buffer.writeln('      children: [');

    for (final layer in _activeScene.layers.where((l) => l.isVisible)) {
      buffer.writeln('        // Layer: ${layer.name} (${layer.layerType.displayName}, z-index: ${layer.zIndex})');
      buffer.writeln('        Opacity(');
      buffer.writeln('          opacity: ${layer.opacity},');
      buffer.writeln('          child: SceneComponent(');
      buffer.writeln('            componentRef: \'${layer.componentReference}\',');
      buffer.writeln('            layerType: \'${layer.layerType.id}\',');
      buffer.writeln('          ),');
      buffer.writeln('        ),');
    }

    buffer.writeln('      ],');
    buffer.writeln('    ),');
    buffer.writeln('  );');
    buffer.writeln('}');

    return buffer.toString();
  }
}
