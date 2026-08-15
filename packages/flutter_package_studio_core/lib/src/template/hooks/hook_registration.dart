/// Registration record for template hooks.
library;

import 'package:flutter_package_studio_core/src/template/hooks/template_hook.dart';

/// Immutable registration record capturing hook details and registration order.
class TemplateHookRegistration {
  /// The registered [TemplateHook].
  final TemplateHook hook;

  /// Insertion index representing stable registration order.
  final int registrationIndex;

  /// Creates a [TemplateHookRegistration].
  const TemplateHookRegistration({
    required this.hook,
    required this.registrationIndex,
  });

  /// Hook identifier shortcut.
  String get id => hook.id;

  /// Provenance shortcut.
  String get provenance => hook.provenance;

  /// Serializes registration record to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': hook.id,
      'name': hook.name,
      'provenance': hook.provenance,
      'priority': hook.priority,
      'enabled': hook.enabled,
      'supportedPhases': hook.supportedPhases.map((p) => p.name).toList(),
      'dependencies': hook.dependencies,
      'failurePolicy': hook.failurePolicy.name,
      'registrationIndex': registrationIndex,
    };
  }
}
