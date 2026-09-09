/// Pure dual-format (JSON + Markdown) renderer for Phase 9.4 Enterprise Audit Logs.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/enterprise/audit/enterprise_audit_models.dart';

/// Pure Dual-Format Renderer for Enterprise Audit Log events.
class EnterpriseAuditRenderer {
  const EnterpriseAuditRenderer();

  /// Renders formatted JSON string.
  String renderJson(List<EnterpriseAuditRecord> records) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(records.map((r) => r.toJson()).toList());
  }

  /// Renders structured Markdown audit log report.
  String renderMarkdown(List<EnterpriseAuditRecord> records, {String? title}) {
    final buffer = StringBuffer();

    buffer.writeln('# ${title ?? "Enterprise Audit Trail Report"}');
    buffer.writeln();
    buffer.writeln('**Total Recorded Events**: `${records.length}`  ');
    buffer.writeln('**Generated At**: `${DateTime.now().toIso8601String()}`');
    buffer.writeln();

    buffer.writeln('## Executive Audit Summary');
    buffer.writeln('```text');
    buffer.writeln('Total Events: ${records.length}');
    buffer.writeln(
        'Success Count: ${records.where((r) => r.outcome == AuditEventOutcome.success).length}');
    buffer.writeln(
        'Failure Count: ${records.where((r) => r.outcome == AuditEventOutcome.failure).length}');
    buffer.writeln(
        'Blocked Count: ${records.where((r) => r.outcome == AuditEventOutcome.blocked).length}');
    buffer.writeln(
        'Warning Count: ${records.where((r) => r.outcome == AuditEventOutcome.warning).length}');
    buffer.writeln('```');
    buffer.writeln();

    buffer.writeln('## Recorded Audit Events');
    if (records.isEmpty) {
      buffer.writeln('*No enterprise audit events recorded.*');
    } else {
      for (final record in records) {
        final icon = record.outcome == AuditEventOutcome.success
            ? '✅'
            : (record.outcome == AuditEventOutcome.failure
                ? '❌'
                : (record.outcome == AuditEventOutcome.blocked ? '🚫' : '⚠️'));

        buffer.writeln(
            '### $icon [${record.eventType.displayName}] `${record.operation}`');
        buffer.writeln('- **Event ID**: `${record.eventId}`');
        buffer.writeln(
            '- **Timestamp**: `${record.timestamp.toIso8601String()}`');
        buffer.writeln(
            '- **Actor**: `${record.actor.displayName}` (`${record.actor.id}` / `${record.actor.role}`)');
        buffer.writeln('- **Target**: `${record.packageOrProject}`');
        buffer.writeln('- **Outcome**: `${record.outcome.label}`');
        buffer.writeln('- **Correlation ID**: `${record.correlationId}`');
        if (record.relevantVersion != null) {
          buffer.writeln('- **Version**: `${record.relevantVersion}`');
        }
        if (record.command != null) {
          buffer.writeln('- **Command**: `${record.command}`');
        }
        if (record.policyDecision != null) {
          buffer.writeln('- **Policy Decision**: `${record.policyDecision}`');
        }
        if (record.failureInformation != null) {
          buffer.writeln('- **Failure**: `${record.failureInformation}`');
        }
        buffer.writeln('- **SHA-256 Hash**: `${record.recordHash}`');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}
