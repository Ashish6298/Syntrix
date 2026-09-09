import 'package:syntrix/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.4: Visual Configuration Inspector Models & Schema', () {
    test('InspectorPropertyDefinition serialization and deserialization', () {
      const prop = InspectorPropertyDefinition(
        propertyKey: 'particle_count',
        label: 'Count',
        category: InspectorPropertyCategory.particles,
        controlType: InspectorControlType.slider,
        minValue: 10.0,
        maxValue: 2000.0,
        step: 10.0,
        defaultValue: 200,
      );

      final json = prop.toJson();
      final restored = InspectorPropertyDefinition.fromJson(json);

      expect(restored.propertyKey, equals('particle_count'));
      expect(restored.label, equals('Count'));
      expect(restored.category, equals(InspectorPropertyCategory.particles));
      expect(restored.controlType, equals(InspectorControlType.slider));
      expect(restored.minValue, equals(10.0));
      expect(restored.maxValue, equals(2000.0));
      expect(restored.defaultValue, equals(200));
    });

    test(
        'VisualInspectorSchema standardPackageSchema covers all required property categories',
        () {
      final schema = VisualInspectorSchema.standardPackageSchema();

      expect(
          schema.getPropertiesByCategory(InspectorPropertyCategory.animation),
          isNotEmpty);
      expect(
          schema.getPropertiesByCategory(InspectorPropertyCategory.particles),
          isNotEmpty);
      expect(schema.getPropertiesByCategory(InspectorPropertyCategory.physics),
          isNotEmpty);
      expect(
          schema.getPropertiesByCategory(InspectorPropertyCategory.dimensions),
          isNotEmpty);
      expect(schema.getPropertiesByCategory(InspectorPropertyCategory.theming),
          isNotEmpty);
      expect(schema.getPropertiesByCategory(InspectorPropertyCategory.shaders),
          isNotEmpty);
      expect(
          schema.getPropertiesByCategory(InspectorPropertyCategory.interaction),
          isNotEmpty);
    });
  });

  group('Phase 10.4: Studio Inspector Engine Operations', () {
    test(
        'Mutates and retrieves property values cleanly across all supported controls',
        () {
      final controller = StudioV2Controller();
      final inspectorEngine = StudioInspectorEngine(controller: controller);

      // Initial defaults
      expect(inspectorEngine.getPropertyValue('animation_speed'), equals(1.0));
      expect(inspectorEngine.getPropertyValue('particle_count'), equals(200));
      expect(inspectorEngine.getPropertyValue('gravity'), equals(9.8));
      expect(
          inspectorEngine.getPropertyValue('theme_id'), equals('deep_space'));
      expect(inspectorEngine.getPropertyValue('shaders_enabled'), isTrue);
      expect(inspectorEngine.getPropertyValue('is_interactive'), isTrue);

      // Mutate animation
      inspectorEngine.setPropertyValue('animation_speed', 2.5);
      expect(inspectorEngine.getPropertyValue('animation_speed'), equals(2.5));
      expect(controller.state.activeConfiguration.animationSpeed, equals(2.5));

      // Mutate particles
      inspectorEngine.setPropertyValue('particle_count', 800);
      expect(inspectorEngine.getPropertyValue('particle_count'), equals(800));

      // Mutate physics
      inspectorEngine.setPropertyValue('gravity', 18.0);
      expect(inspectorEngine.getPropertyValue('gravity'), equals(18.0));

      // Mutate theme & shaders
      inspectorEngine.setPropertyValue('theme_id', 'cyber_galaxy');
      expect(
          inspectorEngine.getPropertyValue('theme_id'), equals('cyber_galaxy'));

      inspectorEngine.setPropertyValue('shaders_enabled', false);
      expect(inspectorEngine.getPropertyValue('shaders_enabled'), isFalse);

      // Reset
      inspectorEngine.resetAllProperties();
      expect(inspectorEngine.getPropertyValue('animation_speed'), equals(1.0));
      expect(inspectorEngine.getPropertyValue('particle_count'), equals(200));
    });
  });

  group('Phase 10.4: Studio Inspector Renderer', () {
    test('Renders ASCII Sliders, Markdown Property Sheet, and JSON Values', () {
      final controller = StudioV2Controller();
      final inspectorEngine = StudioInspectorEngine(controller: controller);

      inspectorEngine.setPropertyValue('animation_speed', 2.0);
      inspectorEngine.setPropertyValue('particle_count', 500);

      // 1. ASCII Inspector Panel
      final ascii =
          StudioInspectorRenderer.renderAsciiInspector(inspectorEngine);
      expect(ascii, contains('VISUAL CONFIGURATION INSPECTOR'));
      expect(ascii, contains('Animation'));
      expect(ascii, contains('Speed'));
      expect(ascii, contains('Particles'));
      expect(ascii, contains('Count'));
      expect(ascii, contains('●'));

      // 2. Markdown Property Sheet
      final markdown = StudioInspectorRenderer.renderMarkdown(inspectorEngine);
      expect(markdown, contains('# Visual Configuration Inspector'));
      expect(markdown, contains('## Animation'));
      expect(markdown, contains('## Particles'));
      expect(markdown, contains('`animation_speed`'));
      expect(markdown, contains('`slider`'));

      // 3. JSON Export
      final json = StudioInspectorRenderer.renderJson(inspectorEngine);
      expect(json, contains('"animation_speed": 2.0'));
      expect(json, contains('"particle_count": 500'));
    });
  });
}
