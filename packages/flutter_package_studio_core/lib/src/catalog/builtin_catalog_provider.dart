import 'package:flutter_package_studio_core/src/catalog/template_catalog_entry.dart';
import 'package:flutter_package_studio_core/src/catalog/template_catalog_provider.dart';
import 'package:flutter_package_studio_core/src/template/builtin_templates.dart';
import 'package:flutter_package_studio_core/src/template/template_registry.dart';

/// Catalog provider backed by the [BuiltinTemplates] and an optional
/// [TemplateRegistry].
///
/// This provider contributes the built-in FPS templates (e.g. `flutter_package`)
/// as catalog entries. If an external [TemplateRegistry] is supplied it will
/// also enumerate any additionally registered templates.
class BuiltinCatalogProvider extends InMemoryCatalogProvider {
  static const String _providerKey = 'builtin';

  final TemplateRegistry? _registry;

  /// Creates a [BuiltinCatalogProvider] with an optional [registry].
  BuiltinCatalogProvider({TemplateRegistry? registry}) : _registry = registry;

  @override
  String get providerKey => _providerKey;

  @override
  String get displayName => 'Flutter Package Studio Built-in Templates';

  @override
  bool get isEnabled => true;

  @override
  List<TemplateCatalogEntry> fetchEntries() {
    final entries = <TemplateCatalogEntry>[];
    final indexedAt =
        DateTime.utc(2025, 1, 1); // Stable timestamp for determinism

    // Always include the static built-in template
    entries.add(TemplateCatalogEntry(
      template: BuiltinTemplates.flutterPackage,
      category: TemplateCatalogCategory.builtin,
      providerKey: _providerKey,
      publisher: 'Flutter Package Studio Team',
      maturity: 'stable',
      discoveryTags: const [
        'official',
        'production',
        'flutter',
        'package',
        'widgets',
      ],
      downloadCount: 0,
      rating: 5.0,
      indexedAt: indexedAt,
    ));

    // Enumerate any extra templates from the registry (excluding duplicates)
    if (_registry != null) {
      for (final template in _registry.listAll()) {
        final alreadyAdded = entries
            .any((e) => e.id == template.id && e.version == template.version);
        if (!alreadyAdded) {
          entries.add(TemplateCatalogEntry(
            template: template,
            category: TemplateCatalogCategory.builtin,
            providerKey: _providerKey,
            publisher: 'Flutter Package Studio Team',
            maturity: template.manifest.extraMetadata['maturity'] as String? ??
                'stable',
            discoveryTags: List<String>.from(
                template.manifest.extraMetadata['discoveryTags'] as List? ??
                    const <String>[]),
            downloadCount: 0,
            rating: 0.0,
            indexedAt: indexedAt,
          ));
        }
      }
    }

    return entries;
  }
}
