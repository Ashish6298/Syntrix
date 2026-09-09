import 'package:syntrix/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.8: Code Generation Studio Models', () {
    test('CodeGenOptions and CodeGenResult JSON roundtrip', () {
      const options = CodeGenOptions(
        style: CodeGenStyle.statelessWidgetClass,
        includeImports: true,
        includeComments: false,
        wrapWithCenter: true,
        customClassName: 'CustomCosmicLoader',
      );

      final optionsJson = options.toJson();
      final restoredOptions = CodeGenOptions.fromJson(optionsJson);

      expect(restoredOptions.style, equals(CodeGenStyle.statelessWidgetClass));
      expect(restoredOptions.includeComments, isFalse);
      expect(restoredOptions.customClassName, equals('CustomCosmicLoader'));

      final result = CodeGenResult(
        sourceCode: 'Widget buildLoader() => const SizedBox();',
        options: options,
        isValidPublicApi: true,
        requiredImports: ['package:flutter/material.dart'],
        warnings: [],
        generatedAt: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      final json = result.toJson();
      final restored = CodeGenResult.fromJson(json);

      expect(restored.sourceCode,
          equals('Widget buildLoader() => const SizedBox();'));
      expect(restored.isValidPublicApi, isTrue);
      expect(restored.requiredImports.length, equals(1));
    });
  });

  group('Phase 10.8: Studio CodeGen Engine Operations', () {
    final engine = StudioCodeGenEngine();

    test('Generates standalone widget function conforming to public API', () {
      const config = StudioConfigurationDescriptor(
        targetLoaderId: 'infinite_universe',
        selectedThemeId: 'deep_space',
        animationSpeed: 1.2,
        particleCount: 250,
      );

      final result = engine.generateLoaderCode(
        config,
        options: const CodeGenOptions(style: CodeGenStyle.standaloneWidget),
      );

      expect(result.isValidPublicApi, isTrue);
      expect(result.warnings, isEmpty);
      expect(result.sourceCode,
          contains('import \'package:flutter/material.dart\';'));
      expect(result.sourceCode, contains('Widget buildInfiniteUniverse() {'));
      expect(result.sourceCode, contains('InfiniteUniverseLoader('));
      expect(result.sourceCode, contains('theme: UniverseTheme.deepSpace'));
      expect(result.sourceCode, contains('animationSpeed: 1.2'));
      expect(result.sourceCode, contains('particleCount: 250'));
    });

    test('Generates StatelessWidget and StatefulWidget classes', () {
      const config = StudioConfigurationDescriptor(
        targetLoaderId: 'galaxy_orbit',
        selectedThemeId: 'solar_flare',
      );

      // 1. StatelessWidget
      final statelessRes = engine.generateLoaderCode(
        config,
        options: const CodeGenOptions(
          style: CodeGenStyle.statelessWidgetClass,
          customClassName: 'MyGalaxyWidget',
        ),
      );
      expect(statelessRes.sourceCode,
          contains('class MyGalaxyWidget extends StatelessWidget {'));
      expect(statelessRes.sourceCode, contains('GalaxyOrbitLoader('));

      // 2. StatefulWidget
      final statefulRes = engine.generateLoaderCode(
        config,
        options: const CodeGenOptions(
          style: CodeGenStyle.statefulInteractiveWidget,
          customClassName: 'InteractiveGalaxy',
        ),
      );
      expect(statefulRes.sourceCode,
          contains('class InteractiveGalaxy extends StatefulWidget {'));
      expect(
          statefulRes.sourceCode,
          contains(
              'class _InteractiveGalaxyState extends State<InteractiveGalaxy> {'));
    });

    test('Generates composite scene stack code', () {
      final scene = VisualSceneDescriptor(
        sceneId: 'scene_test',
        name: 'Space Orbit',
        layers: const [
          SceneComponentLayer(
            layerId: 'layer_01',
            name: 'Deep Space BG',
            layerType: SceneLayerType.background,
            componentReference: 'deep_space',
            zIndex: 0,
          ),
          SceneComponentLayer(
            layerId: 'layer_02',
            name: 'Galaxy Orbit',
            layerType: SceneLayerType.primaryLoader,
            componentReference: 'galaxy_orbit',
            zIndex: 10,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = engine.generateSceneCode(scene);
      expect(result.isValidPublicApi, isTrue);
      expect(result.sourceCode,
          contains('class MyCosmicLoaderScene extends StatelessWidget {'));
      expect(result.sourceCode, contains('child: Stack('));
      expect(result.sourceCode, contains('SceneLayerComponent('));
    });

    test('Flags warning when unknown custom loader ID is passed', () {
      const config = StudioConfigurationDescriptor(
        targetLoaderId: 'unknown_custom_loader_99',
        selectedThemeId: 'custom_theme_99',
      );

      final result = engine.generateLoaderCode(config);
      expect(result.isValidPublicApi, isFalse);
      expect(result.warnings.length, equals(2));
      expect(result.warnings.first,
          contains('not a recognized built-in public loader API'));
    });
  });

  group('Phase 10.8: Studio CodeGen Renderer', () {
    test('Renders Markdown Code Block and JSON export schema', () {
      final engine = StudioCodeGenEngine();
      const config = StudioConfigurationDescriptor(
        targetLoaderId: 'nebula_storm',
        selectedThemeId: 'nebula_storm',
      );

      final result = engine.generateLoaderCode(config);

      // 1. Markdown
      final markdown = StudioCodeGenRenderer.renderMarkdown(result);
      expect(markdown, contains('# Code Generation Studio Output'));
      expect(
          markdown, contains('**Public API Conformance:** `VALIDATED (PASS)`'));
      expect(markdown, contains('```dart'));
      expect(markdown, contains('NebulaStormLoader('));

      // 2. JSON
      final json = StudioCodeGenRenderer.renderJson(result);
      expect(json, contains('"is_valid_public_api": true'));
      expect(json, contains('"source_code"'));
    });
  });
}
