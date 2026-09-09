/// Domain models and layout descriptors for Phase 10.2: Unified Studio Workspace.
library;

import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_models.dart';

/// Workspace zone enumeration defining the 4 primary quadrant areas and toolbars.
enum WorkspaceQuadrantZone {
  topToolbar,
  leftNavigation,
  centerLivePreview,
  bottomLeftInspector,
  bottomRightOutputConsole;

  String get id => name;
}

/// Output mode of the bottom-right console/configuration area.
enum WorkspaceOutputTab {
  configuration,
  codeGen,
  diagnostics,
  performanceMetrics,
  exportSummary;

  String get id => name;

  String get label {
    switch (this) {
      case WorkspaceOutputTab.configuration:
        return 'Configuration JSON';
      case WorkspaceOutputTab.codeGen:
        return 'Generated Dart Code';
      case WorkspaceOutputTab.diagnostics:
        return 'Diagnostics Log';
      case WorkspaceOutputTab.performanceMetrics:
        return 'Performance Telemetry';
      case WorkspaceOutputTab.exportSummary:
        return 'Export Summary';
    }
  }
}

/// Active state and layout composition of the Unified Studio Workspace.
class UnifiedWorkspaceSession {
  final String sessionId;
  final String activeLoaderId;
  final String activeThemeId;
  final StudioConfigurationDescriptor configuration;
  final WorkspaceOutputTab activeOutputTab;
  final bool isToolbarVisible;
  final bool isInspectorExpanded;
  final bool isOutputConsoleExpanded;
  final double liveFps;
  final double frameTimeMs;
  final int activeParticleCount;
  final DateTime lastRefreshedAt;

  const UnifiedWorkspaceSession({
    required this.sessionId,
    this.activeLoaderId = 'infinite_universe',
    this.activeThemeId = 'deep_space',
    this.configuration = const StudioConfigurationDescriptor(),
    this.activeOutputTab = WorkspaceOutputTab.configuration,
    this.isToolbarVisible = true,
    this.isInspectorExpanded = true,
    this.isOutputConsoleExpanded = true,
    this.liveFps = 60.0,
    this.frameTimeMs = 16.6,
    this.activeParticleCount = 200,
    required this.lastRefreshedAt,
  });

  UnifiedWorkspaceSession copyWith({
    String? sessionId,
    String? activeLoaderId,
    String? activeThemeId,
    StudioConfigurationDescriptor? configuration,
    WorkspaceOutputTab? activeOutputTab,
    bool? isToolbarVisible,
    bool? isInspectorExpanded,
    bool? isOutputConsoleExpanded,
    double? liveFps,
    double? frameTimeMs,
    int? activeParticleCount,
    DateTime? lastRefreshedAt,
  }) {
    return UnifiedWorkspaceSession(
      sessionId: sessionId ?? this.sessionId,
      activeLoaderId: activeLoaderId ?? this.activeLoaderId,
      activeThemeId: activeThemeId ?? this.activeThemeId,
      configuration: configuration ?? this.configuration,
      activeOutputTab: activeOutputTab ?? this.activeOutputTab,
      isToolbarVisible: isToolbarVisible ?? this.isToolbarVisible,
      isInspectorExpanded: isInspectorExpanded ?? this.isInspectorExpanded,
      isOutputConsoleExpanded:
          isOutputConsoleExpanded ?? this.isOutputConsoleExpanded,
      liveFps: liveFps ?? this.liveFps,
      frameTimeMs: frameTimeMs ?? this.frameTimeMs,
      activeParticleCount: activeParticleCount ?? this.activeParticleCount,
      lastRefreshedAt: lastRefreshedAt ?? this.lastRefreshedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'active_loader_id': activeLoaderId,
        'active_theme_id': activeThemeId,
        'configuration': configuration.toJson(),
        'active_output_tab': activeOutputTab.id,
        'is_toolbar_visible': isToolbarVisible,
        'is_inspector_expanded': isInspectorExpanded,
        'is_output_console_expanded': isOutputConsoleExpanded,
        'live_fps': liveFps,
        'frame_time_ms': frameTimeMs,
        'active_particle_count': activeParticleCount,
        'last_refreshed_at': lastRefreshedAt.toIso8601String(),
      };

  factory UnifiedWorkspaceSession.fromJson(Map<String, dynamic> json) {
    return UnifiedWorkspaceSession(
      sessionId: json['session_id'] as String? ?? 'session_default',
      activeLoaderId:
          json['active_loader_id'] as String? ?? 'infinite_universe',
      activeThemeId: json['active_theme_id'] as String? ?? 'deep_space',
      configuration: json['configuration'] != null
          ? StudioConfigurationDescriptor.fromJson(
              json['configuration'] as Map<String, dynamic>)
          : const StudioConfigurationDescriptor(),
      activeOutputTab: WorkspaceOutputTab.values.firstWhere(
        (t) =>
            t.id == json['active_output_tab'] ||
            t.name == json['active_output_tab'],
        orElse: () => WorkspaceOutputTab.configuration,
      ),
      isToolbarVisible: json['is_toolbar_visible'] as bool? ?? true,
      isInspectorExpanded: json['is_inspector_expanded'] as bool? ?? true,
      isOutputConsoleExpanded:
          json['is_output_console_expanded'] as bool? ?? true,
      liveFps: (json['live_fps'] as num?)?.toDouble() ?? 60.0,
      frameTimeMs: (json['frame_time_ms'] as num?)?.toDouble() ?? 16.6,
      activeParticleCount: json['active_particle_count'] as int? ?? 200,
      lastRefreshedAt: DateTime.parse(json['last_refreshed_at'] as String),
    );
  }
}
