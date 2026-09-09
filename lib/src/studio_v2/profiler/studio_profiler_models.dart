/// Domain models and performance profile snapshots for Phase 10.10: Performance Profiler.
library;

import 'package:syntrix/src/studio_v2/studio_v2_models.dart';

/// Profiler operational display mode.
enum ProfilerMode {
  live,
  snapshot,
  comparison,
  history;

  String get id => name;

  String get label => name.toUpperCase();
}

/// Detailed stage breakdown timings for a single frame.
class FrameSubsystemTimings {
  final double animationProcessingMs;
  final double particleProcessingMs;
  final double physicsProcessingMs;
  final double renderingDrawPassMs;
  final double shaderExecutionMs;

  double get totalCpuGpuDurationMs =>
      animationProcessingMs +
      particleProcessingMs +
      physicsProcessingMs +
      renderingDrawPassMs +
      shaderExecutionMs;

  const FrameSubsystemTimings({
    this.animationProcessingMs = 1.2,
    this.particleProcessingMs = 3.5,
    this.physicsProcessingMs = 2.1,
    this.renderingDrawPassMs = 6.4,
    this.shaderExecutionMs = 3.0,
  });

  Map<String, dynamic> toJson() => {
        'animation_processing_ms': animationProcessingMs,
        'particle_processing_ms': particleProcessingMs,
        'physics_processing_ms': physicsProcessingMs,
        'rendering_draw_pass_ms': renderingDrawPassMs,
        'shader_execution_ms': shaderExecutionMs,
        'total_duration_ms': totalCpuGpuDurationMs,
      };

  factory FrameSubsystemTimings.fromJson(Map<String, dynamic> json) {
    return FrameSubsystemTimings(
      animationProcessingMs:
          (json['animation_processing_ms'] as num?)?.toDouble() ?? 1.2,
      particleProcessingMs:
          (json['particle_processing_ms'] as num?)?.toDouble() ?? 3.5,
      physicsProcessingMs:
          (json['physics_processing_ms'] as num?)?.toDouble() ?? 2.1,
      renderingDrawPassMs:
          (json['rendering_draw_pass_ms'] as num?)?.toDouble() ?? 6.4,
      shaderExecutionMs:
          (json['shader_execution_ms'] as num?)?.toDouble() ?? 3.0,
    );
  }
}

/// A captured snapshot of performance under a specific loader/configuration state.
class PerformanceSnapshot {
  final String snapshotId;
  final String label;
  final String loaderId;
  final StudioConfigurationDescriptor configuration;
  final double fps;
  final double frameTimeMs;
  final FrameSubsystemTimings timings;
  final int simulatedObjectCount;
  final bool shadersActive;
  final DateTime timestamp;

  const PerformanceSnapshot({
    required this.snapshotId,
    required this.label,
    required this.loaderId,
    required this.configuration,
    required this.fps,
    required this.frameTimeMs,
    required this.timings,
    required this.simulatedObjectCount,
    this.shadersActive = true,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'snapshot_id': snapshotId,
        'label': label,
        'loader_id': loaderId,
        'configuration': configuration.toJson(),
        'fps': fps,
        'frame_time_ms': frameTimeMs,
        'timings': timings.toJson(),
        'simulated_object_count': simulatedObjectCount,
        'shaders_active': shadersActive,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PerformanceSnapshot.fromJson(Map<String, dynamic> json) {
    return PerformanceSnapshot(
      snapshotId: json['snapshot_id'] as String? ?? 'snap_default',
      label: json['label'] as String? ?? 'Snapshot',
      loaderId: json['loader_id'] as String? ?? 'infinite_universe',
      configuration: json['configuration'] != null
          ? StudioConfigurationDescriptor.fromJson(
              json['configuration'] as Map<String, dynamic>)
          : const StudioConfigurationDescriptor(),
      fps: (json['fps'] as num?)?.toDouble() ?? 60.0,
      frameTimeMs: (json['frame_time_ms'] as num?)?.toDouble() ?? 16.6,
      timings: json['timings'] != null
          ? FrameSubsystemTimings.fromJson(
              json['timings'] as Map<String, dynamic>)
          : const FrameSubsystemTimings(),
      simulatedObjectCount: json['simulated_object_count'] as int? ?? 200,
      shadersActive: json['shaders_active'] as bool? ?? true,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Comparison delta between two performance snapshots (e.g. before/after config changes).
class PerformanceDeltaComparison {
  final PerformanceSnapshot before;
  final PerformanceSnapshot after;

  double get fpsDelta => after.fps - before.fps;
  double get frameTimeDeltaMs => after.frameTimeMs - before.frameTimeMs;
  int get objectCountDelta =>
      after.simulatedObjectCount - before.simulatedObjectCount;
  double get totalProcessingDeltaMs =>
      after.timings.totalCpuGpuDurationMs -
      before.timings.totalCpuGpuDurationMs;

  const PerformanceDeltaComparison({
    required this.before,
    required this.after,
  });

  Map<String, dynamic> toJson() => {
        'before': before.toJson(),
        'after': after.toJson(),
        'deltas': {
          'fps_delta': fpsDelta,
          'frame_time_delta_ms': frameTimeDeltaMs,
          'object_count_delta': objectCountDelta,
          'processing_time_delta_ms': totalProcessingDeltaMs,
        },
      };
}
