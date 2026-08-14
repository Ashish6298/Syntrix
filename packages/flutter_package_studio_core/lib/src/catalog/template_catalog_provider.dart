import 'package:flutter_package_studio_core/src/catalog/template_catalog.dart';
import 'package:flutter_package_studio_core/src/catalog/template_catalog_entry.dart';

/// Abstract interface for a source that can produce [TemplateCatalogEntry] instances
/// and contribute them to a [TemplateCatalog].
///
/// Providers are registered with [TemplateDiscoveryService] and queried in
/// priority order during catalog construction. All providers MUST be local and
/// synchronous — no network or disk I/O is permitted unless isolated in a
/// dedicated provider subclass marked with appropriate documentation.
abstract class TemplateCatalogProvider {
  /// Unique identifier for this provider (e.g. `builtin`, `local_workspace`).
  String get providerKey;

  /// Human-readable display name of this provider.
  String get displayName;

  /// Whether this provider is active and should be queried.
  bool get isEnabled;

  /// Returns all [TemplateCatalogEntry] instances this provider can contribute.
  ///
  /// Called once per catalog rebuild by [TemplateDiscoveryService]. Must be
  /// deterministic and must not perform network I/O.
  List<TemplateCatalogEntry> fetchEntries();

  /// Validates provider health. Returns null on success, or an error message.
  String? validate() => null;

  @override
  String toString() => 'TemplateCatalogProvider($providerKey)';
}

/// Mixin that provides default no-op validation for providers with no health
/// check requirement.
mixin NoOpValidationProvider on TemplateCatalogProvider {
  @override
  String? validate() => null;
}

/// Base class for in-memory providers that populate the catalog from a static
/// or runtime-computed list of entries.
abstract class InMemoryCatalogProvider extends TemplateCatalogProvider {
  @override
  bool get isEnabled => true;

  @override
  String? validate() => null;

  /// Builds and returns the catalog from this provider's data source.
  TemplateCatalog buildCatalog() {
    final entries = fetchEntries();
    return TemplateCatalog.fromEntries(entries);
  }
}
