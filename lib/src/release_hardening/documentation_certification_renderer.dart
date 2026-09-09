/// Multi-format (ASCII Documentation Matrix, Markdown, JSON) renderer for Phase 11.6: Documentation Certification.
library;

import 'dart:convert';
import 'package:syntrix/src/release_hardening/documentation_certification_models.dart';

/// Formatter generating ASCII Documentation Matrix dashboards, Markdown reports, and JSON schemas.
class DocumentationCertificationRenderer {
  /// Render documentation certification report as structured JSON.
  static String renderJson(DocumentationCertificationReport report,
      {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(report.toJson());
  }

  /// Render ASCII Documentation Certification Matrix Dashboard.
  static String renderAsciiDocDashboard(
      DocumentationCertificationReport report) {
    final buffer = StringBuffer();

    buffer.writeln(
        '┌────────────────────────────────────────────────────────────┐');
    buffer.writeln(
        '│ PHASE 11.6 — DOCUMENTATION CERTIFICATION AUDIT             │');
    buffer.writeln(
        '├────────────────────────────────────────────────────────────┤');
    buffer.writeln(
        '│ Mandatory Files                                            │');
    buffer.writeln(
        '├────────────────────────────────────────────────────────────┤');

    for (final item in report.fileItems) {
      final nameStr = item.identifier.padRight(40);
      final sym = item.status.symbol;
      final statusStr = item.status.label.padRight(9);
      buffer.writeln('│ $nameStr $sym $statusStr  │');
    }

    buffer.writeln(
        '├────────────────────────────────────────────────────────────┤');
    buffer.writeln(
        '│ Mandatory Topic Coverage                                   │');
    buffer.writeln(
        '├────────────────────────────────────────────────────────────┤');

    for (final item in report.topicItems) {
      final nameStr = item.identifier.padRight(40);
      final sym = item.status.symbol;
      final statusStr = item.status.label.padRight(9);
      buffer.writeln('│ $nameStr $sym $statusStr  │');
    }

    buffer.writeln(
        '├────────────────────────────────────────────────────────────┤');
    buffer.writeln(
        '│ Files: ${report.totalFilesAudited.toString().padRight(2)} | Topics: ${report.totalTopicsAudited.toString().padRight(2)} | Status: ${report.isDocCertified ? "CERTIFIED" : "FAILED"}                   │');
    buffer.writeln(
        '│ Target Release: ${(report.isDocCertified ? "v${report.targetVersion} (DOCUMENTATION CERTIFIED)" : "DOCUMENTATION INCOMPLETE").padRight(42)} │');
    buffer.writeln(
        '└────────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render comprehensive Documentation Certification Report as clean Markdown documentation.
  static String renderMarkdown(DocumentationCertificationReport report) {
    final buffer = StringBuffer();

    buffer.writeln(
        '# Milestone 11 — Phase 11.6: Documentation Certification Report');
    buffer.writeln();
    buffer.writeln(
        '**Documentation Certification Status:** `${report.isDocCertified ? "CERTIFIED (100% Complete)" : "FAILED"}`  ');
    buffer.writeln('**Target Release Version:** `v${report.targetVersion}`  ');
    buffer.writeln('**Total Files Audited:** `${report.totalFilesAudited}`  ');
    buffer
        .writeln('**Total Topics Audited:** `${report.totalTopicsAudited}`  ');
    buffer.writeln('**Certified At:** ${report.certifiedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Mandatory File Verification');
    buffer.writeln();
    buffer.writeln('| File / Directory | Status | Verification Details |');
    buffer.writeln('|---|:---:|---|');
    for (final item in report.fileItems) {
      buffer.writeln(
          '| `${item.identifier}` | ${item.status.symbol} `${item.status.label}` | ${item.verificationDetails} |');
    }
    buffer.writeln();

    buffer.writeln('## Mandatory Topic Coverage');
    buffer.writeln();
    buffer.writeln('| Topic | Status | Verification Details |');
    buffer.writeln('|---|:---:|---|');
    for (final item in report.topicItems) {
      buffer.writeln(
          '| **${item.identifier}** | ${item.status.symbol} `${item.status.label}` | ${item.verificationDetails} |');
    }
    buffer.writeln();

    buffer.writeln('## Next Phase');
    buffer.writeln();
    buffer.writeln('**Phase 11.7 — Example Application Verification**');
    buffer.writeln();

    return buffer.toString();
  }
}
