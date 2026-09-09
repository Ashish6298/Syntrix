/// Domain models, control descriptors, and property definitions for Phase 10.4: Visual Configuration Inspector.
library;

/// Visual control widget types for the Inspector UI.
enum InspectorControlType {
  slider,
  stepper,
  toggleSwitch,
  colorPicker,
  dropdownSelect,
  textInput;

  String get id => name;
}

/// Category grouping of inspector controls.
enum InspectorPropertyCategory {
  animation,
  particles,
  physics,
  dimensions,
  theming,
  shaders,
  interaction;

  String get id => name;

  String get displayName {
    switch (this) {
      case InspectorPropertyCategory.animation:
        return 'Animation';
      case InspectorPropertyCategory.particles:
        return 'Particles';
      case InspectorPropertyCategory.physics:
        return 'Physics';
      case InspectorPropertyCategory.dimensions:
        return 'Dimensions & Layout';
      case InspectorPropertyCategory.theming:
        return 'Themes & Colors';
      case InspectorPropertyCategory.shaders:
        return 'Shaders & GPU Effects';
      case InspectorPropertyCategory.interaction:
        return 'Interactive Gestures';
    }
  }
}

/// Metadata definition of an inspector controllable property.
class InspectorPropertyDefinition {
  final String propertyKey;
  final String label;
  final String description;
  final InspectorPropertyCategory category;
  final InspectorControlType controlType;
  final double? minValue;
  final double? maxValue;
  final double? step;
  final dynamic defaultValue;
  final List<String>? dropdownOptions;

  const InspectorPropertyDefinition({
    required this.propertyKey,
    required this.label,
    this.description = '',
    required this.category,
    required this.controlType,
    this.minValue,
    this.maxValue,
    this.step,
    required this.defaultValue,
    this.dropdownOptions,
  });

  Map<String, dynamic> toJson() => {
        'property_key': propertyKey,
        'label': label,
        'description': description,
        'category': category.id,
        'control_type': controlType.id,
        'min_value': minValue,
        'max_value': maxValue,
        'step': step,
        'default_value': defaultValue,
        'dropdown_options': dropdownOptions,
      };

