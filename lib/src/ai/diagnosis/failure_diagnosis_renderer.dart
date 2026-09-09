/// Pure dual-format (JSON and Markdown) renderers for Failure Diagnosis results (Phase 8.5).
library;

import 'dart:convert';
import 'package:syntrix/src/ai/diagnosis/failure_diagnosis_models.dart';

/// Single authority for pure, deterministic dual-rendering of [DiagnosisResult] objects.
class FailureDiagnosisRenderer {
  const FailureDiagnosisRenderer();

  /// Renders [result] to formatted, indented JSON.
  String renderJson(DiagnosisResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(result.toJson());
  }

  /// Renders [result] to formatted, structured Markdown.
  String renderMarkdown(DiagnosisResult result) {
    final buf = StringBuffer();

    buf.writeln('# Flutter Package Studio — AI Failure Diagnosis Report');
    buf.writeln();
    buf.writeln('**Scope**: `${result.packageId}`  ');
    buf.writeln('**Status**: `${result.isSuccess ? "SUCCESS" : "FAILED"}`  ');
    buf.writeln('**Duration**: `${result.durationMs}ms`  ');
    buf.writeln('**Timestamp**: `${result.timestamp.toIso8601String()}`');
    buf.writeln();

    if (!result.isSuccess || result.diagnosis == null) {
      buf.writeln('## ❌ Diagnosis Failure');
      buf.writeln(result.errorMessage ??
          'An unknown error occurred during failure diagnosis.');
      return buf.toString();
    }

    final diag = result.diagnosis!;

    buf.writeln('## 🔍 Problem Statement');
    buf.writeln(diag.problem);
    buf.writeln();

    buf.writeln('## 🎯 Likely Causes (Tiered by Certainty)');
    buf.writeln();
    for (var i = 0; i < diag.likelyCauses.length; i++) {
      final cause = diag.likelyCauses[i];
      final badge = switch (cause.certainty) {
        CauseCertainty.confirmed => '🟢 `[CONFIRMED CAUSE]`',
        CauseCertainty.probable => '🟡 `[PROBABLE CAUSE]`',
        CauseCertainty.possible => '⚪ `[POSSIBLE CAUSE]`',
      };
      buf.writeln('### ${i + 1}. $badge ${cause.description}');
      buf.writeln('- **Certainty**: `${cause.certainty.name.toUpperCase()}`');
      buf.writeln('- **Rationale**: ${cause.rationale}');
      buf.writeln();
    }

    buf.writeln('## 📑 Cited Evidence (${diag.citedEvidence.length})');
    for (final ev in diag.citedEvidence) {
      buf.writeln('- $ev');
    }
    buf.writeln();

    buf.writeln(
        '## 📦 Affected Components (${diag.affectedComponents.length})');
    for (final comp in diag.affectedComponents) {
      buf.writeln('- `$comp`');
    }
    buf.writeln();

    buf.writeln('## 🛠️ Recommended Remediation Fix');
    buf.writeln('**Remediation Risk**: `${diag.risk.name.toUpperCase()}`');
    buf.writeln();
    buf.writeln(diag.recommendedFix);
    buf.writeln();

    buf.writeln('## 📋 Verification Plan (Human Action Required)');
    buf.writeln(
        '> ℹ️ **Notice**: The diagnosis engine never executes commands automatically. Run these steps manually to verify the remediation.');
    buf.writeln();
    buf.writeln('| Step | Action to Execute | Expected Verification Outcome |');
    buf.writeln('|---|---|---|');
    for (final step in diag.verificationSteps) {
      buf.writeln(
          '| ${step.stepNumber} | `${step.action}` | ${step.expectedOutcome} |');
    }
    buf.writeln();

    if (result.historicalCitations.isNotEmpty) {
      buf.writeln('## 📜 Historical Report References');
      for (final ref in result.historicalCitations) {
        buf.writeln('- `$ref`');
      }
      buf.writeln();
    }

    return buf.toString();
  }
}
