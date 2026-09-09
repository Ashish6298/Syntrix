/// Multi-format (ASCII Profiler Dashboard, Markdown, JSON) renderer for Phase 10.10: Performance Profiler.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/profiler/studio_profiler_models.dart';

/// Formatter generating ASCII Performance breakdown wireframes, Markdown comparison sheets, and JSON schemas.
class StudioProfilerRenderer {
  /// Render snapshot as structured JSON.
  static String renderJson(PerformanceSnapshot snapshot, {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(snapshot.toJson());
  }

  /// Render ASCII Performance Profiler breakdown wireframe.
  static String renderAsciiProfiler(PerformanceSnapshot snapshot,
      {ProfilerMode mode = ProfilerMode.live}) {
    final buffer = StringBuffer();
    final t = snapshot.timings;

    buffer
        .writeln('┌────────────────────────────────────────────────────────┐');
    buffer.writeln(
        '│ PERFORMANCE PROFILER: [MODE: ${mode.label.padRight(12)}] │');
    buffer
        .writeln('├────────────────────────────────────────────────────────┤');
    buffer.writeln('│ Target Loader: ${snapshot.loaderId.padRight(39)} │');
    buffer.writeln(
        '│ Live FPS:      ${snapshot.fps.toStringAsFixed(1).padRight(6)} (Frame: ${snapshot.frameTimeMs.toStringAsFixed(1)}ms)${"".padRight(19)} │');
    buffer.writeln(
        '│ Object Count:  ${snapshot.simulatedObjectCount.toString().padRight(39)} │');
    buffer
        .writeln('├────────────────────────────────────────────────────────┤');
    buffer
        .writeln('│ Subsystem Frame Processing Breakdown:                  │');
    buffer.writeln(
        '│  • Animation Processing:   ${t.animationProcessingMs.toStringAsFixed(2).padLeft(6)} ms                 │');
    buffer.writeln(
        '│  • Particle Processing:    ${t.particleProcessingMs.toStringAsFixed(2).padLeft(6)} ms                 │');
    buffer.writeln(
        '│  • Physics Processing:     ${t.physicsProcessingMs.toStringAsFixed(2).padLeft(6)} ms                 │');
    buffer.writeln(
        '│  • Canvas Render Pass:     ${t.renderingDrawPassMs.toStringAsFixed(2).padLeft(6)} ms                 │');
    buffer.writeln(
        '│  • GPU Shader Execution:   ${t.shaderExecutionMs.toStringAsFixed(2).padLeft(6)} ms                 │');
    buffer
        .writeln('│  ──────────────────────────────────────────            │');
    buffer.writeln(
        '│  Total Processing:         ${t.totalCpuGpuDurationMs.toStringAsFixed(2).padLeft(6)} ms                 │');
    buffer
        .writeln('├────────────────────────────────────────────────────────┤');
    buffer
        .writeln('│ Actions: [Take Snapshot] [Compare] [History] [Export]  │');
    buffer
        .writeln('└────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render performance snapshot comparison delta as clean Markdown documentation.
  static String renderComparisonMarkdown(
      PerformanceDeltaComparison comparison) {
    final buffer = StringBuffer();
    final b = comparison.before;
    final a = comparison.after;

    buffer.writeln('# Performance Snapshot Comparison');
    buffer.writeln();
    buffer.writeln(
        'Comparing before (`${b.label}`) vs after (`${a.label}`) configuration changes.');
    buffer.writeln();

    buffer.writeln('| Metric | Before | After | Delta |');
    buffer.writeln('|---|:---:|:---:|:---:|');
    buffer.writeln(
        '| **FPS** | `${b.fps.toStringAsFixed(1)}` | `${a.fps.toStringAsFixed(1)}` | `${comparison.fpsDelta >= 0 ? "+" : ""}${comparison.fpsDelta.toStringAsFixed(1)} FPS` |');
    buffer.writeln(
        '| **Frame Time** | `${b.frameTimeMs.toStringAsFixed(2)} ms` | `${a.frameTimeMs.toStringAsFixed(2)} ms` | `${comparison.frameTimeDeltaMs >= 0 ? "+" : ""}${comparison.frameTimeDeltaMs.toStringAsFixed(2)} ms` |');
    buffer.writeln(
        '| **Simulated Objects** | `${b.simulatedObjectCount}` | `${a.simulatedObjectCount}` | `${comparison.objectCountDelta >= 0 ? "+" : ""}${comparison.objectCountDelta}` |');
    buffer.writeln(
        '| **Total Processing Time** | `${b.timings.totalCpuGpuDurationMs.toStringAsFixed(2)} ms` | `${a.timings.totalCpuGpuDurationMs.toStringAsFixed(2)} ms` | `${comparison.totalProcessingDeltaMs >= 0 ? "+" : ""}${comparison.totalProcessingDeltaMs.toStringAsFixed(2)} ms` |');
    buffer.writeln();

    buffer.writeln('## Subsystem Timings Breakdown');
    buffer.writeln();
    buffer.writeln('| Subsystem | Before (ms) | After (ms) |');
    buffer.writeln('|---|:---:|:---:|');
    buffer.writeln(
        '| Animation Processing | `${b.timings.animationProcessingMs}` | `${a.timings.animationProcessingMs}` |');
    buffer.writeln(
        '| Particle Processing | `${b.timings.particleProcessingMs}` | `${a.timings.particleProcessingMs}` |');
    buffer.writeln(
        '| Physics Processing | `${b.timings.physicsProcessingMs}` | `${a.timings.physicsProcessingMs}` |');
    buffer.writeln(
        '| Canvas Render Pass | `${b.timings.renderingDrawPassMs}` | `${a.timings.renderingDrawPassMs}` |');
    buffer.writeln(
        '| Shader Execution | `${b.timings.shaderExecutionMs}` | `${a.timings.shaderExecutionMs}` |');
    buffer.writeln();

    return buffer.toString();
  }
}
