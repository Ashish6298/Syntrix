/// Core domain models, enums, and state descriptors for Milestone 10: Studio v2 Architecture Foundation.
library;

/// High-level navigation section within Studio v2.
enum StudioNavigationSection {
  workspace,
  explorer,
  inspector,
  themeStudio,
  sceneBuilder,
  codeGen,
  diagnostics,
  profiler,
  presets,
  comparisonLab,
  interactionLab,
  environment,
  validationCenter,
  extensions,
  settings;

  String get id => name;

  String get label {
    switch (this) {
      case StudioNavigationSection.workspace:
        return 'Unified Workspace';
      case StudioNavigationSection.explorer:
        return 'Loader Explorer';
      case StudioNavigationSection.inspector:
        return 'Configuration Inspector';
      case StudioNavigationSection.themeStudio:
        return 'Theme Studio';
      case StudioNavigationSection.sceneBuilder:
        return 'Scene Builder';
      case StudioNavigationSection.codeGen:
        return 'Code Generation';
      case StudioNavigationSection.diagnostics:
        return 'Diagnostics & Performance';
      case StudioNavigationSection.profiler:
        return 'Performance Profiler';
      case StudioNavigationSection.presets:
        return 'Preset System';
      case StudioNavigationSection.comparisonLab:
        return 'Comparison Lab';
      case StudioNavigationSection.interactionLab:
        return 'Interaction Lab';
      case StudioNavigationSection.environment:
        return 'Environment Center';
      case StudioNavigationSection.validationCenter:
        return 'Validation Center';
      case StudioNavigationSection.extensions:
        return 'Studio Extensions';
      case StudioNavigationSection.settings:
        return 'Workspace Settings';
    }
  }
}

/// Identifiers for dedicated Studio v2 docked and floating panels.
enum StudioPanelArea {
  toolbar,
  navigationSidebar,
  inspectorSidebar,
  previewViewport,
  bottomConsole,
  overlayModal;

  String get id => name;
}

/// A registered Studio Panel definition.
class StudioPanelDefinition {
  final String panelId;
  final String title;
  final StudioPanelArea area;
  final bool isVisible;
  final bool isCollapsible;
  final double defaultWidth;
  final double defaultHeight;
  final Map<String, dynamic> metadata;

