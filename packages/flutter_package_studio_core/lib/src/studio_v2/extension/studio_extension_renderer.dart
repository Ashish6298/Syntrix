/// Multi-format (ASCII Extensions Wireframe, Markdown, JSON) renderer for Phase 10.18: Extension Architecture.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/extension/studio_extension_engine.dart';

/// Formatter generating ASCII Extension Registry wireframes, Markdown catalogs, and JSON schemas.
class StudioExtensionRenderer {
  /// Render all registered extensions as structured JSON.
  static String renderJson(StudioExtensionEngine engine, {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    final list =
        engine.registeredExtensions.values.map((e) => e.toJson()).toList();
    return encoder.convert({'extensions': list, 'count': list.length});
  }

  /// Render ASCII Extension wireframe list matching Phase 10.18 specification.
  static String renderAsciiExtensions(StudioExtensionEngine engine) {
    final buffer = StringBuffer();

    buffer.writeln('┌──────────────────────────────────────┐');
    buffer.writeln('│ Studio Extensions                    │');
    buffer.writeln('├──────────────────────────────────────┤');

    for (final ext in engine.registeredExtensions.values) {
      final nameStr = ext.name.padRight(22);
      final verStr = 'v${ext.version}'.padLeft(8);
      buffer.writeln('│ • $nameStr $verStr │');
    }

    buffer.writeln('├──────────────────────────────────────┤');
    final totalTools = engine.getAllTools().length;
    final totalActions = engine.getAllActions().length;
    buffer.writeln(
        '│ Tools: $totalTools | Actions: $totalActions               │');
    buffer.writeln('└──────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render registered extensions as clean Markdown documentation.
  static String renderMarkdown(StudioExtensionEngine engine) {
    final buffer = StringBuffer();

    buffer.writeln('# Studio Extension Architecture Registry');
    buffer.writeln();
    buffer.writeln(
        'Active extensions installed: `${engine.registeredExtensions.length}`');
    buffer.writeln();

    buffer.writeln(
        '| Extension Name | Version | Author | Tools | Actions | Validators |');
    buffer.writeln('|---|:---:|---|:---:|:---:|:---:|');
    for (final ext in engine.registeredExtensions.values) {
      buffer.writeln(
          '| **${ext.name}** | `v${ext.version}` | ${ext.author} | `${ext.tools.length}` | `${ext.actions.length}` | `${ext.validators.length}` |');
    }
    buffer.writeln();

    buffer.writeln('## Extension Details & Capabilities');
    buffer.writeln();
    for (final ext in engine.registeredExtensions.values) {
      buffer.writeln('### ${ext.name} (`${ext.extensionId}`)');
      buffer.writeln('_${ext.description}_');
      buffer.writeln();
      if (ext.tools.isNotEmpty) {
        buffer.writeln('**Tools:**');
        for (final t in ext.tools) {
          buffer.writeln(
              '- `${t.title}` (${t.category.label}) — ${t.description}');
        }
      }
      if (ext.actions.isNotEmpty) {
        buffer.writeln('**Actions:**');
        for (final a in ext.actions) {
          buffer.writeln('- `${a.label}` [Shortcut: `${a.shortcut}`]');
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
