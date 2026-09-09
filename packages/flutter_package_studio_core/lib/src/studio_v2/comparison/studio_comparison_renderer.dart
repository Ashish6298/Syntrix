/// Multi-format (ASCII Dual Viewport Wireframe, Markdown, JSON) renderer for Phase 10.14: Comparison Laboratory.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/comparison/studio_comparison_models.dart';

/// Formatter generating ASCII Side-by-Side Viewport wireframes, Markdown comparison matrix tables, and JSON schemas.
class StudioComparisonRenderer {
  /// Render comparison session as structured JSON.
  static String renderJson(LoaderComparisonSession session,
      {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(session.toJson());
  }

  /// Render ASCII Side-by-Side comparison wireframe exactly matching Phase 10.14 specification.
  static String renderAsciiComparison(LoaderComparisonSession session) {
    final buffer = StringBuffer();
    final p = session.primary;
    final s = session.secondary;

    buffer.writeln(
        '┌─────────────────────────────┬─────────────────────────────┐');
    buffer.writeln(
        '│ ${p.displayName.padRight(27)} │ ${s.displayName.padRight(27)} │');
    buffer.writeln(
        '│                             │                             │');
    buffer.writeln(
        '│ FPS:             ${p.fps.toStringAsFixed(0).padRight(10)} │ FPS:             ${s.fps.toStringAsFixed(0).padRight(10)} │');
    buffer.writeln(
        '│ Particles:       ${p.particleCount.toString().padRight(10)} │ Particles:       ${s.particleCount.toString().padRight(10)} │');
    buffer.writeln(
        '│ Physics:         ${(p.hasPhysics ? "Yes" : "No").padRight(10)} │ Physics:         ${(s.hasPhysics ? "Yes" : "No").padRight(10)} │');
    buffer.writeln(
        '│ Shaders:         ${(p.hasShaders ? "Yes" : "No").padRight(10)} │ Shaders:         ${(s.hasShaders ? "Yes" : "No").padRight(10)} │');
    buffer.writeln(
        '│ Draw Pass:       ${p.renderPassMs.toStringAsFixed(1)}ms${"".padRight(8)} │ Draw Pass:       ${s.renderPassMs.toStringAsFixed(1)}ms${"".padRight(8)} │');
    buffer.writeln(
        '└─────────────────────────────┴─────────────────────────────┘');

    return buffer.toString();
  }

  /// Render side-by-side comparison matrix as clean Markdown documentation.
  static String renderMarkdownMatrix(LoaderComparisonSession session) {
    final buffer = StringBuffer();
    final p = session.primary;
    final s = session.secondary;

    buffer.writeln('# Loader Comparison Laboratory Report');
    buffer.writeln();
    buffer.writeln(
        'Side-by-side comparison between **${p.displayName}** and **${s.displayName}**.');
    buffer.writeln();

    buffer.writeln(
        '| Comparison Metric | ${p.displayName} (`${p.loaderId}`) | ${s.displayName} (`${s.loaderId}`) | Delta (Secondary - Primary) |');
    buffer.writeln('|---|:---:|:---:|:---:|');
    buffer.writeln(
        '| **FPS Performance** | `${p.fps.toStringAsFixed(1)} FPS` | `${s.fps.toStringAsFixed(1)} FPS` | `${session.fpsDelta >= 0 ? "+" : ""}${session.fpsDelta.toStringAsFixed(1)} FPS` |');
    buffer.writeln(
        '| **Active Particles** | `${p.particleCount}` | `${s.particleCount}` | `${session.particleDelta >= 0 ? "+" : ""}${session.particleDelta}` |');
    buffer.writeln(
        '| **Canvas Draw Pass** | `${p.renderPassMs.toStringAsFixed(2)} ms` | `${s.renderPassMs.toStringAsFixed(2)} ms` | `${session.renderPassDeltaMs >= 0 ? "+" : ""}${session.renderPassDeltaMs.toStringAsFixed(2)} ms` |');
    buffer.writeln(
        '| **Physics Engine** | `${p.hasPhysics ? "Active" : "Disabled"}` | `${s.hasPhysics ? "Active" : "Disabled"}` | — |');
    buffer.writeln(
        '| **GPU Shaders** | `${p.hasShaders ? "Active" : "Disabled"}` | `${s.hasShaders ? "Active" : "Disabled"}` | — |');
    buffer.writeln(
        '| **Interaction** | `${p.isInteractive ? "Interactive" : "Static"}` | `${s.isInteractive ? "Interactive" : "Static"}` | — |');
    buffer.writeln();

    buffer.writeln('## Supported Feature Matrix');
    buffer.writeln();
    buffer.writeln('- **${p.displayName}:** ${p.supportedFeatures.join(", ")}');
    buffer.writeln('- **${s.displayName}:** ${s.supportedFeatures.join(", ")}');
    buffer.writeln();

    return buffer.toString();
  }
}
