import 'package:flutter_package_studio_core/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.12: Project / Workspace Persistence Models', () {
    test('StudioPersistentProjectState JSON roundtrip', () {
      final state = StudioPersistentProjectState(
        projectId: 'proj_galaxy_01',
        name: 'Galaxy Production Setup',
        activeSection: 'inspector',
        selectedLoaderId: 'galaxy_orbit',
        selectedThemeId: 'cyber_galaxy',
        configuration: const StudioConfigurationDescriptor(
          targetLoaderId: 'galaxy_orbit',
          selectedThemeId: 'cyber_galaxy',
          animationSpeed: 2.5,
          particleCount: 800,
        ),
        activeScene: VisualSceneDescriptor(
          sceneId: 'scene_01',
          name: 'Scene 1',
          layers: const [],
          createdAt: DateTime.parse('2026-09-05T12:00:00Z'),
          updatedAt: DateTime.parse('2026-09-05T12:00:00Z'),
        ),
        presets: const [],
        lastSavedAt: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      final json = state.toJson();
      final restored = StudioPersistentProjectState.fromJson(json);

      expect(restored.projectId, equals('proj_galaxy_01'));
      expect(restored.name, equals('Galaxy Production Setup'));
      expect(restored.selectedLoaderId, equals('galaxy_orbit'));
      expect(restored.configuration.animationSpeed, equals(2.5));
      expect(restored.activeSection, equals('inspector'));
    });
  });

  group('Phase 10.12: Studio Persistence Engine Operations', () {
    test('Saves entire workspace state and restores all parameters cleanly',
        () async {
      final controller = StudioV2Controller();
      final sceneEngine = StudioSceneBuilderEngine(controller: controller);
      final presetEngine = StudioPresetEngine(controller: controller);
      final persistenceEngine = StudioPersistenceEngine(
        controller: controller,
        sceneEngine: sceneEngine,
        presetEngine: presetEngine,
      );

      // 1. Mutate controller state
      controller.navigateTo(StudioNavigationSection.inspector);
      controller.updateConfiguration((cfg) => cfg.copyWith(
            targetLoaderId: 'nebula_storm',
            selectedThemeId: 'nebula_storm',
            animationSpeed: 3.2,
            particleCount: 950,
          ));

      // 2. Save workspace state
      final savedState = await persistenceEngine.saveWorkspaceState(
        projectId: 'proj_nebula_experiment',
        name: 'Nebula Experiment',
      );
      expect(savedState.projectId, equals('proj_nebula_experiment'));
      expect(savedState.configuration.animationSpeed, equals(3.2));

      // 3. Reset controller to different values
      controller.navigateTo(StudioNavigationSection.workspace);
      controller.resetConfiguration();
      expect(controller.state.activeConfiguration.animationSpeed, equals(1.0));

      // 4. Restore workspace state
      final restored =
          await persistenceEngine.loadWorkspaceState('proj_nebula_experiment');
      expect(restored, isTrue);
      expect(controller.state.currentSection,
          equals(StudioNavigationSection.inspector));
      expect(controller.state.activeConfiguration.targetLoaderId,
          equals('nebula_storm'));
      expect(controller.state.activeConfiguration.animationSpeed, equals(3.2));
      expect(controller.state.activeConfiguration.particleCount, equals(950));

      // 5. List and Delete
      final list = await persistenceEngine.listProjects();
      expect(list, contains('proj_nebula_experiment'));

      final deleted =
          await persistenceEngine.deleteProject('proj_nebula_experiment');
      expect(deleted, isTrue);
    });
  });

  group('Phase 10.12: Studio Persistence Renderer', () {
    test(
        'Renders ASCII Project Card, Markdown Summary, and JSON persistence schema',
        () async {
      final controller = StudioV2Controller();
      final sceneEngine = StudioSceneBuilderEngine(controller: controller);
      final presetEngine = StudioPresetEngine(controller: controller);
      final persistenceEngine = StudioPersistenceEngine(
        controller: controller,
        sceneEngine: sceneEngine,
        presetEngine: presetEngine,
      );

      final state = await persistenceEngine.saveWorkspaceState(
        projectId: 'proj_card_test',
        name: 'Card Test Setup',
      );

      // 1. ASCII Card
      final ascii = StudioPersistenceRenderer.renderAsciiProjectCard(state);
      expect(ascii, contains('PERSISTENT STUDIO PROJECT: Card Test Setup'));
      expect(ascii, contains('Project ID:       proj_card_test'));
      expect(ascii, contains('Selected Loader:'));

      // 2. Markdown Summary
      final markdown = StudioPersistenceRenderer.renderMarkdown(state);
      expect(markdown,
          contains('# Studio Persistent Project State: Card Test Setup'));
      expect(markdown, contains('**Project ID:** `proj_card_test`'));
      expect(markdown, contains('## Restored Parameter Snapshot'));

      // 3. JSON
      final json = StudioPersistenceRenderer.renderJson(state);
      expect(json, contains('"project_id": "proj_card_test"'));
      expect(json, contains('"selected_loader_id"'));
    });
  });
}
