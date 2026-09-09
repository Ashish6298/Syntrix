/// Pure dual-format (JSON and Markdown) renderers for Security Advisor results (Phase 8.9).
library;

import 'dart:convert';
import 'package:syntrix/src/ai/security/secret_redactor.dart';
import 'package:syntrix/src/ai/security/security_models.dart';

/// Single authority for pure, deterministic dual-rendering of Security Advisor results with mandatory final redaction.
class SecurityAdvisorRenderer {
  const SecurityAdvisorRenderer();

  /// Renders [result] to formatted, indented JSON with an absolute final redaction pass.
  String renderJson(SecurityAnalysisResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    final rawJson = encoder.convert(result.toJson());
    // Mandatory final redaction pass
    return SecretRedactor.redact(rawJson);
  }

  /// Renders [result] to structured Markdown with priority badges, evidence, impact, and verification procedures.
  String renderMarkdown(SecurityAnalysisResult result) {
    final buf = StringBuffer();

    buf.writeln(
        '# Flutter Package Studio — AI Security & Privacy Advisory Report');
    buf.writeln();
    buf.writeln(
        '**Scope**: `${result.scope.name.toUpperCase()}` (`${result.targetScopeId}`)  ');
    buf.writeln('**Status**: `${result.isSuccess ? "SUCCESS" : "FAILED"}`  ');
    buf.writeln('**Total Security Concerns**: `${result.findingCount}`  ');
    buf.writeln(
        '**Monorepo Packages**: `${result.scannedPackages.join(", ")}`  ');
    buf.writeln(
        '**Deterministic Audit Findings Consumed**: `${result.deterministicAuditFindingsCount}`  ');
    buf.writeln('**Duration**: `${result.durationMs}ms`  ');
    buf.writeln('**Timestamp**: `${result.timestamp.toIso8601String()}`');
    buf.writeln();

    if (!result.isSuccess) {
      buf.writeln('## ❌ Analysis Failure');
      buf.writeln(result.errorMessage ??
          'An unknown error occurred during security analysis.');
      return SecretRedactor.redact(buf.toString());
    }

    buf.writeln('## Executive Summary');
    buf.writeln(result.summary);
    buf.writeln();

    if (result.findings.isEmpty) {
      buf.writeln(
          '🛡️ **Zero Security Concerns Detected!** No exposed secrets, sensitive files, or insecure configurations.');
      return SecretRedactor.redact(buf.toString());
    }

    buf.writeln('## 🔒 Prioritized Security Concerns (${result.findingCount})');
    buf.writeln();

    for (var i = 0; i < result.findings.length; i++) {
      final f = result.findings[i];
      final prioBadge = f.priority.name.toUpperCase();
      final catBadge = f.securityCategory.name;

      buf.writeln('### ${i + 1}. [$prioBadge] ${f.problem}');
      buf.writeln('- **Category**: `$catBadge`');
      buf.writeln('- **File Location**: `${f.file}:${f.location}`');
      buf.writeln('- **Confidence**: `${f.confidence.name.toUpperCase()}`');
      buf.writeln('- **Evidence**: ${f.evidence}');
      buf.writeln('- **Risk Explanation**: ${f.explanation}');
      buf.writeln('- **Impact**: ${f.impact}');
      buf.writeln('- **Recommended Mitigation**: ${f.recommendation}');
      buf.writeln('- **Verification Procedure**: ${f.verificationProcedure}');
      buf.writeln();
    }

    // Absolute final redaction pass immediately before returning
    return SecretRedactor.redact(buf.toString());
  }
}
