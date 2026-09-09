/// Pure dual-format (JSON + Markdown) renderer for Phase 9.9 Enterprise Credential References.
library;

import 'dart:convert';
import 'package:syntrix/src/enterprise/credentials/enterprise_credential_models.dart';

/// Pure Dual-Format Renderer for Credential References and Availability Checks.
class EnterpriseCredentialRenderer {
  const EnterpriseCredentialRenderer();

  /// Renders formatted JSON string.
  String renderJson(List<CredentialReference> references) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(references.map((r) => r.toJson()).toList());
  }

  /// Renders structured Markdown credential registry report.
  String renderMarkdown(List<CredentialReference> references,
      {List<SecretAvailabilityResult>? availabilityChecks}) {
    final buffer = StringBuffer();

    buffer.writeln('# Enterprise Credential References Report');
    buffer.writeln();
    buffer.writeln('**Total Registered References**: `${references.length}`  ');
    buffer.writeln('**Generated At**: `${DateTime.now().toIso8601String()}`');
    buffer.writeln();

    buffer.writeln('## Security Guarantee');
    buffer.writeln(
        '> 🛡️ **Zero Secret Exposure Guarantee**: Plaintext values are never stored or displayed. References only provide non-sensitive metadata for execution boundary injection.');
    buffer.writeln();

    if (availabilityChecks != null && availabilityChecks.isNotEmpty) {
      buffer.writeln('## Secret Availability Checks');
      for (final check in availabilityChecks) {
        final icon = check.isAvailable ? '✅' : '❌';
        buffer.writeln(
            '- $icon **`${check.key}`**: ${check.isAvailable ? "Available" : "Missing"} via `${check.providerType.displayName}`');
      }
      buffer.writeln();
    }

    buffer.writeln('## Registered Credential Pointers (${references.length})');
    if (references.isEmpty) {
      buffer.writeln('*No credential references registered in workspace.*');
    } else {
      for (final ref in references) {
        buffer.writeln('### 🔑 Reference: `${ref.key}`');
        buffer.writeln(
            '- **Provider**: `${ref.providerType.displayName}` (`${ref.providerId}`)');
        buffer.writeln('- **Allowed Scope**: `${ref.scope.id}`');
        if (ref.description.isNotEmpty) {
          buffer.writeln('- **Description**: ${ref.description}');
        }
        if (ref.expiresAt != null) {
          buffer
              .writeln('- **Expires**: `${ref.expiresAt!.toIso8601String()}`');
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}
