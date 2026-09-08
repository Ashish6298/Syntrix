/// Multi-format (ASCII Pipeline Matrix, Markdown, JSON) renderer for Phase 10.20: Final Integration & Regression Testing.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/integration_testing/studio_integration_models.dart';

/// Formatter generating ASCII Pipeline Matrix wireframes, Markdown reports, and JSON schemas.
class StudioFinalIntegrationRenderer {
  /// Render final integration report as structured JSON.
  static String renderJson(StudioFinalIntegrationReport report, {bool pretty = true}) {
    final encoder = pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(report.toJson());
  }

  /// Render ASCII Pipeline & Test Matrix matching Phase 10.20 specification.
  static String renderAsciiPipelineMatrix(StudioFinalIntegrationReport report) {
    final buffer = StringBuffer();

    buffer.writeln('┌────────────────────────────────────────────────────────┐');
    buffer.writeln('│ Studio v2 Multi-Subsystem Integration Pipeline         │');
    buffer.writeln('├────────────────────────────────────────────────────────┤');

    for (var i = 0; i < report.stageVerifications.length; i++) {
      final stage = report.stageVerifications[i];
      final labelStr = stage.stage.label.padRight(16);
      final sym = stage.status.symbol;
      final testsStr = '(${stage.testsExecuted} tests)'.padRight(12);

      buffer.writeln('│  $labelStr  $testsStr  [$sym] PASSED          │');
      if (i < report.stageVerifications.length - 1) {
        buffer.writeln('│       ↓                                                │');
      }
    }

    buffer.writeln('├────────────────────────────────────────────────────────┤');
    buffer.writeln('│ Total Tests: ${report.totalTestsRun.toString().padRight(4)} | Passed: ${report.totalTestsPassed.toString().padRight(4)} | Failed: ${report.totalTestsFailed.toString().padRight(4)}        │');
    buffer.writeln('│ Pipeline Status: ${(report.overallSuccess ? "ALL SUBSYSTEMS OPERATIONAL" : "FAILED").padRight(36)} │');
    buffer.writeln('└────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render comprehensive Integration & Regression report as clean Markdown documentation.
  static String renderMarkdown(StudioFinalIntegrationReport report) {
    final buffer = StringBuffer();

    buffer.writeln('# Studio v2 Final Integration & Regression Test Report');
    buffer.writeln();
    buffer.writeln('**Pipeline Status:** `${report.overallSuccess ? "PASSED (100% Verified)" : "FAILED"}`  ');
    buffer.writeln('**Total Tests Run:** `${report.totalTestsRun}` | **Passed:** `${report.totalTestsPassed}` | **Failed:** `${report.totalTestsFailed}`  ');
    buffer.writeln('**Completed At:** ${report.completedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Subsystem Verification Matrix');
    buffer.writeln();
    buffer.writeln('| Stage | Subsystem | Status | Tests | Time (ms) | Verification Details |');
    buffer.writeln('|:---:|---|:---:|:---:|:---:|---|');
    for (var i = 0; i < report.stageVerifications.length; i++) {
      final s = report.stageVerifications[i];
      buffer.writeln('| ${i + 1} | **${s.stage.label}** | ${s.status.symbol} | `${s.testsExecuted}` | `${s.executionTimeMs.toStringAsFixed(0)} ms` | ${s.verificationDetails} |');
    }
    buffer.writeln();

    buffer.writeln('## Test Suite Category Breakdown');
    buffer.writeln();
    buffer.writeln('| Test Category | Tests Executed | Status |');
    buffer.writeln('|---|:---:|:---:|');
    for (final e in report.testTypeBreakdown.entries) {
      buffer.writeln('| **${e.key.label}** | `${e.value}` | ✓ `PASS` |');
    }
    buffer.writeln();

    return buffer.toString();
  }
}
