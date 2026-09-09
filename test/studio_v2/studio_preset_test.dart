import 'package:syntrix/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.11: Configuration Preset Models', () {
    test('StudioConfigurationPreset JSON serialization and deserialization',
        () {
      final preset = StudioConfigurationPreset(
        presetId: 'preset_custom_01',
        name: 'High Density Nebula',
        description: 'Dense particle field preset',
        targetLoaderId: 'nebula_storm',
        selectedThemeId: 'nebula_storm',
        configuration: const StudioConfigurationDescriptor(
          targetLoaderId: 'nebula_storm',
          selectedThemeId: 'nebula_storm',
          particleCount: 1200,
          animationSpeed: 2.2,
        ),
        isBuiltIn: false,
        createdAt: DateTime.parse('2026-09-05T12:00:00Z'),
        updatedAt: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      final json = preset.toJson();
      final restored = StudioConfigurationPreset.fromJson(json);

      expect(restored.presetId, equals('preset_custom_01'));
      expect(restored.name, equals('High Density Nebula'));
      expect(restored.targetLoaderId, equals('nebula_storm'));
      expect(restored.configuration.particleCount, equals(1200));
      expect(restored.configuration.animationSpeed, equals(2.2));
      expect(restored.isBuiltIn, isFalse);
    });
  });

  group('Phase 10.11: Studio Preset Engine Operations', () {
    test(
        'Performs complete lifecycle: create, save, load, duplicate, rename, delete',
        () async {
      final controller = StudioV2Controller();
      final presetEngine = StudioPresetEngine(controller: controller);

      final initialPresets = await presetEngine.listPresets();
      expect(initialPresets.length, greaterThanOrEqualTo(3));

      // 1. Create from current state
      controller.updateConfiguration((cfg) => cfg.copyWith(
            targetLoaderId: 'quantum_void',
            selectedThemeId: 'quantum_void',
            animationSpeed: 3.0,
            particleCount: 750,
          ));

      final created = await presetEngine.createPresetFromCurrentState(
        presetId: 'preset_my_quantum',
        name: 'My Quantum Config',
      );
      expect(created.presetId, equals('preset_my_quantum'));
      expect(created.configuration.animationSpeed, equals(3.0));

      // 2. Load preset
      await presetEngine.loadPreset('preset_minimal_zen_pulse');
      expect(controller.state.activeConfiguration.targetLoaderId,
          equals('pulsar_wave'));
      expect(controller.state.activeConfiguration.animationSpeed, equals(0.5));

      // 3. Duplicate preset
      final duplicated = await presetEngine.duplicatePreset(
        'preset_my_quantum',
        newPresetId: 'preset_my_quantum_v2',
        newName: 'My Quantum V2',
      );
      expect(duplicated.presetId, equals('preset_my_quantum_v2'));
      expect(duplicated.name, equals('My Quantum V2'));

      // 4. Rename preset
      final renamed = await presetEngine.renamePreset(
          'preset_my_quantum_v2', 'My Quantum Ultimate');
      expect(renamed, isTrue);
      final fetched = await presetEngine.getPreset('preset_my_quantum_v2');
      expect(fetched?.name, equals('My Quantum Ultimate'));

      // 5. Delete preset
      final deleted = await presetEngine.deletePreset('preset_my_quantum_v2');
      expect(deleted, isTrue);
      final checkDeleted = await presetEngine.getPreset('preset_my_quantum_v2');
      expect(checkDeleted, isNull);
    });

    test('Exports and imports preset to/from JSON cleanly', () async {
      final controller = StudioV2Controller();
      final presetEngine = StudioPresetEngine(controller: controller);

      final jsonString =
          await presetEngine.exportPresetToJson('preset_cosmic_vortex_ultra');
      expect(jsonString, contains('"preset_id": "preset_cosmic_vortex_ultra"'));
      expect(jsonString, contains('"target_loader_id": "infinite_universe"'));

      // Modify ID and re-import
      final modifiedJson = jsonString.replaceAll(
          'preset_cosmic_vortex_ultra', 'preset_imported_vortex');
      final imported = await presetEngine.importPresetFromJson(modifiedJson);

      expect(imported.presetId, equals('preset_imported_vortex'));
      final lookup = await presetEngine.getPreset('preset_imported_vortex');
      expect(lookup, isNotNull);
    });
  });

  group('Phase 10.11: Studio Preset Renderer', () {
    test('Renders ASCII Preset Tree, Markdown Catalog, and JSON array',
        () async {
      final controller = StudioV2Controller();
      final presetEngine = StudioPresetEngine(controller: controller);

      final presets = await presetEngine.listPresets();
      final preset = presets.first;

      // 1. ASCII Tree
      final ascii = StudioPresetRenderer.renderAsciiPresetTree(preset);
      expect(ascii, contains('Preset:'));
      expect(ascii, contains('├── Loader:'));
      expect(ascii, contains('├── Theme:'));
      expect(ascii, contains('├── Animation:'));
      expect(ascii, contains('└── Interaction:'));

      // 2. Markdown Catalog
      final markdown = StudioPresetRenderer.renderMarkdownCatalog(presets);
      expect(markdown, contains('# Studio Configuration Presets'));
      expect(markdown, contains('Cosmic Vortex Ultra'));
      expect(markdown, contains('Minimal Zen Pulse'));

      // 3. JSON Array
      final json = StudioPresetRenderer.renderJson(presets);
      expect(json, contains('"preset_id"'));
    });
  });
}
