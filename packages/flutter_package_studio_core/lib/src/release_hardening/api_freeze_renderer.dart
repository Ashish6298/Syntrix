/// Multi-format (ASCII Freeze Matrix, Markdown, JSON) renderer for Phase 11.1: Final API Freeze.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/release_hardening/api_freeze_models.dart';

/// Formatter generating ASCII API Freeze dashboards, Markdown reports, and JSON schemas.
class ApiFreezeRenderer {
  /// Render API freeze audit report as structured JSON.
  static String renderJson(ApiFreezeAuditReport report, {bool pretty = true}) {
    final encoder = pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(report.toJson());
  }

  /// Render ASCII API Freeze Dashboard.
  static String renderAsciiFreezeDashboard(ApiFreezeAuditReport report) {
    final buffer = StringBuffer();

    buffer.writeln('┌────────────────────────────────────────────────────────────┐');
    buffer.writeln('│ PHASE 11.1 — FINAL PUBLIC API FREEZE MATRIX                │');
    buffer.writeln('├────────────────────────────────────────────────────────────┤');

    for (final sym in report.auditedSymbols) {
      final kindStr = '[${sym.kind.label}]'.padRight(14);
      final nameStr = sym.name.padRight(28);
      final statusStr = sym.decision.symbol;
      buffer.writeln('│ $kindStr $nameStr $statusStr FROZEN │');
    }

    buffer.writeln('├────────────────────────────────────────────────────────────┤');
    buffer.writeln('│ Total Audited: ${report.totalSymbolsAudited.toString().padRight(4)} | Public Frozen: ${report.publicSymbolsFrozen.toString().padRight(4)} | Internal: ${report.internalSymbolsRestricted.toString().padRight(4)}   │');
    buffer.writeln('│ API Freeze Status: ${(report.isFrozen ? "FROZEN FOR RELEASE (v${report.targetVersion})" : "UNFROZEN").padRight(39)} │');
    buffer.writeln('└────────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render comprehensive API Freeze Report as clean Markdown documentation.
  static String renderMarkdown(ApiFreezeAuditReport report) {
    final buffer = StringBuffer();

    buffer.writeln('# Milestone 11 — Phase 11.1: Final API Freeze Report');
    buffer.writeln();
    buffer.writeln('**API Freeze Status:** `${report.isFrozen ? "FROZEN (Ready for Release Hardening)" : "UNFROZEN"}`  ');
    buffer.writeln('**Target Release Version:** `v${report.targetVersion}`  ');
    buffer.writeln('**Audited At:** ${report.auditedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Public API Surface Summary');
    buffer.writeln();
    buffer.writeln('- **Total Symbols Audited:** `${report.totalSymbolsAudited}`');
    buffer.writeln('- **Public Symbols Frozen:** `${report.publicSymbolsFrozen}`');
    buffer.writeln('- **Internal Encapsulated Symbols:** `${report.internalSymbolsRestricted}`');
    buffer.writeln();

    buffer.writeln('## Audited Public Symbols Breakdown');
    buffer.writeln();
    buffer.writeln('| Symbol Name | Kind | Defined In | Decision | Stability | Rationale |');
    buffer.writeln('|---|---|---|:---:|:---:|---|');
    for (final sym in report.auditedSymbols) {
      buffer.writeln('| **`${sym.name}`** | ${sym.kind.label} | `${sym.definedInFile}` | ${sym.decision.symbol} `${sym.decision.name}` | ${sym.isStable ? "Stable" : "Evolving"} | ${sym.rationale} |');
    }
    buffer.writeln();

    buffer.writeln('## Next Phase');
    buffer.writeln();
    buffer.writeln('**Phase 11.2 — Breaking-Change Audit**');
    buffer.writeln();

    return buffer.toString();
  }
}
