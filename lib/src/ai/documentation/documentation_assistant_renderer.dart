/// Pure dual-format (JSON and Markdown) renderers for Documentation Assistant results (Phase 8.7).
library;

import 'dart:convert';
import 'package:syntrix/src/ai/documentation/documentation_models.dart';

/// Single authority for pure, deterministic dual-rendering of Documentation Assistant results.
class DocumentationAssistantRenderer {
  const DocumentationAssistantRenderer();

  /// Renders [result] to formatted, indented JSON.
  String renderGenerationJson(DocumentationGenerationResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(result.toJson());
  }

  /// Renders [result] to formatted, indented JSON.
  String renderConsistencyJson(DocumentationConsistencyResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(result.toJson());
  }

  /// Renders consistency audit result to structured Markdown.
  String renderConsistencyMarkdown(DocumentationConsistencyResult result) {
    final buf = StringBuffer();

    buf.writeln(
        '# Flutter Package Studio — AI Documentation Consistency Report');
    buf.writeln();
    buf.writeln('**Scope**: `${result.targetScope}`  ');
    buf.writeln('**Status**: `${result.isSuccess ? "SUCCESS" : "FAILED"}`  ');
    buf.writeln('**Total Mismatches**: `${result.findings.length}`  ');
    buf.writeln('**Files Compared**: `${result.comparedFiles.length}`  ');
    buf.writeln('**Duration**: `${result.durationMs}ms`  ');
    buf.writeln('**Timestamp**: `${result.timestamp.toIso8601String()}`');
    buf.writeln();

    if (!result.isSuccess) {
      buf.writeln('## ❌ Consistency Check Failure');
      buf.writeln(result.errorMessage ??
          'An unknown error occurred during documentation consistency check.');
      return buf.toString();
    }

    buf.writeln('## Summary');
    buf.writeln(result.summary);
    buf.writeln();

    if (result.findings.isEmpty) {
      buf.writeln(
          '🎉 **Documentation is Up-to-Date!** No discrepancies or outdated options detected between source code and documentation.');
      return buf.toString();
    }

    buf.writeln(
        '## 📑 Documentation Inconsistencies (${result.findings.length})');
    buf.writeln();

    for (var i = 0; i < result.findings.length; i++) {
      final f = result.findings[i];
      final sevBadge = f.severity.name.toUpperCase();
      buf.writeln('### ${i + 1}. [$sevBadge] ${f.problem}');
      buf.writeln('- **File**: `${f.file}:${f.location}`');
      buf.writeln('- **Artifact Type**: `${f.artifactType.name}`');
      buf.writeln('- **Confidence**: `${f.confidence.name.toUpperCase()}`');
      buf.writeln('- **Implemented Reality**: `${f.implementedReality}`');
      buf.writeln('- **Documented Claim**: `${f.documentedClaim}`');
      buf.writeln('- **Explanation**: ${f.explanation}');
      buf.writeln('- **Recommendation**: ${f.recommendation}');
      buf.writeln();
    }

    return buf.toString();
  }
}
