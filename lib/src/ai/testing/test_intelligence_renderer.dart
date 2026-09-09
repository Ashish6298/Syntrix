/// Pure dual-format (JSON and Markdown) renderers for Test Intelligence results (Phase 8.4).
library;

import 'dart:convert';
import 'package:syntrix/src/ai/testing/test_intelligence_models.dart';

/// Single authority for pure, deterministic dual-rendering of [TestIntelligenceResult] objects.
class TestIntelligenceRenderer {
  const TestIntelligenceRenderer();

  /// Renders [result] to formatted, indented JSON.
  String renderJson(TestIntelligenceResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(result.toJson());
  }

  /// Renders [result] to formatted, structured Markdown.
  String renderMarkdown(TestIntelligenceResult result) {
    final buf = StringBuffer();

    buf.writeln(
        '# Flutter Package Studio — Test Generation & Test Intelligence Report');
    buf.writeln();
    buf.writeln('**Package**: `${result.packageId}`  ');
    buf.writeln('**Status**: `${result.isSuccess ? "SUCCESS" : "FAILED"}`  ');
    buf.writeln('**Existing Tests**: `${result.existingCoverage.length}`  ');
    buf.writeln(
        '**Suggested Candidate Tests**: `${result.suggestedCoverage.length}`  ');
    buf.writeln(
        '**Total Coverage Gaps**: `${result.gapReports.fold<int>(0, (sum, g) => sum + g.missingCases.length)}`  ');
    buf.writeln('**Duration**: `${result.durationMs}ms`  ');
    buf.writeln('**Timestamp**: `${result.timestamp.toIso8601String()}`');
    buf.writeln();

    if (!result.isSuccess) {
      buf.writeln('## ❌ Test Intelligence Failure');
      buf.writeln(result.errorMessage ??
          'An unknown error occurred during test intelligence analysis.');
      return buf.toString();
    }

    buf.writeln('## Summary');
    buf.writeln(result.summary);
    buf.writeln();

    buf.writeln('## Target Coverage Gap Reports (${result.gapReports.length})');
    buf.writeln();

    for (var i = 0; i < result.gapReports.length; i++) {
      final report = result.gapReports[i];
      final regBadge = report.isRegressionRisk ? ' ⚠️ `[REGRESSION RISK]`' : '';

      buf.writeln('### ${i + 1}. ${report.targetName}$regBadge');
      buf.writeln('- **Source**: `${report.sourceFile}`');
      buf.writeln(
          '- **Paired Test**: `${report.pairedTestFile ?? "NONE (Untested)"}`');
      buf.writeln('- **Missing Test Cases**: ${report.missingCases.length}');
      buf.writeln();

      if (report.missingCases.isNotEmpty) {
        buf.writeln('| Gap ID | Title | Category | Severity | Rationale |');
        buf.writeln('|---|---|---|---|---|');
        for (final c in report.missingCases) {
          buf.writeln(
              '| `${c.id}` | ${c.title} | `${c.category.name}` | **${c.severity.name.toUpperCase()}** | ${c.rationale} |');
        }
        buf.writeln();
      }
    }

    if (result.proposals.isNotEmpty) {
      buf.writeln(
          '## 🧪 Proposed Candidate Test Suites (${result.proposals.length})');
      buf.writeln(
          '> ⚠️ **Notice**: These tests are isolated proposals. They are NOT active coverage and will NOT run until approved.');
      buf.writeln();

      for (var i = 0; i < result.proposals.length; i++) {
        final prop = result.proposals[i];
        buf.writeln('### ${i + 1}. Proposal for `${prop.targetSourceFile}`');
        buf.writeln('**Proposal Location**: `${prop.proposalFilePath}`');
        buf.writeln('```dart');
        buf.writeln(prop.proposedCode);
        buf.writeln('```');
        buf.writeln();
      }
    }

    return buf.toString();
  }
}
