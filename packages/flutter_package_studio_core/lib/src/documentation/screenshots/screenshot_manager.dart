import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/documentation/screenshots/screenshot_models.dart';
import 'package:flutter_package_studio_core/src/documentation/screenshots/screenshot_validator.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';

/// Core manager service for discovering, validating, and managing screenshots.
class ScreenshotManager {
  final Logger _logger = Logger('ScreenshotManager');

  /// Plans screenshot management without filesystem writes.
  ScreenshotPlan planScreenshots(ScreenshotOptions options) {
    _logger.info('Planning screenshot management for "${options.packageName}"');

    final itemsToValidate = options.screenshots.isEmpty
        ? _defaultScreenshots(options.packageName)
        : options.screenshots;

    ScreenshotValidator.validate(itemsToValidate);

    final filtered = options.filterCategory != null
        ? itemsToValidate
            .where((i) => i.category == options.filterCategory)
            .toList()
        : itemsToValidate;

    return ScreenshotPlan(
      packageName: options.packageName,
      items: filtered,
    );
  }

  /// Renders screenshot plan into a deterministic Markdown gallery manifest.
  ScreenshotResult manageScreenshots(ScreenshotPlan plan) {
    _logger.info('Rendering screenshot manifest for "${plan.packageName}"');

    final buffer = StringBuffer();
    final cleanPkgName = ReadmeSanitizer.escapeText(plan.packageName);

    buffer.writeln('# Screenshot Gallery — $cleanPkgName\n');

    if (plan.items.isEmpty) {
      buffer.writeln('No screenshots available for this project.\n');
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

    return ScreenshotResult(
      packageName: plan.packageName,
      markdownManifest: '$markdown\n',
      itemCount: plan.items.length,
    );
  }

  List<ScreenshotItem> _defaultScreenshots(String packageName) {
    return [
      ScreenshotItem(
        id: 'overview',
        title: 'Application Overview',
        path: 'doc/assets/overview.png',
        category: ScreenshotCategory.overview,
        description: 'Main user interface of $packageName.',
      ),
      ScreenshotItem(
        id: 'feature_light',
        title: 'Light Theme Feature',
        path: 'doc/assets/feature_light.png',
        category: ScreenshotCategory.feature,
        description: 'Primary feature UI in light theme.',
      ),
    ];
  }
}
