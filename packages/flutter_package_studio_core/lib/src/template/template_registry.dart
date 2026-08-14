import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';
import 'package:flutter_package_studio_core/src/template/template_semver.dart';

/// Registry responsible for discovering, registering, searching, and retrieving templates.
class TemplateRegistry {
  final Map<String, Template> _templates = {};
  final Logger _logger = Logger('TemplateRegistry');

  String _makeKey(String id, String version) => '$id@$version';

  /// Registers a new [template].
  /// Throws [TemplateException] if a template with the exact same ID and version is already registered.
  void register(Template template) {
    final key = _makeKey(template.id, template.version);
    if (_templates.containsKey(key)) {
      throw TemplateException(
        'Template registration failed: Template with ID "${template.id}" and version "${template.version}" is already registered.',
      );
    }
    _logger.debug(
        'Registering template: ${template.id}@${template.version} (${template.displayName})');
    _templates[key] = template;
  }

  /// Unregisters template by [id] and optional [version]. Returns true if found and removed.
  bool unregister(String id, {String? version}) {
    if (version != null) {
      return _templates.remove(_makeKey(id, version)) != null;
    }
    final keys = _templates.keys.where((k) => k.startsWith('$id@')).toList();
    for (final k in keys) {
      _templates.remove(k);
    }
    return keys.isNotEmpty;
  }

  /// Looks up a template by [id]. Returns highest matching version if found.
  Template? get(String id) => resolve(id);

  /// Returns true if template with [id] exists in registry.
  bool contains(String id) =>
      _templates.keys.any((k) => k.startsWith('$id@') || k == id);

  /// Lists all registered templates.
  List<Template> listAll() => List.unmodifiable(_templates.values);

  /// Filters registered templates by [projectType].
  List<Template> filterByProjectType(String projectType) {
    return _templates.values
        .where((t) => t.projectType == projectType)
        .toList();
  }

  /// Searches templates matching query in ID, name, or description.
  List<Template> search(String query) {
    final lower = query.trim().toLowerCase();
    if (lower.isEmpty) return listAll();
    return _templates.values.where((t) {
      return t.id.toLowerCase().contains(lower) ||
          t.displayName.toLowerCase().contains(lower) ||
          t.manifest.description.toLowerCase().contains(lower);
    }).toList();
  }

  /// Looks up template by [id] and optional [versionConstraint].
  Template? resolve(String id, {String versionConstraint = '*'}) {
    final list = _templates.values.where((t) => t.id == id).toList();
    if (list.isEmpty) return null;

    final matching = list
        .where(
            (t) => TemplateSemVer.parse(t.version).satisfies(versionConstraint))
        .toList();
    if (matching.isEmpty) return null;

    matching.sort((a, b) => TemplateSemVer.parse(b.version)
        .compareTo(TemplateSemVer.parse(a.version)));
    return matching.first;
  }

  /// Filters templates by capability.
  List<Template> filterByCapability(String capability) {
    return _templates.values
        .where((t) => t.manifest.capabilities.contains(capability))
        .toList();
  }

  /// Filters templates by tag.
  List<Template> filterByTag(String tag) {
    return _templates.values
        .where((t) => t.manifest.tags.contains(tag))
        .toList();
  }

  /// Clears all registered templates.
  void clear() {
    _logger.debug('Clearing all registered templates.');
    _templates.clear();
  }

  /// Count of registered templates.
  int get length => _templates.length;
}
