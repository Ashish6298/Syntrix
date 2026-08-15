import 'package:flutter_package_studio_core/src/documentation/readme/readme_models.dart';
import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';

/// Registry for building and ordering README sections from options.
class ReadmeSectionRegistry {
  List<ReadmeSection> buildDefaultSections(ReadmeGenerationOptions options) {
    final sections = <ReadmeSection>[];

    // Description & Overview
    sections.add(ReadmeSection(
      id: 'overview',
      title: 'Overview',
      content: ReadmeSanitizer.escapeText(options.description),
      order: 10,
    ));

    // Features
    if (options.features.isNotEmpty) {
      final featureList = options.features
          .map((f) => '- ${ReadmeSanitizer.escapeText(f)}')
          .join('\n');
      sections.add(ReadmeSection(
        id: 'features',
        title: 'Features',
        content: featureList,
        order: 20,
      ));
    }

    // Supported Platforms
    if (options.platforms.isNotEmpty) {
      final platformList = options.platforms
          .map((p) => '- **${ReadmeSanitizer.escapeText(p.toUpperCase())}**')
          .join('\n');
      sections.add(ReadmeSection(
        id: 'platforms',
        title: 'Supported Platforms',
        content: platformList,
        order: 30,
      ));
    }

    // Installation
    final installCmd = '```bash\nflutter pub add ${options.packageName}\n```';
    sections.add(ReadmeSection(
      id: 'installation',
      title: 'Installation',
      content:
          'Add `${options.packageName}` to your `pubspec.yaml`:\n\n$installCmd',
      order: 40,
    ));

    // Usage Example
    final usageCode = '''
```dart
import 'package:${options.packageName}/${options.packageName}.dart';

void main() {
  print('Using ${options.packageName} v${options.version}');
}
```
''';
    sections.add(ReadmeSection(
      id: 'usage',
      title: 'Usage',
      content: usageCode,
      order: 50,
    ));

    // License
    sections.add(ReadmeSection(
      id: 'license',
      title: 'License',
      content: 'This project is licensed under the ${options.license} License.',
      order: 60,
    ));

    // Provenance / Footer
    if (options.includeProvenance) {
      sections.add(const ReadmeSection(
        id: 'provenance',
        title: 'Generated Metadata',
        content: '_Generated with Flutter Package Studio (FPS)_',
        order: 70,
      ));
    }

    sections.sort((a, b) => a.order.compareTo(b.order));
    return List.unmodifiable(sections);
  }
}
