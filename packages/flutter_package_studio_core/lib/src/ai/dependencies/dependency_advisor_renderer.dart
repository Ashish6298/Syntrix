/// Pure dual-format (JSON and Markdown) renderers for Dependency Advisor results (Phase 8.8).
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/ai/dependencies/dependency_models.dart';

/// Single authority for pure, deterministic dual-rendering of Dependency Advisor results.
class DependencyAdvisorRenderer {
  const DependencyAdvisorRenderer();

  /// Renders [result] to formatted, indented JSON.
  String renderJson(DependencyAnalysisResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(result.toJson());
  }

  /// Renders [result] to structured Markdown with severity badges, certainty markers, and recommendations.
  String renderMarkdown(DependencyAnalysisResult result) {
    final buf = StringBuffer();

    buf.writeln(
        '# Flutter Package Studio — AI Dependency & Compatibility Advisory Report');
    buf.writeln();
    buf.writeln(
        '**Scope**: `${result.scope.name.toUpperCase()}` (`${result.targetScopeId}`)  ');
    buf.writeln('**Status**: `${result.isSuccess ? "SUCCESS" : "FAILED"}`  ');
    buf.writeln('**Total Concerns**: `${result.findingCount}`  ');
    buf.writeln(
        '**Monorepo Packages**: `${result.analyzedPackages.join(", ")}`  ');
    buf.writeln(
        '**Total Unique Dependencies**: `${result.totalDependenciesCount}`  ');
    buf.writeln('**Duration**: `${result.durationMs}ms`  ');
    buf.writeln('**Timestamp**: `${result.timestamp.toIso8601String()}`');
    buf.writeln();

    if (!result.isSuccess) {
      buf.writeln('## ❌ Analysis Failure');
      buf.writeln(result.errorMessage ??
          'An unknown error occurred during dependency analysis.');
      return buf.toString();
    }

    buf.writeln('## Summary');
    buf.writeln(result.summary);
    buf.writeln();

    if (result.findings.isEmpty) {
      buf.writeln(
          '🎉 **All Dependencies Healthy!** No version conflicts, SDK incompatibilities, or deprecation risks detected.');
      return buf.toString();
    }

    buf.writeln('## 📦 Dependency Concerns (${result.findingCount})');
    buf.writeln();

    for (var i = 0; i < result.findings.length; i++) {
      final f = result.findings[i];
      final sevBadge = f.severity.name.toUpperCase();
      final certaintyBadge = f.certainty.name.toUpperCase();

      buf.writeln('### ${i + 1}. [$sevBadge] ${f.problem}');
      buf.writeln(
          '- **Dependency**: `${f.dependencyName}` (`${f.currentConstraint}`)');
      buf.writeln('- **Artifact Type**: `${f.artifactType.name}`');
      buf.writeln('- **Certainty**: `${certaintyBadge}`');
      buf.writeln('- **Confidence**: `${f.confidence.name.toUpperCase()}`');
      buf.writeln('- **Location**: `${f.file}:${f.location}`');
      if (f.affectedPackages.isNotEmpty) {
        buf.writeln(
            '- **Affected Packages**: `${f.affectedPackages.join(", ")}`');
      }
      buf.writeln('- **Explanation**: ${f.explanation}');
      buf.writeln('- **Recommendation**: ${f.recommendation}');
      buf.writeln();
    }

    return buf.toString();
  }
}
