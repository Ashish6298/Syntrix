/// Dual-format (JSON + Markdown) and ASCII Wireframe renderer for Phase 10.2: Unified Studio Workspace.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/workspace/studio_workspace_models.dart';
import 'package:flutter_package_studio_core/src/studio_v2/workspace/studio_workspace_engine.dart';

/// Renderer for Unified Studio Workspace sessions, live wireframes, and output summaries.
class StudioWorkspaceRenderer {
  /// Render workspace session as structured JSON.
  static String renderJson(UnifiedWorkspaceSession session, {bool pretty = true}) {
    final encoder = pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(session.toJson());
  }

  /// Render an ASCII 4-quadrant layout wireframe reflecting current workspace session state.
  static String renderAsciiWorkspace(UnifiedWorkspaceSession session) {
    final buffer = StringBuffer();
    final cfg = session.configuration;

    buffer.writeln('┌──────────────────────────────────────────────────────────────────────────────┐');
    buffer.writeln('│                        STUDIO v2 UNIFIED TOOLBAR                             │');
    buffer.writeln('│ [Loader: ${cfg.targetLoaderId.padRight(16)}] │ [Theme: ${cfg.selectedThemeId.padRight(12)}] │ [FPS: ${session.liveFps.toStringAsFixed(0).padLeft(3)}] │ [Time: ${session.frameTimeMs.toStringAsFixed(1)}ms] │');
    buffer.writeln('├────────────────────────────────┬─────────────────────────────────────────────┤');
    buffer.writeln('│  NAVIGATION & SELECTION        │  LIVE PREVIEW VIEWPORT                      │');
    buffer.writeln('│  -----------------------       │  ---------------------                      │');
    buffer.writeln('│  Active Loader: ${cfg.targetLoaderId.padRight(14)} │  [Live Rendering Viewport]                  │');
    buffer.writeln('│  Active Theme:  ${cfg.selectedThemeId.padRight(14)} │  Interactive Gestures: ${cfg.isInteractive.toString().padRight(21)} │');
    buffer.writeln('│  Status: Active Session        │  Shader Hardware Accel: ${cfg.shadersEnabled.toString().padRight(20)} │');
    buffer.writeln('├────────────────────────────────┼─────────────────────────────────────────────┤');
    buffer.writeln('│  CONFIGURATION INSPECTOR       │  WORKSPACE OUTPUT: ${session.activeOutputTab.label.padRight(24)} │');
    buffer.writeln('│  -----------------------       │  ----------------------------------------   │');
    buffer.writeln('│  Speed:     ${cfg.animationSpeed.toStringAsFixed(1).padRight(18)} │  Active Tab:   ${session.activeOutputTab.id.padRight(28)} │');
    buffer.writeln('│  Particles: ${cfg.particleCount.toString().padRight(18)} │  Particles:    ${session.activeParticleCount.toString().padRight(28)} │');
    buffer.writeln('│  Gravity:   ${cfg.gravity.toStringAsFixed(1).padRight(18)} │  Frame Time:   ${session.frameTimeMs.toStringAsFixed(2)}ms${"".padRight(24)} │');
    buffer.writeln('└────────────────────────────────┴─────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render workspace session as a clean Markdown status report.
  static String renderMarkdown(UnifiedWorkspaceSession session, StudioWorkspaceEngine engine) {
    final buffer = StringBuffer();
    final cfg = session.configuration;

    buffer.writeln('# Unified Studio Workspace Status');
    buffer.writeln();
    buffer.writeln('**Session ID:** `${session.sessionId}`  ');
    buffer.writeln('**Active Loader:** `${session.activeLoaderId}`  ');
    buffer.writeln('**Active Theme:** `${session.activeThemeId}`  ');
    buffer.writeln('**Performance:** `${session.liveFps.toStringAsFixed(0)} FPS` | `${session.frameTimeMs.toStringAsFixed(1)}ms` | `${session.activeParticleCount} particles`  ');
    buffer.writeln('**Active Output Tab:** `${session.activeOutputTab.label}`  ');
    buffer.writeln('**Refreshed At:** ${session.lastRefreshedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Configuration Parameters');
    buffer.writeln();
    buffer.writeln('| Parameter | Value |');
    buffer.writeln('|---|---|');
    buffer.writeln('| Animation Speed | `${cfg.animationSpeed}x` |');
    buffer.writeln('| Intensity | `${cfg.intensity}` |');
    buffer.writeln('| Scale | `${cfg.scale}` |');
    buffer.writeln('| Particle Count | `${cfg.particleCount}` |');
    buffer.writeln('| Particle Size | `${cfg.particleSize}` |');
    buffer.writeln('| Particle Opacity | `${cfg.particleOpacity}` |');
    buffer.writeln('| Gravity | `${cfg.gravity}` |');
    buffer.writeln('| Velocity | `${cfg.velocity}` |');
    buffer.writeln('| Interactive Gestures | `${cfg.isInteractive}` |');
    buffer.writeln('| Shaders Enabled | `${cfg.shadersEnabled}` |');
    buffer.writeln();

    buffer.writeln('## Generated Flutter Widget Preview');
    buffer.writeln();
    buffer.writeln('```dart');
    buffer.writeln(engine.generateFlutterCode());
    buffer.writeln('```');
    buffer.writeln();

    return buffer.toString();
  }
}
