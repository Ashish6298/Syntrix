import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/testing/project/test_project_models.dart';
import 'package:flutter_package_studio_core/src/testing/project/test_project_validator.dart';

/// Core generator for creating isolated test projects for Flutter packages.
class TestProjectGenerator {
  final Logger _logger = Logger('TestProjectGenerator');

  /// Plans test project generation without filesystem writes.
  TestProjectPlan planTestProject(TestProjectOptions options) {
    _logger.info('Planning test project for "${options.packageName}"');

    TestProjectValidator.validate(options);

    final cleanPkgName = ReadmeSanitizer.escapeText(options.packageName);

    final filePaths = [
      'pubspec.yaml',
      'analysis_options.yaml',
      'test/${cleanPkgName}_test.dart',
    ]..sort();

    return TestProjectPlan(
      packageName: options.packageName,
      targetDir: options.targetDir,
      relativeFilePaths: List.unmodifiable(filePaths),
    );
  }

  /// Renders a [plan] into a deterministic test project file map (`path -> content`).
  TestProjectResult generateTestProject(
      TestProjectPlan plan, TestProjectOptions options) {
    _logger.info('Rendering test project files for "${plan.packageName}"');

    final cleanPkgName = ReadmeSanitizer.escapeText(plan.packageName);
    final files = <String, String>{};

    // pubspec.yaml
    files['pubspec.yaml'] = '''
name: ${cleanPkgName}_test_runner
description: Isolated test runner project for $cleanPkgName.
version: 1.0.0
publish_to: 'none'

environment:
  sdk: '${options.config.sdkConstraint}'

dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.24.0
''';

    // analysis_options.yaml
    files['analysis_options.yaml'] = '''
include: package:flutter_lints/flutter.yaml
''';

    // test entrypoint
    files['test/${cleanPkgName}_test.dart'] = '''
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('$cleanPkgName Test Project Suite', () {
    test('Initial test project assertion', () {
      expect(true, isTrue);
    });
  });
}
''';

    return TestProjectResult(
      packageName: plan.packageName,
      files: Map.unmodifiable(files),
    );
  }
}
