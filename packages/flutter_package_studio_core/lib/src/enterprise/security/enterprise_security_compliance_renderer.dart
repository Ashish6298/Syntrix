/// Pure dual-format (JSON + Markdown) renderer for Phase 9.7 Security Compliance.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/enterprise/security/enterprise_security_compliance_models.dart';

/// Pure Dual-Format Renderer for Enterprise Security Compliance assessments.
class EnterpriseSecurityComplianceRenderer {
  const EnterpriseSecurityComplianceRenderer();

  /// Renders formatted JSON string.
  String renderJson(SecurityComplianceAssessmentResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(result.toJson());
  }

  /// Renders structured Markdown security compliance report.
  String renderMarkdown(SecurityComplianceAssessmentResult result) {
    final buffer = StringBuffer();

    final statusIcon =
        result.isCompliant ? '✅' : (result.isBlocked ? '❌' : '⚠️');

    buffer.writeln('# Enterprise Security Policy & Compliance Report');
    buffer.writeln();
    buffer.writeln('**Target Project**: `${result.targetProject}`  ');
    buffer.writeln('**Compliance Profile**: `${result.profile.displayName}`  ');
    buffer.writeln(
        '**Overall Compliance Status**: $statusIcon **${result.isCompliant ? "COMPLIANT" : (result.isBlocked ? "BLOCKED (POLICY VIOLATION)" : "NON-COMPLIANT")}**  ');
    buffer.writeln(
        '**Total Controls Evaluated**: `${result.totalControlsEvaluated}`  ');
    buffer.writeln('**Duration**: `${result.durationMs}ms`  ');
    buffer.writeln('**Timestamp**: `${result.timestamp.toIso8601String()}`');
    buffer.writeln();

    buffer.writeln('## Executive Summary');
    buffer.writeln('```text');
    buffer.writeln('Compliant: ${result.isCompliant ? "YES" : "NO"}');
    buffer.writeln('Blocked: ${result.isBlocked ? "YES" : "NO"}');
    buffer.writeln('Critical Violations: ${result.criticalViolations}');
    buffer.writeln('High Violations: ${result.highViolations}');
    buffer.writeln('Medium Violations: ${result.mediumViolations}');
    buffer.writeln('Passed Gates: ${result.passedGates.join(", ")}');
    buffer.writeln(
        'Failed Gates: ${result.failedGates.isEmpty ? "NONE" : result.failedGates.join(", ")}');
    buffer.writeln('```');
    buffer.writeln();

    buffer.writeln(
        '## Evaluated Security Compliance Controls (${result.controlFindings.length})');
    for (final finding in result.controlFindings) {
      final icon = finding.status == ComplianceStatus.passed
          ? '✅'
          : (finding.status == ComplianceStatus.failed ? '❌' : '⚠️');

      buffer.writeln(
          '### $icon [${finding.controlId}] ${finding.controlTitle} (`${finding.category}`)');
      buffer.writeln('- **Status**: `${finding.status.label}`');
      buffer.writeln('- **Description**: ${finding.description}');
      if (finding.affectedResource != null) {
        buffer
            .writeln('- **Affected Resource**: `${finding.affectedResource}`');
      }
      if (finding.remediation != null) {
        buffer.writeln('- **Remediation**: ${finding.remediation}');
      }
      buffer.writeln('- **Blocking**: ${finding.isBlocking ? "YES" : "NO"}');
      buffer.writeln();
    }

    return buffer.toString();
  }
}
