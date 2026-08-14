import 'package:flutter_package_studio_core/src/template/template_model.dart';

/// Classification category for a template in the catalog.
enum TemplateCatalogCategory {
  /// Official, built-in templates shipped with FPS.
  builtin,

  /// Community-contributed or user-installed templates.
  community,

  /// Privately defined workspace-local templates.
  local,
}

/// Rich, search-indexable entry in a [TemplateCatalog].
///
/// Wraps a [Template] with catalog-specific metadata such as download count,
/// star rating, maturity level, and discovery tags that supplement the core
/// template manifest.
class TemplateCatalogEntry {
  /// The underlying template bundle.
  final Template template;

  /// Catalog classification category.
  final TemplateCatalogCategory category;

  /// Optional publisher or author handle shown in listings.
  final String? publisher;

  /// Optional human-readable maturity badge (`stable`, `preview`, `experimental`).
  final String? maturity;

  /// Discovery tags that supplement [TemplateManifest.tags].
  final List<String> discoveryTags;

  /// Total accumulated download count (informational, not fetched remotely).
  final int downloadCount;

  /// Star or approval rating (0.0–5.0 scale).
  final double rating;

  /// Timestamp when this entry was first indexed.
  final DateTime indexedAt;

  /// Source provider identifier that contributed this entry.
  final String providerKey;

  /// Creates a [TemplateCatalogEntry] instance.
  const TemplateCatalogEntry({
    required this.template,
    required this.category,
    required this.providerKey,
    this.publisher,
    this.maturity,
    this.discoveryTags = const [],
    this.downloadCount = 0,
    this.rating = 0.0,
    required this.indexedAt,
  });

  // ── Convenience passthroughs ──────────────────────────────────────────────

  /// Template unique identifier.
  String get id => template.id;

  /// Template semantic version string.
  String get version => template.version;

  /// Human-readable display name.
  String get displayName => template.displayName;

  /// Short description from the manifest.
  String get description => template.manifest.description;

  /// Project archetype (`flutter_package`, `dart_package`, `plugin`, etc.).
  String get projectType => template.projectType;

  /// Combined list of manifest tags and discovery tags for full-text search.
  List<String> get allTags => [
        ...template.manifest.tags,
        ...discoveryTags,
      ];

  /// Creates a copy of this entry with overrides applied.
  TemplateCatalogEntry copyWith({
    Template? template,
    TemplateCatalogCategory? category,
    String? providerKey,
    String? publisher,
    String? maturity,
    List<String>? discoveryTags,
    int? downloadCount,
    double? rating,
    DateTime? indexedAt,
  }) {
    return TemplateCatalogEntry(
      template: template ?? this.template,
      category: category ?? this.category,
      providerKey: providerKey ?? this.providerKey,
      publisher: publisher ?? this.publisher,
      maturity: maturity ?? this.maturity,
      discoveryTags: discoveryTags ?? this.discoveryTags,
      downloadCount: downloadCount ?? this.downloadCount,
      rating: rating ?? this.rating,
      indexedAt: indexedAt ?? this.indexedAt,
    );
  }

  @override
  String toString() =>
      'TemplateCatalogEntry(id: $id, version: $version, category: $category)';
}
