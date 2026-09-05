import 'package:flutter_package_studio_core/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.6: Theme Studio Models', () {
    test('StudioThemeDescriptor serialization and deserialization', () {
      const theme = StudioThemeDescriptor(
        id: 'deep_space',
        name: 'Deep Space',
        description: 'Abyssal cosmic midnight dark palette',
        palette: [
          ThemeColorDefinition(role: 'background', hex: '#0B0D1B'),
          ThemeColorDefinition(role: 'primary', hex: '#6366F1'),
        ],
        backgroundColor: '#0B0D1B',
        particleGlowColor: '#4F46E5',
        defaultParticleSize: 2.5,
        defaultParticleOpacity: 0.85,
        isCustom: false,
      );

      final json = theme.toJson();
      final restored = StudioThemeDescriptor.fromJson(json);

      expect(restored.id, equals('deep_space'));
      expect(restored.name, equals('Deep Space'));
      expect(restored.palette.length, equals(2));
      expect(restored.backgroundColor, equals('#0B0D1B'));
      expect(restored.defaultParticleSize, equals(2.5));
      expect(restored.isCustom, isFalse);
    });
  });

  group('Phase 10.6: Studio Theme Engine Operations', () {
    test('Browses default themes and applies theme to controller workspace', () {
      final controller = StudioV2Controller();
      final themeEngine = StudioThemeEngine(controller: controller);

      expect(themeEngine.allThemes.length, greaterThanOrEqualTo(7));

      // Apply theme
      themeEngine.applyTheme('cyber_galaxy');
      expect(controller.state.activeConfiguration.selectedThemeId, equals('cyber_galaxy'));

      themeEngine.applyTheme('aurora_cosmos');
      expect(controller.state.activeConfiguration.selectedThemeId, equals('aurora_cosmos'));
    });

    test('Duplicates theme creating custom variation', () {
      final controller = StudioV2Controller();
      final themeEngine = StudioThemeEngine(controller: controller);

      final customTheme = themeEngine.duplicateTheme(
        'deep_space',
        newId: 'custom_deep_space_v2',
        newName: 'Deep Space Custom V2',
      );

      expect(customTheme.id, equals('custom_deep_space_v2'));
      expect(customTheme.name, equals('Deep Space Custom V2'));
      expect(customTheme.isCustom, isTrue);

      final lookup = themeEngine.getTheme('custom_deep_space_v2');
      expect(lookup, isNotNull);
      expect(lookup!.isCustom, isTrue);
    });

    test('Compares two themes and generates production-ready theme code', () {
      final controller = StudioV2Controller();
      final themeEngine = StudioThemeEngine(controller: controller);

      final comparison = themeEngine.compareThemes('deep_space', 'solar_flare');
      expect(comparison.containsKey('error'), isFalse);
      expect(comparison['theme_a']['id'], equals('deep_space'));
      expect(comparison['theme_b']['id'], equals('solar_flare'));

      final code = themeEngine.generateThemeCode('solar_flare');
      expect(code, contains('class SolarFlareTheme'));
      expect(code, contains('static const String themeId = \'solar_flare\''));
      expect(code, contains('static const List<Color> palette = ['));
    });
  });

  group('Phase 10.6: Studio Theme Renderer', () {
    test('Renders ASCII Theme Card, Markdown Catalog, and JSON Theme Array', () {
      final controller = StudioV2Controller();
      final themeEngine = StudioThemeEngine(controller: controller);

      final theme = themeEngine.getTheme('cyber_galaxy')!;

      // 1. ASCII Card
      final card = StudioThemeRenderer.renderThemeCardAscii(theme, isActive: true);
      expect(card, contains('Cyber Galaxy'));
      expect(card, contains('ACTIVE'));
      expect(card, contains('Palette Swatch:'));
      expect(card, contains('Background:  #090A1A'));

      // 2. Markdown Catalog
      final catalogMd = StudioThemeRenderer.renderMarkdownCatalog(themeEngine.allThemes, themeEngine);
      expect(catalogMd, contains('# Theme & Visual System Studio Catalog'));
      expect(catalogMd, contains('Deep Space'));
      expect(catalogMd, contains('Cyber Galaxy'));
      expect(catalogMd, contains('```dart'));

      // 3. Comparison Matrix
      final comp = themeEngine.compareThemes('deep_space', 'nebula_storm');
      final compMd = StudioThemeRenderer.renderComparisonMarkdown(comp);
      expect(compMd, contains('# Theme Comparison Matrix'));
      expect(compMd, contains('Deep Space'));
      expect(compMd, contains('Nebula Storm'));

      // 4. JSON
      final json = StudioThemeRenderer.renderJson(themeEngine.allThemes);
      expect(json, contains('"id": "deep_space"'));
    });
  });
}
