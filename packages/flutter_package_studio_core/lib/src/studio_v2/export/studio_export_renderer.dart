/// Multi-format (ASCII Export Dialog, Markdown, JSON) renderer for Phase 10.13: Export & Import System.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/export/studio_export_models.dart';

/// Formatter generating ASCII Export Dialog wireframes, Markdown export sheets, and JSON schemas.
class StudioExportRenderer {
  /// Render export bundle as structured JSON.
  static String renderJson(StudioExportBundle bundle, {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(bundle.toJson());
  }

  /// Render ASCII Export Dialog wireframe matching Phase 10.13 mockup.
  static String renderAsciiExportDialog(
      ExportTargetEntity target, ExportFormat selectedFormat) {
    final buffer = StringBuffer();
    final jsonRad = selectedFormat == ExportFormat.json ? '●' : '○';
    final dartRad = selectedFormat == ExportFormat.dart ? '●' : '○';
    final mdRad = selectedFormat == ExportFormat.markdown ? '●' : '○';

    buffer.writeln('┌──────────────────────────────────────┐');
    buffer.writeln('│ Export ${target.label.padRight(29)} │');
    buffer.writeln('├──────────────────────────────────────┤');
    buffer.writeln('│ $jsonRad JSON                               │');
    buffer.writeln('│ $dartRad Dart                               │');
    buffer.writeln('│ $mdRad Markdown                           │');
    buffer.writeln('├──────────────────────────────────────┤');
    buffer.writeln('│ [Export]                [Cancel]     │');
    buffer.writeln('└──────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render bundle summary as clean Markdown documentation.
  static String renderMarkdown(StudioExportBundle bundle) {
    final buffer = StringBuffer();

    buffer.writeln('# Studio Export Bundle: ${bundle.suggestedFilename}');
    buffer.writeln();
    buffer.writeln('**Target Entity:** `${bundle.targetEntity.label}`  ');
    buffer.writeln('**Format:** `${bundle.format.name.toUpperCase()}`  ');
    buffer.writeln('**Exported At:** ${bundle.exportedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Content Payload');
    buffer.writeln();
    buffer.writeln('```${bundle.format.fileExtension}');
    buffer.writeln(bundle.content.trimRight());
    buffer.writeln('```');
    buffer.writeln();

    return buffer.toString();
  }
}
