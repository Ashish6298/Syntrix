/// Multi-format (ASCII Environment Wireframe, Markdown, JSON) renderer for Phase 10.16: Environment Center.
library;

import 'dart:convert';
import 'package:syntrix/src/studio_v2/environment/studio_environment_models.dart';

/// Formatter generating ASCII Environment wireframes, Markdown platform support sheets, and JSON schemas.
class StudioEnvironmentRenderer {
  /// Render environment report as structured JSON.
  static String renderJson(StudioEnvironmentReport report,
      {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(report.toJson());
  }

  /// Render ASCII Environment list wireframe matching Phase 10.16 specification.
  static String renderAsciiEnvironment(StudioEnvironmentReport report) {
    final buffer = StringBuffer();

    buffer.writeln('┌────────────────────────┐');
    buffer.writeln('│ Environment            │');
    buffer.writeln('├────────────────────────┤');
    for (final p in report.platformProfiles) {
      final nameStr = p.platform.label.padRight(12);
      final sym = p.supportStatus.symbol;
      buffer.writeln('│ $nameStr $sym          │');
    }
    buffer.writeln('├────────────────────────┤');
    buffer.writeln('│ Host: ${report.activeHostPlatform.padRight(16)} │');
    buffer.writeln('└────────────────────────┘');

    return buffer.toString();
  }

  /// Render platform profiles as clean Markdown documentation.
  static String renderMarkdown(StudioEnvironmentReport report) {
    final buffer = StringBuffer();

    buffer.writeln('# Cross-Platform Environment Center Report');
    buffer.writeln();
    buffer.writeln('**Active Host:** `${report.activeHostPlatform}`  ');
    buffer.writeln('**Inspected At:** ${report.inspectedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Supported Platforms & Capability Matrix');
    buffer.writeln();
    buffer.writeln(
        '| Platform | Status | Renderer Backend | Shaders | Diagnostics | Limitations |');
    buffer.writeln('|---|:---:|---|:---:|:---:|---|');
    for (final p in report.platformProfiles) {
      final statusBadge = p.supportStatus == PlatformCapabilityStatus.verified
          ? 'Verified `✓`'
          : p.supportStatus.name;
      final limitations =
          p.knownLimitations.isEmpty ? 'None' : p.knownLimitations.join('; ');
      buffer.writeln(
          '| **${p.platform.label}** | $statusBadge | `${p.rendererBackend ?? "Auto"}` | ${p.shadersSupported ? "Yes" : "No"} | ${p.diagnosticsSupported ? "Yes" : "No"} | $limitations |');
    }
    buffer.writeln();

    buffer.writeln('## Feature Breakdown by Platform');
    buffer.writeln();
    for (final p in report.platformProfiles) {
      buffer.writeln('### ${p.platform.label}');
      buffer.writeln('- **Renderer:** `${p.rendererBackend}`');
      buffer.writeln('- **Features:** ${p.supportedFeatures.join(", ")}');
      if (p.knownLimitations.isNotEmpty) {
        buffer.writeln('- **Limitations:** ${p.knownLimitations.join(", ")}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
