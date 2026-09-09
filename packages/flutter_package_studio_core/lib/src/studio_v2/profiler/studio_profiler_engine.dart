/// Central Performance Profiler Engine for Phase 10.10.
library;

import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_controller.dart';
import 'package:flutter_package_studio_core/src/studio_v2/profiler/studio_profiler_models.dart';

/// Central Performance Profiler Engine providing live profiling, snapshot capture, and comparison deltas.
class StudioProfilerEngine {
  final Logger _logger = Logger('StudioProfilerEngine');
  final StudioV2Controller controller;

  ProfilerMode _currentMode = ProfilerMode.live;
  final List<PerformanceSnapshot> _history = [];
  final List<void Function(ProfilerMode)> _modeListeners = [];

  ProfilerMode get mode => _currentMode;
  List<PerformanceSnapshot> get history => List.unmodifiable(_history);

  StudioProfilerEngine({required this.controller});

  void addModeListener(void Function(ProfilerMode) listener) {
    _modeListeners.add(listener);
  }

  void removeModeListener(void Function(ProfilerMode) listener) {
    _modeListeners.remove(listener);
  }

  /// Switch active profiler mode (Live, Snapshot, Comparison, History).
  void setMode(ProfilerMode newMode) {
    _currentMode = newMode;
    _logger.info('Switched profiler mode to: ${newMode.label}');
    for (final l in _modeListeners) {
      l(_currentMode);
    }
  }

  /// Capture a performance snapshot of current workspace configuration.
  PerformanceSnapshot captureSnapshot({
    String label = 'Snapshot',
    double fps = 60.0,
    double frameTimeMs = 16.2,
    FrameSubsystemTimings timings = const FrameSubsystemTimings(),
  }) {
    final cfg = controller.state.activeConfiguration;
    final snapshot = PerformanceSnapshot(
      snapshotId: 'snap_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      loaderId: cfg.targetLoaderId,
      configuration: cfg,
      fps: fps,
      frameTimeMs: frameTimeMs,
      timings: timings,
      simulatedObjectCount: cfg.particleCount + 10,
      shadersActive: cfg.shadersEnabled,
      timestamp: DateTime.now(),
    );

    _history.add(snapshot);
    if (_history.length > 50) {
      _history.removeAt(0);
    }

    _logger.info(
        'Captured performance snapshot: ${snapshot.snapshotId} ("$label")');
    return snapshot;
  }

  /// Compare two performance snapshots.
  PerformanceDeltaComparison compareSnapshots(
      PerformanceSnapshot before, PerformanceSnapshot after) {
    return PerformanceDeltaComparison(before: before, after: after);
  }

  /// Clear snapshot history.
  void clearHistory() {
    _history.clear();
    _logger.info('Cleared profiler snapshot history.');
  }
}
