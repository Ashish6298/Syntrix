import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/documentation/screenshots/screenshot_models.dart';

/// Validates screenshot paths, image formats, and duplicate IDs.
class ScreenshotValidator {
  static const Set<String> _allowedExtensions = {
    '.png',
    '.jpg',
    '.jpeg',
    '.svg',
    '.webp',
  };

  /// Validates a list of [items] for screenshot management.
  static void validate(List<ScreenshotItem> items) {
    final seenIds = <String>{};

    for (final item in items) {
      if (seenIds.contains(item.id)) {
        throw ScreenshotManagementException(
            'Duplicate screenshot ID detected: "${item.id}".');
      }
      seenIds.add(item.id);

      final lowerPath = item.path.toLowerCase();
      if (lowerPath.startsWith('/') ||
          lowerPath.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
        throw ScreenshotManagementException(
            'Absolute screenshot paths are forbidden: "${item.path}". Relative path required.');
      }

      if (lowerPath.contains('..')) {
        throw ScreenshotManagementException(
            'Path traversal ("..") is forbidden in screenshot paths: "${item.path}".');
      }

      final hasValidExt =
          _allowedExtensions.any((ext) => lowerPath.endsWith(ext));
      if (!hasValidExt) {
        throw ScreenshotManagementException(
            'Unsupported screenshot format for "${item.path}". Supported formats: .png, .jpg, .jpeg, .svg, .webp');
      }
    }
  }
}
