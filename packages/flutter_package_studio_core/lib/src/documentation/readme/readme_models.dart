import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';

/// Represents a Markdown badge displayed at the top of a README.
class ReadmeBadge {
  final String label;
  final String imageUrl;
  final String targetUrl;

  const ReadmeBadge({
    required this.label,
    required this.imageUrl,
    required this.targetUrl,
  });

  String toMarkdown() {
    final cleanLabel = ReadmeSanitizer.escapeText(label);
    return '[![$cleanLabel]($imageUrl)]($targetUrl)';
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'imageUrl': imageUrl,
        'targetUrl': targetUrl,
      };
}

/// Represents an individual section of a generated README document.
class ReadmeSection {
  final String id;
  final String title;
  final String content;
  final int order;
  final bool enabled;

  const ReadmeSection({
    required this.id,
    required this.title,
    required this.content,
    this.order = 0,
    this.enabled = true,
  });

  String toMarkdown() {
    if (!enabled || content.trim().isEmpty) return '';
    final cleanTitle = ReadmeSanitizer.escapeText(title);
    return '## $cleanTitle\n\n${content.trim()}\n';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'order': order,
        'enabled': enabled,
      };
}

/// Options configuring README generation.
class ReadmeGenerationOptions {
  final String packageName;
  final String description;
  final String version;
  final String license;
  final List<String> platforms;
  final List<String> features;
  final String? repositoryUrl;
  final List<ReadmeBadge> badges;
  final bool includeProvenance;

  const ReadmeGenerationOptions({
    required this.packageName,
    required this.description,
    this.version = '1.0.0',
    this.license = 'MIT',
    this.platforms = const [
      'android',
      'ios',
      'web',
      'windows',
      'macos',
      'linux'
    ],
    this.features = const [],
    this.repositoryUrl,
    this.badges = const [],
    this.includeProvenance = true,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'description': description,
        'version': version,
        'license': license,
        'platforms': platforms,
        'features': features,
        if (repositoryUrl != null) 'repositoryUrl': repositoryUrl,
        'badges': badges.map((b) => b.toJson()).toList(),
        'includeProvenance': includeProvenance,
      };
}

/// Preview plan of the README to be generated.
class ReadmeGenerationPlan {
  final String packageName;
  final List<ReadmeBadge> badges;
  final List<ReadmeSection> sections;

  const ReadmeGenerationPlan({
    required this.packageName,
    required this.badges,
    required this.sections,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'badgeCount': badges.length,
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}

/// Final result containing generated Markdown string and metadata.
class ReadmeGenerationResult {
  final String packageName;
  final String markdown;
  final int sectionCount;

  const ReadmeGenerationResult({
    required this.packageName,
    required this.markdown,
    required this.sectionCount,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'markdown': markdown,
        'sectionCount': sectionCount,
      };
}
