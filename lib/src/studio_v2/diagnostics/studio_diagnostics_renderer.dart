/// Multi-format (ASCII Dashboard, Markdown, JSON) renderer for Phase 10.9: Diagnostics & Performance Center.
library;

import 'dart:convert';
import 'package:syntrix/src/studio_v2/diagnostics/studio_diagnostics_models.dart';

/// Formatter generating ASCII Diagnostics dashboard, Markdown reports, and JSON schemas.
class StudioDiagnosticsRenderer {
  /// Render snapshot as structured JSON.
  static String renderJson(DiagnosticsDashboardSnapshot snapshot,
      {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(snapshot.toJson());
  }

  /// Render ASCII Diagnostics Dashboard exactly as specified in Milestone 10.9 mockup.
  static String renderAsciiDashboard(DiagnosticsDashboardSnapshot snapshot) {
    final buffer = StringBuffer();

    buffer
        .writeln('┌────────────────────────────────────────────────────────┐');
    buffer
        .writeln('│          DIAGNOSTICS & PERFORMANCE CENTER              │');
    buffer
        .writeln('├────────────────────────────────────────────────────────┤');
    buffer
        .writeln('│ Diagnostics Subsystems                                 │');
    buffer
        .writeln('│ ──────────────────────                                 │');

    for (final h in snapshot.healthItems) {
      buffer.writeln(
          '│ ${h.subsystem.padRight(20)} ${h.status.symbol.padLeft(4)}${"".padRight(30)} │');
    }

    buffer
        .writeln('│                                                        │');
    buffer
        .writeln('│ Performance Telemetry                                  │');
    buffer
        .writeln('│ ─────────────────────                                  │');
    buffer.writeln(
        '│ FPS:             ${snapshot.liveFps.toStringAsFixed(0).padLeft(6)}${"".padRight(32)} │');
    buffer.writeln(
        '│ Frame Time:      ${snapshot.liveFrameTimeMs.toStringAsFixed(1)}ms${"".padRight(32)} │');
    buffer.writeln(
        '│ Particle Count:  ${snapshot.activeParticleCount.toString().padLeft(6)}${"".padRight(32)} │');
    buffer.writeln(
        '│ Est. Memory:     ${snapshot.estimatedMemoryMb.toStringAsFixed(1)}MB${"".padRight(32)} │');
    buffer
        .writeln('├────────────────────────────────────────────────────────┤');
    buffer.writeln(
        '│ Exceptions: ${snapshot.recentExceptions.length.toString().padLeft(2)} captured | Logs: ${snapshot.recentLogEntries.length.toString().padLeft(3)} lines recorded       │');
    buffer
        .writeln('│ Actions: [Export Diagnostics] [Clear Logs] [Run Sweep] │');
    buffer
        .writeln('└────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render diagnostics overview as clean Markdown documentation.
  static String renderMarkdown(DiagnosticsDashboardSnapshot snapshot) {
    final buffer = StringBuffer();

    buffer.writeln('# Diagnostics & Performance Center Report');
    buffer.writeln();
    buffer.writeln('**Dashboard ID:** `${snapshot.dashboardId}`  ');
    buffer.writeln('**Captured At:** ${snapshot.capturedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Subsystem Health Checks');
    buffer.writeln();
    buffer.writeln('| Subsystem | Status | Message |');
    buffer.writeln('|---|:---:|---|');
    for (final h in snapshot.healthItems) {
      buffer.writeln(
          '| **${h.subsystem}** | `${h.status.symbol} ${h.status.id.toUpperCase()}` | ${h.message} |');
    }
    buffer.writeln();

    buffer.writeln('## Telemetry Metrics');
    buffer.writeln();
    buffer.writeln('| Metric | Value |');
    buffer.writeln('|---|---|');
    buffer.writeln(
        '| **Live FPS** | `${snapshot.liveFps.toStringAsFixed(1)} FPS` |');
    buffer.writeln(
        '| **Frame Duration** | `${snapshot.liveFrameTimeMs.toStringAsFixed(2)} ms` |');
    buffer
        .writeln('| **Particle Count** | `${snapshot.activeParticleCount}` |');
    buffer.writeln(
        '| **Estimated Memory** | `${snapshot.estimatedMemoryMb.toStringAsFixed(1)} MB` |');
    buffer.writeln();

    if (snapshot.recentExceptions.isNotEmpty) {
      buffer.writeln('## Recent Exceptions');
      buffer.writeln();
      for (final e in snapshot.recentExceptions) {
        buffer.writeln(
            '- ❌ **[${e.context}]** `${e.error}` (${e.timestamp.toIso8601String()})');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
