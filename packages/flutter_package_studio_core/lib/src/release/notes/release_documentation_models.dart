/// Category of release note item.
enum ReleaseNoteCategory {
  feature,
  fix,
  breaking,
  documentation,
  maintenance,
}

/// An individual release note item entry.
class ReleaseNoteItem {
  final String title;
  final String description;
  final ReleaseNoteCategory category;

  const ReleaseNoteItem({
    required this.title,
    required this.description,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'category': category.name,
      };
}

/// A section in the release documentation bundle.
class ReleaseDocumentationSection {
  final String title;
  final String content;

  const ReleaseDocumentationSection({
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
      };
}

/// Options configuring release documentation bundle generation.
class ReleaseDocumentationOptions {
  final String packageName;
  final String version;
  final String profile;
  final String outputDir;

  const ReleaseDocumentationOptions({
    required this.packageName,
    this.version = '1.0.0',
    this.profile = 'standard',
    this.outputDir = 'doc/release',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'profile': profile,
        'outputDir': outputDir,
      };
}

/// Preview plan of release documentation sections.
class ReleaseDocumentationPlan {
  final String packageName;
  final String version;
  final String profile;
  final List<ReleaseDocumentationSection> sections;

  const ReleaseDocumentationPlan({
    required this.packageName,
    required this.version,
    required this.profile,
    required this.sections,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'profile': profile,
        'sectionCount': sections.length,
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}

/// Result of release documentation bundle generation.
class ReleaseDocumentationResult {
  final String packageName;
  final String version;
  final bool isSuccess;
  final List<ReleaseDocumentationSection> sections;

  const ReleaseDocumentationResult({
    required this.packageName,
    required this.version,
    required this.isSuccess,
    required this.sections,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Release Documentation Bundle: $packageName');
    buf.writeln();
    buf.writeln('**Package Version**: $version');
    buf.writeln(
        '**Status**: ${isSuccess ? "DOCUMENTATION BUNDLE GENERATED ✓" : "FAILED ✗"}');
    buf.writeln();
    for (final s in sections) {
      buf.writeln('## ${s.title}');
      buf.writeln();
      buf.writeln(s.content);
      buf.writeln();
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'isSuccess': isSuccess,
        'sectionCount': sections.length,
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}
