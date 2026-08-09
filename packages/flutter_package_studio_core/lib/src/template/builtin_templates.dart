import 'package:flutter_package_studio_core/src/template/template_manifest.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';
import 'package:flutter_package_studio_core/src/template/template_registry.dart';

/// Provides built-in starter templates for Flutter Package Studio.
class BuiltinTemplates {
  /// Builds and registers default templates into [registry].
  static void registerDefaultTemplates(TemplateRegistry registry) {
    if (!registry.contains('flutter_package')) {
      registry.register(flutterPackage);
    }
  }

  /// Initial built-in production-ready `flutter_package` template.
  static final Template flutterPackage = Template(
    manifest: const TemplateManifest(
      id: 'flutter_package',
      name: 'Flutter Package',
      displayName: 'Standard Production-Ready Flutter Package',
      description:
          'A modular, high-quality template for Flutter widget or utility packages.',
      version: '1.0.0',
      projectType: 'flutter_package',
      minimumDartSdk: '>=3.5.0 <4.0.0',
      minimumFlutterSdk: '>=3.22.0',
      supportedPlatforms: [
        'android',
        'ios',
        'web',
        'windows',
        'macos',
        'linux'
      ],
      directories: [
        'lib',
        'lib/src',
        'test',
        'example',
      ],
      files: {
        'pubspec.yaml': _pubspecContent,
        'README.md': _readmeContent,
        'CHANGELOG.md': _changelogContent,
        'LICENSE': _licenseContent,
        'analysis_options.yaml': _analysisOptionsContent,
        'lib/{{package_name}}.dart': _libraryContent,
        'test/{{package_name}}_test.dart': _testContent,
      },
    ),
    fileTemplates: const {
      'pubspec.yaml': _pubspecContent,
      'README.md': _readmeContent,
      'CHANGELOG.md': _changelogContent,
      'LICENSE': _licenseContent,
      'analysis_options.yaml': _analysisOptionsContent,
      'lib/{{package_name}}.dart': _libraryContent,
      'test/{{package_name}}_test.dart': _testContent,
    },
  );

  static const String _pubspecContent = '''
name: {{package_name}}
description: {{description}}
version: {{version}}
homepage: {{homepage}}
repository: {{repository}}
issue_tracker: {{issue_tracker}}

environment:
  sdk: '{{dart_sdk_constraint}}'
  flutter: '{{flutter_sdk_constraint}}'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
''';

  static const String _readmeContent = '''
# {{display_name}}

{{description}}

## Getting Started

Add `{{package_name}}` to your `pubspec.yaml`:

```yaml
dependencies:
  {{package_name}}: ^0.1.0
```

## License

Created by {{author}} <{{author_email}}>. Released under {{license}} License.
''';

  static const String _changelogContent = '''
# Changelog

## 0.1.0

* Initial release of `{{package_name}}` created via Flutter Package Studio.
''';

  static const String _licenseContent = '''
{{license}} License

Copyright (c) {{year}} {{author}}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files.
''';

  static const String _analysisOptionsContent = '''
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    always_declare_return_types: true
''';

  static const String _libraryContent = '''
/// {{description}}
library {{package_name}};

/// Sample placeholder calculator function.
int addTwoNumbers(int a, int b) => a + b;
''';

  static const String _testContent = '''
import 'package:flutter_test/flutter_test.dart';
import 'package:{{package_name}}/{{package_name}}.dart';

void main() {
  test('addTwoNumbers test', () {
    expect(addTwoNumbers(2, 3), equals(5));
  });
}
''';
}
