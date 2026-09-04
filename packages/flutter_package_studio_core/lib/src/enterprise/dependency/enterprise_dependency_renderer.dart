/// Pure dual-format (JSON + Markdown) renderer for Phase 9.6 Dependency Governance.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/enterprise/dependency/enterprise_dependency_models.dart';

/// Pure Dual-Format Renderer for Dependency Governance audit results.
class EnterpriseDependencyRenderer {
  const EnterpriseDependencyRenderer();

  /// Renders formatted JSON string.
  String renderJson(DependencyGovernanceResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(result.toJson());
  }

  /// Renders structured Markdown dependency governance report.
  String renderMarkdown(DependencyGovernanceResult result) {
    final buffer = StringBuffer();

    final statusIcon = result.isCompliant
        ? '✅'
        : (result.isBlocked ? '❌' : '⚠️');

    buffer.writeln('# Enterprise Dependency Governance Report');
    buffer.writeln();
    buffer.writeln('**Target Package**: `${result.targetPackageName}`  ');
    buffer.writeln('**Compliance Status**: $statusIcon **${result.isCompliant ? "COMPLIANT" : (result.isBlocked ? "BLOCKED (POLICY VIOLATION)" : "NON-COMPLIANT")}**  ');
    buffer.writeln('**Total Dependencies Analyzed**: `${result.totalDependenciesAnalyzed}`  ');
    buffer.writeln('**Duration**: `${result.durationMs}ms`  ');
    buffer.writeln('**Timestamp**: `${result.timestamp.toIso8601String()}`');
    buffer.writeln();

    buffer.writeln('## Executive Summary');
    buffer.writeln('```text');
    buffer.writeln('Compliant: ${result.isCompliant ? "YES" : "NO"}');
    buffer.writeln('Blocked: ${result.isBlocked ? "YES" : "NO"}');
    buffer.writeln('Approved Packages: ${result.approvedCount}');
    buffer.writeln('Restricted Packages: ${result.restrictedCount}');
    buffer.writeln('Blocked Packages: ${result.blockedCount}');
    buffer.writeln('Known Vulnerabilities: ${result.vulnerableCount}');
    buffer.writeln('License Violations: ${result.licenseViolationCount}');
    buffer.writeln('```');
    buffer.writeln();

    buffer.writeln('## Evaluated Dependencies (${result.findings.length})');
    if (result.findings.isEmpty) {
      buffer.writeln('*No dependencies found in pubspec.yaml.*');
    } else {
      for (final finding in result.findings) {
        final icon = finding.status == DependencyGovernanceStatus.approved
            ? '✅'
            : (finding.status == DependencyGovernanceStatus.restricted
                ? '⚠️'
                : (finding.status == DependencyGovernanceStatus.vulnerable
                    ? '🛡️'
                    : (finding.status == DependencyGovernanceStatus.licenseViolation ? '⚖️' : '❌')));

        buffer.writeln('### $icon [${finding.status.label}] `${finding.packageName}` (`${finding.declaredVersion}`)');
        buffer.writeln('- **Type**: `${finding.dependencyType.id}`');
        buffer.writeln('- **Reason**: ${finding.reason}');
        if (finding.license != null) {
          buffer.writeln('- **License**: `${finding.license}`');
        }
        if (finding.advisoryId != null) {
          buffer.writeln('- **Advisory**: `${finding.advisoryId}`');
        }
        if (finding.recommendation != null) {
          buffer.writeln('- **Recommendation**: ${finding.recommendation}');
        }
        buffer.writeln('- **Blocking**: ${finding.isBlocking ? "YES" : "NO"}');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}
