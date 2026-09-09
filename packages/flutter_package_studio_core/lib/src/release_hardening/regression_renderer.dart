/// Multi-format (ASCII Test Matrix, Markdown, JSON) renderer for Phase 11.3: Full Regression Testing.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/release_hardening/regression_models.dart';

/// Formatter generating ASCII Regression test matrices, Markdown reports, and JSON schemas.
class RegressionTestRenderer {
  /// Render regression report as structured JSON.
  static String renderJson(RegressionTestReport report, {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(report.toJson());
  }

  /// Render ASCII Regression Test Matrix Dashboard.
  static String renderAsciiRegressionDashboard(RegressionTestReport report) {
    final buffer = StringBuffer();

    buffer.writeln(
        '┌────────────────────────────────────────────────────────────┐');
    buffer.writeln(
        '│ PHASE 11.3 — FULL REGRESSION TEST MATRIX                   │');
    buffer.writeln(
        '├────────────────────────────────────────────────────────────┤');

    for (final item in report.testItems) {
      final nameStr = item.category.label.padRight(36);
      final sym = item.status.symbol;
      final statusStr = item.status.label.padRight(4);
      buffer.writeln('│ $nameStr $sym $statusStr      │');
    }

    buffer.writeln(
        '├────────────────────────────────────────────────────────────┤');
    buffer.writeln(
        '│ Total Tests Run: ${report.totalTestsRun.toString().padRight(4)} | Code Coverage: ${("${report.coveragePercentage.toStringAsFixed(1)}%").padRight(6)} | Status: ${report.isRegressionPassed ? "PASSED" : "FAILED"}   │');
    buffer.writeln(
        '│ Target Release: ${(report.isRegressionPassed ? "v${report.targetVersion} (CERTIFIED)" : "BLOCKED").padRight(42)} │');
    buffer.writeln(
        '└────────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render comprehensive Regression Test Report as clean Markdown documentation.
  static String renderMarkdown(RegressionTestReport report) {
    final buffer = StringBuffer();

    buffer
        .writeln('# Milestone 11 — Phase 11.3: Full Regression Testing Report');
    buffer.writeln();
    buffer.writeln(
        '**Regression Suite Status:** `${report.isRegressionPassed ? "PASSED (100% Green)" : "FAILED"}`  ');
    buffer.writeln('**Target Release Version:** `v${report.targetVersion}`  ');
    buffer.writeln(
        '**Total Automated Tests Executed:** `${report.totalTestsRun}`  ');
    buffer.writeln(
        '**Line Coverage:** `${report.coveragePercentage.toStringAsFixed(1)}%`  ');
    buffer.writeln('**Tested At:** ${report.testedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Regression Matrix Breakdown');
    buffer.writeln();
    buffer.writeln(
        '| Category | Command | Status | Duration | Verification Details |');
    buffer.writeln('|---|---|:---:|:---:|---|');
    for (final item in report.testItems) {
      buffer.writeln(
          '| **${item.category.label}** | `${item.command}` | ${item.status.symbol} `${item.status.label}` | ${item.durationMs}ms | ${item.verificationDetails} |');
    }
    buffer.writeln();

    buffer.writeln('## Next Phase');
    buffer.writeln();
    buffer.writeln('**Phase 11.4 — Platform Verification**');
    buffer.writeln();

    return buffer.toString();
  }
}
