/// Multi-format (ASCII Package Health Dashboard, Markdown, JSON) renderer for Phase 10.17: Validation Center.
library;

import 'dart:convert';
import 'package:syntrix/src/studio_v2/validation/studio_validation_models.dart';

/// Formatter generating ASCII Package Health Dashboards, Markdown validation sheets, and JSON schemas.
class StudioValidationRenderer {
  /// Render validation report as structured JSON.
  static String renderJson(StudioValidationReport report,
      {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(report.toJson());
  }

  /// Render ASCII Package Health Dashboard matching Phase 10.17 specification.
  static String renderAsciiDashboard(StudioValidationReport report) {
    final buffer = StringBuffer();

    buffer.writeln('PACKAGE HEALTH');
    buffer.writeln();

    for (final cat in StudioValidationCategory.values) {
      final status =
          report.categorySummaries[cat] ?? ValidationCheckStatus.pass;
      buffer.writeln('${cat.label.padRight(19)}${status.label}');
    }

    buffer.writeln();
    buffer.writeln('Overall: ${report.overallHealth.label}');

    return buffer.toString();
  }

  /// Render comprehensive validation breakdown as clean Markdown documentation.
  static String renderMarkdown(StudioValidationReport report) {
    final buffer = StringBuffer();

    buffer.writeln('# Automated Validation Center — Package Health Report');
    buffer.writeln();
    buffer.writeln(
        '**Package:** `${report.packageName}` v`${report.packageVersion}`  ');
    buffer.writeln(
        '**Overall Health Status:** `${report.overallHealth.label}`  ');
    buffer.writeln('**Validated At:** ${report.validatedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Category Summary Dashboard');
    buffer.writeln();
    buffer.writeln('| Category | Status | Evaluation |');
    buffer.writeln('|---|:---:|:---:|');
    for (final cat in StudioValidationCategory.values) {
      final status =
          report.categorySummaries[cat] ?? ValidationCheckStatus.pass;
      buffer.writeln(
          '| **${cat.label}** | ${status.symbol} | `${status.label}` |');
    }
    buffer.writeln();

    buffer.writeln('## Detailed Check Matrix');
    buffer.writeln();
    buffer.writeln('| Check | Category | Status | Duration | Details |');
    buffer.writeln('|---|---|:---:|:---:|---|');
    for (final c in report.checks) {
      buffer.writeln(
          '| **${c.title}** | ${c.category.label} | ${c.status.symbol} | `${c.durationMs.toStringAsFixed(0)} ms` | ${c.details} |');
    }
    buffer.writeln();

    return buffer.toString();
  }
}
