import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/example/example_generation_plan.dart';
import 'package:flutter_package_studio_core/src/example/example_generation_result.dart';
import 'package:flutter_package_studio_core/src/example/example_options.dart';
import 'package:flutter_package_studio_core/src/example/example_project_validator.dart';
import 'package:flutter_package_studio_core/src/example/example_template.dart';
import 'package:flutter_package_studio_core/src/example/flutter_project_service.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/template/generation_plan.dart';
import 'package:flutter_package_studio_core/src/template/project_generator.dart';
import 'package:flutter_package_studio_core/src/template/template_context.dart';

import 'package:flutter_package_studio_core/src/template/template_renderer.dart';
import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/validation/validators.dart';

/// Generator for isolated, runnable Flutter example applications.
class ExampleGenerator {
  final FileUtils _fileUtils;
  final FlutterProjectService _flutterService;
  final ExampleTemplateRegistry _templateRegistry;
  final TemplateRenderer _renderer;
  final Logger _logger;

  /// Creates an [ExampleGenerator] with dependencies.
  ExampleGenerator({
    FileUtils fileUtils = const SystemFileUtils(),
    FlutterProjectService? flutterService,
    ExampleTemplateRegistry? templateRegistry,
    TemplateRenderer? renderer,
    Logger? logger,
  })  : _fileUtils = fileUtils,
        _flutterService =
            flutterService ?? SystemFlutterProjectService(logger: logger),
        _templateRegistry = templateRegistry ?? ExampleTemplateRegistry(),
        _renderer = renderer ?? TemplateRenderer(),
        _logger = logger ?? Logger('ExampleGenerator');

  /// Validates options using [PackageNameValidator].
  void validateOptions(ExampleOptions options) {
    final nameRes = const PackageNameValidator().validate(options.appName);
    if (!nameRes.isValid) {
      throw ValidationException(
          'Invalid example app name: ${nameRes.errors.join(', ')}');
    }
  }

  /// Constructs an in-memory inspectable [ExampleGenerationPlan] without mutating the filesystem.
  ExampleGenerationPlan buildPlan({
    required ExampleOptions options,
    required TemplateContext context,
    required String packageDirectory,
  }) {
    validateOptions(options);

    final pkgRootDir = p.normalize(p.absolute(packageDirectory));
    final exampleRootDir = _sanitizePath(pkgRootDir, options.exampleDirName);

    final template = _templateRegistry.get(options.templateId);
    final actions = <ExampleAction>[];

    // Helper for dir actions
    void addDirAction(String relPath) {
      final absPath = _sanitizePath(exampleRootDir, relPath);
      actions.add(ExampleAction(
        type: ActionType.createDir,
        relativePath: relPath,
        absolutePath: absPath,
      ));
    }

    // Helper for file actions
    void addFileAction(String relPath, String content) {
      final absPath = _sanitizePath(exampleRootDir, relPath);
      if (_fileUtils.exists(absPath)) {
        if (options.overwritePolicy == OverwritePolicy.fail) {
          throw ExampleGenerationException(
              'Example file already exists at "$absPath".');
        } else if (options.overwritePolicy == OverwritePolicy.skip) {
          actions.add(ExampleAction(
            type: ActionType.skip,
            relativePath: relPath,
            absolutePath: absPath,
            reason: 'File exists (OverwritePolicy.skip)',
          ));
        } else {
          actions.add(ExampleAction(
            type: ActionType.overwriteFile,
            relativePath: relPath,
            absolutePath: absPath,
            textContent: content,
          ));
        }
      } else {
        actions.add(ExampleAction(
          type: ActionType.createFile,
          relativePath: relPath,
          absolutePath: absPath,
          textContent: content,
        ));
      }
    }

    // 1. Directory Structure
    addDirAction('');
    addDirAction('lib');
    if (options.generateTests) addDirAction('test');

    // 2. pubspec.yaml
    final pubspecContent = _buildPubspecContent(options, context);
    addFileAction('pubspec.yaml', pubspecContent);

    // 3. lib/main.dart
    final renderedMain =
        _renderer.renderText(template.mainDartTemplate, context);
    addFileAction('lib/main.dart', renderedMain);

    // 4. test/widget_test.dart
    if (options.generateTests) {
      final renderedTest =
          _renderer.renderText(template.widgetTestTemplate, context);
      addFileAction('test/widget_test.dart', renderedTest);
    }

    // 5. README.md
    if (options.generateReadme) {
      final readmeContent = _buildReadmeContent(options, context);
      addFileAction('README.md', readmeContent);
    }

    final pkgName =
        (context.get('package_name') as String?) ?? p.basename(pkgRootDir);

    return ExampleGenerationPlan(
      exampleDirectory: exampleRootDir,
      parentPackageDirectory: pkgRootDir,
      expectedPackageName: pkgName,
      templateId: template.id,
      actions: actions,
    );
  }

