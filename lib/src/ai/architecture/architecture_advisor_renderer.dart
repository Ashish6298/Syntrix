/// Pure dual-format (JSON and Markdown) renderers for Architecture Advisory results (Phase 8.6).
library;

import 'dart:convert';
import 'package:syntrix/src/ai/architecture/architecture_models.dart';

/// Single authority for pure, deterministic dual-rendering of [ArchitectureScanResult] objects.
class ArchitectureAdvisorRenderer {
  const ArchitectureAdvisorRenderer();

  /// Renders [result] to formatted, indented JSON.
  String renderJson(ArchitectureScanResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(result.toJson());
  }

  /// Renders [result] to formatted, structured Markdown.
  String renderMarkdown(ArchitectureScanResult result) {
    final buf = StringBuffer();

    buf.writeln('# Flutter Package Studio — AI Architecture Advisory Report');
    buf.writeln();
    buf.writeln(
        '**Scope**: `${result.scope.name.toUpperCase()}` (`${result.targetScopeId}`)  ');
    buf.writeln('**Status**: `${result.isSuccess ? "SUCCESS" : "FAILED"}`  ');
    buf.writeln('**Total Findings**: `${result.findings.length}`  ');
    buf.writeln(
        '**Monorepo Packages**: `${result.structuralModel.packageNames.join(", ")}`  ');
    buf.writeln('**Duration**: `${result.durationMs}ms`  ');
    buf.writeln('**Timestamp**: `${result.timestamp.toIso8601String()}`');
    buf.writeln();

    if (!result.isSuccess) {
      buf.writeln('## ❌ Architecture Scan Failure');
      buf.writeln(result.errorMessage ??
          'An unknown error occurred during architecture advisory scan.');
      return buf.toString();
    }

    buf.writeln('## Summary');
    buf.writeln(result.summary);
    buf.writeln();

    if (result.structuralModel.detectedCycles.isNotEmpty) {
      buf.writeln('## ⚠️ Circular Dependency Cycles Detected');
      for (final cycle in result.structuralModel.detectedCycles) {
        buf.writeln('- 🔴 `${cycle.join(" -> ")}`');
      }
      buf.writeln();
    }

    if (result.findings.isEmpty) {
      buf.writeln(
          '🎉 **Clean Architecture!** No layering violations, circular dependencies, or architectural anti-patterns detected.');
      return buf.toString();
    }

    buf.writeln('## 🏛️ Architectural Findings (${result.findings.length})');
    buf.writeln();

    for (var i = 0; i < result.findings.length; i++) {
      final f = result.findings[i];
      final sevBadge = f.severity.name.toUpperCase();
      buf.writeln('### ${i + 1}. [$sevBadge] ${f.issue}');
      buf.writeln('- **Component**: `${f.component}`');
      buf.writeln('- **Category**: `${f.category.name}`');
      buf.writeln('- **Confidence**: `${f.confidence.name.toUpperCase()}`');
      buf.writeln('- **Reason**: ${f.reason}');
      buf.writeln('- **Recommendation**: ${f.recommendation}');
      buf.writeln();
    }

    return buf.toString();
  }
}
