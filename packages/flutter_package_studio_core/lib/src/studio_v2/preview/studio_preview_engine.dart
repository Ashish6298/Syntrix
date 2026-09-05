/// Central Live Preview Engine for Phase 10.5.
library;

import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_controller.dart';
import 'package:flutter_package_studio_core/src/studio_v2/preview/studio_preview_models.dart';

/// Central Live Preview Engine orchestrating real-time updates, playback controls, and telemetry.
class StudioLivePreviewEngine {
  final Logger _logger = Logger('StudioLivePreviewEngine');
  final StudioV2Controller controller;

  LivePreviewSessionState _previewState;
  final List<void Function(LivePreviewSessionState)> _listeners = [];

  LivePreviewSessionState get state => _previewState;

  StudioLivePreviewEngine({
    required this.controller,
    LivePreviewSessionState? initialState,
  }) : _previewState = initialState ??
            LivePreviewSessionState(
              previewId: 'prev_${DateTime.now().millisecondsSinceEpoch}',
              activeLoaderId: controller.state.activeConfiguration.targetLoaderId,
              configuration: controller.state.activeConfiguration,
              startedAt: DateTime.now(),
            ) {
    // React to parent controller configuration changes in real time
    controller.addListener((v2State) {
      _previewState = _previewState.copyWith(
        activeLoaderId: v2State.activeConfiguration.targetLoaderId,
        configuration: v2State.activeConfiguration,
        playbackState: v2State.isLivePreviewPaused
            ? LivePreviewPlaybackState.paused
            : LivePreviewPlaybackState.playing,
      );
      _notify();
    });
  }

  void addPreviewListener(void Function(LivePreviewSessionState) listener) {
    _listeners.add(listener);
  }

  void removePreviewListener(void Function(LivePreviewSessionState) listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in _listeners) {
      listener(_previewState);
    }
  }

  /// Pause animation playback.
  void pause() {
    _logger.info('Pausing live preview animation.');
    if (!_previewState.playbackState.name.contains('paused')) {
      controller.toggleLivePreviewPause();
    }
  }

  /// Resume animation playback.
  void resume() {
    _logger.info('Resuming live preview animation.');
    if (_previewState.playbackState == LivePreviewPlaybackState.paused) {
      controller.toggleLivePreviewPause();
    }
  }

  /// Restart animation cycle from t=0.
  void restartAnimation() {
    _logger.info('Restarting animation cycle.');
    _previewState = _previewState.copyWith(
      playbackState: LivePreviewPlaybackState.restarting,
    );
    _notify();

    // Immediately return to playing state
    _previewState = _previewState.copyWith(
      playbackState: LivePreviewPlaybackState.playing,
    );
    _notify();
  }

  /// Reset configuration to default values.
  void resetConfiguration() {
    controller.resetConfiguration();
  }

  /// Set viewport mode (e.g. embedded vs fullscreen).
  void setViewportMode(PreviewViewportMode mode) {
    _previewState = _previewState.copyWith(viewportMode: mode);
    _logger.info('Set preview viewport mode: ${mode.id}');
    _notify();
  }

  /// Record a new frame timing sample and update FPS / frame time metrics.
  void recordFrameTiming(FrameTimingSample sample) {
    final recent = List<FrameTimingSample>.from(_previewState.recentTimingSamples);
    if (recent.length >= 60) {
      recent.removeAt(0);
    }
    recent.add(sample);

    final avgFps = recent.isNotEmpty
        ? recent.map((s) => 1000.0 / s.frameDurationMs).reduce((a, b) => a + b) / recent.length
        : 60.0;

    final updatedMetrics = LivePreviewMetrics(
      currentFps: 1000.0 / sample.frameDurationMs,
      averageFps: avgFps,
      currentFrameTimeMs: sample.frameDurationMs,
      minFrameTimeMs: recent.map((s) => s.frameDurationMs).reduce((a, b) => a < b ? a : b),
      maxFrameTimeMs: recent.map((s) => s.frameDurationMs).reduce((a, b) => a > b ? a : b),
      totalFramesRendered: _previewState.metrics.totalFramesRendered + 1,
      droppedFrames: _previewState.metrics.droppedFrames + (sample.frameDurationMs > 20.0 ? 1 : 0),
      currentParticleCount: sample.activeParticleCount,
    );

    _previewState = _previewState.copyWith(
      metrics: updatedMetrics,
      recentTimingSamples: recent,
    );
    _notify();
  }
}
