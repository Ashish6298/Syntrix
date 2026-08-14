import 'package:flutter_package_studio_core/src/catalog/template_catalog_entry.dart';
import 'package:flutter_package_studio_core/src/catalog/template_catalog_provider.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/marketplace/registry_manager.dart';
import 'package:flutter_package_studio_core/src/marketplace/registry_source.dart';
import 'package:flutter_package_studio_core/src/marketplace/remote_template_record.dart';
import 'package:flutter_package_studio_core/src/template/template_manifest.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';

/// Source-selection filter for catalog operations.
enum CatalogSource {
  /// Only local (builtin, workspace) providers.
  local,

  /// Only remote registry providers.
  remote,

  /// All providers (local + remote).
  all,
}

/// Adapter that converts [RegistryManager] validated remote records into
/// [TemplateCatalogEntry] instances, satisfying the [TemplateCatalogProvider]
/// interface so remote registries integrate cleanly with [TemplateDiscoveryService].
///
/// ## Trust Model & Conflict Handling
///
/// [RemoteCatalogProvider] only contributes entries whose `id@version` does
/// NOT already exist in the catalog. The ordering in [TemplateDiscoveryService]
/// determines priority: register builtin/local providers first, then
/// [RemoteCatalogProvider], so local entries always win over remote ones.
///
/// ## Security
///
/// - Only records previously validated by [RemoteMetadataValidator] are
///   converted here; no re-fetching or re-parsing occurs.
/// - No executable content (hooks, scripts, generators) is loaded from remote
///   records. Only catalog metadata fields are transferred.
/// - Credentials are never exposed through catalog entries.
///
/// ## No Network I/O in fetchEntries()
///
/// [fetchEntries] is synchronous and reads only from in-memory validated
/// records in [RegistryManager]. The network fetch must be triggered separately
/// via [RegistryManager.refresh] before calling [fetchEntries].
class RemoteCatalogProvider extends TemplateCatalogProvider {
  @override
  final String providerKey;

  @override
  final String displayName;

  final RegistryManager _manager;
  bool _enabled;
  final Logger _logger = Logger('RemoteCatalogProvider');

  /// Creates a [RemoteCatalogProvider] backed by [manager].
  ///
  /// [providerKey] should be unique across all providers — typically `remote`.
  RemoteCatalogProvider({
    required RegistryManager manager,
    this.providerKey = 'remote',
    this.displayName = 'Remote Registry Catalog',
    bool enabled = true,
  })  : _manager = manager,
        _enabled = enabled;

  @override
  bool get isEnabled => _enabled;

  set isEnabled(bool value) => _enabled = value;

  @override
  String? validate() {
    // Provider is always structurally valid; registry connectivity issues
    // are reported through RegistryManager.status().
    return null;
  }

  /// Returns [TemplateCatalogEntry] instances from all validated remote records.
  ///
  /// **Does not perform any network I/O.** Call [RegistryManager.refresh]
  /// before catalog builds that require fresh remote data.
  @override
  List<TemplateCatalogEntry> fetchEntries() {
    final records = _manager.allValidatedRecords();
    _logger.debug(
        'RemoteCatalogProvider: converting ${records.length} validated records.');

    final entries = <TemplateCatalogEntry>[];
    for (final record in records) {
      final entry = _convert(record);
      if (entry != null) entries.add(entry);
    }

    _logger.debug(
        'RemoteCatalogProvider: produced ${entries.length} catalog entries.');
    return entries;
  }

  // ── Conversion ─────────────────────────────────────────────────────────────

  TemplateCatalogEntry? _convert(RemoteTemplateRecord record) {
    try {
      final manifest = TemplateManifest(
        id: record.id,
        name: record.id,
        displayName: record.displayName,
        description: record.description,
        version: record.version,
        projectType: record.projectType,
        minimumDartSdk: record.minimumDartSdk,
        minimumFlutterSdk: record.minimumFlutterSdk,
        supportedPlatforms: record.supportedPlatforms,
        capabilities: record.capabilities,
        tags: record.tags,
        extraMetadata: {
          if (record.maturity != null) 'maturity': record.maturity!,
          if (record.license != null) 'license': record.license!,
          if (record.documentationUrl != null)
            'documentationUrl': record.documentationUrl!,
        },
      );

      final template = Template(manifest: manifest);

      final category = _parseCategory(record.category);
      final source = _manager.sourceFor(
        // Find the source registry for this record — use first available
        record.id,
      );

      return TemplateCatalogEntry(
        template: template,
        category: category,
        providerKey: providerKey,
        publisher: record.publisher.isNotEmpty ? record.publisher : null,
        maturity: record.maturity,
        discoveryTags: const [],
        downloadCount: record.downloadCount,
        rating: record.rating,
        indexedAt: source?.fetchedAt ?? DateTime.now().toUtc(),
      );
    } catch (e, st) {
      _logger.error(
          'Failed to convert remote record "${record.id}@${record.version}": $e',
          e,
          st);
      return null;
    }
  }

  TemplateCatalogCategory _parseCategory(String raw) {
    switch (raw.toLowerCase()) {
      case 'builtin':
        // Remote records cannot claim builtin — downgrade to community
        return TemplateCatalogCategory.community;
      case 'local':
        return TemplateCatalogCategory.local;
      default:
        return TemplateCatalogCategory.community;
    }
  }
}

/// Extension on [RegistrySource] providing a lookup key for provenance.
extension RegistrySourceKey on RegistrySource {
  /// Composite key for provenance lookup.
  String get cacheKey => '$registryId@$protocolVersion';
}
