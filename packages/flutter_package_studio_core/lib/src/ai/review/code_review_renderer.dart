/// Pure dual-format (JSON and Markdown) renderers for Code Review Results (Phase 8.3).
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/ai/review/code_review_models.dart';

/// Single authority for pure, deterministic dual-rendering of [CodeReviewResult] objects.
class CodeReviewRenderer {
  const CodeReviewRenderer();

  /// Renders [result] to a formatted, indented JSON string.
  String renderJson(CodeReviewResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(result.toJson());
  }

  /// Renders [result] to a formatted Markdown string.
  String renderMarkdown(CodeReviewResult result) {
    final buf = StringBuffer();

    buf.writeln('# Flutter Package Studio — AI Code Analysis & Review Report');
    buf.writeln();
    buf.writeln('**Mode**: `${result.mode.name.toUpperCase()}`  ');
    buf.writeln('**Status**: `${result.isSuccess ? "SUCCESS" : "FAILED"}`  ');
    buf.writeln('**Inspected Files**: `${result.inspectedFiles.length}`  ');
    buf.writeln('**Total Findings**: `${result.findings.length}`  ');
    buf.writeln('**Duration**: `${result.durationMs}ms`  ');
    buf.writeln('**Timestamp**: `${result.timestamp.toIso8601String()}`');
    buf.writeln();

    if (!result.isSuccess) {
      buf.writeln('## ❌ Review Execution Failure');
      buf.writeln(result.errorMessage ??
          'An unknown error occurred during code review.');
      return buf.toString();
    }

    buf.writeln('## Summary');
    buf.writeln(result.summary);
    buf.writeln();

    final criticals = result.findings
        .where((f) => f.severity == CodeReviewSeverity.critical)
        .toList();
    final highs = result.findings
        .where((f) => f.severity == CodeReviewSeverity.high)
        .toList();
    final mediums = result.findings
        .where((f) => f.severity == CodeReviewSeverity.medium)
        .toList();
    final lows = result.findings
        .where((f) => f.severity == CodeReviewSeverity.low)
        .toList();
    final infos = result.findings
        .where((f) => f.severity == CodeReviewSeverity.informational)
        .toList();

    buf.writeln('### Severity Breakdown');
    buf.writeln('- **Critical**: ${criticals.length}');
    buf.writeln('- **High**: ${highs.length}');
    buf.writeln('- **Medium**: ${mediums.length}');
    buf.writeln('- **Low**: ${lows.length}');
    buf.writeln('- **Informational**: ${infos.length}');
    buf.writeln();

    if (result.findings.isEmpty) {
      buf.writeln(
          '🎉 **No code review findings identified!** The inspected codebase adheres cleanly to all quality and safety rules.');
      return buf.toString();
    }

    buf.writeln('## Detailed Findings');
    buf.writeln();

    for (var i = 0; i < result.findings.length; i++) {
      final f = result.findings[i];
      final sevBadge = _badgeForSeverity(f.severity);

      buf.writeln('### ${i + 1}. $sevBadge ${f.problem}');
      buf.writeln('- **File**: `${f.file}` (${f.location})');
      buf.writeln(
          '- **Category**: `${f.category.name}` | **Confidence**: `${f.confidence.name.toUpperCase()}`');
      buf.writeln();
      buf.writeln('**Explanation**:  ');
      buf.writeln(f.explanation);
      buf.writeln();
      buf.writeln('**Recommendation**:  ');
      buf.writeln(f.recommendation);
      buf.writeln();
    }

    buf.writeln('---');
    buf.writeln('### Inspected Files List');
    for (final file in result.inspectedFiles) {
      buf.writeln('- `$file`');
    }

    return buf.toString();
  }

  String _badgeForSeverity(CodeReviewSeverity severity) {
    switch (severity) {
      case CodeReviewSeverity.critical:
        return '🚨 [CRITICAL]';
      case CodeReviewSeverity.high:
        return '🔴 [HIGH]';
      case CodeReviewSeverity.medium:
        return '🟡 [MEDIUM]';
      case CodeReviewSeverity.low:
        return '🔵 [LOW]';
      case CodeReviewSeverity.informational:
        return 'ℹ️ [INFO]';
    }
  }
}
