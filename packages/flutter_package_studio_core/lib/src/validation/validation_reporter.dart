import 'dart:convert';
import 'package:flutter_package_studio_core/src/validation/validation_models.dart';

/// Abstract reporter interface for rendering [ValidationReport]s.
abstract interface class ValidationReporter {
  /// Renders [report] into formatted string output.
  String render(ValidationReport report);
}

/// Plain text / CLI human-readable reporter.
class TextValidationReporter implements ValidationReporter {
  @override
  String render(ValidationReport report) {
    final buffer = StringBuffer();
    buffer.writeln('=== FPS VALIDATION REPORT ===');
    buffer.writeln('Target: ${report.targetDirectory}');
    buffer.writeln('Profile: ${report.profile}');
    buffer.writeln('Status: ${report.isValid ? 'PASS' : 'FAIL'}');
    buffer.writeln(
        'Summary: ${report.summary.passedRulesCount} Passed, ${report.summary.errorCount} Errors, ${report.summary.warningCount} Warnings, ${report.summary.infoCount} Info');

    if (report.issues.isNotEmpty) {
      buffer.writeln('\nIssues Discovered:');
      for (final issue in report.issues) {
        final pathStr = issue.filePath != null ? ' [${issue.filePath}]' : '';
        buffer.writeln(
            ' - [${issue.severity.name.toUpperCase()}][$pathStr] ${issue.ruleId}: ${issue.message}');
        if (issue.remediation != null) {
          buffer.writeln('   Fix: ${issue.remediation}');
        }
      }
    } else {
      buffer.writeln('\nNo validation issues discovered!');
    }

    return buffer.toString();
  }
}

/// Machine-readable JSON reporter.
class JsonValidationReporter implements ValidationReporter {
  @override
  String render(ValidationReport report) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(report.toJson());
  }
}
