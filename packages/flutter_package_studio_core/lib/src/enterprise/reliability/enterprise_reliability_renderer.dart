/// Dual-format (JSON + Markdown) renderer for Phase 9.13: Enterprise Reliability & Recovery.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/enterprise/reliability/enterprise_reliability_models.dart';

/// Formatter generating JSON telemetry payloads and Markdown recovery operation reports.
class EnterpriseReliabilityRenderer {
  /// Render recovery result as structured JSON.
  static String renderJson(RecoveryOperationResult result,
      {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(result.toJson());
  }

  /// Render recovery result as a Markdown report.
  static String renderMarkdown(RecoveryOperationResult result) {
    final buffer = StringBuffer();

    buffer.writeln('# Enterprise Recovery & Disaster Readiness Report');
    buffer.writeln();
    buffer.writeln('**Workflow ID:** `${result.workflowId}`  ');
    buffer.writeln('**Operation Type:** `${result.operationType}`  ');
    buffer.writeln(
        '**Recovery Outcome:** `${result.isSuccess ? "SUCCESS" : "FAILED"}`  ');
    buffer.writeln(
        '**Recovered Checkpoints:** ${result.recoveredCheckpointsCount}  ');
    buffer.writeln(
        '**Destructive Ops Skipped (Idempotency Guard):** ${result.skippedDestructiveOperations}  ');
    buffer.writeln('**Executed At:** ${result.executedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Actions & Idempotency Audit Trail');
    buffer.writeln();
    for (int i = 0; i < result.actionsTaken.length; i++) {
      buffer.writeln('${i + 1}. ${result.actionsTaken[i]}');
    }
    buffer.writeln();

    if (result.errorMessage != null) {
      buffer.writeln('## Error Details');
      buffer.writeln();
      buffer.writeln('> ${result.errorMessage}');
      buffer.writeln();
    }

    return buffer.toString();
  }
}
