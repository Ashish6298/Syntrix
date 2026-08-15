import 'package:flutter_package_studio_core/src/documentation/readme/readme_models.dart';
import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/documentation/readme/readme_section_registry.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';

/// Core service for planning and generating README documentation.
class ReadmeGenerator {
  final ReadmeSectionRegistry sectionRegistry;
  final Logger _logger = Logger('ReadmeGenerator');

  ReadmeGenerator({ReadmeSectionRegistry? sectionRegistry})
      : sectionRegistry = sectionRegistry ?? ReadmeSectionRegistry();

  /// Plans a README generation without rendering the final Markdown (preview mode).
  ReadmeGenerationPlan planReadme(ReadmeGenerationOptions options) {
    _logger.info('Planning README generation for "${options.packageName}"');

    final sections = sectionRegistry.buildDefaultSections(options);
    final badges = List<ReadmeBadge>.unmodifiable(options.badges);

    return ReadmeGenerationPlan(
      packageName: options.packageName,
      badges: badges,
      sections: sections,
    );
  }

  /// Generates deterministic Markdown content from a [plan].
  ReadmeGenerationResult generateReadme(ReadmeGenerationPlan plan) {
    _logger.info('Rendering README markdown for "${plan.packageName}"');

    final buffer = StringBuffer();

    // Title
    final cleanTitle = ReadmeSanitizer.escapeText(plan.packageName);
    buffer.writeln('# $cleanTitle\n');

    // Badges
    if (plan.badges.isNotEmpty) {
      final badgeRow = plan.badges.map((b) => b.toMarkdown()).join(' ');
      buffer.writeln('$badgeRow\n');
    }

    // Sections
    int count = 0;
    for (final s in plan.sections) {
      if (s.enabled && s.content.trim().isNotEmpty) {
        buffer.writeln(s.toMarkdown());
        count++;
      }
    }

    final markdown = buffer.toString().trimRight();

    return ReadmeGenerationResult(
      packageName: plan.packageName,
      markdown: '$markdown\n',
      sectionCount: count,
    );
  }
}
