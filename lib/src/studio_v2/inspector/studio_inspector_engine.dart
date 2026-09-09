/// Central Visual Configuration Inspector Engine for Phase 10.4.
library;

import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/studio_v2/studio_v2_controller.dart';
import 'package:syntrix/src/studio_v2/inspector/studio_inspector_models.dart';

/// Central Visual Configuration Inspector Engine managing property modifications and schema binding.
class StudioInspectorEngine {
  final Logger _logger = Logger('StudioInspectorEngine');
  final StudioV2Controller controller;
  final VisualInspectorSchema schema;

  StudioInspectorEngine({
    required this.controller,
    VisualInspectorSchema? schema,
  }) : schema = schema ?? VisualInspectorSchema.standardPackageSchema();

  /// Retrieve the current live value for a given property key.
  dynamic getPropertyValue(String propertyKey) {
    final cfg = controller.state.activeConfiguration;
    switch (propertyKey) {
      case 'animation_speed':
        return cfg.animationSpeed;
      case 'intensity':
        return cfg.intensity;
      case 'scale':
        return cfg.scale;
      case 'particle_count':
        return cfg.particleCount;
      case 'particle_size':
        return cfg.particleSize;
      case 'particle_opacity':
        return cfg.particleOpacity;
      case 'gravity':
        return cfg.gravity;
      case 'velocity':
        return cfg.velocity;
      case 'theme_id':
        return cfg.selectedThemeId;
      case 'shaders_enabled':
        return cfg.shadersEnabled;
      case 'is_interactive':
        return cfg.isInteractive;
      default:
        return cfg.customParameters[propertyKey];
    }
  }

  /// Mutate a property value through the visual inspector control.
  void setPropertyValue(String propertyKey, dynamic value) {
    _logger.info('Inspector updated property "$propertyKey" to "$value"');

    controller.updateConfiguration((cfg) {
      switch (propertyKey) {
        case 'animation_speed':
          return cfg.copyWith(animationSpeed: (value as num).toDouble());
        case 'intensity':
          return cfg.copyWith(intensity: (value as num).toDouble());
        case 'scale':
          return cfg.copyWith(scale: (value as num).toDouble());
        case 'particle_count':
          return cfg.copyWith(particleCount: (value as num).toInt());
        case 'particle_size':
          return cfg.copyWith(particleSize: (value as num).toDouble());
        case 'particle_opacity':
          return cfg.copyWith(particleOpacity: (value as num).toDouble());
        case 'gravity':
          return cfg.copyWith(gravity: (value as num).toDouble());
        case 'velocity':
          return cfg.copyWith(velocity: (value as num).toDouble());
        case 'theme_id':
          return cfg.copyWith(selectedThemeId: value.toString());
        case 'shaders_enabled':
          return cfg.copyWith(shadersEnabled: value as bool);
        case 'is_interactive':
          return cfg.copyWith(isInteractive: value as bool);
        default:
          final updatedCustom = Map<String, dynamic>.from(cfg.customParameters)
            ..[propertyKey] = value;
          return cfg.copyWith(customParameters: updatedCustom);
      }
    });
  }

  /// Reset all inspector properties to their initial defaults.
  void resetAllProperties() {
    controller.resetConfiguration();
  }
}
