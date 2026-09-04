/// Dual-format (JSON + Markdown) renderer for Phase 9.12: Enterprise Observability Dashboard.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/enterprise/observability/enterprise_observability_models.dart';

/// Formatter generating JSON telemetry payloads and Markdown operational dashboard views.
class EnterpriseDashboardRenderer {
  /// Render snapshot as structured JSON.
  static String renderJson(EnterpriseDashboardSnapshot snapshot, {bool pretty = true}) {
    final encoder = pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(snapshot.toJson());
  }

  /// Render snapshot as a clean Markdown operational overview.
  static String renderMarkdown(EnterpriseDashboardSnapshot snapshot) {
    final buffer = StringBuffer();

    buffer.writeln('# Enterprise Operational Dashboard');
    buffer.writeln();
    buffer.writeln('**Organization:** `${snapshot.organizationId}`  ');
    buffer.writeln('**System Health:** `${snapshot.overallSystemHealth.label}`  ');
    buffer.writeln('**Generated At:** ${snapshot.generatedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## High-Level Operations Overview');
    buffer.writeln();
    buffer.writeln('| Metric | Count | Status / Notes |');
    buffer.writeln('|---|:---:|---|');
    buffer.writeln('| Total Release Workflows | ${snapshot.totalWorkflowsExecuted} | ${snapshot.successfulWorkflows} Succeeded, ${snapshot.failedWorkflows} Failed, ${snapshot.gateBlockedWorkflows} Blocked |');
    buffer.writeln('| Worker Nodes | ${snapshot.workerStats.totalRegisteredWorkers} | ${snapshot.workerStats.healthyWorkers} Healthy, ${snapshot.workerStats.busyWorkers} Busy, ${snapshot.workerStats.degradedOrOfflineWorkers} Degraded |');
    buffer.writeln('| Policy & Security Violations | ${snapshot.activePolicyViolations} | ${snapshot.blockedDependencyCount} Blocked Dependencies |');
    buffer.writeln('| Audit Trail Events | ${snapshot.totalAuditEventsRecorded} | ${snapshot.failedOperationsRecorded} Failed Operations Recorded |');
    buffer.writeln();

    buffer.writeln('## Package Health');
    buffer.writeln();
    buffer.writeln('| Package Name | Version | Health Status | Violations | AI Quality | Last Inspected |');
    buffer.writeln('|---|---|:---:|:---:|:---:|---|');
    for (final p in snapshot.packageHealth) {
      buffer.writeln('| `${p.packageName}` | `${p.currentVersion}` | `${p.status.label}` | ${p.policyViolations} | ${p.aiQualityScore}% | ${p.lastInspectedAt.toIso8601String().split("T").first} |');
    }
    buffer.writeln();

    buffer.writeln('## AI Code Review & Intelligence Telemetry');
    buffer.writeln();
    buffer.writeln('- **Total AI Reviews Executed:** ${snapshot.aiReviewStats.totalReviewsExecuted}');
    buffer.writeln('- **Average Quality Score:** ${snapshot.aiReviewStats.averageQualityScore}%');
    buffer.writeln('- **Approved Releases:** ${snapshot.aiReviewStats.approvedReleasesCount}');
    buffer.writeln('- **Blocked Releases:** ${snapshot.aiReviewStats.blockedReleasesCount}');
    buffer.writeln('- **Findings Flagged:** ${snapshot.aiReviewStats.totalFindingsReported}');
    buffer.writeln();

    if (snapshot.recentFailedOperations.isNotEmpty) {
      buffer.writeln('## Recent Failed Operations');
      buffer.writeln();
      buffer.writeln('| Operation | Package / Target | Actor | Failure Information | Timestamp |');
      buffer.writeln('|---|---|---|---|---|');
      for (final f in snapshot.recentFailedOperations) {
        buffer.writeln('| `${f["operation"]}` | `${f["package"]}` | ${f["actor"]} | ${f["failure_info"]} | ${f["timestamp"]} |');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
