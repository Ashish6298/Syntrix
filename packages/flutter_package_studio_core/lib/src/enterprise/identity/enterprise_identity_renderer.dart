/// Pure dual-format (JSON + Markdown) renderer for Phase 9.2 Enterprise Identity.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/enterprise/identity/enterprise_identity_models.dart';

/// Pure Dual-Format Renderer for Identity and Session details.
class EnterpriseIdentityRenderer {
  const EnterpriseIdentityRenderer();

  /// Renders formatted JSON string.
  String renderJson(EnterpriseIdentity identity) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(identity.toJson());
  }

  /// Renders structured Markdown profile.
  String renderMarkdown(EnterpriseIdentity identity,
      {EnterpriseSession? session}) {
    final buffer = StringBuffer();

    buffer.writeln('# Enterprise Identity Profile');
    buffer.writeln();
    buffer.writeln('**Identity ID**: `${identity.id}`  ');
    buffer.writeln('**Display Name**: `${identity.displayName}`  ');
    buffer.writeln('**Principal Type**: `${identity.type.id}`  ');
    buffer.writeln('**Organization**: `${identity.organizationId}`  ');
    if (identity.email.isNotEmpty) {
      buffer.writeln('**Email**: `${identity.email}`  ');
    }
    buffer.writeln(
        '**Assigned Roles**: `${identity.roles.map((r) => r.displayName).join(", ")}`');
    buffer.writeln();

    if (session != null) {
      buffer.writeln('## Active Session Info');
      buffer.writeln('```text');
      buffer.writeln('Session ID: ${session.sessionId}');
      buffer.writeln('Status: ${session.status.name}');
      buffer.writeln('Provider: ${session.providerId}');
      buffer.writeln('Expires At: ${session.expiresAt.toIso8601String()}');
      buffer.writeln('Is Valid: ${session.isValid ? "YES" : "NO"}');
      buffer.writeln('```');
      buffer.writeln();
    }

    buffer.writeln('## Direct Permissions');
    if (identity.directPermissions.isEmpty) {
      buffer.writeln(
          '*No direct permissions assigned (inherited through role definitions).*');
    } else {
      for (final perm in identity.directPermissions) {
        buffer.writeln('- `$perm`');
      }
    }

    return buffer.toString();
  }
}
