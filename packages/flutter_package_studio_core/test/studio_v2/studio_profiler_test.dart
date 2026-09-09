import 'package:flutter_package_studio_core/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.10: Performance Profiler Models', () {
    test(
        'FrameSubsystemTimings, PerformanceSnapshot, and PerformanceDeltaComparison JSON roundtrip',
        () {
      const timings = FrameSubsystemTimings(
        animationProcessingMs: 1.5,
        particleProcessingMs: 4.2,
        physicsProcessingMs: 2.8,
        renderingDrawPassMs: 5.5,
        shaderExecutionMs: 2.5,
      );

      expect(timings.totalCpuGpuDurationMs, closeTo(16.5, 0.01));

      final snapshot = PerformanceSnapshot(
        snapshotId: 'snap_test_01',
        label: 'Baseline 200 Particles',
        loaderId: 'infinite_universe',
        configuration: const StudioConfigurationDescriptor(
          targetLoaderId: 'infinite_universe',
          particleCount: 200,
        ),
        fps: 60.0,
        frameTimeMs: 16.5,
        timings: timings,
        simulatedObjectCount: 210,
        shadersActive: true,
        timestamp: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      final json = snapshot.toJson();
      final restored = PerformanceSnapshot.fromJson(json);

      expect(restored.snapshotId, equals('snap_test_01'));
      expect(restored.label, equals('Baseline 200 Particles'));
      expect(restored.fps, equals(60.0));
      expect(restored.timings.particleProcessingMs, equals(4.2));
      expect(restored.simulatedObjectCount, equals(210));
    });
  });

  group('Phase 10.10: Studio Profiler Engine Operations', () {
    test(
        'Captures snapshots, switches profiler modes, and computes comparison deltas',
        () {
      final controller = StudioV2Controller();
      final profiler = StudioProfilerEngine(controller: controller);

      ProfilerMode? notifiedMode;
      profiler.addModeListener((mode) {
        notifiedMode = mode;
      });

      // 1. Switch mode
      profiler.setMode(ProfilerMode.snapshot);
      expect(profiler.mode, equals(ProfilerMode.snapshot));
      expect(notifiedMode, equals(ProfilerMode.snapshot));

      // 2. Capture baseline snapshot
      final snapA = profiler.captureSnapshot(
        label: 'Before (200 particles)',
        fps: 60.0,
        frameTimeMs: 16.2,
        timings: const FrameSubsystemTimings(particleProcessingMs: 3.0),
      );
      expect(profiler.history.length, equals(1));

      // 3. Mutate config and capture after snapshot
      controller.updateConfiguration((cfg) => cfg.copyWith(particleCount: 800));
      final snapB = profiler.captureSnapshot(
        label: 'After (800 particles)',
        fps: 52.5,
        frameTimeMs: 19.0,
        timings: const FrameSubsystemTimings(particleProcessingMs: 6.5),
      );
      expect(profiler.history.length, equals(2));

      // 4. Compare snapshots
      final comparison = profiler.compareSnapshots(snapA, snapB);
      expect(comparison.fpsDelta, closeTo(-7.5, 0.1));
      expect(comparison.frameTimeDeltaMs, closeTo(2.8, 0.1));
      expect(comparison.objectCountDelta, equals(600));

      // 5. Clear history
      profiler.clearHistory();
      expect(profiler.history, isEmpty);
    });
  });

  group('Phase 10.10: Studio Profiler Renderer', () {
    test(
        'Renders ASCII Profiler Breakdown, Markdown Comparison, and JSON state',
        () {
      final controller = StudioV2Controller();
      final profiler = StudioProfilerEngine(controller: controller);

      final snapA = profiler.captureSnapshot(
        label: 'Base',
        fps: 60.0,
        frameTimeMs: 16.2,
      );

      final snapB = profiler.captureSnapshot(
        label: 'Overclocked',
        fps: 54.0,
        frameTimeMs: 18.5,
      );

      // 1. ASCII Wireframe
      final ascii = StudioProfilerRenderer.renderAsciiProfiler(snapA,
          mode: ProfilerMode.live);
      expect(ascii, contains('PERFORMANCE PROFILER: [MODE: LIVE        ]'));
      expect(ascii, contains('Subsystem Frame Processing Breakdown:'));
      expect(ascii, contains('Animation Processing:'));
      expect(ascii, contains('Particle Processing:'));
      expect(ascii, contains('GPU Shader Execution:'));

      // 2. Markdown Comparison Sheet
      final comparison = profiler.compareSnapshots(snapA, snapB);
      final markdown =
          StudioProfilerRenderer.renderComparisonMarkdown(comparison);
      expect(markdown, contains('# Performance Snapshot Comparison'));
      expect(markdown, contains('## Subsystem Timings Breakdown'));
      expect(markdown, contains('**FPS**'));
      expect(markdown, contains('**Frame Time**'));

      // 3. JSON
      final json = StudioProfilerRenderer.renderJson(snapA);
      expect(json, contains('"snapshot_id"'));
      expect(json, contains('"fps": 60.0'));
    });
  });
}
