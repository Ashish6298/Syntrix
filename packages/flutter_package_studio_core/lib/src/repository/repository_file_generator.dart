import 'package:flutter_package_studio_core/src/repository/license_provider.dart';
import 'package:flutter_package_studio_core/src/repository/repository_options.dart';
import 'package:flutter_package_studio_core/src/template/template_context.dart';
import 'package:flutter_package_studio_core/src/template/template_renderer.dart';

/// Helper generator for standard repository files using [TemplateContext] and [TemplateRenderer].
class RepositoryFileGenerator {
  final TemplateRenderer _renderer;

  /// Creates a [RepositoryFileGenerator] with optional [_renderer].
  RepositoryFileGenerator({TemplateRenderer? renderer})
      : _renderer = renderer ?? TemplateRenderer();

  /// Generates README.md content.
  String generateReadme(RepositoryOptions options, TemplateContext context) {
    final pkgName = options.repositoryName;
    final desc = options.description.isNotEmpty
        ? options.description
        : 'A production-grade Flutter/Dart package created with Flutter Package Studio.';
    final author = options.author;
    final repoUrl = options.repositoryUrl;

    final buffer = StringBuffer();
    buffer.writeln('# $pkgName');
    buffer.writeln();
    buffer.writeln(desc);
    buffer.writeln();
    buffer.writeln('## Getting Started');
    buffer.writeln();
    buffer.writeln('Add `$pkgName` to your `pubspec.yaml`:');
    buffer.writeln();
    buffer.writeln('```yaml');
    buffer.writeln('dependencies:');
    buffer.writeln('  $pkgName: ^1.0.0');
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('Then run:');
    buffer.writeln();
    buffer.writeln('```bash');
    buffer.writeln('flutter pub get');
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('## Usage');
    buffer.writeln();
    buffer.writeln('```dart');
    buffer.writeln("import 'package:$pkgName/$pkgName.dart';");
    buffer.writeln();
    buffer.writeln('void main() {');
    buffer.writeln('  // Initialize and use $pkgName');
    buffer.writeln('}');
    buffer.writeln('```');
    buffer.writeln();

    if (options.generateContributing) {
      buffer.writeln('## Contributing');
      buffer.writeln();
      buffer.writeln(
          'Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.');
      buffer.writeln();
    }

    if (options.license.isNotEmpty && options.license.toLowerCase() != 'none') {
      buffer.writeln('## License');
      buffer.writeln();
      buffer.writeln(
          'This project is licensed under the ${options.license} License - see the [LICENSE](LICENSE) file for details.');
      buffer.writeln();
    }

    if (author.isNotEmpty || repoUrl.isNotEmpty) {
      buffer.writeln('---');
      if (author.isNotEmpty) buffer.writeln('Created by $author.');
      if (repoUrl.isNotEmpty)
        buffer.writeln('Repository: [$repoUrl]($repoUrl)');
    }

    return _renderer.renderText(buffer.toString(), context);
  }

  /// Generates CHANGELOG.md content.
  String generateChangelog(RepositoryOptions options, TemplateContext context) {
    const raw = '''
# Changelog

All notable changes to {{package_name}} will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - {{current_date}}

### Added
- Initial release of {{package_name}}.
''';
    return _renderer.renderText(raw, context);
  }

  /// Generates LICENSE file content.
  String generateLicense(RepositoryOptions options, TemplateContext context) {
    final template = LicenseProvider.getLicenseTemplate(options.license);
    return _renderer.renderText(template, context);
  }

  /// Generates CONTRIBUTING.md content.
  String generateContributing(
      RepositoryOptions options, TemplateContext context) {
    const raw = '''
# Contributing to {{package_name}}

Thank you for considering contributing to {{package_name}}!

## How to Contribute

1. Fork the repository on GitHub.
2. Create a feature branch (`git checkout -b feature/my-feature`).
3. Commit your changes (`git commit -m 'Add new feature'`).
4. Push to the branch (`git push origin feature/my-feature`).
5. Open a Pull Request.

## Code Style & Testing

- Ensure all code is formatted: `dart format .`
- Ensure static analysis is clean: `dart analyze`
- Ensure tests pass: `flutter test`
''';
    return _renderer.renderText(raw, context);
  }

  /// Generates CODE_OF_CONDUCT.md content.
  String generateCodeOfConduct(
      RepositoryOptions options, TemplateContext context) {
    const raw = '''
# Contributor Covenant Code of Conduct

## Our Pledge

We as members, contributors, and leaders pledge to make participation in our
community a harassment-free experience for everyone, regardless of age, body
size, visible or invisible disability, ethnicity, sex characteristics, gender
identity and expression, level of experience, education, socio-economic status,
nationality, personal appearance, race, religion, or sexual identity
and orientation.

## Our Standards

Examples of behavior that contributes to a positive environment for our
community include:

* Demonstrating empathy and kindness toward other people
* Being respectful of differing opinions, viewpoints, and experiences
* Giving and gracefully accepting constructive feedback

Contact: {{email}}
''';
    return _renderer.renderText(raw, context);
  }

  /// Generates SECURITY.md content.
  String generateSecurity(RepositoryOptions options, TemplateContext context) {
    const raw = '''
# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability within {{package_name}}, please send an email to {{email}}.
All security vulnerabilities will be promptly addressed.
''';
    return _renderer.renderText(raw, context);
  }
}
