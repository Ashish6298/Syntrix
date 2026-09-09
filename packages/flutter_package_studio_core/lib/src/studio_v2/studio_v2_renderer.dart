/// Multi-format (JSON, Markdown, ASCII Workspace Shell) renderer for Studio v2 Architecture.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_models.dart';

/// Renderer for Studio v2 workspace layouts, state summaries, and console reports.
class StudioV2Renderer {
  /// Render workspace state as a structured JSON string.
  static String renderJson(StudioV2State state, {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(state.toJson());
  }

  /// Render an ASCII representation of the unified Studio v2 Shell & Workspace layout.
  static String renderAsciiLayout(StudioV2State state) {
    final buffer = StringBuffer();
    final config = state.activeConfiguration;

    buffer.writeln(
        '┌────────────────────────────────────────────────────────────────────────┐');
    buffer.writeln(
        '│  Syntrix Studio v2 Shell  │  Section: ${state.currentSection.label.padRight(28)} │');
    buffer.writeln(
        '├────────────────────────────────────────────────────────────────────────┤');
    buffer.writeln(
        '│ [Toolbar] Reset (Ctrl+R) │ Pause (Space) [${state.isLivePreviewPaused ? "PAUSED " : "PLAYING"}] │ Diag: ${state.isDiagnosticsOverlayVisible ? "ON " : "OFF"} │');
    buffer.writeln(
        '├──────────────────────────────┬─────────────────────────────────────────┤');
    buffer.writeln(
        '│  Navigation Rail             │  Live Viewport Preview                  │');
    buffer.writeln(
        '│  -------------------         │  ----------------------                 │');
    for (final sec in StudioNavigationSection.values.take(6)) {
      final marker = sec == state.currentSection ? '►' : ' ';
      buffer.writeln(
          '│ $marker ${sec.label.padRight(26)} │ Target: ${config.targetLoaderId.padRight(31)} │');
    }
    buffer.writeln(
        '├──────────────────────────────┼─────────────────────────────────────────┤');
    buffer.writeln(
        '│  Configuration Inspector     │  Console & Telemetry Output             │');
    buffer.writeln(
        '│  -----------------------     │  --------------------------             │');
    buffer.writeln(
        '│  Speed:     ${config.animationSpeed.toStringAsFixed(1).padRight(16)} │  Theme:     ${config.selectedThemeId.padRight(27)} │');
    buffer.writeln(
        '│  Intensity: ${config.intensity.toStringAsFixed(1).padRight(16)} │  Particles: ${config.particleCount.toString().padRight(27)} │');
    buffer.writeln(
        '│  Scale:     ${config.scale.toStringAsFixed(1).padRight(16)} │  Interactive: ${config.isInteractive.toString().padRight(25)} │');
    buffer.writeln(
        '└──────────────────────────────┴─────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render state as a Markdown report detailing active panels, configuration, and state flags.
  static String renderMarkdown(StudioV2State state) {
    final buffer = StringBuffer();
    final config = state.activeConfiguration;

    buffer.writeln('# Studio v2 Workspace Status');
    buffer.writeln();
    buffer.writeln('**Workspace Name:** `${state.workspaceName}`  ');
    buffer.writeln('**Workspace ID:** `${state.workspaceId}`  ');
    buffer.writeln(
        '**Current Navigation Section:** `${state.currentSection.label}`  ');
    buffer.writeln(
        '**Live Preview Status:** `${state.isLivePreviewPaused ? "PAUSED" : "ACTIVE"}`  ');
    buffer.writeln(
        '**Diagnostics Overlay:** `${state.isDiagnosticsOverlayVisible ? "ENABLED" : "DISABLED"}`  ');
    buffer.writeln(
        '**Last Modified:** ${state.lastModifiedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Active Configuration Parameters');
    buffer.writeln();
    buffer.writeln('| Parameter | Value |');
    buffer.writeln('|---|---|');
    buffer.writeln('| **Target Loader ID** | `${config.targetLoaderId}` |');
    buffer.writeln('| **Selected Theme ID** | `${config.selectedThemeId}` |');
    buffer.writeln('| **Animation Speed** | `${config.animationSpeed}x` |');
    buffer.writeln('| **Intensity** | `${config.intensity}` |');
    buffer.writeln('| **Scale** | `${config.scale}` |');
    buffer.writeln('| **Particle Count** | `${config.particleCount}` |');
    buffer.writeln('| **Interactive Gestures** | `${config.isInteractive}` |');
    buffer.writeln('| **Shader Effects** | `${config.shadersEnabled}` |');
    buffer.writeln();

    buffer.writeln('## Docked Panels');
    buffer.writeln();
    buffer.writeln('| Panel ID | Title | Area | Collapsible |');
    buffer.writeln('|---|---|---|:---:|');
    for (final p in state.registeredPanels) {
      buffer.writeln(
          '| `${p.panelId}` | ${p.title} | `${p.area.id}` | ${p.isCollapsible ? "Yes" : "No"} |');
    }
    buffer.writeln();

    return buffer.toString();
  }
}
