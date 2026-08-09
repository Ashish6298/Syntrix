import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/repository/ci_workflow_builder.dart';
import 'package:flutter_package_studio_core/src/repository/git_service.dart';
import 'package:flutter_package_studio_core/src/repository/gitignore_builder.dart';
import 'package:flutter_package_studio_core/src/repository/repository_file_generator.dart';
import 'package:flutter_package_studio_core/src/repository/repository_generation_plan.dart';
import 'package:flutter_package_studio_core/src/repository/repository_generation_result.dart';
import 'package:flutter_package_studio_core/src/repository/repository_options.dart';
import 'package:flutter_package_studio_core/src/repository/repository_presets.dart';
import 'package:flutter_package_studio_core/src/template/generation_plan.dart';
import 'package:flutter_package_studio_core/src/template/project_generator.dart';
import 'package:flutter_package_studio_core/src/template/template_context.dart';
import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/validation/validators.dart';

/// Core Repository Generator responsible for creating repository files and initializing Git.
class RepositoryGenerator {
  final FileUtils _fileUtils;
  final GitService _gitService;
  final RepositoryFileGenerator _fileGenerator;
  final Logger _logger;

  /// Creates a [RepositoryGenerator] with dependencies.
  RepositoryGenerator({
    FileUtils fileUtils = const SystemFileUtils(),
    GitService? gitService,
    RepositoryFileGenerator? fileGenerator,
    Logger? logger,
  })  : _fileUtils = fileUtils,
        _gitService = gitService ?? SystemGitService(logger: logger),
        _fileGenerator = fileGenerator ?? RepositoryFileGenerator(),
        _logger = logger ?? Logger('RepositoryGenerator');

  /// Validates [options] using core validation framework.
  void validateOptions(RepositoryOptions options) {
    final repoNameRes =
        const RepositoryNameValidator().validate(options.repositoryName);
    if (!repoNameRes.isValid) {
      throw ValidationException(
          'Invalid repository name: ${repoNameRes.errors.join(', ')}');
    }

    final branchRes = const GitBranchValidator().validate(options.branchName);
    if (!branchRes.isValid) {
      throw ValidationException(
          'Invalid Git branch: ${branchRes.errors.join(', ')}');
    }

    final licenseRes =
        const LicenseIdentifierValidator().validate(options.license);
    if (!licenseRes.isValid) {
      throw ValidationException(
          'Invalid license choice: ${licenseRes.errors.join(', ')}');
    }

    final repoUrlRes =
        const UrlValidator(allowEmpty: true).validate(options.repositoryUrl);
    if (!repoUrlRes.isValid) {
      throw ValidationException(
          'Invalid repository URL: ${repoUrlRes.errors.join(', ')}');
    }
  }

  /// Constructs an in-memory inspectable [RepositoryGenerationPlan] without mutating the filesystem.
  RepositoryGenerationPlan buildPlan({
    required RepositoryOptions options,
    required TemplateContext context,
    required String outputDirectory,
    OverwritePolicy overwritePolicy = OverwritePolicy.fail,
  }) {
    validateOptions(options);

    final rootDir = p.normalize(p.absolute(outputDirectory));
    final preset = RepositoryPreset.resolve(options.preset);
    final effectiveOptions = _mergePreset(options, preset);

    final actions = <RepositoryAction>[];

    // Helper to evaluate overwrite and path sanitization
    void addFileAction(String relPath, String content) {
      final absPath = _sanitizePath(rootDir, relPath);
      if (_fileUtils.exists(absPath)) {
        if (overwritePolicy == OverwritePolicy.fail) {
          actions.add(RepositoryAction(
            type: ActionType.overwriteFile,
            relativePath: relPath,
            absolutePath: absPath,
            textContent: content,
          ));
        } else if (overwritePolicy == OverwritePolicy.skip) {
          actions.add(RepositoryAction(
            type: ActionType.skip,
            relativePath: relPath,
            absolutePath: absPath,
            reason: 'File exists (OverwritePolicy.skip)',
          ));
        } else {
          actions.add(RepositoryAction(
            type: ActionType.overwriteFile,
            relativePath: relPath,
            absolutePath: absPath,
            textContent: content,
          ));
        }
      } else {
        actions.add(RepositoryAction(
          type: ActionType.createFile,
          relativePath: relPath,
          absolutePath: absPath,
          textContent: content,
        ));
      }
    }

    // 1. README.md
    if (effectiveOptions.generateReadme) {
      addFileAction('README.md',
          _fileGenerator.generateReadme(effectiveOptions, context));
    }

    // 2. CHANGELOG.md
    if (effectiveOptions.generateChangelog) {
      addFileAction('CHANGELOG.md',
          _fileGenerator.generateChangelog(effectiveOptions, context));
    }

    // 3. LICENSE
    if (effectiveOptions.license.isNotEmpty &&
        effectiveOptions.license.toLowerCase() != 'none') {
      addFileAction(
          'LICENSE', _fileGenerator.generateLicense(effectiveOptions, context));
    }

    // 4. .gitignore
    if (effectiveOptions.generateGitignore) {
      final isFlutter = context.get('is_flutter') as bool? ?? true;
      addFileAction(
          '.gitignore', GitignoreBuilder.buildGitignore(isFlutter: isFlutter));
    }

    // 5. CONTRIBUTING.md
    if (effectiveOptions.generateContributing) {
      addFileAction('CONTRIBUTING.md',
          _fileGenerator.generateContributing(effectiveOptions, context));
    }

    // 6. CODE_OF_CONDUCT.md
    if (effectiveOptions.generateCodeOfConduct) {
      addFileAction('CODE_OF_CONDUCT.md',
          _fileGenerator.generateCodeOfConduct(effectiveOptions, context));
    }

    // 7. SECURITY.md
    if (effectiveOptions.generateSecurity) {
      addFileAction('SECURITY.md',
          _fileGenerator.generateSecurity(effectiveOptions, context));
    }

    // 8. CI Workflow (.github/workflows/ci.yml)
    if (effectiveOptions.generateCi) {
      final isFlutter = context.get('is_flutter') as bool? ?? true;
      final ciContent = CiWorkflowBuilder.buildGitHubWorkflow(
        packageName: effectiveOptions.repositoryName,
        isFlutter: isFlutter,
      );
      addFileAction('.github/workflows/ci.yml', ciContent);
    }

    return RepositoryGenerationPlan(
      rootDirectory: rootDir,
      presetId: effectiveOptions.preset,
      licenseId: effectiveOptions.license,
      actions: actions,
      executeGitInit: effectiveOptions.gitInit,
      branchName: effectiveOptions.branchName,
    );
  }

