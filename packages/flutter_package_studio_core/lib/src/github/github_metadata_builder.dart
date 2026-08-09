import 'package:flutter_package_studio_core/src/github/github_options.dart';
import 'package:flutter_package_studio_core/src/template/template_context.dart';

/// Helper utility for normalizing GitHub topics and repository metadata.
class GitHubMetadataBuilder {
  /// Builds clean, normalized GitHub repository topics.
  static List<String> buildTopics(
      GitHubOptions options, TemplateContext context) {
    final rawTopics = <String>[...options.topics];

    final pkgName = context.get('package_name') as String?;
    if (pkgName != null && pkgName.isNotEmpty) {
      rawTopics.add(pkgName);
    }

    final isFlutter = context.get('is_flutter') as bool? ?? true;
    if (isFlutter) {
      rawTopics.add('flutter');
      rawTopics.add('flutter-package');
    } else {
      rawTopics.add('dart');
      rawTopics.add('dart-package');
    }

    // Deduplicate and sanitize GitHub topic format (lowercase, alphanumerics and hyphens only, max 50 chars)
    final cleaned = <String>{};
    final regExp = RegExp(r'^[a-z0-9\-]+$');

    for (final raw in rawTopics) {
      final normalized = raw.trim().toLowerCase().replaceAll('_', '-');
      if (normalized.isNotEmpty &&
          normalized.length <= 50 &&
          regExp.hasMatch(normalized)) {
        cleaned.add(normalized);
      }
    }

    return cleaned.toList();
  }
}
