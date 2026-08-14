import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/template/generation_plan.dart';
import 'package:flutter_package_studio_core/src/template/generation_result.dart';
import 'package:flutter_package_studio_core/src/template/resolved_template.dart';
import 'package:flutter_package_studio_core/src/template/template_condition.dart';
import 'package:flutter_package_studio_core/src/template/template_context.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';
import 'package:flutter_package_studio_core/src/template/template_renderer.dart';
import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/validation/validators.dart';

/// Overwrite collision resolution policy for existing files.
enum OverwritePolicy {
  /// Fail generation immediately if file or directory exists.
  fail,

  /// Skip existing files and continue.
  skip,

  /// Overwrite existing files.
  overwrite,
}

/// Core project generator constructing and executing [GenerationPlan]s.
class ProjectGenerator {
  final FileUtils _fileUtils;
  final TemplateRenderer _renderer;
  final Logger _logger = Logger('ProjectGenerator');

  /// Creates a [ProjectGenerator] with dependency on [_fileUtils] and [_renderer].
  ProjectGenerator({
    FileUtils fileUtils = const SystemFileUtils(),
    TemplateRenderer? renderer,
  })  : _fileUtils = fileUtils,
        _renderer = renderer ?? TemplateRenderer();

  /// Constructs a [GenerationPlan] from a composed [ResolvedTemplate].
  GenerationPlan buildPlanFromResolved({
    required ResolvedTemplate resolvedTemplate,
    required TemplateContext context,
    required String outputDirectory,
    OverwritePolicy overwritePolicy = OverwritePolicy.fail,
  }) {
    final pkgName = context.get('package_name') as String?;
    if (pkgName != null && pkgName.isNotEmpty) {
      final nameRes = PackageNameValidator().validate(pkgName);
      if (!nameRes.isValid) {
        throw ValidationException(
            'Invalid package name: ${nameRes.errors.join(', ')}');
      }
    }

    final rootDir = p.normalize(p.absolute(outputDirectory));
    final actions = <GenerationAction>[];

    // Directories
    for (final dirPattern in resolvedTemplate.effectiveManifest.directories) {
      final renderedRel = _renderer.renderPath(dirPattern, context);
      final absPath = _sanitizePath(rootDir, renderedRel);
      actions.add(GenerationAction(
        type: ActionType.createDir,
        relativePath: renderedRel,
        absolutePath: absPath,
        sourceTemplateId: resolvedTemplate.baseTemplate.id,
      ));
    }

    // Files with provenance
    resolvedTemplate.files.forEach((path, contentTemplate) {
      final renderedRel = _renderer.renderPath(path, context);
      final absPath = _sanitizePath(rootDir, renderedRel);
      final sourceId = resolvedTemplate.fileProvenance[path] ??
          resolvedTemplate.baseTemplate.id;

      final textContent = _renderer.renderText(contentTemplate, context);

      actions.add(GenerationAction(
        type: _fileUtils.exists(absPath) &&
                overwritePolicy == OverwritePolicy.overwrite
            ? ActionType.overwriteFile
            : ActionType.createFile,
        relativePath: renderedRel,
        absolutePath: absPath,
        textContent: textContent,
        sourceTemplateId: sourceId,
      ));
    });

    return GenerationPlan(
      targetDirectory: rootDir,
      templateId: resolvedTemplate.id,
      actions: actions,
      conditionResults: const {},
      variablesUsed: context.toMap(),
    );
  }

  /// Constructs an in-memory inspectable [GenerationPlan] without mutating the filesystem.
  /// Throws [TemplateException] on path traversal security violations or invalid arguments.
  GenerationPlan buildPlan({
    required Template template,
    required TemplateContext context,
    required String outputDirectory,
    OverwritePolicy overwritePolicy = OverwritePolicy.fail,
  }) {
    final pkgName = context.get('package_name') as String?;
    if (pkgName != null && pkgName.isNotEmpty) {
      final nameRes = PackageNameValidator().validate(pkgName);
      if (!nameRes.isValid) {
        throw ValidationException(
            'Invalid package name: ${nameRes.errors.join(', ')}');
      }
    }

    final rootDir = p.normalize(p.absolute(outputDirectory));

    final actions = <GenerationAction>[];
    final conditionResults = <String, bool>{};

    // 1. Directories
    for (final dirPattern in template.manifest.directories) {
      final renderedRel = _renderer.renderPath(dirPattern, context);
      final absPath = _sanitizePath(rootDir, renderedRel);

      if (_fileUtils.exists(absPath)) {
        actions.add(GenerationAction(
          type: ActionType.skip,
          relativePath: renderedRel,
          absolutePath: absPath,
          reason: 'Directory already exists',
        ));
      } else {
        actions.add(GenerationAction(
          type: ActionType.createDir,
          relativePath: renderedRel,
          absolutePath: absPath,
        ));
      }
    }

    // 2. Text Files
    template.fileTemplates.forEach((relPattern, contentTemplate) {
      final renderedRel = _renderer.renderPath(relPattern, context);
      final absPath = _sanitizePath(rootDir, renderedRel);

      // Evaluate condition if specified
      final conditionExpr = template.manifest.conditions[relPattern];
      if (conditionExpr != null) {
        final pass = TemplateCondition.evaluate(conditionExpr, context);
        conditionResults[relPattern] = pass;
        if (!pass) return; // Skip conditional file
      }

      final renderedContent = _renderer.renderText(contentTemplate, context);

      if (_fileUtils.exists(absPath)) {
        if (overwritePolicy == OverwritePolicy.fail) {
          throw TemplateException(
              'File already exists at target path: "$absPath".');
        } else if (overwritePolicy == OverwritePolicy.skip) {
          actions.add(GenerationAction(
            type: ActionType.skip,
            relativePath: renderedRel,
            absolutePath: absPath,
            reason: 'File already exists (OverwritePolicy.skip)',
          ));
        } else {
          actions.add(GenerationAction(
            type: ActionType.overwriteFile,
            relativePath: renderedRel,
            absolutePath: absPath,
            textContent: renderedContent,
          ));
        }
      } else {
        actions.add(GenerationAction(
          type: ActionType.createFile,
          relativePath: renderedRel,
          absolutePath: absPath,
          textContent: renderedContent,
        ));
      }
    });

    // 3. Binary Assets
    template.binaryTemplates.forEach((relPattern, bytes) {
      final renderedRel = _renderer.renderPath(relPattern, context);
      final absPath = _sanitizePath(rootDir, renderedRel);

      if (_fileUtils.exists(absPath)) {
        if (overwritePolicy == OverwritePolicy.fail) {
          throw TemplateException(
              'Binary asset already exists at target path: "$absPath".');
        } else if (overwritePolicy == OverwritePolicy.skip) {
          actions.add(GenerationAction(
            type: ActionType.skip,
            relativePath: renderedRel,
            absolutePath: absPath,
            reason: 'Asset already exists',
          ));
        } else {
          actions.add(GenerationAction(
            type: ActionType.overwriteFile,
            relativePath: renderedRel,
            absolutePath: absPath,
            binaryContent: bytes,
          ));
        }
      } else {
        actions.add(GenerationAction(
          type: ActionType.createFile,
          relativePath: renderedRel,
          absolutePath: absPath,
          binaryContent: bytes,
        ));
      }
    });

    return GenerationPlan(
      targetDirectory: rootDir,
      templateId: template.id,
      actions: actions,
      conditionResults: conditionResults,
      variablesUsed: context.toMap(),
    );
  }