  /// Executes [plan] against filesystem and Git.
  Future<RepositoryGenerationResult> execute({
    required RepositoryGenerationPlan plan,
    bool dryRun = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final createdFiles = <String>[];
    final skippedFiles = <String>[];
    final warnings = <String>[];
    bool gitInitialized = false;

    _logger.info(
        'Executing repository generation in "${plan.rootDirectory}" (dryRun: $dryRun)');

    if (dryRun) {
      stopwatch.stop();
      return RepositoryGenerationSuccess(
        targetPath: plan.rootDirectory,
        duration: stopwatch.elapsed,
        isDryRun: true,
        createdFiles: plan.actions.map((a) => a.relativePath).toList(),
        skippedFiles: [],
        gitInitialized: false,
        preset: plan.presetId,
        license: plan.licenseId,
      );
    }

    try {
      // 1. Filesystem writes
      for (final action in plan.actions) {
        if (action.type == ActionType.skip) {
          skippedFiles.add(action.relativePath);
          continue;
        }

        if (action.type == ActionType.createFile ||
            action.type == ActionType.overwriteFile) {
          if (action.textContent != null) {
            _fileUtils.writeString(action.absolutePath, action.textContent!);
            createdFiles.add(action.relativePath);
          }
        }
      }

      // 2. Git initialization
      if (plan.executeGitInit) {
        final gitAvailable = await _gitService.isGitInstalled();
        if (gitAvailable) {
          await _gitService.initRepository(plan.rootDirectory,
              defaultBranch: plan.branchName);
          gitInitialized = true;
        } else {
          warnings.add(
              'Git executable is not installed or available on PATH. Skipped git init.');
          _logger.warning(
              'Git CLI not found on PATH. Skipped local git initialization.');
        }
      }

      stopwatch.stop();
      return RepositoryGenerationSuccess(
        targetPath: plan.rootDirectory,
        duration: stopwatch.elapsed,
        isDryRun: false,
        createdFiles: createdFiles,
        skippedFiles: skippedFiles,
        gitInitialized: gitInitialized,
        preset: plan.presetId,
        license: plan.licenseId,
        warnings: warnings,
      );
    } catch (e, st) {
      stopwatch.stop();
      _logger.error('Repository generation failed: $e', e, st);
      return RepositoryGenerationFailure(
        targetPath: plan.rootDirectory,
        duration: stopwatch.elapsed,
        isDryRun: false,
        message: 'Repository generation failed: $e',
        errors: [e.toString()],
      );
    }
  }

  /// Merges user options with preset defaults.
  RepositoryOptions _mergePreset(
      RepositoryOptions userOptions, RepositoryPreset preset) {
    final pOpt = preset.options;
    return RepositoryOptions(
      repositoryName: userOptions.repositoryName,
      description: userOptions.description,
      author: userOptions.author,
      email: userOptions.email,
      license: userOptions.license,
      branchName: userOptions.branchName,
      repositoryUrl: userOptions.repositoryUrl,
      homepageUrl: userOptions.homepageUrl,
      issueTrackerUrl: userOptions.issueTrackerUrl,
      documentationUrl: userOptions.documentationUrl,
      preset: preset.id,
      gitInit: userOptions.gitInit,
      generateReadme: userOptions.generateReadme && pOpt.generateReadme,
      generateChangelog:
          userOptions.generateChangelog && pOpt.generateChangelog,
      generateContributing:
          userOptions.generateContributing && pOpt.generateContributing,
      generateCodeOfConduct:
          userOptions.generateCodeOfConduct && pOpt.generateCodeOfConduct,
      generateSecurity: userOptions.generateSecurity && pOpt.generateSecurity,
      generateCi: userOptions.generateCi && pOpt.generateCi,
      generateGitignore:
          userOptions.generateGitignore && pOpt.generateGitignore,
    );
  }

  /// Sanitizes [relativePath] relative to [rootDir] and enforces path traversal security rules.
  String _sanitizePath(String rootDir, String relativePath) {
    final normalizedRel = p.normalize(relativePath);
    if (p.isAbsolute(normalizedRel)) {
      throw RepositoryException(
          'Absolute path rejected in repository generation: "$relativePath".');
    }

    final resolvedAbs = p.normalize(p.join(rootDir, normalizedRel));
    if (!resolvedAbs.startsWith(rootDir)) {
      throw RepositoryException(
          'Path traversal security violation detected: "$relativePath".');
    }

    return resolvedAbs;
  }
}
