import 'package:syntrix/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.7: Scene Builder Models', () {
    test('SceneComponentLayer and VisualSceneDescriptor JSON roundtrip', () {
      final scene = VisualSceneDescriptor(
        sceneId: 'scene_test_01',
        name: 'Test Orbit Scene',
        description: 'Orbit scene description',
        width: 500.0,
        height: 500.0,
        layers: const [
          SceneComponentLayer(
            layerId: 'layer_0',
            name: 'Background',
            layerType: SceneLayerType.background,
            componentReference: 'deep_space',
            zIndex: 0,
          ),
          SceneComponentLayer(
            layerId: 'layer_1',
            name: 'Primary Loader',
            layerType: SceneLayerType.primaryLoader,
            componentReference: 'galaxy_orbit',
            zIndex: 10,
            opacity: 0.9,
          ),
        ],
        createdAt: DateTime.parse('2026-09-05T12:00:00Z'),
        updatedAt: DateTime.parse('2026-09-05T12:30:00Z'),
      );

      final json = scene.toJson();
      final restored = VisualSceneDescriptor.fromJson(json);

      expect(restored.sceneId, equals('scene_test_01'));
      expect(restored.name, equals('Test Orbit Scene'));
      expect(restored.layers.length, equals(2));
      expect(
          restored.layers.first.layerType, equals(SceneLayerType.background));
      expect(restored.layers.last.opacity, equals(0.9));
    });
  });

  group('Phase 10.7: Studio Scene Builder Engine Operations', () {
    test('Adds, reorders, configures, and removes scene component layers', () {
      final controller = StudioV2Controller();
      final engine = StudioSceneBuilderEngine(controller: controller);

      expect(engine.activeScene.layers.length, equals(5));

      // 1. Add Layer
      const newLayer = SceneComponentLayer(
        layerId: 'layer_custom_01',
        name: 'Custom Hologram Layer',
        layerType: SceneLayerType.effectLayer,
        componentReference: 'hologram_scan',
        zIndex: 25,
      );
      engine.addLayer(newLayer);
      expect(engine.activeScene.layers.length, equals(6));

      // 2. Reorder Layer
      engine.reorderLayer('layer_custom_01', 5);
      expect(
          engine.activeScene.layers
              .firstWhere((l) => l.layerId == 'layer_custom_01')
              .zIndex,
          equals(5));

      // 3. Configure Layer
      engine.configureLayer('layer_custom_01', opacity: 0.4, isVisible: false);
      final configured = engine.activeScene.layers
          .firstWhere((l) => l.layerId == 'layer_custom_01');
      expect(configured.opacity, equals(0.4));
      expect(configured.isVisible, isFalse);

      // 4. Remove Layer
      final removed = engine.removeLayer('layer_custom_01');
      expect(removed, isTrue);
      expect(engine.activeScene.layers.length, equals(5));
    });

    test('Saves and restores scene configurations', () {
      final controller = StudioV2Controller();
      final engine = StudioSceneBuilderEngine(controller: controller);

      engine.saveScene();
      expect(engine.savedScenes.length, equals(1));

      final restored = engine.restoreScene('scene_default');
      expect(restored, isTrue);
    });

    test('Generates production-ready Flutter composition code', () {
      final controller = StudioV2Controller();
      final engine = StudioSceneBuilderEngine(controller: controller);

      final code = engine.generateSceneFlutterCode();
      expect(code, contains('Widget buildCompositeScene()'));
      expect(code, contains('child: Stack('));
      expect(code, contains('SceneComponent('));
      expect(code, contains('componentRef: \'galaxy_orbit\''));
    });
  });

  group('Phase 10.7: Studio Scene Renderer', () {
    test('Renders ASCII Scene Tree, Markdown Documentation, and JSON state',
        () {
      final controller = StudioV2Controller();
      final engine = StudioSceneBuilderEngine(controller: controller);

      // 1. ASCII Tree
      final ascii =
          StudioSceneRenderer.renderAsciiSceneTree(engine.activeScene);
      expect(ascii, contains('Scene: Deep Space Galaxy Scene'));
      expect(ascii, contains('Deep Space Background'));
      expect(ascii, contains('Galaxy Orbit Loader'));

      // 2. Markdown Report
      final markdown =
          StudioSceneRenderer.renderMarkdown(engine.activeScene, engine);
      expect(markdown,
          contains('# Visual Scene Builder: Deep Space Galaxy Scene'));
      expect(markdown, contains('## Layer Hierarchy'));
      expect(markdown, contains('```dart'));

      // 3. JSON
      final json = StudioSceneRenderer.renderJson(engine.activeScene);
      expect(json, contains('"scene_id": "scene_default"'));
      expect(json, contains('"layers"'));
    });
  });
}
