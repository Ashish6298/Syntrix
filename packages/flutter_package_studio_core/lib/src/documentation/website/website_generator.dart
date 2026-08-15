import 'package:flutter_package_studio_core/src/documentation/architecture/architecture_generator.dart';
import 'package:flutter_package_studio_core/src/documentation/architecture/architecture_models.dart';
import 'package:flutter_package_studio_core/src/documentation/examples/example_generator.dart';
import 'package:flutter_package_studio_core/src/documentation/examples/example_models.dart';
import 'package:flutter_package_studio_core/src/documentation/gifs/gif_manager.dart';
import 'package:flutter_package_studio_core/src/documentation/gifs/gif_models.dart';
import 'package:flutter_package_studio_core/src/documentation/readme/readme_generator.dart';
import 'package:flutter_package_studio_core/src/documentation/readme/readme_models.dart';
import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/documentation/screenshots/screenshot_manager.dart';
import 'package:flutter_package_studio_core/src/documentation/screenshots/screenshot_models.dart';
import 'package:flutter_package_studio_core/src/documentation/website/website_models.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';

/// Core generator for assembling documentation into a static website structure.
class StaticWebsiteGenerator {
  final Logger _logger = Logger('StaticWebsiteGenerator');

  /// Plans website structure by aggregating documentation generators.
  WebsitePlan planWebsite(WebsiteOptions options) {
    _logger.info(
        'Planning static documentation website for "${options.packageName}"');

    final cleanPkgName = ReadmeSanitizer.escapeText(options.packageName);

    // 1. README Page
    final readmeGen = ReadmeGenerator();
    final readmePlan = readmeGen.planReadme(
      ReadmeGenerationOptions(
        packageName: options.packageName,
        description: 'Flutter Package',
      ),
    );

    final readmeRes = readmeGen.generateReadme(readmePlan);

    // 2. Architecture Page
    final archGen = ArchitectureDocGenerator();
    final archPlan = archGen.planArchitectureDoc(const ArchDocOptions());
    final archRes = archGen.generateArchitectureDoc(archPlan);

    // 3. Examples Page
    final exGen = CodeExampleGenerator();
    final exPlan =
        exGen.planExample(CodeExampleOptions(packageName: options.packageName));
    final exRes = exGen.generateExample(exPlan);

    // 4. Screenshots Page
    final ssMgr = ScreenshotManager();
    final ssPlan = ssMgr
        .planScreenshots(ScreenshotOptions(packageName: options.packageName));
    final ssRes = ssMgr.manageScreenshots(ssPlan);

    // 5. GIFs Page
    final gifMgr = GifManager();
    final gifPlan =
        gifMgr.planGifs(GifOptions(packageName: options.packageName));
    final gifRes = gifMgr.manageGifs(gifPlan);

    final pages = [
      WebsitePage(
        title: 'Overview',
        route: 'index.html',
        content: readmeRes.markdown,
        order: 10,
      ),
      WebsitePage(
        title: 'Architecture',
        route: 'architecture.html',
        content: archRes.markdown,
        order: 20,
      ),
      WebsitePage(
        title: 'Code Examples',
        route: 'examples.html',
        content: '```dart\n${exRes.code}\n```',
        order: 30,
      ),
      WebsitePage(
        title: 'Screenshots',
        route: 'screenshots.html',
        content: ssRes.markdownManifest,
        order: 40,
      ),
      WebsitePage(
        title: 'Demos & GIFs',
        route: 'gifs.html',
        content: gifRes.markdownManifest,
        order: 50,
      ),
    ];

    final nav = pages
        .map((p) => WebsiteNav(label: p.title, route: p.route, order: p.order))
        .toList();

    return WebsitePlan(
      packageName: options.packageName,
      title: '$cleanPkgName Documentation Portal',
      navigation: nav,
      pages: pages,
    );
  }

  /// Renders a [plan] into a static website file bundle map (`path -> HTML/MD`).
  WebsiteResult generateWebsite(WebsitePlan plan) {
    _logger.info('Rendering static website for "${plan.packageName}"');

    final files = <String, String>{};

    for (final page in plan.pages) {
      final html = _renderHtmlPage(plan.title, page, plan.navigation);
      files[page.route] = html;
    }

    return WebsiteResult(
      packageName: plan.packageName,
      files: Map.unmodifiable(files),
    );
  }

  String _renderHtmlPage(
      String siteTitle, WebsitePage page, List<WebsiteNav> nav) {
    final navHtml = nav
        .map((n) =>
            '<a href="${n.route}">${ReadmeSanitizer.escapeText(n.label)}</a>')
        .join(' | ');

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>${ReadmeSanitizer.escapeText(page.title)} — ${ReadmeSanitizer.escapeText(siteTitle)}</title>
  <style>
    body { font-family: sans-serif; line-height: 1.6; margin: 2rem auto; max-width: 800px; padding: 0 1rem; }
    nav { border-bottom: 1px solid #ccc; padding-bottom: 1rem; margin-bottom: 2rem; }
    nav a { margin-right: 1rem; text-decoration: none; color: #0066cc; }
    pre { background: #f4f4f4; padding: 1rem; border-radius: 4px; overflow-x: auto; }
  </style>
</head>
<body>
  <header>
    <h1>${ReadmeSanitizer.escapeText(siteTitle)}</h1>
    <nav>$navHtml</nav>
  </header>
  <main>
    <h2>${ReadmeSanitizer.escapeText(page.title)}</h2>
    <div>
      <pre>${ReadmeSanitizer.escapeText(page.content)}</pre>
    </div>
  </main>
</body>
</html>
''';
  }
}
