/// Sort order for [TemplateCatalogQuery] results.
enum TemplateCatalogSortOrder {
  /// Sort alphabetically by template display name (A→Z).
  nameAscending,

  /// Sort reverse-alphabetically by template display name (Z→A).
  nameDescending,

  /// Sort by semantic version, newest first.
  versionNewest,

  /// Sort by semantic version, oldest first.
  versionOldest,

  /// Sort by download count, highest first.
  mostDownloaded,

  /// Sort by star rating, highest first.
  topRated,

  /// Sort by indexed timestamp, most recently added first.
  recentlyAdded,
}

/// Value object that encapsulates all filtering, search, and sorting parameters
/// for a [TemplateCatalog] query.
///
/// All fields are optional; an empty query returns all catalog entries in the
/// default sort order ([TemplateCatalogSortOrder.nameAscending]).
class TemplateCatalogQuery {
  /// Free-text search string matched against ID, name, description, and tags.
  final String? searchText;

  /// Filter by project archetype (e.g. `flutter_package`, `dart_package`).
  final String? projectType;

  /// Filter by category (builtin, community, local).
  final String? category;

  /// Filter by required maturity level (e.g. `stable`, `preview`).
  final String? maturity;

  /// Filter entries that contain ALL of the specified tags.
  final List<String> requiredTags;

  /// Filter entries that contain AT LEAST ONE of the specified tags.
  final List<String> anyTags;

  /// Filter entries whose version satisfies this constraint (e.g. `^1.0.0`).
  final String? versionConstraint;

  /// Filter by specific provider key.
  final String? providerKey;

  /// Sort order to apply to the result set.
  final TemplateCatalogSortOrder sortOrder;

  /// Maximum number of entries to return (null = no limit).
  final int? limit;

  /// Creates a [TemplateCatalogQuery] instance.
  const TemplateCatalogQuery({
    this.searchText,
    this.projectType,
    this.category,
    this.maturity,
    this.requiredTags = const [],
    this.anyTags = const [],
    this.versionConstraint,
    this.providerKey,
    this.sortOrder = TemplateCatalogSortOrder.nameAscending,
    this.limit,
  });

  /// Returns true when no filtering criteria are specified (matches all).
  bool get isEmpty =>
      (searchText == null || searchText!.trim().isEmpty) &&
      projectType == null &&
      category == null &&
      maturity == null &&
      requiredTags.isEmpty &&
      anyTags.isEmpty &&
      versionConstraint == null &&
      providerKey == null;

  /// Creates a copy of this query with overrides applied.
  TemplateCatalogQuery copyWith({
    String? searchText,
    String? projectType,
    String? category,
    String? maturity,
    List<String>? requiredTags,
    List<String>? anyTags,
    String? versionConstraint,
    String? providerKey,
    TemplateCatalogSortOrder? sortOrder,
    int? limit,
  }) {
    return TemplateCatalogQuery(
      searchText: searchText ?? this.searchText,
      projectType: projectType ?? this.projectType,
      category: category ?? this.category,
      maturity: maturity ?? this.maturity,
      requiredTags: requiredTags ?? this.requiredTags,
      anyTags: anyTags ?? this.anyTags,
      versionConstraint: versionConstraint ?? this.versionConstraint,
      providerKey: providerKey ?? this.providerKey,
      sortOrder: sortOrder ?? this.sortOrder,
      limit: limit ?? this.limit,
    );
  }

  @override
  String toString() =>
      'TemplateCatalogQuery(search: $searchText, projectType: $projectType, '
      'sort: $sortOrder, limit: $limit)';
}
