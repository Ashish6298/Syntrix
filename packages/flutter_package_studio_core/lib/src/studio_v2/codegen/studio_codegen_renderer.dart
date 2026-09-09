/// Multi-format (Markdown Code Blocks, JSON, Plain Source) renderer for Phase 10.8: Code Generation Studio.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/codegen/studio_codegen_models.dart';

/// Formatter generating Markdown code tabs, syntax highlighted blocks, and JSON export schemas.
class StudioCodeGenRenderer {
  /// Render CodeGen result as structured JSON.
  static String renderJson(CodeGenResult result, {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(result.toJson());
  }

  /// Render generated code inside a clean Markdown code block.
  static String renderMarkdown(CodeGenResult result) {
    final buffer = StringBuffer();

    buffer.writeln('# Code Generation Studio Output');
    buffer.writeln();
    buffer.writeln('**Style:** `${result.options.style.label}`  ');
    buffer.writeln(
        '**Public API Conformance:** `${result.isValidPublicApi ? "VALIDATED (PASS)" : "CUSTOM / UNKNOWN"}`  ');
    buffer.writeln('**Generated At:** ${result.generatedAt.toIso8601String()}');
    buffer.writeln();

    if (result.warnings.isNotEmpty) {
      buffer.writeln('### Warnings');
      for (final w in result.warnings) {
        buffer.writeln('- ⚠️ $w');
      }
      buffer.writeln();
    }

    buffer.writeln('```dart');
    buffer.writeln(result.sourceCode.trimRight());
    buffer.writeln('```');
    buffer.writeln();

    return buffer.toString();
  }
}
