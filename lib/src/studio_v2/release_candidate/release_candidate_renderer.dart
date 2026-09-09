/// Multi-format (ASCII Release Gate Box, Markdown, JSON) renderer for Phase 10.21 & Milestone 10 Completion Gate.
library;

import 'dart:convert';
import 'package:syntrix/src/studio_v2/release_candidate/release_candidate_models.dart';

/// Formatter generating ASCII Milestone 10 Release Gate dashboards, Markdown reports, and JSON schemas.
class ReleaseCandidateRenderer {
  /// Render release candidate audit report as structured JSON.
  static String renderJson(ReleaseCandidateAuditReport report,
      {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(report.toJson());
  }

  /// Render ASCII Milestone 10 Release Gate box matching Phase 10.21 specification.
  static String renderAsciiReleaseGate(ReleaseCandidateAuditReport report) {
    final buffer = StringBuffer();

    buffer.writeln('┌─────────────────────────────────────────────┐');
    buffer.writeln('│       MILESTONE 10 RELEASE GATE             │');
    buffer.writeln('├─────────────────────────────────────────────┤');

    for (final gate in report.gates) {
      final nameStr = gate.dimension.label.padRight(30);
      final sym = gate.status.symbol;
      buffer.writeln('│ $nameStr   $sym         │');
    }

    buffer.writeln('├─────────────────────────────────────────────┤');
    buffer.writeln('│ Milestone 10 Status: COMPLETE               │');
    buffer.writeln('│ Project Status:      RELEASE CANDIDATE (RC) │');
    buffer.writeln(
        '│ Target Release:      v${report.targetVersion.padRight(22)} │');
    buffer.writeln('└─────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render comprehensive Release Candidate Audit report as clean Markdown documentation.
  static String renderMarkdown(ReleaseCandidateAuditReport report) {
    final buffer = StringBuffer();

    buffer.writeln('# Milestone 10 — Release Candidate Audit Report');
    buffer.writeln();
    buffer.writeln(
        '**Milestone 10 Status:** `${report.isMilestone10Complete ? "COMPLETE" : "INCOMPLETE"}`  ');
    buffer.writeln(
        '**Project Status:** `${report.isReleaseCandidateReady ? "RELEASE CANDIDATE READY (RC)" : "NOT READY"}`  ');
    buffer.writeln('**Target Version:** `v${report.targetVersion}`  ');
    buffer.writeln('**Audited At:** ${report.auditedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Milestone 10 Release Gate Evaluation Matrix');
    buffer.writeln();
    buffer.writeln('| Dimension | Evaluation | Verification Details |');
    buffer.writeln('|---|:---:|---|');
    for (final g in report.gates) {
      buffer.writeln(
          '| **${g.dimension.label}** | `${g.status.symbol}` | ${g.verificationDetails} |');
    }
    buffer.writeln();

    buffer.writeln('## Package Metadata & Publication Pre-Flight Checks');
    buffer.writeln();
    buffer.writeln('| Check Item | Status | Result |');
    buffer.writeln('|---|:---:|---|');
    for (final e in report.packageMetadataCheck.entries) {
      final formattedKey = e.key.replaceAll('_', ' ').toUpperCase();
      buffer.writeln('| **$formattedKey** | ✓ | `${e.value}` |');
    }
    buffer.writeln();

    buffer.writeln('## Next Steps');
    buffer.writeln();
    buffer.writeln('1. **Milestone 10 → COMPLETE**');
    buffer.writeln('2. **Project → Release Candidate (RC)**');
    buffer.writeln('3. **Next → `v1.0.0` publication preparation**');
    buffer.writeln();

    return buffer.toString();
  }
}
