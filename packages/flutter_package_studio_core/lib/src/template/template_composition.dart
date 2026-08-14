import 'package:flutter_package_studio_core/src/template/composition/composition_request.dart';
import 'package:flutter_package_studio_core/src/template/composition/enhanced_composition_engine.dart';
import 'package:flutter_package_studio_core/src/template/resolved_template.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';
import 'package:flutter_package_studio_core/src/template/template_registry.dart';

/// Strategy for resolving file path collisions during template composition.
enum OverrideStrategy {
  fail,
  override,
  skip,
}

/// Composes base template with feature extensions and resolves file collisions cleanly.
class TemplateCompositionEngine {
  /// Composes [baseTemplate] with [extensions] into a unified [ResolvedTemplate].
  static ResolvedTemplate compose({
    required Template baseTemplate,
    List<Template> extensions = const [],
    OverrideStrategy strategy = OverrideStrategy.fail,
  }) {
    final registry = TemplateRegistry();
    registry.register(baseTemplate);
    for (final ext in extensions) {
      if (!registry.contains(ext.id)) {
        registry.register(ext);
      }
    }

    final engine = EnhancedCompositionEngine();
    final plan = engine.composePlan(
      request: CompositionRequest(
        baseTemplateId: baseTemplate.id,
        baseVersionConstraint: baseTemplate.version,
        extensionIds: extensions.map((e) => e.id).toList(),
        conflictPolicy: strategy,
      ),
      registry: registry,
    );

    return plan.resolvedTemplate;
  }
}
