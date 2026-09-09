/// Multi-format (ASCII Performance Matrix, Markdown, JSON) renderer for Phase 11.5: Performance Certification.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/release_hardening/performance_certification_models.dart';

/// Formatter generating ASCII Performance Matrix dashboards, Markdown reports, and JSON schemas.
class PerformanceCertificationRenderer {
  /// Render performance certification report as structured JSON.
  static String renderJson(PerformanceCertificationReport report,
      {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(report.toJson());
  }

  /// Render ASCII Performance Matrix Dashboard.
  static String renderAsciiPerformanceDashboard(
      PerformanceCertificationReport report) {
    final buffer = StringBuffer();

    buffer.writeln(
        '┌────────────────────────────────────────────────────────────┐');
    buffer.writeln(
        '│ PHASE 11.5 — PERFORMANCE CERTIFICATION BASELINES           │');
    buffer.writeln(
        '├────────────────────────────────────────────────────────────┤');
    buffer.writeln(
        '│ Metric                      Low-End     Normal      High-End│');
    buffer.writeln(
        '├────────────────────────────────────────────────────────────┤');

    final low =
        report.profiles.firstWhere((p) => p.tier == HardwareProfileTier.lowEnd);
    final norm =
        report.profiles.firstWhere((p) => p.tier == HardwareProfileTier.normal);
    final high = report.profiles
        .firstWhere((p) => p.tier == HardwareProfileTier.highEnd);

    buffer.writeln(
        '│ Target FPS                  ${low.fps.toStringAsFixed(1).padRight(11)} ${norm.fps.toStringAsFixed(1).padRight(11)} ${high.fps.toStringAsFixed(1).padRight(7)} │');
    buffer.writeln(
        '│ Frame Time (ms)             ${low.frameTimeMs.toStringAsFixed(1).padRight(11)} ${norm.frameTimeMs.toStringAsFixed(1).padRight(11)} ${high.frameTimeMs.toStringAsFixed(1).padRight(7)} │');
    buffer.writeln(
        '│ CPU Usage (%)               ${("${low.cpuUsagePercentage}%").padRight(11)} ${("${norm.cpuUsagePercentage}%").padRight(11)} ${("${high.cpuUsagePercentage}%").padRight(7)} │');
    buffer.writeln(
        '│ GPU Workload (%)            ${("${low.gpuWorkloadPercentage}%").padRight(11)} ${("${norm.gpuWorkloadPercentage}%").padRight(11)} ${("${high.gpuWorkloadPercentage}%").padRight(7)} │');
    buffer.writeln(
        '│ Memory Usage (MB)           ${("${low.memoryUsageMb}MB").padRight(11)} ${("${norm.memoryUsageMb}MB").padRight(11)} ${("${high.memoryUsageMb}MB").padRight(7)} │');
    buffer.writeln(
        '│ Allocation Rate (MB/s)      ${("${low.allocationRateMbPerSec}MB/s").padRight(11)} ${("${norm.allocationRateMbPerSec}MB/s").padRight(11)} ${("${high.allocationRateMbPerSec}MB/s").padRight(7)} │');
    buffer.writeln(
        '│ GC Pressure (events/min)    ${low.gcPressureEventsPerMin.toStringAsFixed(1).padRight(11)} ${norm.gcPressureEventsPerMin.toStringAsFixed(1).padRight(11)} ${high.gcPressureEventsPerMin.toStringAsFixed(1).padRight(7)} │');
    buffer.writeln(
        '│ Particle Capacity           ${low.particleCount.toString().padRight(11)} ${norm.particleCount.toString().padRight(11)} ${high.particleCount.toString().padRight(7)} │');
    buffer.writeln(
        '│ Rendering Cost (ms)         ${("${low.renderingCostMs}ms").padRight(11)} ${("${norm.renderingCostMs}ms").padRight(11)} ${("${high.renderingCostMs}ms").padRight(7)} │');
    buffer.writeln(
        '│ Startup Time (ms)           ${("${low.startupTimeMs}ms").padRight(11)} ${("${norm.startupTimeMs}ms").padRight(11)} ${("${high.startupTimeMs}ms").padRight(7)} │');

    buffer.writeln(
        '├────────────────────────────────────────────────────────────┤');
    buffer.writeln(
        '│ Overall Certification: ${(report.isOverallCertified ? "CERTIFIED (ALL TIERS PASS)" : "FAILED").padRight(35)} │');
    buffer.writeln(
        '└────────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render comprehensive Performance Certification Report as clean Markdown documentation.
  static String renderMarkdown(PerformanceCertificationReport report) {
    final buffer = StringBuffer();

    buffer.writeln(
        '# Milestone 11 — Phase 11.5: Performance Certification Report');
    buffer.writeln();
    buffer.writeln(
        '**Performance Certification Status:** `${report.isOverallCertified ? "CERTIFIED (Real Empirical Baselines)" : "FAILED"}`  ');
    buffer.writeln('**Target Release Version:** `v${report.targetVersion}`  ');
    buffer.writeln('**Certified At:** ${report.certifiedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Empirical Performance Baselines Matrix');
    buffer.writeln();
    buffer.writeln(
        '| Telemetry Metric | Low-End Tier | Normal Tier | High-End Tier | Target / SLA |');
    buffer.writeln('|---|:---:|:---:|:---:|:---:|');

    final low =
        report.profiles.firstWhere((p) => p.tier == HardwareProfileTier.lowEnd);
    final norm =
        report.profiles.firstWhere((p) => p.tier == HardwareProfileTier.normal);
    final high = report.profiles
        .firstWhere((p) => p.tier == HardwareProfileTier.highEnd);

    buffer.writeln(
        '| **FPS** | `${low.fps.toStringAsFixed(1)}` | `${norm.fps.toStringAsFixed(1)}` | `${high.fps.toStringAsFixed(1)}` | `>= 58.0 FPS` |');
    buffer.writeln(
        '| **Frame Time** | `${low.frameTimeMs}ms` | `${norm.frameTimeMs}ms` | `${high.frameTimeMs}ms` | `<= 16.6ms` |');
    buffer.writeln(
        '| **CPU Usage** | `${low.cpuUsagePercentage}%` | `${norm.cpuUsagePercentage}%` | `${high.cpuUsagePercentage}%` | `<= 20.0%` |');
    buffer.writeln(
        '| **GPU Workload** | `${low.gpuWorkloadPercentage}%` | `${norm.gpuWorkloadPercentage}%` | `${high.gpuWorkloadPercentage}%` | `<= 30.0%` |');
    buffer.writeln(
        '| **Memory Usage** | `${low.memoryUsageMb} MB` | `${norm.memoryUsageMb} MB` | `${high.memoryUsageMb} MB` | `<= 100 MB` |');
    buffer.writeln(
        '| **Allocation Rate** | `${low.allocationRateMbPerSec} MB/s` | `${norm.allocationRateMbPerSec} MB/s` | `${high.allocationRateMbPerSec} MB/s` | `<= 5.0 MB/s` |');
    buffer.writeln(
        '| **GC Pressure** | `${low.gcPressureEventsPerMin}/min` | `${norm.gcPressureEventsPerMin}/min` | `${high.gcPressureEventsPerMin}/min` | `<= 1.0/min` |');
    buffer.writeln(
        '| **Particle Count** | `${low.particleCount}` | `${norm.particleCount}` | `${high.particleCount}` | Scaled |');
    buffer.writeln(
        '| **Rendering Cost** | `${low.renderingCostMs}ms` | `${norm.renderingCostMs}ms` | `${high.renderingCostMs}ms` | `<= 8.0ms` |');
    buffer.writeln(
        '| **Startup Time** | `${low.startupTimeMs}ms` | `${norm.startupTimeMs}ms` | `${high.startupTimeMs}ms` | `<= 250ms` |');
    buffer.writeln();

    buffer.writeln('## Next Phase');
    buffer.writeln();
    buffer.writeln('**Phase 11.6 — Stress & Soak Testing**');
    buffer.writeln();

    return buffer.toString();
  }
}
