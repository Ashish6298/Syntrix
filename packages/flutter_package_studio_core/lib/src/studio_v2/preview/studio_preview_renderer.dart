/// Multi-format (ASCII Preview Frame, Markdown, JSON) renderer for Phase 10.5: Live Preview Engine.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/preview/studio_preview_models.dart';

/// Formatter generating ASCII live preview wireframes, Markdown telemetry sheets, and JSON schemas.
class StudioPreviewRenderer {
  /// Render preview session as structured JSON.
  static String renderJson(LivePreviewSessionState state, {bool pretty = true}) {
    final encoder = pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(state.toJson());
  }

  /// Render ASCII Live Preview Viewport frame reflecting current rendering state and telemetry.
  static String renderAsciiViewport(LivePreviewSessionState state) {
    final buffer = StringBuffer();
    final cfg = state.configuration;
    final m = state.metrics;
    final isPlaying = state.playbackState == LivePreviewPlaybackState.playing;

    buffer.writeln('┌──────────────────────────────────────────────────────────────┐');
    buffer.writeln('│ LIVE PREVIEW VIEWPORT: ${state.activeLoaderId.padRight(20)} [${state.viewportMode.id.toUpperCase()}] │');
    buffer.writeln('├──────────────────────────────────────────────────────────────┤');
    buffer.writeln('│ [Status: ${state.playbackState.id.toUpperCase().padRight(10)}] │ [Speed: ${cfg.animationSpeed.toStringAsFixed(1)}x] │ [Scale: ${cfg.scale.toStringAsFixed(1)}x] │ [Particles: ${cfg.particleCount.toString().padLeft(4)}] │');
    buffer.writeln('├──────────────────────────────────────────────────────────────┤');
    buffer.writeln('│                                                              │');
    buffer.writeln('│                   .  *  .  *   .   *   .                     │');
    buffer.writeln('│              *   .    ┌─────────────┐    .   *               │');
    buffer.writeln('│            .   *      │  ( 🌀 )     │      *   .             │');
    buffer.writeln('│              *   .    └─────────────┘    .   *               │');
    buffer.writeln('│                   .  *  .  *   .   *   .                     │');
    buffer.writeln('│                                                              │');
    buffer.writeln('├──────────────────────────────────────────────────────────────┤');
    buffer.writeln('│ Telemetry: FPS: ${m.currentFps.toStringAsFixed(1).padLeft(5)} │ Frame: ${m.currentFrameTimeMs.toStringAsFixed(1).padLeft(5)}ms │ Avg: ${m.averageFps.toStringAsFixed(1).padLeft(5)} FPS │ Drops: ${m.droppedFrames} │');
    buffer.writeln('│ Controls:  [Pause/Play] [Restart] [Reset] [Toggle Fullscreen] │');
    buffer.writeln('└──────────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render live telemetry and state as a clean Markdown report.
  static String renderMarkdown(LivePreviewSessionState state) {
    final buffer = StringBuffer();
    final m = state.metrics;
    final cfg = state.configuration;

    buffer.writeln('# Live Preview Engine Telemetry');
    buffer.writeln();
    buffer.writeln('**Preview ID:** `${state.previewId}`  ');
    buffer.writeln('**Active Loader:** `${state.activeLoaderId}`  ');
    buffer.writeln('**Playback State:** `${state.playbackState.id.toUpperCase()}`  ');
    buffer.writeln('**Viewport Mode:** `${state.viewportMode.id.toUpperCase()}`  ');
    buffer.writeln('**Started At:** ${state.startedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Real-time Telemetry Metrics');
    buffer.writeln();
    buffer.writeln('| Metric | Live Value |');
    buffer.writeln('|---|---|');
    buffer.writeln('| **Current Framerate** | `${m.currentFps.toStringAsFixed(1)} FPS` |');
    buffer.writeln('| **Average Framerate** | `${m.averageFps.toStringAsFixed(1)} FPS` |');
    buffer.writeln('| **Frame Time Duration** | `${m.currentFrameTimeMs.toStringAsFixed(2)} ms` |');
    buffer.writeln('| **Min / Max Frame Time** | `${m.minFrameTimeMs.toStringAsFixed(2)} ms / ${m.maxFrameTimeMs.toStringAsFixed(2)} ms` |');
    buffer.writeln('| **Total Frames Rendered** | `${m.totalFramesRendered}` |');
    buffer.writeln('| **Dropped Frames (<50 FPS)** | `${m.droppedFrames}` |');
    buffer.writeln('| **Active Particle Simulations** | `${m.currentParticleCount}` |');
    buffer.writeln();

    buffer.writeln('## Bound Configuration');
    buffer.writeln();
    buffer.writeln('- **Speed:** `${cfg.animationSpeed}x`');
    buffer.writeln('- **Intensity:** `${cfg.intensity}`');
    buffer.writeln('- **Scale:** `${cfg.scale}`');
    buffer.writeln('- **Theme:** `${cfg.selectedThemeId}`');
    buffer.writeln('- **Shaders:** `${cfg.shadersEnabled ? "Enabled" : "Disabled"}`');
    buffer.writeln('- **Interactive Gestures:** `${cfg.isInteractive ? "Enabled" : "Disabled"}`');
    buffer.writeln();

    return buffer.toString();
  }
}
