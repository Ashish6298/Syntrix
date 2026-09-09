/// Pure dual-format (JSON + Markdown) renderer for Phase 9.1 Enterprise Policy results.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/enterprise/policy/enterprise_policy_models.dart';

/// Pure Dual-Format Renderer for Enterprise Policy evaluation results.
class EnterprisePolicyRenderer {
  const EnterprisePolicyRenderer();

  /// Renders formatted JSON string.
  String renderJson(PolicyEvaluationResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(result.toJson());
  }

  /// Renders structured Markdown report.
  String renderMarkdown(PolicyEvaluationResult result) {
    final buffer = StringBuffer();

    buffer.writeln('# Enterprise Policy Evaluation Report');
    buffer.writeln();
    buffer.writeln('**Organization**: `${result.organizationId}`  ');
    buffer.writeln('**Scope**: `${result.scope.id}`  ');
    buffer.writeln('**Enforcement Mode**: `${result.enforcementMode.id}`  ');
    buffer.writeln(
        '**Status**: ${result.isCompliant ? "✅ COMPLIANT" : (result.isBlocked ? "❌ BLOCKED (STRICT VIOLATIONS)" : "⚠️ NON-COMPLIANT (PERMISSIVE)")}  ');
    buffer.writeln('**Duration**: `${result.durationMs}ms`  ');
    buffer.writeln('**Timestamp**: `${result.timestamp.toIso8601String()}`');
    buffer.writeln();

    buffer.writeln('## Executive Summary');
    buffer.writeln('```text');
    buffer.writeln('Policy Compliant: ${result.isCompliant ? "YES" : "NO"}');
    buffer.writeln('Operation Blocked: ${result.isBlocked ? "YES" : "NO"}');
    buffer.writeln('Critical Findings: ${result.criticalCount}');
    buffer.writeln('High Findings: ${result.highCount}');
    buffer.writeln('Medium Findings: ${result.mediumCount}');
    buffer.writeln('Low Findings: ${result.lowCount}');
    buffer.writeln('Passed Gates: ${result.passedGates.join(", ")}');
    buffer.writeln(
        'Failed Gates: ${result.failedGates.isEmpty ? "NONE" : result.failedGates.join(", ")}');
    buffer.writeln('```');
    buffer.writeln();

    buffer.writeln('## Evaluated Policy Gates');
    if (result.passedGates.isNotEmpty) {
      buffer.writeln('### ✅ Passed Gates');
      for (final gate in result.passedGates) {
        buffer.writeln('- **`$gate`**');
      }
      buffer.writeln();
    }

    if (result.failedGates.isNotEmpty) {
      buffer.writeln('### ❌ Failed Gates');
      for (final gate in result.failedGates) {
        buffer.writeln('- **`$gate`**');
      }
      buffer.writeln();
    }

    buffer.writeln('## Policy Findings (${result.findings.length})');
    if (result.findings.isEmpty) {
      buffer.writeln(
          '🎉 **Zero policy findings! All enterprise governance rules satisfied.**');
    } else {
      for (final finding in result.findings) {
        final icon = finding.status == PolicyCheckStatus.failed
            ? '❌'
            : (finding.status == PolicyCheckStatus.warning ? '⚠️' : '✅');
        buffer.writeln(
            '- **$icon [${finding.ruleId}] ${finding.ruleName}** (`${finding.severity.label}`)');
        buffer.writeln('  - *Message*: ${finding.message}');
        if (finding.location != null) {
          buffer.writeln('  - *Location*: `${finding.location}`');
        }
        if (finding.remediation != null) {
          buffer.writeln('  - *Remediation*: ${finding.remediation}');
        }
      }
    }

    return buffer.toString();
  }
}
