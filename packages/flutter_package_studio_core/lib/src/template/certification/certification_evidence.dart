/// Structured evidence item attached to certification findings.
library;

import 'package:flutter_package_studio_core/src/template/hooks/hook_context.dart';

/// Key-value evidence item documenting grounds for a certification finding.
class TemplateCertificationEvidence {
  /// Category or key identifier for the evidence.
  final String key;

  /// Value content (automatically redacted if sensitive).
  final String value;

  /// Creates a [TemplateCertificationEvidence] instance.
  TemplateCertificationEvidence({
    required this.key,
    required String value,
  }) : value = TemplateHookContext.redactSecrets(value);

  /// Serializes evidence to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
    };
  }
}
