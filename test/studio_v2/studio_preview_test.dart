import 'package:syntrix/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.5: Live Preview Engine Models', () {
    test('FrameTimingSample and LivePreviewMetrics JSON roundtrip', () {
      final sample = FrameTimingSample(
        frameNumber: 120,
        frameDurationMs: 16.2,
        buildDurationMs: 2.1,
        rasterDurationMs: 4.3,
        activeParticleCount: 300,
        timestamp: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      final sampleJson = sample.toJson();
      final restoredSample = FrameTimingSample.fromJson(sampleJson);

      expect(restoredSample.frameNumber, equals(120));
      expect(restoredSample.frameDurationMs, equals(16.2));
      expect(restoredSample.activeParticleCount, equals(300));

      const metrics = LivePreviewMetrics(
        currentFps: 61.2,
        averageFps: 60.1,
        currentFrameTimeMs: 16.3,
        totalFramesRendered: 7200,
        droppedFrames: 2,
        currentParticleCount: 300,
      );

      final metricsJson = metrics.toJson();
      final restoredMetrics = LivePreviewMetrics.fromJson(metricsJson);

      expect(restoredMetrics.currentFps, equals(61.2));
      expect(restoredMetrics.averageFps, equals(60.1));
      expect(restoredMetrics.droppedFrames, equals(2));
    });

    test('LivePreviewSessionState serialization and deserialization', () {
      final state = LivePreviewSessionState(
        previewId: 'prev_test_99',
        activeLoaderId: 'infinite_universe',
        configuration: const StudioConfigurationDescriptor(
          targetLoaderId: 'infinite_universe',
          animationSpeed: 1.5,
        ),
        playbackState: LivePreviewPlaybackState.playing,
        viewportMode: PreviewViewportMode.fullscreen,
        startedAt: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      final json = state.toJson();
      final restored = LivePreviewSessionState.fromJson(json);

      expect(restored.previewId, equals('prev_test_99'));
      expect(restored.activeLoaderId, equals('infinite_universe'));
      expect(restored.playbackState, equals(LivePreviewPlaybackState.playing));
      expect(restored.viewportMode, equals(PreviewViewportMode.fullscreen));
      expect(restored.configuration.animationSpeed, equals(1.5));
    });
  });

  group('Phase 10.5: Studio Live Preview Engine Operations', () {
    test('Playback controls: pause, resume, restart, and reset', () {
      final controller = StudioV2Controller();
      final previewEngine = StudioLivePreviewEngine(controller: controller);

      LivePreviewSessionState? notifiedState;
      previewEngine.addPreviewListener((state) {
        notifiedState = state;
      });

      expect(previewEngine.state.playbackState,
          equals(LivePreviewPlaybackState.playing));

      // Pause
      previewEngine.pause();
      expect(controller.state.isLivePreviewPaused, isTrue);

      // Resume
      previewEngine.resume();
      expect(controller.state.isLivePreviewPaused, isFalse);

      // Restart animation
      previewEngine.restartAnimation();
      expect(previewEngine.state.playbackState,
          equals(LivePreviewPlaybackState.playing));

      // Reset
      controller
          .updateConfiguration((cfg) => cfg.copyWith(animationSpeed: 3.5));
      previewEngine.resetConfiguration();
      expect(previewEngine.state.configuration.animationSpeed, equals(1.0));

      // Viewport mode
      previewEngine.setViewportMode(PreviewViewportMode.fullscreen);
      expect(previewEngine.state.viewportMode,
          equals(PreviewViewportMode.fullscreen));

      expect(notifiedState, isNotNull);
    });

    test('Frame timing sampling records metrics and calculates FPS dynamically',
        () {
      final controller = StudioV2Controller();
      final previewEngine = StudioLivePreviewEngine(controller: controller);

      for (int i = 1; i <= 10; i++) {
        previewEngine.recordFrameTiming(FrameTimingSample(
          frameNumber: i,
          frameDurationMs: 16.6,
          buildDurationMs: 2.0,
          rasterDurationMs: 4.0,
          activeParticleCount: 200,
          timestamp: DateTime.now(),
        ));
      }

      expect(previewEngine.state.metrics.totalFramesRendered, equals(10));
      expect(previewEngine.state.metrics.currentFps, closeTo(60.24, 0.5));
      expect(previewEngine.state.recentTimingSamples.length, equals(10));
    });
  });

  group('Phase 10.5: Studio Preview Renderer', () {
    test('Renders ASCII Viewport wireframe, Markdown telemetry, and JSON state',
        () {
      final controller = StudioV2Controller();
      final previewEngine = StudioLivePreviewEngine(controller: controller);

      previewEngine.recordFrameTiming(FrameTimingSample(
        frameNumber: 1,
        frameDurationMs: 16.6,
        buildDurationMs: 2.0,
        rasterDurationMs: 4.0,
        activeParticleCount: 200,
        timestamp: DateTime.now(),
      ));

      // 1. ASCII Viewport
      final ascii =
          StudioPreviewRenderer.renderAsciiViewport(previewEngine.state);
      expect(ascii, contains('LIVE PREVIEW VIEWPORT'));
      expect(ascii, contains('Telemetry: FPS:'));
      expect(
          ascii,
          contains(
              'Controls:  [Pause/Play] [Restart] [Reset] [Toggle Fullscreen]'));

      // 2. Markdown Report
      final markdown =
          StudioPreviewRenderer.renderMarkdown(previewEngine.state);
      expect(markdown, contains('# Live Preview Engine Telemetry'));
      expect(markdown, contains('**Current Framerate**'));
      expect(markdown, contains('FPS'));

      // 3. JSON State
      final json = StudioPreviewRenderer.renderJson(previewEngine.state);
      expect(json, contains('"preview_id"'));
      expect(json, contains('"playback_state": "playing"'));
    });
  });
}
