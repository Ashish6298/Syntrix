/// Supported screenshot categories.
enum ScreenshotCategory {
  overview,
  feature,
  usage,
  workflow,
  platform,
  custom,
}

/// Represents a single screenshot item metadata.
class ScreenshotItem implements Comparable<ScreenshotItem> {
  final String id;
  final String title;
  final String path;
  final ScreenshotCategory category;
  final String? description;

  const ScreenshotItem({
    required this.id,
    required this.title,
    required this.path,
    this.category = ScreenshotCategory.overview,
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
  int compareTo(ScreenshotItem other) => id.compareTo(other.id);
}

/// Options for configuring Screenshot management.
class ScreenshotOptions {
  final String packageName;
  final ScreenshotCategory? filterCategory;
  final List<ScreenshotItem> screenshots;

  const ScreenshotOptions({
    required this.packageName,
    this.filterCategory,
    this.screenshots = const [],
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        if (filterCategory != null) 'filterCategory': filterCategory!.name,
        'screenshotCount': screenshots.length,
      };
}

/// Preview plan of screenshot management before rendering.
class ScreenshotPlan {
  final String packageName;
  final List<ScreenshotItem> items;

  ScreenshotPlan({
    required this.packageName,
    required List<ScreenshotItem> items,
  }) : items = _sorted(items);

  static List<ScreenshotItem> _sorted(List<ScreenshotItem> list) {
    final copy = List<ScreenshotItem>.from(list);
    copy.sort();
    return List.unmodifiable(copy);
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'itemCount': items.length,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

/// Result of screenshot management execution containing Markdown manifest output.
class ScreenshotResult {
  final String packageName;
  final String markdownManifest;
  final int itemCount;

  const ScreenshotResult({
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
