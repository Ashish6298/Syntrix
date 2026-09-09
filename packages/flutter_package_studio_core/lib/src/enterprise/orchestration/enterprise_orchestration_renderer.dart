/// Rendering utilities for Phase 9.11: Enterprise Workflow Orchestration results.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/enterprise/orchestration/enterprise_orchestration_models.dart';

/// Formatter producing human-readable text, Markdown reports, and structured JSON summaries.
class EnterpriseWorkflowRenderer {
  /// Render execution result as a structured JSON string.
  static String renderJson(EnterpriseWorkflowExecutionResult result,
      {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(result.toJson());
  }

  /// Render execution result as a Markdown report.
  static String renderMarkdown(EnterpriseWorkflowExecutionResult result) {
    final buffer = StringBuffer();

    buffer.writeln('# Enterprise Release Workflow Report');
    buffer.writeln();
    buffer.writeln('**Workflow Name:** ${result.name}');
    buffer.writeln('**Workflow ID:** `${result.workflowId}`');
    buffer.writeln(
        '**Target Package:** `${result.targetPackageName}` @ `${result.targetVersion}`');
    buffer.writeln('**Execution Status:** `${result.status.label}`');
    buffer.writeln('**Total Duration:** ${result.durationMs}ms');
    buffer.writeln(
        '**Execution Time:** ${result.startedAt.toIso8601String()} → ${result.completedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Stage Summary');
    buffer.writeln();
    buffer.writeln('| Total | Passed | Failed | Skipped / Cancelled |');
    buffer.writeln('| :---: | :----: | :----: | :-----------------: |');
    buffer.writeln(
        '| ${result.totalStages} | ${result.passedStages} | ${result.failedStages} | ${result.skippedStages} |');
    buffer.writeln();

    buffer.writeln('## Stage Execution Details');
    buffer.writeln();
    buffer.writeln(
        '| # | Stage Name | Type | Status | Retries | Duration | Outcome / Notes |');
    buffer.writeln(
        '|---|------------|------|:------:|:-------:|:--------:|-----------------|');

    for (int i = 0; i < result.stageResults.length; i++) {
      final s = result.stageResults[i];
      final statusIcon = s.status == EnterpriseWorkflowStageStatus.passed
          ? 'PASSED'
          : s.status == EnterpriseWorkflowStageStatus.failed
              ? 'FAILED'
              : s.status == EnterpriseWorkflowStageStatus.cancelled
                  ? 'CANCELLED'
                  : 'SKIPPED';

      final notes =
          s.errorMessage ?? (s.outputData.isNotEmpty ? 'Success' : 'OK');
      buffer.writeln(
          '| ${i + 1} | ${s.name} | `${s.stageType.id}` | `$statusIcon` | ${s.retryCount} | ${s.durationMs}ms | $notes |');
    }

    buffer.writeln();
    buffer.writeln('## Execution Summary');
    buffer.writeln();
    buffer.writeln('> ${result.summary}');
    buffer.writeln();

    return buffer.toString();
  }
}
