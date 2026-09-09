/// Multi-format (ASCII Accessibility Matrix, Markdown, JSON) renderer for Phase 10.19: UX & Accessibility Hardening.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/ux_hardening/studio_ux_models.dart';

/// Formatter generating ASCII Accessibility Matrix dashboards, Markdown audit logs, and JSON schemas.
class StudioUxRenderer {
  /// Render UX audit report as structured JSON.
  static String renderJson(StudioUxHardeningReport report,
      {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(report.toJson());
  }

  /// Render ASCII UX & Accessibility Hardening dashboard.
  static String renderAsciiDashboard(StudioUxHardeningReport report) {
    final buffer = StringBuffer();

    buffer.writeln(
        '┌────────────────────────────────────────────────────────────┐');
    buffer.writeln(
        '│ Studio UX & Accessibility Hardening Matrix                 │');
    buffer.writeln(
        '├────────────────────────────────────────────────────────────┤');

    for (final item in report.auditItems) {
      final nameStr = item.dimension.label.padRight(36);
      final sym = item.status.symbol;
      buffer.writeln('│ • $nameStr [$sym] Verified │');
    }

    buffer.writeln(
        '├────────────────────────────────────────────────────────────┤');
    buffer.writeln(
        '│ Overall Compliance: ${(report.overallCompliant ? "PRODUCTION READY (PASS)" : "FAIL").padRight(38)} │');
    buffer.writeln(
        '└────────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render UX & Accessibility Hardening report as clean Markdown documentation.
  static String renderMarkdown(StudioUxHardeningReport report) {
    final buffer = StringBuffer();

    buffer.writeln('# Studio UX & Accessibility Hardening Report');
    buffer.writeln();
    buffer.writeln(
        '**Audit Status:** `${report.overallCompliant ? "PASSED (Production-Grade)" : "FAILED"}`  ');
    buffer.writeln('**Audited At:** ${report.auditedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Verification & Hardening Dimension Matrix');
    buffer.writeln();
    buffer.writeln(
        '| Dimension | Status | Min Contrast | Keyboard | Compliance Verification Details |');
    buffer.writeln('|---|:---:|:---:|:---:|---|');
    for (final i in report.auditItems) {
      buffer.writeln(
          '| **${i.dimension.label}** | ${i.status.symbol} | `${i.minimumContrastRatio}:1` | ${i.keyboardAccessible ? "Yes" : "No"} | ${i.complianceDetails} |');
    }
    buffer.writeln();

    return buffer.toString();
  }
}
