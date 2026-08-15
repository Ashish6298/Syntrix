/// Supported GIF animation categories.
enum GifCategory {
  demo,
  feature,
  workflow,
  onboarding,
  custom,
}

/// Represents a single GIF item metadata.
class GifItem implements Comparable<GifItem> {
  final String id;
  final String title;
  final String path;
  final GifCategory category;
  final String? description;

  const GifItem({
    required this.id,
    required this.title,
    required this.path,
    this.category = GifCategory.demo,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'path': path,
        'category': category.name,
        if (description != null) 'description': description,
      };

  @override
  int compareTo(GifItem other) => id.compareTo(other.id);
}

/// Options for configuring GIF pipeline execution.
class GifOptions {
  final String packageName;
  final GifCategory? filterCategory;
  final List<GifItem> gifs;

  const GifOptions({
    required this.packageName,
    this.filterCategory,
    this.gifs = const [],
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        if (filterCategory != null) 'filterCategory': filterCategory!.name,
        'gifCount': gifs.length,
      };
}

/// Preview plan of GIF pipeline execution before rendering.
class GifPlan {
  final String packageName;
  final List<GifItem> items;

  GifPlan({
    required this.packageName,
    required List<GifItem> items,
  }) : items = _sorted(items);

  static List<GifItem> _sorted(List<GifItem> list) {
    final copy = List<GifItem>.from(list);
    copy.sort();
    return List.unmodifiable(copy);
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'itemCount': items.length,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

/// Result of GIF pipeline execution containing Markdown manifest output.
class GifResult {
  final String packageName;
  final String markdownManifest;
  final int itemCount;

  const GifResult({
    required this.packageName,
    required this.markdownManifest,
    required this.itemCount,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'markdownManifest': markdownManifest,
        'itemCount': itemCount,
      };
}