  factory InspectorPropertyDefinition.fromJson(Map<String, dynamic> json) {
    return InspectorPropertyDefinition(
      propertyKey: json['property_key'] as String? ?? '',
      label: json['label'] as String? ?? 'Property',
      description: json['description'] as String? ?? '',
      category: InspectorPropertyCategory.values.firstWhere(
        (c) => c.id == json['category'] || c.name == json['category'],
        orElse: () => InspectorPropertyCategory.animation,
      ),
      controlType: InspectorControlType.values.firstWhere(
        (t) => t.id == json['control_type'] || t.name == json['control_type'],
        orElse: () => InspectorControlType.slider,
      ),
      minValue: (json['min_value'] as num?)?.toDouble(),
      maxValue: (json['max_value'] as num?)?.toDouble(),
      step: (json['step'] as num?)?.toDouble(),
      defaultValue: json['default_value'],
      dropdownOptions: (json['dropdown_options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}

/// Comprehensive Visual Inspector Schema containing all controllable package properties.
class VisualInspectorSchema {
  final List<InspectorPropertyDefinition> properties;

  const VisualInspectorSchema({required this.properties});

  List<InspectorPropertyDefinition> getPropertiesByCategory(
      InspectorPropertyCategory category) {
    return properties.where((p) => p.category == category).toList();
  }

  /// Default predefined inspector controls adhering strictly to package capabilities.
  factory VisualInspectorSchema.standardPackageSchema() {
    return const VisualInspectorSchema(
      properties: [
        // Animation
        InspectorPropertyDefinition(
          propertyKey: 'animation_speed',
          label: 'Speed',
          description: 'Multiplier for oscillation and rotation velocity.',
          category: InspectorPropertyCategory.animation,
          controlType: InspectorControlType.slider,
          minValue: 0.1,
          maxValue: 5.0,
          step: 0.1,
          defaultValue: 1.0,
        ),
        InspectorPropertyDefinition(
          propertyKey: 'intensity',
          label: 'Intensity',
          description: 'Visual amplitude and pulsation energy.',
          category: InspectorPropertyCategory.animation,
          controlType: InspectorControlType.slider,
          minValue: 0.0,
          maxValue: 3.0,
          step: 0.1,
          defaultValue: 1.0,
        ),
        InspectorPropertyDefinition(
          propertyKey: 'scale',
          label: 'Scale',
          description: 'Global render viewport scale factor.',
          category: InspectorPropertyCategory.animation,
          controlType: InspectorControlType.slider,
          minValue: 0.2,
          maxValue: 3.0,
          step: 0.05,
          defaultValue: 1.0,
        ),

        // Particles
        InspectorPropertyDefinition(
          propertyKey: 'particle_count',
          label: 'Count',
          description: 'Total active simulated particles.',
          category: InspectorPropertyCategory.particles,
          controlType: InspectorControlType.slider,
          minValue: 10.0,
          maxValue: 2000.0,
          step: 10.0,
          defaultValue: 200,
        ),
        InspectorPropertyDefinition(
          propertyKey: 'particle_size',
          label: 'Size',
          description: 'Radius/thickness of particle points.',
          category: InspectorPropertyCategory.particles,
          controlType: InspectorControlType.slider,
          minValue: 0.5,
          maxValue: 10.0,
          step: 0.25,
          defaultValue: 2.0,
        ),
        InspectorPropertyDefinition(
          propertyKey: 'particle_opacity',
          label: 'Opacity',
          description: 'Alpha blending transparency of particle field.',
          category: InspectorPropertyCategory.particles,
          controlType: InspectorControlType.slider,
          minValue: 0.0,
          maxValue: 1.0,
          step: 0.05,
          defaultValue: 0.8,
        ),

        // Physics
        InspectorPropertyDefinition(
          propertyKey: 'gravity',
          label: 'Gravity',
          description: 'Gravitational attraction toward vortex center.',
          category: InspectorPropertyCategory.physics,
          controlType: InspectorControlType.slider,
          minValue: 0.0,
          maxValue: 25.0,
          step: 0.5,
          defaultValue: 9.8,
        ),
        InspectorPropertyDefinition(
          propertyKey: 'velocity',
          label: 'Velocity',
          description: 'Base particle kinetic velocity vector.',
          category: InspectorPropertyCategory.physics,
          controlType: InspectorControlType.slider,
          minValue: 0.1,
          maxValue: 5.0,
          step: 0.1,
          defaultValue: 1.0,
        ),

        // Dimensions
        InspectorPropertyDefinition(
          propertyKey: 'width',
          label: 'Width',
          description: 'Loader canvas render width.',
          category: InspectorPropertyCategory.dimensions,
          controlType: InspectorControlType.stepper,
          minValue: 50.0,
          maxValue: 1200.0,
          step: 10.0,
          defaultValue: 300.0,
        ),
        InspectorPropertyDefinition(
          propertyKey: 'height',
          label: 'Height',
          description: 'Loader canvas render height.',
          category: InspectorPropertyCategory.dimensions,
          controlType: InspectorControlType.stepper,
          minValue: 50.0,
          maxValue: 1200.0,
          step: 10.0,
          defaultValue: 300.0,
        ),

        // Theming
        InspectorPropertyDefinition(
          propertyKey: 'theme_id',
          label: 'Theme',
          description: 'Visual color palette preset.',
          category: InspectorPropertyCategory.theming,
          controlType: InspectorControlType.dropdownSelect,
          defaultValue: 'deep_space',
          dropdownOptions: [
            'deep_space',
            'milky_way',
            'nebula_storm',
            'quantum_void',
            'solar_flare',
            'cyber_galaxy',
            'aurora_cosmos',
          ],
        ),

        // Shaders
        InspectorPropertyDefinition(
          propertyKey: 'shaders_enabled',
          label: 'Shaders',
          description: 'Enable GPU fragment shader passes.',
          category: InspectorPropertyCategory.shaders,
          controlType: InspectorControlType.toggleSwitch,
          defaultValue: true,
        ),

        // Interaction
        InspectorPropertyDefinition(
          propertyKey: 'is_interactive',
          label: 'Gestures',
          description: 'Enable touch/drag interactive physics response.',
          category: InspectorPropertyCategory.interaction,
          controlType: InspectorControlType.toggleSwitch,
          defaultValue: true,
        ),
      ],
    );
  }
}
