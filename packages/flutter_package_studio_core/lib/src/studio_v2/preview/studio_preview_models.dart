/// Domain models and performance telemetry descriptors for Phase 10.5: Live Preview Engine.
library;

import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_models.dart';

/// Playback and animation state of the live preview engine.
enum LivePreviewPlaybackState {
  playing,
  paused,
  restarting,
  stopped;

  String get id => name;
}

/// Viewport display mode.
enum PreviewViewportMode {
  embedded,
  fullscreen,
  sideBySide,
  isolatedCanvas;

  String get id => name;
}

/// Frame timing telemetry sample.
class FrameTimingSample {
  final int frameNumber;
  final double frameDurationMs;
  final double buildDurationMs;
  final double rasterDurationMs;
  final int activeParticleCount;
  final DateTime timestamp;

  const FrameTimingSample({
    required this.frameNumber,
    required this.frameDurationMs,
    required this.buildDurationMs,
    required this.rasterDurationMs,
    required this.activeParticleCount,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'frame_number': frameNumber,
        'frame_duration_ms': frameDurationMs,
        'build_duration_ms': buildDurationMs,
        'raster_duration_ms': rasterDurationMs,
        'active_particle_count': activeParticleCount,
        'timestamp': timestamp.toIso8601String(),
      };

  factory FrameTimingSample.fromJson(Map<String, dynamic> json) {
    return FrameTimingSample(
      frameNumber: json['frame_number'] as int? ?? 0,
      frameDurationMs: (json['frame_duration_ms'] as num?)?.toDouble() ?? 16.6,
      buildDurationMs: (json['build_duration_ms'] as num?)?.toDouble() ?? 2.0,
      rasterDurationMs: (json['raster_duration_ms'] as num?)?.toDouble() ?? 4.0,
      activeParticleCount: json['active_particle_count'] as int? ?? 200,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Aggregated Live Preview Performance Metrics.
class LivePreviewMetrics {
  final double currentFps;
  final double averageFps;
  final double currentFrameTimeMs;
  final double minFrameTimeMs;
  final double maxFrameTimeMs;
  final int totalFramesRendered;
  final int droppedFrames;
  final int currentParticleCount;

  const LivePreviewMetrics({
    this.currentFps = 60.0,
    this.averageFps = 59.8,
    this.currentFrameTimeMs = 16.6,
    this.minFrameTimeMs = 14.2,
    this.maxFrameTimeMs = 18.1,
    this.totalFramesRendered = 0,
    this.droppedFrames = 0,
    this.currentParticleCount = 200,
  });

  Map<String, dynamic> toJson() => {
        'current_fps': currentFps,
        'average_fps': averageFps,
        'current_frame_time_ms': currentFrameTimeMs,
        'min_frame_time_ms': minFrameTimeMs,
        'max_frame_time_ms': maxFrameTimeMs,
        'total_frames_rendered': totalFramesRendered,
        'dropped_frames': droppedFrames,
        'current_particle_count': currentParticleCount,
      };

  factory LivePreviewMetrics.fromJson(Map<String, dynamic> json) {
    return LivePreviewMetrics(
      currentFps: (json['current_fps'] as num?)?.toDouble() ?? 60.0,
      averageFps: (json['average_fps'] as num?)?.toDouble() ?? 59.8,
      currentFrameTimeMs:
          (json['current_frame_time_ms'] as num?)?.toDouble() ?? 16.6,
      minFrameTimeMs: (json['min_frame_time_ms'] as num?)?.toDouble() ?? 14.2,
      maxFrameTimeMs: (json['max_frame_time_ms'] as num?)?.toDouble() ?? 18.1,
      totalFramesRendered: json['total_frames_rendered'] as int? ?? 0,
      droppedFrames: json['dropped_frames'] as int? ?? 0,
      currentParticleCount: json['current_particle_count'] as int? ?? 200,
    );
  }
}

/// Comprehensive Live Preview State representation.
class LivePreviewSessionState {
  final String previewId;
  final String activeLoaderId;
  final StudioConfigurationDescriptor configuration;
  final LivePreviewPlaybackState playbackState;
  final PreviewViewportMode viewportMode;
  final LivePreviewMetrics metrics;
  final List<FrameTimingSample> recentTimingSamples;
  final DateTime startedAt;

  const LivePreviewSessionState({
    required this.previewId,
    required this.activeLoaderId,
    required this.configuration,
    this.playbackState = LivePreviewPlaybackState.playing,
    this.viewportMode = PreviewViewportMode.embedded,
    this.metrics = const LivePreviewMetrics(),
    this.recentTimingSamples = const [],
    required this.startedAt,
  });

  LivePreviewSessionState copyWith({
    String? previewId,
    String? activeLoaderId,
    StudioConfigurationDescriptor? configuration,
    LivePreviewPlaybackState? playbackState,
    PreviewViewportMode? viewportMode,
    LivePreviewMetrics? metrics,
    List<FrameTimingSample>? recentTimingSamples,
    DateTime? startedAt,
  }) {
    return LivePreviewSessionState(
      previewId: previewId ?? this.previewId,
      activeLoaderId: activeLoaderId ?? this.activeLoaderId,
      configuration: configuration ?? this.configuration,
      playbackState: playbackState ?? this.playbackState,
      viewportMode: viewportMode ?? this.viewportMode,
      metrics: metrics ?? this.metrics,
      recentTimingSamples: recentTimingSamples ?? this.recentTimingSamples,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'preview_id': previewId,
        'active_loader_id': activeLoaderId,
        'configuration': configuration.toJson(),
        'playback_state': playbackState.id,
        'viewport_mode': viewportMode.id,
        'metrics': metrics.toJson(),
        'recent_timing_samples':
            recentTimingSamples.map((s) => s.toJson()).toList(),
        'started_at': startedAt.toIso8601String(),
      };

  factory LivePreviewSessionState.fromJson(Map<String, dynamic> json) {
    return LivePreviewSessionState(
      previewId: json['preview_id'] as String? ?? 'prev_default',
      activeLoaderId:
          json['active_loader_id'] as String? ?? 'infinite_universe',
      configuration: json['configuration'] != null
          ? StudioConfigurationDescriptor.fromJson(
              json['configuration'] as Map<String, dynamic>)
          : const StudioConfigurationDescriptor(),
      playbackState: LivePreviewPlaybackState.values.firstWhere(
        (p) =>
            p.id == json['playback_state'] || p.name == json['playback_state'],
        orElse: () => LivePreviewPlaybackState.playing,
      ),
      viewportMode: PreviewViewportMode.values.firstWhere(
        (v) => v.id == json['viewport_mode'] || v.name == json['viewport_mode'],
        orElse: () => PreviewViewportMode.embedded,
      ),
      metrics: json['metrics'] != null
          ? LivePreviewMetrics.fromJson(json['metrics'] as Map<String, dynamic>)
          : const LivePreviewMetrics(),
      recentTimingSamples: (json['recent_timing_samples'] as List<dynamic>?)
              ?.map(
                  (s) => FrameTimingSample.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      startedAt: DateTime.parse(json['started_at'] as String),
    );
  }
}
