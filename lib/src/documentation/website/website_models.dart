/// Navigation item for static website pages.
class WebsiteNav implements Comparable<WebsiteNav> {
  final String label;
  final String route;
  final int order;

  const WebsiteNav({
    required this.label,
    required this.route,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'route': route,
        'order': order,
      };

  @override
  int compareTo(WebsiteNav other) {
    final o = order.compareTo(other.order);
    if (o != 0) return o;
    return label.compareTo(other.label);
  }
}

/// Represents a single documentation page in the static website.
class WebsitePage implements Comparable<WebsitePage> {
  final String title;
  final String route;
  final String content;
  final int order;

  const WebsitePage({
    required this.title,
    required this.route,
    required this.content,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'route': route,
        'order': order,
        'contentLength': content.length,
      };

  @override
  int compareTo(WebsitePage other) {
    final o = order.compareTo(other.order);
    if (o != 0) return o;
    return route.compareTo(other.route);
  }
}

/// Options for configuring static website generation.
class WebsiteOptions {
  final String packageName;
  final String title;

  const WebsiteOptions({
    required this.packageName,
    this.title = 'Documentation Portal',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'title': title,
      };
}

/// Preview plan of static website generation before rendering files.
class WebsitePlan {
  final String packageName;
  final String title;
  final List<WebsiteNav> navigation;
  final List<WebsitePage> pages;

  WebsitePlan({
    required this.packageName,
    required this.title,
    required List<WebsiteNav> navigation,
    required List<WebsitePage> pages,
  })  : navigation = _sortNav(navigation),
        pages = _sortPages(pages);

  static List<WebsiteNav> _sortNav(List<WebsiteNav> list) {
    final copy = List<WebsiteNav>.from(list);
    copy.sort();
    return List.unmodifiable(copy);
  }

  static List<WebsitePage> _sortPages(List<WebsitePage> list) {
    final copy = List<WebsitePage>.from(list);
    copy.sort();
    return List.unmodifiable(copy);
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'title': title,
        'pageCount': pages.length,
        'navigation': navigation.map((n) => n.toJson()).toList(),
        'pages': pages.map((p) => p.toJson()).toList(),
      };
}

/// Result of static website generation containing rendered page maps (`route -> content`).
class WebsiteResult {
  final String packageName;
  final Map<String, String> files;

  const WebsiteResult({
    required this.packageName,
    required this.files,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'fileCount': files.length,
        'routes': files.keys.toList(),
      };
}
