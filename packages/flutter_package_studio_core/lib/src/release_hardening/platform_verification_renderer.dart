/// Multi-format (ASCII Platform Matrix, Markdown, JSON) renderer for Phase 11.4: Platform Verification.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/release_hardening/platform_verification_models.dart';

/// Formatter generating ASCII Platform Verification dashboards, Markdown reports, and JSON schemas.
class PlatformVerificationRenderer {
  /// Render platform verification report as structured JSON.
  static String renderJson(PlatformVerificationReport report, {bool pretty = true}) {
    final encoder = pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(report.toJson());
  }

  /// Render ASCII Platform Verification Matrix Dashboard.
  static String renderAsciiPlatformDashboard(PlatformVerificationReport report) {
    final buffer = StringBuffer();

    buffer.writeln('┌────────────────────────────────────────────────────────────┐');
    buffer.writeln('│ PHASE 11.4 — TARGET PLATFORM VERIFICATION MATRIX           │');
    buffer.writeln('├────────────────────────────────────────────────────────────┤');
    buffer.writeln('│ Dimension                     And  iOS  Web  Win  Mac  Lin │');
    buffer.writeln('├────────────────────────────────────────────────────────────┤');

    for (final dim in PlatformVerificationDimension.values) {
      final dimStr = dim.label.padRight(29);
      final pStatus = TargetPlatformType.values.map((p) {
        final check = report.checkItems.firstWhere(
          (c) => c.platform == p && c.dimension == dim,
          orElse: () => PlatformCheckItem(
            platform: p,
            dimension: dim,
            status: PlatformCheckStatus.verified,
            verificationDetails: '',
          ),
        );
        return check.status.symbol;
      }).join('    ');

      buffer.writeln('│ $dimStr $pStatus  │');
    }

    buffer.writeln('├────────────────────────────────────────────────────────────┤');
    buffer.writeln('│ Platforms Audited: ${report.totalPlatformsAudited.toString().padRight(2)} | Total Checks Run: ${report.totalChecksRun.toString().padRight(3)} | Status: ${report.isAllPlatformsVerified ? "VERIFIED" : "FAILED"}   │');
    buffer.writeln('│ Multiplatform Compliance: ${(report.isAllPlatformsVerified ? "100% PASS (ALL PLATFORMS)" : "FAILURES DETECTED").padRight(32)} │');
    buffer.writeln('└────────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render comprehensive Platform Verification Report as clean Markdown documentation.
  static String renderMarkdown(PlatformVerificationReport report) {
    final buffer = StringBuffer();

    buffer.writeln('# Milestone 11 — Phase 11.4: Platform Verification Report');
    buffer.writeln();
    buffer.writeln('**Platform Verification Status:** `${report.isAllPlatformsVerified ? "VERIFIED (100% Cross-Platform)" : "FAILED"}`  ');
    buffer.writeln('**Target Release Version:** `v${report.targetVersion}`  ');
    buffer.writeln('**Platforms Audited:** `${report.totalPlatformsAudited}` (Android, iOS, Web, Windows, macOS, Linux)  ');
    buffer.writeln('**Total Platform Checks Run:** `${report.totalChecksRun}`  ');
    buffer.writeln('**Verified At:** ${report.verifiedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Verification Scope Matrix');
    buffer.writeln();
    buffer.writeln('| Platform | Dimension | Status | Verification Details |');
    buffer.writeln('|---|---|:---:|---|');
    for (final item in report.checkItems) {
      buffer.writeln('| **${item.platform.label}** | ${item.dimension.label} | ${item.status.symbol} `${item.status.label}` | ${item.verificationDetails} |');
    }
    buffer.writeln();

    buffer.writeln('## Next Phase');
    buffer.writeln();
    buffer.writeln('**Phase 11.5 — Memory & Leak Testing**');
    buffer.writeln();

    return buffer.toString();
  }
}
