/// Multi-format (ASCII Interaction Monitor Wireframe, Markdown, JSON) renderer for Phase 10.15: Interaction Laboratory.
library;

import 'dart:convert';
import 'package:syntrix/src/studio_v2/interaction/studio_interaction_models.dart';

/// Formatter generating ASCII Interaction Monitor wireframes, Markdown telemetry sheets, and JSON schemas.
class StudioInteractionRenderer {
  /// Render interaction monitor state as structured JSON.
  static String renderJson(InteractionMonitorState state,
      {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(state.toJson());
  }

  /// Render ASCII Interaction Monitor wireframe matching Phase 10.15 specification.
  static String renderAsciiMonitor(InteractionMonitorState state) {
    final buffer = StringBuffer();

    buffer.writeln('┌──────────────────────────────────────┐');
    buffer.writeln('│ Interaction Monitor                  │');
    buffer.writeln('├──────────────────────────────────────┤');
    buffer.writeln(
        '│ Pointer Position:   ${state.pointerPosition.toString().padRight(16)} │');
    buffer.writeln(
        '│ Gesture State:      ${state.gestureState.label.padRight(16)} │');
    buffer.writeln(
        '│ Scale:              ${state.scale.toStringAsFixed(2)}x${"".padRight(13)} │');
    buffer.writeln(
        '│ Rotation:           ${state.rotationDegrees.toStringAsFixed(1)}°${"".padRight(13)} │');
    buffer.writeln(
        '│ Velocity:           ${state.velocity.toString().padRight(16)} │');
    buffer.writeln(
        '│ Active Interaction: ${(state.isInteractionActive ? "YES" : "NO").padRight(16)} │');
    buffer.writeln('├──────────────────────────────────────┤');
    buffer.writeln('│ Controls: [Touch] [Drag] [Pinch] [↺] │');
    buffer.writeln('└──────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render interaction telemetry as clean Markdown documentation.
  static String renderMarkdown(InteractionMonitorState state) {
    final buffer = StringBuffer();

    buffer.writeln('# Advanced Interaction Laboratory Telemetry');
    buffer.writeln();
    buffer.writeln('**Monitor ID:** `${state.monitorId}`  ');
    buffer.writeln('**Interaction Active:** `${state.isInteractionActive}`  ');
    buffer.writeln('**Recorded At:** ${state.timestamp.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Real-Time Gesture Telemetry');
    buffer.writeln();
    buffer.writeln('| Telemetry Metric | Monitored Value |');
    buffer.writeln('|---|---|');
    buffer.writeln('| **Pointer Position** | `${state.pointerPosition}` |');
    buffer.writeln('| **Gesture State** | `${state.gestureState.label}` |');
    buffer
        .writeln('| **Scale Factor** | `${state.scale.toStringAsFixed(2)}x` |');
    buffer.writeln(
        '| **Rotation Angle** | `${state.rotationDegrees.toStringAsFixed(1)}°` (`${state.rotationRadians.toStringAsFixed(3)} rad`) |');
    buffer.writeln('| **Pointer Velocity** | `${state.velocity}` |');
    buffer.writeln(
        '| **Simulated Inertia** | `${state.simulatedInertia.toStringAsFixed(2)}` |');
    buffer.writeln();

    return buffer.toString();
  }
}