  /// Executes [plan] against filesystem.
  Future<ExampleGenerationResult> execute({
    required ExampleGenerationPlan plan,
    bool dryRun = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final createdFiles = <String>[];
    final skippedFiles = <String>[];

    _logger.info(
        'Executing example generation in "${plan.exampleDirectory}" (dryRun: $dryRun)');

    if (dryRun) {
      stopwatch.stop();
      return ExampleGenerationSuccess(
        targetPath: plan.exampleDirectory,
        duration: stopwatch.elapsed,
        isDryRun: true,
        createdFiles: plan.actions.map((a) => a.relativePath).toList(),
        skippedFiles: [],
        templateId: plan.templateId,
      );
    }

    try {
      // Verify Flutter SDK availability
      final hasFlutter = await _flutterService.isFlutterInstalled();
      if (!hasFlutter) {
        _logger.debug(
            'Flutter CLI not detected on PATH. Generated pure template example app structure.');
      }

      for (final action in plan.actions) {
        if (action.type == ActionType.skip) {
          skippedFiles.add(action.relativePath);
          continue;
        }

        if (action.type == ActionType.createDir) {
          _fileUtils.createDirectory(action.absolutePath);
        } else if (action.type == ActionType.createFile ||
            action.type == ActionType.overwriteFile) {
          if (action.textContent != null) {
            _fileUtils.writeString(action.absolutePath, action.textContent!);
            createdFiles.add(action.relativePath);
          }
        }
      }

      // Post-generation validation
      final validationRes =
          ExampleProjectValidator(fileUtils: _fileUtils).validate(
        plan.exampleDirectory,
        expectedPackageName: plan.expectedPackageName,
      );

      if (!validationRes.isValid) {
        throw ExampleGenerationException(
            'Example application structural validation failed: ${validationRes.errors.join(', ')}');
      }

      stopwatch.stop();
      return ExampleGenerationSuccess(
        targetPath: plan.exampleDirectory,
        duration: stopwatch.elapsed,
        isDryRun: false,
        createdFiles: createdFiles,
        skippedFiles: skippedFiles,
        templateId: plan.templateId,
      );
    } catch (e, st) {
      stopwatch.stop();
      _logger.error('Example generation failed: $e', e, st);
      return ExampleGenerationFailure(
        targetPath: plan.exampleDirectory,
        duration: stopwatch.elapsed,
        isDryRun: false,
        message: 'Example generation failed: $e',
        errors: [e.toString()],
      );
    }
  }

  String _buildPubspecContent(ExampleOptions options, TemplateContext context) {
    final pkgName = context.get('package_name') as String? ?? 'my_package';
    final appName = options.appName;

    return '''
name: $appName
description: Example application for package $pkgName.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter
  $pkgName:
    path: ../

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0

flutter:
  uses-material-design: true
''';
  }

  String _buildReadmeContent(ExampleOptions options, TemplateContext context) {
    final pkgName = context.get('package_name') as String? ?? 'my_package';
    final appName = options.appName;

    return '''
# $appName

An example application demonstrating usage of the `$pkgName` package.

## Getting Started

This project is a starting point for a Flutter application.

1. Ensure Flutter SDK is installed.
2. Run `flutter pub get` in this directory.
3. Launch the app using `flutter run`.

## Dependency Details

This example depends on the local `$pkgName` package via a path dependency in `pubspec.yaml`:

```yaml
dependencies:
  $pkgName:
    path: ../
```
''';
  }

  /// Sanitizes [relativePath] relative to [rootDir] and enforces path traversal security rules.
  String _sanitizePath(String rootDir, String relativePath) {
    final normalizedRel = p.normalize(relativePath);
    if (p.isAbsolute(normalizedRel)) {
      throw ExampleGenerationException(
          'Absolute path rejected in example generation: "$relativePath".');
    }

    final resolvedAbs = p.normalize(p.join(rootDir, normalizedRel));
    if (!resolvedAbs.startsWith(rootDir)) {
      throw ExampleGenerationException(
          'Path traversal security violation detected in example generation: "$relativePath".');
    }

    return resolvedAbs;
  }
}
