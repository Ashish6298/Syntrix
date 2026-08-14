import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';
import 'package:flutter_package_studio_core/src/template/template_semver.dart';

/// Declaration of a dependency required by a template.
class TemplateDependency {
  /// Target template identifier.
  final String templateId;

  /// Version constraint string (e.g. `>=1.0.0 <2.0.0`).
  final String versionConstraint;

  /// Whether missing dependency fails resolution.
  final bool isRequired;

  /// Creates a [TemplateDependency] instance.
  const TemplateDependency({
    required this.templateId,
    this.versionConstraint = '*',
    this.isRequired = true,
  });

  factory TemplateDependency.fromMap(Map<String, dynamic> map) {
    return TemplateDependency(
      templateId: map['id'] as String? ?? map['template_id'] as String? ?? '',
      versionConstraint: map['version'] as String? ??
          map['version_constraint'] as String? ??
          '*',
      isRequired: map['required'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': templateId,
        'version': versionConstraint,
        'required': isRequired,
      };
}

/// Helper for building topological order and detecting circular dependencies.
class TemplateDependencySolver {
  /// Resolves order of template dependencies or throws [TemplateException] on cycle or missing dependency.
  static List<Template> solve({
    required Template root,
    required Map<String, List<Template>> availableTemplates,
  }) {
    final resolved = <Template>[];
    final visited = <String>{};
    final visiting = <String>{};

    void visit(Template t) {
      if (visiting.contains(t.id)) {
        throw TemplateException(
            'Circular template dependency detected involving "${t.id}".');
      }
      if (!visited.contains(t.id)) {
        visiting.add(t.id);

        for (final dep in t.manifest.dependencies) {
          final candidates = availableTemplates[dep.templateId];
          if (candidates == null || candidates.isEmpty) {
            if (dep.isRequired) {
              throw TemplateException(
                  'Missing required template dependency "${dep.templateId}".');
            }
            continue;
          }

          final matching = candidates.where((c) {
            final ver = TemplateSemVer.parse(c.version);
            return ver.satisfies(dep.versionConstraint);
          }).toList();

          if (matching.isEmpty) {
            if (dep.isRequired) {
              throw TemplateException(
                  'No compatible version found for template dependency "${dep.templateId}" (${dep.versionConstraint}).');
            }
            continue;
          }

          // Sort candidates descending by version
          matching.sort((a, b) => TemplateSemVer.parse(b.version)
              .compareTo(TemplateSemVer.parse(a.version)));
          visit(matching.first);
        }

        visiting.remove(t.id);
        visited.add(t.id);
        resolved.add(t);
      }
    }

    visit(root);
    return resolved;
  }
}
