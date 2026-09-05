/// Multi-format (Markdown, JSON, CSV) renderer for Phase 9.14: Enterprise Compliance & Governance Reports.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/enterprise/reporting/enterprise_reporting_models.dart';

/// Formatter generating Markdown tables, JSON data schemas, and CSV exports for compliance audits.
class EnterpriseReportingRenderer {
  /// Render compliance report as structured JSON.
  static String renderJson(EnterpriseComplianceReport report, {bool pretty = true}) {
    final encoder = pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(report.toJson());
  }

  /// Render compliance report as a clean, formal Markdown document.
  static String renderMarkdown(EnterpriseComplianceReport report) {
    final buffer = StringBuffer();

    buffer.writeln('# ${report.title}');
    buffer.writeln();
    buffer.writeln('**Report ID:** `${report.reportId}`  ');
    buffer.writeln('**Organization:** `${report.organizationId}`  ');
    buffer.writeln('**Report Type:** `${report.reportType.displayName}`  ');
    buffer.writeln('**Compliance Status:** `${report.isCompliant ? "COMPLIANT" : "NON-COMPLIANT"}`  ');
    buffer.writeln('**Generated At:** ${report.generatedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Executive Summary');
    buffer.writeln();
    buffer.writeln('> ${report.executiveSummary}');
    buffer.writeln();

    for (final section in report.sections) {
      buffer.writeln('## ${section.title}');
      if (section.description.isNotEmpty) {
        buffer.writeln();
        buffer.writeln(section.description);
      }
      buffer.writeln();

      if (section.headers.isNotEmpty) {
        buffer.writeln('| ${section.headers.join(" | ")} |');
        buffer.writeln('| ${section.headers.map((_) => "---").join(" | ")} |');

        for (final row in section.rows) {
          buffer.writeln('| ${row.join(" | ")} |');
        }
        buffer.writeln();
      }
    }

    if (report.summaryMetrics.isNotEmpty) {
      buffer.writeln('## Key Compliance Metrics');
      buffer.writeln();
      report.summaryMetrics.forEach((k, v) {
        buffer.writeln('- **$k:** `$v`');
      });
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Render tabular section data as CSV for audit spreadsheets.
  static String renderCsv(EnterpriseComplianceReport report) {
    final buffer = StringBuffer();

    for (final section in report.sections) {
      buffer.writeln('# Section: ${section.title}');
      if (section.headers.isNotEmpty) {
        buffer.writeln(section.headers.map(_escapeCsv).join(','));
        for (final row in section.rows) {
          buffer.writeln(row.map(_escapeCsv).join(','));
        }
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  static String _escapeCsv(String val) {
    if (val.contains(',') || val.contains('"') || val.contains('\n')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }
}
