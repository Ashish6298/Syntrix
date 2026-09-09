/// Categories for changelog entries.
enum ChangelogCategory {
  breaking,
  feature,
  improvement,
  fix,
  performance,
  security,
  documentation,
}

/// A structured section in a changelog release entry.
class ChangelogSection {
  final ChangelogCategory category;
  final List<String> entries;

  const ChangelogSection({
    required this.category,
    required this.entries,
  });

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'entries': entries,
      };
}

/// Options for configuring automated changelog generation.
class AutomatedChangelogOptions {
  final String packageName;
  final String version;
  final String date;
  final String changelogPath;
  final String outputDir;

  const AutomatedChangelogOptions({
    required this.packageName,
    this.version = '1.0.0',
    this.date = '',
    this.changelogPath = 'CHANGELOG.md',
    this.outputDir = 'doc/release',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'date': date,
        'changelogPath': changelogPath,
        'outputDir': outputDir,
      };
}

/// Plan for automated changelog entry generation.
class AutomatedChangelogPlan {
  final String packageName;
  final String version;
  final String date;
  final List<ChangelogSection> sections;

  const AutomatedChangelogPlan({
    required this.packageName,
    required this.version,
    required this.date,
    required this.sections,
  });

  String toMarkdownEntry() {
    final buf = StringBuffer();
    buf.writeln('## [$version] - $date');
    buf.writeln();
    for (final sec in sections) {
      if (sec.entries.isNotEmpty) {
        buf.writeln('### ${_categoryTitle(sec.category)}');
        buf.writeln();
        for (final entry in sec.entries) {
          buf.writeln('- $entry');
        }
        buf.writeln();
      }
    }
    return buf.toString();
  }

  static String _categoryTitle(ChangelogCategory category) {
    switch (category) {
      case ChangelogCategory.breaking:
        return '⚠️ Breaking Changes';
      case ChangelogCategory.feature:
        return '🚀 Features';
      case ChangelogCategory.improvement:
        return '✨ Improvements';
      case ChangelogCategory.fix:
        return '🐛 Bug Fixes';
      case ChangelogCategory.performance:
        return '⚡ Performance';
      case ChangelogCategory.security:
        return '🔒 Security';
      case ChangelogCategory.documentation:
        return '📝 Documentation';
    }
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'date': date,
        'sectionCount': sections.length,
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}

/// Result of executing automated changelog generation.
class AutomatedChangelogResult {
  final String packageName;
  final String version;
  final bool isApplied;
  final String entryMarkdown;

  const AutomatedChangelogResult({
    required this.packageName,
    required this.version,
    required this.isApplied,
    required this.entryMarkdown,
  });

  String toMarkdownReport() {
    final buf = StringBuffer();
    buf.writeln('# Automated Changelog Report: $packageName');
    buf.writeln();
    buf.writeln('**Package Version**: $version');
    buf.writeln(
        '**Status**: ${isApplied ? "CHANGELOG APPLIED ✓" : "PREVIEW DRY-RUN (NOT APPLIED)"}');
    buf.writeln();
    buf.writeln('### Generated Changelog Entry');
    buf.writeln();
    buf.writeln(entryMarkdown);
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'isApplied': isApplied,
        'entryMarkdown': entryMarkdown,
      };
}
