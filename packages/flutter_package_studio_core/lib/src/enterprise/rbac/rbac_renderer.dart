/// Pure dual-format (JSON + Markdown) renderer for Phase 9.3 RBAC evaluation results.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/enterprise/rbac/rbac_models.dart';

/// Pure Dual-Format Renderer for Role-Based Access Control decisions.
class RbacRenderer {
  const RbacRenderer();

  /// Renders formatted JSON string.
  String renderJson(AuthorizationResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(result.toJson());
  }

  /// Renders structured Markdown authorization report.
  String renderMarkdown(AuthorizationResult result) {
    final buffer = StringBuffer();

    buffer.writeln('# Enterprise Authorization Decision Report');
    buffer.writeln();
    buffer.writeln(
        '**Identity**: `${result.identity.displayName}` (`${result.identity.id}`)  ');
    buffer.writeln(
        '**Operation**: `${result.operation.name}` (`${result.operation.permissionKey}`)  ');
    buffer.writeln(
        '**Decision**: ${result.decision == AuthorizationDecision.allow ? "✅ ALLOW" : (result.decision == AuthorizationDecision.requiresApproval ? "⚠️ REQUIRES APPROVAL (✓*)" : "❌ DENY")}  ');
    buffer.writeln('**Duration**: `${result.durationMs}ms`  ');
    buffer.writeln('**Timestamp**: `${result.timestamp.toIso8601String()}`');
    buffer.writeln();

    buffer.writeln('## Decision Summary');
    buffer.writeln('```text');
    buffer.writeln('Allowed: ${result.isAllowed ? "YES" : "NO"}');
    buffer.writeln(
        'Requires Approval: ${result.requiresAdditionalApproval ? "YES" : "NO"}');
    buffer.writeln('Reason: ${result.reason}');
    buffer.writeln(
        'Authorized Roles: ${result.authorizedRoles.map((r) => r.displayName).join(", ")}');
    buffer.writeln('```');
    buffer.writeln();

    buffer.writeln('## Required Permissions');
    for (final perm in result.requiredPermissions) {
      buffer.writeln('- `$perm`');
    }

    return buffer.toString();
  }
}
