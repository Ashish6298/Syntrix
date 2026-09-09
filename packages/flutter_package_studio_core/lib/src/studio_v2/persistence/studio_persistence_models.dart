/// Domain models and persistence contract for Phase 10.12: Project / Workspace Persistence.
library;

import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_models.dart';
import 'package:flutter_package_studio_core/src/studio_v2/scene/studio_scene_models.dart';
import 'package:flutter_package_studio_core/src/studio_v2/presets/studio_preset_models.dart';

/// Complete persistent snapshot of the entire Studio workspace environment.
class StudioPersistentProjectState {
  final String projectId;
  final String name;
  final String activeSection;
  final String selectedLoaderId;
  final String selectedThemeId;
  final StudioConfigurationDescriptor configuration;
  final VisualSceneDescriptor activeScene;
  final List<StudioConfigurationPreset> presets;
  final Map<String, dynamic> inspectorState;
  final Map<String, dynamic> workspaceLayout;
  final List<StudioConfigurationDescriptor> recentConfigurations;
  final Set<String> favoriteLoaderIds;
  final DateTime lastSavedAt;

  const StudioPersistentProjectState({
    required this.projectId,
    required this.name,
    this.activeSection = 'workspace',
    required this.selectedLoaderId,
    required this.selectedThemeId,
    required this.configuration,
    required this.activeScene,
    this.presets = const [],
    this.inspectorState = const {},
    this.workspaceLayout = const {},
    this.recentConfigurations = const [],
    this.favoriteLoaderIds = const {},
    required this.lastSavedAt,
  });

  StudioPersistentProjectState copyWith({
    String? projectId,
    String? name,
    String? activeSection,
    String? selectedLoaderId,
    String? selectedThemeId,
    StudioConfigurationDescriptor? configuration,
    VisualSceneDescriptor? activeScene,
    List<StudioConfigurationPreset>? presets,
    Map<String, dynamic>? inspectorState,
    Map<String, dynamic>? workspaceLayout,
    List<StudioConfigurationDescriptor>? recentConfigurations,
    Set<String>? favoriteLoaderIds,
    DateTime? lastSavedAt,
  }) {
    return StudioPersistentProjectState(
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      activeSection: activeSection ?? this.activeSection,
      selectedLoaderId: selectedLoaderId ?? this.selectedLoaderId,
      selectedThemeId: selectedThemeId ?? this.selectedThemeId,
      configuration: configuration ?? this.configuration,
      activeScene: activeScene ?? this.activeScene,
      presets: presets ?? this.presets,
      inspectorState: inspectorState ?? this.inspectorState,
      workspaceLayout: workspaceLayout ?? this.workspaceLayout,
      recentConfigurations: recentConfigurations ?? this.recentConfigurations,
      favoriteLoaderIds: favoriteLoaderIds ?? this.favoriteLoaderIds,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'project_id': projectId,
        'name': name,
        'active_section': activeSection,
        'selected_loader_id': selectedLoaderId,
        'selected_theme_id': selectedThemeId,
        'configuration': configuration.toJson(),
        'active_scene': activeScene.toJson(),
        'presets': presets.map((p) => p.toJson()).toList(),
        'inspector_state': inspectorState,
        'workspace_layout': workspaceLayout,
        'recent_configurations':
            recentConfigurations.map((c) => c.toJson()).toList(),
        'favorite_loader_ids': favoriteLoaderIds.toList(),
        'last_saved_at': lastSavedAt.toIso8601String(),
      };

  factory StudioPersistentProjectState.fromJson(Map<String, dynamic> json) {
    return StudioPersistentProjectState(
      projectId: json['project_id'] as String? ?? 'proj_default',
      name: json['name'] as String? ?? 'Default Project',
      activeSection: json['active_section'] as String? ?? 'workspace',
      selectedLoaderId:
          json['selected_loader_id'] as String? ?? 'infinite_universe',
      selectedThemeId: json['selected_theme_id'] as String? ?? 'deep_space',
      configuration: json['configuration'] != null
          ? StudioConfigurationDescriptor.fromJson(
              json['configuration'] as Map<String, dynamic>)
          : const StudioConfigurationDescriptor(),
      activeScene: json['active_scene'] != null
          ? VisualSceneDescriptor.fromJson(
              json['active_scene'] as Map<String, dynamic>)
          : VisualSceneDescriptor(
              sceneId: 'scene_default',
              name: 'Default Scene',
              layers: const [],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
      presets: (json['presets'] as List<dynamic>?)
              ?.map((p) =>
                  StudioConfigurationPreset.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      inspectorState:
          (json['inspector_state'] as Map<String, dynamic>?) ?? const {},
      workspaceLayout:
          (json['workspace_layout'] as Map<String, dynamic>?) ?? const {},
      recentConfigurations: (json['recent_configurations'] as List<dynamic>?)
              ?.map((c) => StudioConfigurationDescriptor.fromJson(
                  c as Map<String, dynamic>))
              .toList() ??
          const [],
      favoriteLoaderIds: (json['favorite_loader_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          const {},
      lastSavedAt: DateTime.parse(json['last_saved_at'] as String),
    );
  }
}

/// Abstract storage driver contract for Project & Workspace persistence.
abstract class WorkspacePersistenceDriver {
  Future<void> saveProjectState(StudioPersistentProjectState state);
  Future<StudioPersistentProjectState?> loadProjectState(String projectId);
  Future<bool> deleteProjectState(String projectId);
  Future<List<String>> listStoredProjectIds();
}

/// In-memory implementation of [WorkspacePersistenceDriver].
class InMemoryWorkspacePersistenceDriver implements WorkspacePersistenceDriver {
  final Map<String, StudioPersistentProjectState> _storage = {};

  @override
  Future<void> saveProjectState(StudioPersistentProjectState state) async {
    _storage[state.projectId] = state;
  }

  @override
  Future<StudioPersistentProjectState?> loadProjectState(
      String projectId) async {
    return _storage[projectId];
  }

  @override
  Future<bool> deleteProjectState(String projectId) async {
    return _storage.remove(projectId) != null;
  }

  @override
  Future<List<String>> listStoredProjectIds() async => _storage.keys.toList();
}
