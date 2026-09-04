/// Pure dual-format (JSON + Markdown) renderer for Phase 9.10 Controlled Workers.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/enterprise/workers/enterprise_worker_models.dart';

/// Pure Dual-Format Renderer for Controlled Workers and execution results.
class EnterpriseWorkerRenderer {
  const EnterpriseWorkerRenderer();

  /// Renders formatted JSON string.
  String renderJson(List<ControlledWorkerInfo> workers, {List<WorkerExecutionResult>? executions}) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert({
      'workers': workers.map((w) => w.toJson()).toList(),
      'executions': executions?.map((e) => e.toJson()).toList() ?? [],
    });
  }

  /// Renders structured Markdown worker status report.
  String renderMarkdown(List<ControlledWorkerInfo> workers, {List<WorkerExecutionResult>? executions}) {
    final buffer = StringBuffer();

    buffer.writeln('# Enterprise Controlled Workers & Remote Execution Report');
    buffer.writeln();
    buffer.writeln('**Total Registered Workers**: `${workers.length}`  ');
    buffer.writeln('**Generated At**: `${DateTime.now().toIso8601String()}`');
    buffer.writeln();

    buffer.writeln('## Executive Summary');
    buffer.writeln('```text');
    buffer.writeln('Total Workers: ${workers.length}');
    buffer.writeln('Healthy Workers: ${workers.where((w) => w.healthStatus == WorkerHealthStatus.healthy).length}');
    buffer.writeln('Busy Workers: ${workers.where((w) => w.healthStatus == WorkerHealthStatus.busy).length}');
    buffer.writeln('Total Executions: ${executions?.length ?? 0}');
    buffer.writeln('```');
    buffer.writeln();

    buffer.writeln('## Registered Workers (${workers.length})');
    if (workers.isEmpty) {
      buffer.writeln('*No controlled workers registered in pool.*');
    } else {
      for (final w in workers) {
        final icon = w.healthStatus == WorkerHealthStatus.healthy
            ? '🟢'
            : (w.healthStatus == WorkerHealthStatus.busy ? '🟡' : '🔴');

        buffer.writeln('### $icon Worker: `${w.displayName}` (`${w.workerId}`)');
        buffer.writeln('- **Host**: `${w.host}`');
        buffer.writeln('- **Status**: `${w.healthStatus.label}`');
        buffer.writeln('- **Capabilities**: ${w.capabilities.map((c) => c.id).join(", ")}');
        buffer.writeln('- **Limits**: Max ${w.capacity.maxMemoryMb}MB RAM, ${w.capacity.maxCpuCores} Cores, ${w.capacity.timeout.inMinutes}m timeout');
        buffer.writeln();
      }
    }

    if (executions != null && executions.isNotEmpty) {
      buffer.writeln('## Recent Worker Executions (${executions.length})');
      for (final ex in executions) {
        final exIcon = ex.isSuccess ? '✅' : '❌';
        buffer.writeln('### $exIcon Task: `${ex.taskId}` (${ex.status.label})');
        buffer.writeln('- **Worker**: `${ex.workerId}`');
        buffer.writeln('- **Duration**: `${ex.durationMs}ms`');
        buffer.writeln('- **Exit Code**: `${ex.exitCode}`');
        if (ex.errorMessage != null) {
          buffer.writeln('- **Error**: `${ex.errorMessage}`');
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}