  const StudioPanelDefinition({
    required this.panelId,
    required this.title,
    required this.area,
    this.isVisible = true,
    this.isCollapsible = true,
    this.defaultWidth = 320.0,
    this.defaultHeight = 240.0,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'panel_id': panelId,
        'title': title,
        'area': area.id,
        'is_visible': isVisible,
        'is_collapsible': isCollapsible,
        'default_width': defaultWidth,
        'default_height': defaultHeight,
        'metadata': metadata,
      };

  factory StudioPanelDefinition.fromJson(Map<String, dynamic> json) {
    return StudioPanelDefinition(
      panelId: json['panel_id'] as String? ?? 'panel_unknown',
      title: json['title'] as String? ?? 'Unnamed Panel',
      area: StudioPanelArea.values.firstWhere(
        (a) => a.id == json['area'] || a.name == json['area'],
        orElse: () => StudioPanelArea.inspectorSidebar,
      ),
      isVisible: json['is_visible'] as bool? ?? true,
      isCollapsible: json['is_collapsible'] as bool? ?? true,
      defaultWidth: (json['default_width'] as num?)?.toDouble() ?? 320.0,
      defaultHeight: (json['default_height'] as num?)?.toDouble() ?? 240.0,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Action trigger executable within Studio v2 Shell and Workspace.
class StudioActionDefinition {
  final String actionId;
  final String label;
  final String? shortcut;
  final String category;
  final bool isEnabled;

  const StudioActionDefinition({
    required this.actionId,
    required this.label,
    this.shortcut,
    this.category = 'General',
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'action_id': actionId,
        'label': label,
        'shortcut': shortcut,
        'category': category,
        'is_enabled': isEnabled,
      };

  factory StudioActionDefinition.fromJson(Map<String, dynamic> json) {
    return StudioActionDefinition(
      actionId: json['action_id'] as String? ?? 'action_unknown',
      label: json['label'] as String? ?? 'Action',
      shortcut: json['shortcut'] as String?,
      category: json['category'] as String? ?? 'General',
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }
}

/// Configuration descriptor for active loader / component preview parameters.
class StudioConfigurationDescriptor {
  final String targetLoaderId;
  final String selectedThemeId;
  final double animationSpeed;
  final double intensity;
  final double scale;
  final int particleCount;
  final double particleSize;
  final double particleOpacity;
  final double gravity;
  final double velocity;
  final bool isInteractive;
  final bool shadersEnabled;
  final Map<String, dynamic> customParameters;

  const StudioConfigurationDescriptor({
    this.targetLoaderId = 'infinite_universe',
    this.selectedThemeId = 'deep_space',
    this.animationSpeed = 1.0,
    this.intensity = 1.0,
    this.scale = 1.0,
    this.particleCount = 200,
    this.particleSize = 2.0,
    this.particleOpacity = 0.8,
    this.gravity = 9.8,
    this.velocity = 1.0,
    this.isInteractive = true,
    this.shadersEnabled = true,
    this.customParameters = const {},
  });

  StudioConfigurationDescriptor copyWith({
    String? targetLoaderId,
    String? selectedThemeId,
    double? animationSpeed,
    double? intensity,
    double? scale,
    int? particleCount,
    double? particleSize,
    double? particleOpacity,
    double? gravity,
    double? velocity,
    bool? isInteractive,
    bool? shadersEnabled,
    Map<String, dynamic>? customParameters,
  }) {
    return StudioConfigurationDescriptor(
      targetLoaderId: targetLoaderId ?? this.targetLoaderId,
      selectedThemeId: selectedThemeId ?? this.selectedThemeId,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      intensity: intensity ?? this.intensity,
      scale: scale ?? this.scale,
      particleCount: particleCount ?? this.particleCount,
      particleSize: particleSize ?? this.particleSize,
      particleOpacity: particleOpacity ?? this.particleOpacity,
      gravity: gravity ?? this.gravity,
      velocity: velocity ?? this.velocity,
      isInteractive: isInteractive ?? this.isInteractive,
      shadersEnabled: shadersEnabled ?? this.shadersEnabled,
      customParameters: customParameters ?? this.customParameters,
    );
  }

  Map<String, dynamic> toJson() => {
        'target_loader_id': targetLoaderId,
        'selected_theme_id': selectedThemeId,
        'animation_speed': animationSpeed,
        'intensity': intensity,
        'scale': scale,
        'particle_count': particleCount,
        'particle_size': particleSize,
        'particle_opacity': particleOpacity,
        'gravity': gravity,
        'velocity': velocity,
        'is_interactive': isInteractive,
        'shaders_enabled': shadersEnabled,
        'custom_parameters': customParameters,
      };

  factory StudioConfigurationDescriptor.fromJson(Map<String, dynamic> json) {
    return StudioConfigurationDescriptor(
      targetLoaderId:
          json['target_loader_id'] as String? ?? 'infinite_universe',
      selectedThemeId: json['selected_theme_id'] as String? ?? 'deep_space',
      animationSpeed: (json['animation_speed'] as num?)?.toDouble() ?? 1.0,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 1.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      particleCount: json['particle_count'] as int? ?? 200,
      particleSize: (json['particle_size'] as num?)?.toDouble() ?? 2.0,
      particleOpacity: (json['particle_opacity'] as num?)?.toDouble() ?? 0.8,
      gravity: (json['gravity'] as num?)?.toDouble() ?? 9.8,
      velocity: (json['velocity'] as num?)?.toDouble() ?? 1.0,
      isInteractive: json['is_interactive'] as bool? ?? true,
      shadersEnabled: json['shaders_enabled'] as bool? ?? true,
      customParameters:
          (json['custom_parameters'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Comprehensive, immutable Studio v2 State Snapshot.
class StudioV2State {
  final String workspaceId;
  final String workspaceName;
  final StudioNavigationSection currentSection;
  final StudioConfigurationDescriptor activeConfiguration;
  final List<StudioPanelDefinition> registeredPanels;
  final List<StudioActionDefinition> registeredActions;
  final List<String> favoriteLoaderIds;
  final List<String> recentPresetIds;
  final bool isLivePreviewPaused;
  final bool isDiagnosticsOverlayVisible;
  final DateTime lastModifiedAt;

  const StudioV2State({
    required this.workspaceId,
    required this.workspaceName,
    this.currentSection = StudioNavigationSection.workspace,
    this.activeConfiguration = const StudioConfigurationDescriptor(),
    this.registeredPanels = const [],
    this.registeredActions = const [],
    this.favoriteLoaderIds = const [],
    this.recentPresetIds = const [],
    this.isLivePreviewPaused = false,
    this.isDiagnosticsOverlayVisible = false,
    required this.lastModifiedAt,
  });

  StudioV2State copyWith({
    String? workspaceId,
    String? workspaceName,
    StudioNavigationSection? currentSection,
    StudioConfigurationDescriptor? activeConfiguration,
    List<StudioPanelDefinition>? registeredPanels,
    List<StudioActionDefinition>? registeredActions,
    List<String>? favoriteLoaderIds,
    List<String>? recentPresetIds,
    bool? isLivePreviewPaused,
    bool? isDiagnosticsOverlayVisible,
    DateTime? lastModifiedAt,
  }) {
    return StudioV2State(
      workspaceId: workspaceId ?? this.workspaceId,
      workspaceName: workspaceName ?? this.workspaceName,
      currentSection: currentSection ?? this.currentSection,
      activeConfiguration: activeConfiguration ?? this.activeConfiguration,
      registeredPanels: registeredPanels ?? this.registeredPanels,
      registeredActions: registeredActions ?? this.registeredActions,
      favoriteLoaderIds: favoriteLoaderIds ?? this.favoriteLoaderIds,
      recentPresetIds: recentPresetIds ?? this.recentPresetIds,
      isLivePreviewPaused: isLivePreviewPaused ?? this.isLivePreviewPaused,
      isDiagnosticsOverlayVisible:
          isDiagnosticsOverlayVisible ?? this.isDiagnosticsOverlayVisible,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'workspace_id': workspaceId,
        'workspace_name': workspaceName,
        'current_section': currentSection.id,
        'active_configuration': activeConfiguration.toJson(),
        'registered_panels': registeredPanels.map((p) => p.toJson()).toList(),
        'registered_actions': registeredActions.map((a) => a.toJson()).toList(),
        'favorite_loader_ids': favoriteLoaderIds,
        'recent_preset_ids': recentPresetIds,
        'is_live_preview_paused': isLivePreviewPaused,
        'is_diagnostics_overlay_visible': isDiagnosticsOverlayVisible,
        'last_modified_at': lastModifiedAt.toIso8601String(),
      };

  factory StudioV2State.fromJson(Map<String, dynamic> json) {
    return StudioV2State(
      workspaceId: json['workspace_id'] as String? ?? 'default_ws',
      workspaceName: json['workspace_name'] as String? ?? 'Studio v2 Workspace',
      currentSection: StudioNavigationSection.values.firstWhere(
        (s) =>
            s.id == json['current_section'] ||
            s.name == json['current_section'],
        orElse: () => StudioNavigationSection.workspace,
      ),
      activeConfiguration: json['active_configuration'] != null
          ? StudioConfigurationDescriptor.fromJson(
              json['active_configuration'] as Map<String, dynamic>)
          : const StudioConfigurationDescriptor(),
      registeredPanels: (json['registered_panels'] as List<dynamic>?)
              ?.map((p) =>
                  StudioPanelDefinition.fromJson(p as Map<String, dynamic>))
              .toList() ??
          const [],
      registeredActions: (json['registered_actions'] as List<dynamic>?)
              ?.map((a) =>
                  StudioActionDefinition.fromJson(a as Map<String, dynamic>))
              .toList() ??
          const [],
      favoriteLoaderIds: (json['favorite_loader_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      recentPresetIds: (json['recent_preset_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isLivePreviewPaused: json['is_live_preview_paused'] as bool? ?? false,
      isDiagnosticsOverlayVisible:
          json['is_diagnostics_overlay_visible'] as bool? ?? false,
      lastModifiedAt: DateTime.parse(json['last_modified_at'] as String),
    );
  }
}
