import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/documentation/gifs/gif_models.dart';

/// Validates GIF paths, animation formats, and duplicate IDs.
class GifValidator {
  static const Set<String> _allowedExtensions = {
    '.gif',
    '.webp',
  };

  /// Validates a list of [items] for GIF pipeline operations.
  static void validate(List<GifItem> items) {
    final seenIds = <String>{};

    for (final item in items) {
      if (seenIds.contains(item.id)) {
        throw GifPipelineException('Duplicate GIF ID detected: "${item.id}".');
      }
      seenIds.add(item.id);

      final lowerPath = item.path.toLowerCase();
      if (lowerPath.startsWith('/') ||
          lowerPath.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
        throw GifPipelineException(
            'Absolute GIF paths are forbidden: "${item.path}". Relative path required.');
      }

      if (lowerPath.contains('..')) {
        throw GifPipelineException(
            'Path traversal ("..") is forbidden in GIF paths: "${item.path}".');
      }

      final hasValidExt =
          _allowedExtensions.any((ext) => lowerPath.endsWith(ext));
      if (!hasValidExt) {
        throw GifPipelineException(
            'Unsupported GIF animation format for "${item.path}". Supported formats: .gif, .webp');
      }
    }
  }
}