  /// Executes [plan] on the filesystem. If [dryRun] is true, returns simulated result without mutating filesystem.
  Future<GenerationResult> execute({
    required GenerationPlan plan,
    bool dryRun = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    _logger.info(
        'Executing project generation plan (dryRun: $dryRun) for template: ${plan.templateId}');

    final filesCreated = <String>[];
    final directoriesCreated = <String>[];
    final filesSkipped = <String>[];
    final warnings = <String>[];
    final errors = <String>[];

    if (dryRun) {
      for (final action in plan.actions) {
        switch (action.type) {
          case ActionType.createDir:
            directoriesCreated.add(action.relativePath);
            break;
          case ActionType.createFile:
          case ActionType.overwriteFile:
            filesCreated.add(action.relativePath);
            break;
          case ActionType.skip:
            filesSkipped.add(action.relativePath);
            break;
        }
      }

      stopwatch.stop();
      return GenerationResult(
        isSuccess: true,
        isDryRun: true,
        templateId: plan.templateId,
        outputDirectory: plan.targetDirectory,
        filesCreated: filesCreated,
        directoriesCreated: directoriesCreated,
        filesSkipped: filesSkipped,
        warnings: warnings,
        errors: errors,
        duration: stopwatch.elapsed,
      );
    }

    // Real Filesystem Execution
    try {
      for (final action in plan.actions) {
        switch (action.type) {
          case ActionType.createDir:
            _fileUtils.createDirectory(action.absolutePath);
            directoriesCreated.add(action.relativePath);
            break;
          case ActionType.createFile:
          case ActionType.overwriteFile:
            // Ensure parent directory exists
            final parentDir = p.dirname(action.absolutePath);
            if (!_fileUtils.exists(parentDir)) {
              _fileUtils.createDirectory(parentDir);
            }

            if (action.isBinary) {
              // Binary copy placeholder for future asset writing
              filesCreated.add(action.relativePath);
            } else {
              _fileUtils.writeString(
                  action.absolutePath, action.textContent ?? '');
              filesCreated.add(action.relativePath);
            }
            break;
          case ActionType.skip:
            filesSkipped.add(action.relativePath);
            warnings.add('Skipped existing file at "${action.relativePath}"');
            break;
        }
      }

      stopwatch.stop();
      _logger.info(
          'Project generation completed successfully in ${stopwatch.elapsedMilliseconds}ms.');
      return GenerationResult(
        isSuccess: true,
        isDryRun: false,
        templateId: plan.templateId,
        outputDirectory: plan.targetDirectory,
        filesCreated: filesCreated,
        directoriesCreated: directoriesCreated,
        filesSkipped: filesSkipped,
        warnings: warnings,
        errors: errors,
        duration: stopwatch.elapsed,
      );
    } catch (e, st) {
      stopwatch.stop();
      _logger.error('Project generation failed: $e', e, st);
      errors.add('Generation failed: $e');
      return GenerationResult(
        isSuccess: false,
        isDryRun: false,
        templateId: plan.templateId,
        outputDirectory: plan.targetDirectory,
        filesCreated: filesCreated,
        directoriesCreated: directoriesCreated,
        filesSkipped: filesSkipped,
        warnings: warnings,
        errors: errors,
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Sanitizes [relativePath] against [rootDir] preventing path traversal outside root directory.
  String _sanitizePath(String rootDir, String relativePath) {
    final joined = p.normalize(p.join(rootDir, relativePath));
    if (!joined.startsWith(rootDir)) {
      throw TemplateException(
        'Security violation: Target path "$relativePath" attempts path traversal outside output directory "$rootDir".',
      );
    }
    return joined;
  }
}
