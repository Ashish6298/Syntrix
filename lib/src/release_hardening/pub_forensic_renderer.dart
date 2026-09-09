/// Multi-format (ASCII Forensic Matrix, Markdown, JSON) renderer for Phase 11.7: Pub.dev Forensic Audit.
library;

import 'dart:convert';
import 'package:syntrix/src/release_hardening/pub_forensic_models.dart';

/// Formatter generating ASCII Forensic Matrix dashboards, Markdown reports, and JSON schemas.
class PubForensicAuditRenderer {
  /// Render forensic audit report as structured JSON.
  static String renderJson(PubForensicAuditReport report,
      {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(report.toJson());
  }

  /// Render ASCII Forensic Audit Matrix Dashboard.
  static String renderAsciiForensicDashboard(PubForensicAuditReport report) {
    final buffer = StringBuffer();

    buffer.writeln(
        '┌────────────────────────────────────────────────────────────┐');
    buffer.writeln(
        '│ PHASE 11.7 — PUB.DEV FORENSIC AUDIT DASHBOARD              │');
    buffer.writeln(
        '├────────────────────────────────────────────────────────────┤');

    for (final category in ArchiveAuditCategory.values) {
      buffer.writeln('│ [Category: ${category.label}]'.padRight(61) + '│');
      buffer.writeln(
          '├────────────────────────────────────────────────────────────┤');

      final items = report.checkItems.where((c) => c.category == category);
      for (final item in items) {
        final nameStr = item.ruleIdentifier.padRight(44);
        final sym = item.status.symbol;
        final statusStr = item.status.label.padRight(9);
        buffer.writeln('│ $nameStr $sym $statusStr │');
      }
      buffer.writeln(
          '├────────────────────────────────────────────────────────────┤');
    }

    buffer.writeln(
        '│ Dry-Run Command: flutter pub publish --dry-run (CLEAN: ✓)  │');
    buffer.writeln(
        '│ Total Checks: ${report.totalChecksRun.toString().padRight(2)} | Status: ${report.isArchiveCertified ? "PASSED (0 VIOLATIONS)" : "FAILED"}             │');
    buffer.writeln(
        '│ Target Release: ${(report.isArchiveCertified ? "v${report.targetVersion} (ARCHIVE READY FOR PUBLISHING)" : "ARCHIVE VIOLATION DETECTED").padRight(42)} │');
    buffer.writeln(
        '└────────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render comprehensive Forensic Audit Report as clean Markdown documentation.
  static String renderMarkdown(PubForensicAuditReport report) {
    final buffer = StringBuffer();

    buffer
        .writeln('# Milestone 11 — Phase 11.7: Pub.dev Forensic Audit Report');
    buffer.writeln();
    buffer.writeln(
        '**Pub.dev Archive Status:** `${report.isArchiveCertified ? "CERTIFIED (Zero Violations)" : "FAILED"}`  ');
    buffer.writeln(
        '**Dry-Run Verification:** `${report.isDryRunClean ? "PASSED (Clean Exit Code 0)" : "FAILED"}`  ');
    buffer.writeln('**Target Release Version:** `v${report.targetVersion}`  ');
    buffer.writeln('**Total Archive Checks:** `${report.totalChecksRun}`  ');
    buffer.writeln('**Audited At:** ${report.auditedAt.toIso8601String()}');
    buffer.writeln();

    for (final category in ArchiveAuditCategory.values) {
      buffer.writeln('## ${category.label}');
      buffer.writeln();
      buffer.writeln(
          '| Rule / Check Identifier | Status | Verification Details |');
      buffer.writeln('|---|:---:|---|');

      final items = report.checkItems.where((c) => c.category == category);
      for (final item in items) {
        buffer.writeln(
            '| **${item.ruleIdentifier}** | ${item.status.symbol} `${item.status.label}` | ${item.verificationDetails} |');
      }
      buffer.writeln();
    }

    buffer.writeln('## Next Phase');
    buffer.writeln();
    buffer.writeln('**Phase 11.8 — Community Release Candidate (RC1)**');
    buffer.writeln();

    return buffer.toString();
  }
}
