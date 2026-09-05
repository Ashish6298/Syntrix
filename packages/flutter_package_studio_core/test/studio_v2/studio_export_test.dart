import 'package:flutter_package_studio_core/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.13: Export & Import Models', () {
    test('StudioExportBundle JSON roundtrip', () {
      final bundle = StudioExportBundle(
        bundleId: 'bundle_test_01',
        targetEntity: ExportTargetEntity.scene,
        format: ExportFormat.dart,
        content: 'Widget buildScene() => const Stack();',
        suggestedFilename: 'scene_test.dart',
        exportedAt: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      final json = bundle.toJson();
      final restored = StudioExportBundle.fromJson(json);

      expect(restored.bundleId, equals('bundle_test_01'));
      expect(restored.targetEntity, equals(ExportTargetEntity.scene));
      expect(restored.format, equals(ExportFormat.dart));
      expect(restored.content, equals('Widget buildScene() => const Stack();'));
      expect(restored.suggestedFilename, equals('scene_test.dart'));
    });
  });

  group('Phase 10.13: Studio Export & Import Engine Operations', () {
    test('Exports configuration, scene, diagnostics, and code deterministically', () {
      final controller = StudioV2Controller();
      final sceneEngine = StudioSceneBuilderEngine(controller: controller);
      final presetEngine = StudioPresetEngine(controller: controller);
      final codeGenEngine = StudioCodeGenEngine();
      final diagnosticsEngine = StudioDiagnosticsEngine(controller: controller);
      final profilerEngine = StudioProfilerEngine(controller: controller);

      final exportEngine = StudioExportEngine(
        controller: controller,
        sceneEngine: sceneEngine,
        presetEngine: presetEngine,
        codeGenEngine: codeGenEngine,
        diagnosticsEngine: diagnosticsEngine,
        profilerEngine: profilerEngine,
      );

      // 1. Export Configuration in JSON
      final configJsonBundle = exportEngine.export(
        target: ExportTargetEntity.configuration,
        format: ExportFormat.json,
      );
      expect(configJsonBundle.format, equals(ExportFormat.json));
      expect(configJsonBundle.content, contains('"target_loader_id": "infinite_universe"'));

      // 2. Export Scene in Dart
      final sceneDartBundle = exportEngine.export(
        target: ExportTargetEntity.scene,
        format: ExportFormat.dart,
      );
      expect(sceneDartBundle.format, equals(ExportFormat.dart));
      expect(sceneDartBundle.content, contains('Widget buildCompositeScene()'));

      // 3. Export Diagnostics in Markdown
      final diagMdBundle = exportEngine.export(
        target: ExportTargetEntity.diagnostics,
        format: ExportFormat.markdown,
      );
      expect(diagMdBundle.format, equals(ExportFormat.markdown));
      expect(diagMdBundle.content, contains('# Diagnostics & Performance Center Report'));

      // 4. Import configuration back
      exportEngine.importConfigurationJson('''
      {
        "target_loader_id": "galaxy_orbit",
        "selected_theme_id": "cyber_galaxy",
        "animation_speed": 2.2,
        "particle_count": 650
      }
      ''');

      expect(controller.state.activeConfiguration.targetLoaderId, equals('galaxy_orbit'));
      expect(controller.state.activeConfiguration.animationSpeed, equals(2.2));
      expect(controller.state.activeConfiguration.particleCount, equals(650));
    });
  });

  group('Phase 10.13: Studio Export Renderer', () {
    test('Renders ASCII Export Dialog wireframe, Markdown summary, and JSON bundle', () {
      final bundle = StudioExportBundle(
        bundleId: 'bundle_export_test',
        targetEntity: ExportTargetEntity.scene,
        format: ExportFormat.json,
        content: '{"scene_id": "deep_space"}',
        suggestedFilename: 'deep_space.json',
        exportedAt: DateTime.now(),
      );

      // 1. ASCII Dialog Wireframe
      final ascii = StudioExportRenderer.renderAsciiExportDialog(ExportTargetEntity.scene, ExportFormat.json);
      expect(ascii, contains('Export Scene'));
      expect(ascii, contains('● JSON'));
      expect(ascii, contains('○ Dart'));
      expect(ascii, contains('[Export]'));

      // 2. Markdown Summary
      final markdown = StudioExportRenderer.renderMarkdown(bundle);
      expect(markdown, contains('# Studio Export Bundle: deep_space.json'));
      expect(markdown, contains('**Target Entity:** `Scene`'));
      expect(markdown, contains('```json'));

      // 3. JSON
      final json = StudioExportRenderer.renderJson(bundle);
      expect(json, contains('"bundle_id": "bundle_export_test"'));
      expect(json, contains('"format": "json"'));
    });
  });
}
