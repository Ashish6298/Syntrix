/// Pure dual-format (JSON and Markdown) renderers for AI Safety & Governance results (Phase 8.15).
library;

import 'dart:convert';
import 'package:syntrix/src/ai/security/secret_redactor.dart';
import 'package:syntrix/src/ai/governance/safety_governance_models.dart';

/// Single authority for pure, deterministic dual-rendering of Safety & Governance reports.
class SafetyGovernanceRenderer {
  const SafetyGovernanceRenderer();

  /// Escapes HTML special characters in [text] to prevent injection.
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Renders [result] to formatted, indented JSON with an absolute final redaction pass.
  String renderJson(SafetyGovernanceResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    final rawJson = encoder.convert(result.toJson());
    return SecretRedactor.redact(rawJson);
  }

  /// Renders [result] to structured Markdown report matching Milestone 8 verification requirements.
  String renderMarkdown(SafetyGovernanceResult result) {
    final buf = StringBuffer();

    buf.writeln(
        '# AI Safety, Governance & Verification — Milestone 8 Final Report');
    buf.writeln();
    buf.writeln('**Project Root**: `${_escapeHtml(result.projectRoot)}`  ');
    buf.writeln(
        '**Status**: ${result.allGatesPassed ? "✅ ALL GATES PASSED" : "❌ GATES FAILED"}  ');
    buf.writeln('**Duration**: `${result.durationMs}ms`  ');
    buf.writeln('**Timestamp**: `${result.timestamp.toIso8601String()}`');
    buf.writeln();

    buf.writeln('## Executive Verification Summary');
    buf.writeln('```text');
    buf.writeln(
        'All verification gates passed: ${result.allGatesPassed ? "YES" : "NO"}');
    buf.writeln(
        'Existing functionality preserved: ${result.existingFunctionalityPreserved ? "YES" : "NO"}');
    buf.writeln(
        'Security verification: ${result.securityVerificationPassed ? "PASS" : "FAIL"}');
    buf.writeln(
        'AI safety verification: ${result.aiSafetyVerificationPassed ? "PASS" : "FAIL"}');
    buf.writeln(
        'Unresolved blockers: ${result.unresolvedBlockers.isEmpty ? "NONE" : result.unresolvedBlockers.join(", ")}');
    buf.writeln(
        'Ready for Milestone 9: ${result.readyForMilestone9 ? "YES" : "NO"}');
    buf.writeln('```');
    buf.writeln();

    buf.writeln(
        '## Evaluated Safety & Verification Gates (${result.checks.length})');
    buf.writeln();

    for (final category in SafetyVerificationCategory.values) {
      final categoryChecks =
          result.checks.where((c) => c.category == category).toList();
      if (categoryChecks.isEmpty) continue;

      buf.writeln('### ${category.name.toUpperCase()} CHECKS');
      buf.writeln();

      for (final check in categoryChecks) {
        final icon = check.status == VerificationGateStatus.passed ? '✅' : '❌';
        buf.writeln('- **$icon [${check.id}] ${check.title}**');
        buf.writeln('  - *Description*: ${_escapeHtml(check.description)}');
        if (check.remediation != null) {
          buf.writeln('  - *Remediation*: ${_escapeHtml(check.remediation!)}');
        }
      }
      buf.writeln();
    }

    if (result.unresolvedBlockers.isNotEmpty) {
      buf.writeln('## ❌ Unresolved Blockers');
      for (final b in result.unresolvedBlockers) {
        buf.writeln('- ${_escapeHtml(b)}');
      }
      buf.writeln();
    }

    return SecretRedactor.redact(buf.toString().trim());
  }
}
