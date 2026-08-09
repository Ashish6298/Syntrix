import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';

/// Registry responsible for discovering, registering, searching, and retrieving templates.
class TemplateRegistry {
  final Map<String, Template> _templates = {};
  final Logger _logger = Logger('TemplateRegistry');

  /// Registers a new [template].
  /// Throws [TemplateException] if a template with the same ID is already registered.
  void register(Template template) {
    if (_templates.containsKey(template.id)) {
      throw TemplateException(
        'Template registration failed: Template with ID "${template.id}" is already registered.',
      );
    }
    _logger.debug(
        'Registering template: ${template.id} (${template.displayName})');
    _templates[template.id] = template;
  }

  /// Unregisters template by [id]. Returns true if found and removed.
  bool unregister(String id) {
    if (_templates.containsKey(id)) {
      _logger.debug('Unregistering template: $id');
      _templates.remove(id);
      return true;
    }
    return false;
  }

  /// Looks up a template by [id]. Returns null if not found.
  Template? get(String id) => _templates[id];

  /// Returns true if template with [id] exists in registry.
  bool contains(String id) => _templates.containsKey(id);

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

  /// Clears all registered templates.
  void clear() => _templates.clear();

  /// Count of registered templates.
  int get length => _templates.length;
}
