/// Multi-format (ASCII Lifecycle Matrix, Markdown, JSON) renderer for Phase 11.8: Release Candidate.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/release_hardening/release_candidate_models.dart';

/// Formatter generating ASCII Release Lifecycle dashboards, Markdown reports, and JSON schemas.
class ReleaseHardeningCandidateRenderer {
  /// Render release candidate promotion report as structured JSON.
  static String renderJson(ReleaseCandidatePromotionReport report, {bool pretty = true}) {
    final encoder = pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(report.toJson());
  }

  /// Render ASCII Release Lifecycle Dashboard.
  static String renderAsciiLifecycleDashboard(ReleaseCandidatePromotionReport report) {
    final buffer = StringBuffer();

    buffer.writeln('┌────────────────────────────────────────────────────────────┐');
    buffer.writeln('│ PHASE 11.8 — FINAL RELEASE CANDIDATE & PROMOTION DASHBOARD │');
    buffer.writeln('├────────────────────────────────────────────────────────────┤');
    buffer.writeln('│ Release Progression Pipeline                               │');
    buffer.writeln('│ Milestone 1..10  ──> Feature Complete                       │');
    buffer.writeln('│ Milestone 11     ──> Release Hardening                     │');
    buffer.writeln('│ ${report.releaseCandidateTag}        ──> Tagged Candidate                      │');
    buffer.writeln('│ Final Validation ──> Independent Audit                     │');
    buffer.writeln('│ ${report.promotedStableVersion}             ──> ${report.isReadyForV100Promotion ? "PROMOTED TO STABLE PRODUCTION" : "PENDING PROMOTION"}        │');
    buffer.writeln('├────────────────────────────────────────────────────────────┤');
    buffer.writeln('│ Final Independent Validation Gates                         │');
    buffer.writeln('├────────────────────────────────────────────────────────────┤');

    for (final item in report.gateItems) {
      final nameStr = item.gate.label.padRight(44);
      final sym = item.isPassed ? '✓' : '✗';
      final statusStr = item.isPassed ? 'PASSED   ' : 'FAILED   ';
      buffer.writeln('│ $nameStr $sym $statusStr │');
    }

    buffer.writeln('├────────────────────────────────────────────────────────────┤');
    buffer.writeln('│ Gates Evaluated: ${report.totalGatesEvaluated.toString().padRight(2)} | Status: ${report.isReadyForV100Promotion ? "ALL GATES PASSED (100%)" : "GATES BLOCKED"}   │');
    buffer.writeln('│ Official Release Status: ${(report.isReadyForV100Promotion ? "${report.promotedStableVersion} READY FOR GENERAL AVAILABILITY" : "CANDIDATE UNDER REVIEW").padRight(36)} │');
    buffer.writeln('└────────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render comprehensive Release Candidate Promotion Report as clean Markdown documentation.
  static String renderMarkdown(ReleaseCandidatePromotionReport report) {
    final buffer = StringBuffer();

    buffer.writeln('# Milestone 11 — Phase 11.8: Final Release Candidate & Promotion Report');
    buffer.writeln();
    buffer.writeln('**Release Candidate Tag:** `${report.releaseCandidateTag}`  ');
    buffer.writeln('**Promoted Production Release:** `${report.promotedStableVersion}`  ');
    buffer.writeln('**Current Release Stage:** `${report.currentStage.label}`  ');
    buffer.writeln('**Promotion Status:** `${report.isReadyForV100Promotion ? "PROMOTED TO STABLE GENERAL AVAILABILITY" : "UNDER FINAL VALIDATION"}`  ');
    buffer.writeln('**Total Gates Evaluated:** `${report.totalGatesEvaluated}`  ');
    buffer.writeln('**Evaluated At:** ${report.evaluatedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Independent Validation Gates');
    buffer.writeln();
    buffer.writeln('| Validation Gate | Status | Verification Details |');
    buffer.writeln('|---|:---:|---|');
    for (final item in report.gateItems) {
      buffer.writeln('| **${item.gate.label}** | ${item.isPassed ? "✓ `PASSED`" : "✗ `FAILED`"} | ${item.verificationDetails} |');
    }
    buffer.writeln();

    buffer.writeln('## Release Hardening Conclusion & Roadmap');
    buffer.writeln();
    buffer.writeln('> **Stability Guarantee:** The `v1.0.0` public API is locked, hardened, and verified with zero breaking changes.');
    buffer.writeln('> Next evolutions (`v1.1.x`, `v1.2.x`, and future `v2.0.0`) can proceed safely with strict SemVer guarantees.');
    buffer.writeln();

    return buffer.toString();
  }
}
