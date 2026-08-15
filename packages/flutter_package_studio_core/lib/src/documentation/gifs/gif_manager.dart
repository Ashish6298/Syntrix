import 'package:flutter_package_studio_core/src/documentation/gifs/gif_models.dart';
import 'package:flutter_package_studio_core/src/documentation/gifs/gif_validator.dart';
import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';

/// Core manager service for discovering, validating, and managing GIF animations.
class GifManager {
  final Logger _logger = Logger('GifManager');

  /// Plans GIF pipeline execution without filesystem writes.
  GifPlan planGifs(GifOptions options) {
    _logger.info('Planning GIF pipeline for "${options.packageName}"');

    final itemsToValidate =
        options.gifs.isEmpty ? _defaultGifs(options.packageName) : options.gifs;

    GifValidator.validate(itemsToValidate);

    final filtered = options.filterCategory != null
        ? itemsToValidate
            .where((i) => i.category == options.filterCategory)
            .toList()
        : itemsToValidate;

    return GifPlan(
      packageName: options.packageName,
      items: filtered,
    );
  }

  /// Renders GIF plan into a deterministic Markdown gallery manifest.
  GifResult manageGifs(GifPlan plan) {
    _logger.info('Rendering GIF manifest for "${plan.packageName}"');

    final buffer = StringBuffer();
    final cleanPkgName = ReadmeSanitizer.escapeText(plan.packageName);

    buffer.writeln('# Animated Demonstrations — $cleanPkgName\n');

    if (plan.items.isEmpty) {
      buffer.writeln('No GIF animations available for this project.\n');
    } else {
      for (final item in plan.items) {
        final cleanTitle = ReadmeSanitizer.escapeText(item.title);
        final cleanPath = ReadmeSanitizer.escapeText(item.path);

        buffer.writeln('### $cleanTitle `[${item.category.name}]`');
        buffer.writeln('![$cleanTitle]($cleanPath)');

        if (item.description != null && item.description!.isNotEmpty) {
          buffer.writeln(
              '\n_${ReadmeSanitizer.escapeText(item.description!)}_\n');
        } else {
          buffer.writeln('');
        }
      }
    }

    final markdown = buffer.toString().trimRight();

    return GifResult(
      packageName: plan.packageName,
      markdownManifest: '$markdown\n',
      itemCount: plan.items.length,
    );
  }

  List<GifItem> _defaultGifs(String packageName) {
    return [
      GifItem(
        id: 'demo_flow',
        title: 'Feature Demo Flow',
        path: 'doc/assets/demo.gif',
        category: GifCategory.demo,
        description: 'Interactive demonstration flow of $packageName.',
      ),
      GifItem(
        id: 'onboarding_animation',
        title: 'Onboarding Animation',
        path: 'doc/assets/onboarding.webp',
        category: GifCategory.onboarding,
        description: 'First-time user onboarding workflow animation.',
      ),
    ];
  }
}
