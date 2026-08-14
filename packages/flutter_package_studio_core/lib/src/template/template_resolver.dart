import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/template/resolved_template.dart';
import 'package:flutter_package_studio_core/src/template/template_composition.dart';
import 'package:flutter_package_studio_core/src/template/template_dependency.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';
import 'package:flutter_package_studio_core/src/template/template_registry.dart';

/// Orchestrates template discovery, dependency resolution, and composition into a [ResolvedTemplate].
class TemplateResolver {
  final TemplateRegistry registry;

  TemplateResolver({required this.registry});

  /// Resolves [templateId] and optional extension IDs into a unified [ResolvedTemplate].
  ResolvedTemplate resolve({
    required String templateId,
    String versionConstraint = '*',
    List<String> extensionIds = const [],
    OverrideStrategy overrideStrategy = OverrideStrategy.fail,
  }) {
    final base =
        registry.resolve(templateId, versionConstraint: versionConstraint);
    if (base == null) {
      throw TemplateException(
          'Template "$templateId" ($versionConstraint) not found in registry.');
    }

    final extensions = <Template>[];
    for (final extId in extensionIds) {
      final ext = registry.get(extId);
      if (ext == null) {
        throw TemplateException(
            'Extension template "$extId" not found in registry.');
      }
      extensions.add(ext);
    }

    // Solve dependency order for base + extensions
    final allAvailable = <String, List<Template>>{};
    for (final t in registry.listAll()) {
      allAvailable.putIfAbsent(t.id, () => []).add(t);
    }

    TemplateDependencySolver.solve(
        root: base, availableTemplates: allAvailable);

    return TemplateCompositionEngine.compose(
      baseTemplate: base,
      extensions: extensions,
      strategy: overrideStrategy,
    );
  }
}
