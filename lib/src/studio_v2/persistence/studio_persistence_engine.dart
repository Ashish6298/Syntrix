/// Central Project / Workspace Persistence Engine for Phase 10.12.
library;

import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/studio_v2/studio_v2_models.dart';
import 'package:syntrix/src/studio_v2/studio_v2_controller.dart';
import 'package:syntrix/src/studio_v2/scene/studio_scene_engine.dart';
import 'package:syntrix/src/studio_v2/presets/studio_preset_engine.dart';
import 'package:syntrix/src/studio_v2/persistence/studio_persistence_models.dart';

/// Central Persistence Engine coordinating state synchronization and project loading/saving.
class StudioPersistenceEngine {
  final Logger _logger = Logger('StudioPersistenceEngine');
  final StudioV2Controller controller;
  final StudioSceneBuilderEngine sceneEngine;
  final StudioPresetEngine presetEngine;
  final WorkspacePersistenceDriver storageDriver;

  StudioPersistenceEngine({
    required this.controller,
    required this.sceneEngine,
    required this.presetEngine,
    WorkspacePersistenceDriver? storageDriver,
  }) : storageDriver = storageDriver ?? InMemoryWorkspacePersistenceDriver();

  /// Snapshot current workspace state and save into persistent storage.
  Future<StudioPersistentProjectState> saveWorkspaceState({
    required String projectId,
    required String name,
  }) async {
    final v2State = controller.state;
    final scene = sceneEngine.activeScene;
    final presets = await presetEngine.listPresets();
    final now = DateTime.now();

    final projectState = StudioPersistentProjectState(
      projectId: projectId,
      name: name,
      activeSection: v2State.currentSection.id,
      selectedLoaderId: v2State.activeConfiguration.targetLoaderId,
      selectedThemeId: v2State.activeConfiguration.selectedThemeId,
      configuration: v2State.activeConfiguration,
      activeScene: scene,
      presets: presets,
      inspectorState: {
        'speed': v2State.activeConfiguration.animationSpeed,
        'particles': v2State.activeConfiguration.particleCount,
        'shaders': v2State.activeConfiguration.shadersEnabled,
      },
      workspaceLayout: {
        'split_ratio': 0.5,
        'sidebar_collapsed': false,
      },
      recentConfigurations: [v2State.activeConfiguration],
      favoriteLoaderIds: v2State.favoriteLoaderIds.toSet(),
      lastSavedAt: now,
    );

    await storageDriver.saveProjectState(projectState);
    _logger.info('Successfully saved Studio project "$name" ($projectId)');
    return projectState;
  }

  /// Load and apply a saved project state into the active Studio instance.
  Future<bool> loadWorkspaceState(String projectId) async {
    final state = await storageDriver.loadProjectState(projectId);
    if (state == null) {
      _logger.warning('Failed to load project "$projectId": Not found');
      return false;
    }

    // 1. Restore Controller configuration & navigation
    final section = StudioNavigationSection.values.firstWhere(
      (s) => s.id == state.activeSection || s.name == state.activeSection,
      orElse: () => StudioNavigationSection.workspace,
    );
    controller.navigateTo(section);
    controller.updateConfiguration((_) => state.configuration);

    // 2. Restore Scene
    sceneEngine.restoreScene(state.activeScene.sceneId);

    // 3. Restore Presets
    for (final p in state.presets) {
      await presetEngine.savePreset(p);
    }

    _logger.info(
        'Successfully restored Studio workspace from project "$projectId"');
    return true;
  }

  /// List all stored project IDs.
  Future<List<String>> listProjects() async {
    return storageDriver.listStoredProjectIds();
  }

  /// Delete a saved project state.
  Future<bool> deleteProject(String projectId) async {
    return storageDriver.deleteProjectState(projectId);
  }
}
