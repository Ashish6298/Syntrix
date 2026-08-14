import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';
import 'package:flutter_package_studio_cli/src/commands/template_command.dart';

export 'package:flutter_package_studio_cli/src/commands/template_command.dart';

/// Command to create a new production-ready Flutter package.
class CreateCommand extends FpsCommand {
  @override
  final String name = 'create';

  @override
  final String description =
      'Create a new production-ready Flutter package template.';

  /// Creates a [CreateCommand] instance and sets CLI options.
  CreateCommand() {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'The package name identifier.',
    );
    argParser.addOption(
      'org',
      abbr: 'o',
      help: 'The organization reverse domain prefix.',
      defaultsTo: 'com.example',
    );
    argParser.addOption(
      'template',
      abbr: 't',
      help: 'Project template archetype.',
      defaultsTo: 'standard',
    );
    argParser.addOption(
      'output',
      abbr: 'd',
      help: 'Target output directory.',
      defaultsTo: '.',
    );

    argParser.addFlag(
      'interactive',
      abbr: 'i',
      defaultsTo: true,
      help: 'Launch interactive project wizard if inputs are unspecified.',
    );
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Preview project generation without writing files to disk.',
    );
    argParser.addOption(
      'overwrite',
      help: 'Overwrite policy for existing files (fail, skip, overwrite).',
      defaultsTo: 'fail',
    );
    argParser.addOption(
      'license',
      abbr: 'l',
      help:
          'Open-source license (MIT, Apache-2.0, BSD-3-Clause, GPL-3.0, none).',
      defaultsTo: 'MIT',
    );
    argParser.addOption(
      'preset',
      abbr: 'p',
      help:
          'Repository profile preset (minimal, standard, open_source, maintainer).',
      defaultsTo: 'standard',
    );
    argParser.addFlag(
      'git',
      defaultsTo: true,
      help: 'Initialize local Git repository.',
    );
    argParser.addFlag(
      'ci',
      defaultsTo: true,
      help: 'Generate GitHub Actions CI workflow.',
    );
    argParser.addFlag(
      'example',
      defaultsTo: true,
      help: 'Generate runnable isolated Flutter example application.',
    );
    argParser.addOption(
      'example-template',
      help: 'Example application template (standard, minimal).',
      defaultsTo: 'standard',
    );
    argParser.addOption(
      'example-dir',
      help: 'Example application directory name.',
      defaultsTo: 'example',
    );
    argParser.addFlag(
      'github',
      defaultsTo: false,
      help: 'Automate remote GitHub repository creation and remote push.',
    );
    argParser.addOption(
      'github-owner',
      help: 'GitHub user or organization owner account.',
      defaultsTo: '',
    );
    argParser.addFlag(
      'github-private',
      defaultsTo: false,
      help: 'Make created GitHub repository private.',
    );
  }

  @override
  Future<int> run() async {
    logger.info('Executing package creation...');

    final nameArg = argResults?['name'] as String?;
    final isInteractive = argResults?['interactive'] as bool? ?? true;
    final isDryRun = argResults?['dry-run'] as bool? ?? false;
    final overwritePolicyStr = argResults?['overwrite'] as String? ?? 'fail';

    final container = DependencyContainer();
    final terminal = container.isRegistered<TerminalUtils>()
        ? container.resolve<TerminalUtils>()
        : const SystemTerminalUtils();
    final fileUtils = container.isRegistered<FileUtils>()
        ? container.resolve<FileUtils>()
        : const SystemFileUtils();

    // Registry setup
    final registry = container.isRegistered<TemplateRegistry>()
        ? container.resolve<TemplateRegistry>()
        : TemplateRegistry();
    BuiltinTemplates.registerDefaultTemplates(registry);

    WizardContext wizardContext = WizardContext(
      packageName: nameArg ?? '',
      orgName: argResults?['org'] as String? ?? 'com.example',
      templateSelection:
          argResults?['template'] as String? ?? 'flutter_package',
      outputDirectory: argResults?['output'] as String? ?? '.',
    );

    if (isInteractive && (nameArg == null || nameArg.isEmpty)) {
      final engine = WizardEngine(
        renderer: WizardRenderer.fromTerminal(terminal),
      );
      final flow = WizardFlow.standard(fileUtils: fileUtils);
      final session = WizardSession(
        sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
        context: wizardContext,
      );

      final result = await engine.run(flow: flow, session: session);
      if (result is WizardSuccess) {
        wizardContext = result.context;
      } else if (result is WizardCancelled) {
        logger.warning(result.message);
        return 0;
      } else if (result is WizardFailure) {
        logger.error(result.message);
        return 1;
      }
    } else {
      // Non-interactive execution validation
      final validator = const PackageNameValidator();
      final valRes = validator.validate(wizardContext.packageName);
      if (!valRes.isValid) {
        logger.error(valRes.errors.join('\n'));
        return 1;
      }
    }

    // Resolve template & execute generator
    final templateId = wizardContext.templateSelection == 'standard' ||
            wizardContext.templateSelection.isEmpty
        ? 'flutter_package'
        : wizardContext.templateSelection;
    final template =
        registry.get(templateId) ?? registry.get('flutter_package');

    if (template == null) {
      logger.error('Template with ID "$templateId" could not be resolved.');
      return 1;
    }

    final overwritePolicy = OverwritePolicy.values.firstWhere(
      (p) => p.name == overwritePolicyStr.toLowerCase(),
      orElse: () => OverwritePolicy.fail,
    );

    final generator = ProjectGenerator(fileUtils: fileUtils);
    final templateContext = TemplateContext.fromWizardContext(wizardContext);

    final targetOutputDir = wizardContext.outputDirectory == '.'
        ? './${wizardContext.packageName}'
        : wizardContext.outputDirectory;

    try {
      final plan = generator.buildPlan(
        template: template,
        context: templateContext,
        outputDirectory: targetOutputDir,
        overwritePolicy: overwritePolicy,
      );

      final result = await generator.execute(plan: plan, dryRun: isDryRun);

      if (!result.isSuccess) {
        logger.error('Project generation failed: ${result.errors.join(', ')}');
        return 1;
      }

      // Execute repository generation
      final repoOptions = RepositoryOptions.fromWizardContext(
        wizardContext,
        preset: argResults?['preset'] as String?,
        license: argResults?['license'] as String?,
        gitInit: argResults?['git'] as bool?,
        generateCi: argResults?['ci'] as bool?,
      );

      final repoGenerator = RepositoryGenerator(
        fileUtils: fileUtils,
        logger: logger,
      );

      final repoPlan = repoGenerator.buildPlan(
        options: repoOptions,
        context: templateContext,
        outputDirectory: targetOutputDir,
        overwritePolicy: overwritePolicy,
      );

      final repoResult = await repoGenerator.execute(
        plan: repoPlan,
        dryRun: isDryRun,
      );

      if (!repoResult.isSuccess) {
        logger.error('Repository generation failed.');
        return 1;
      }

      // Execute Example Application Generation if enabled
      final generateExample = argResults?['example'] as bool? ?? true;
      if (generateExample) {
        final exampleOptions = ExampleOptions.fromWizardContext(
          wizardContext,
          exampleDirName: argResults?['example-dir'] as String?,
          templateId: argResults?['example-template'] as String?,
          overwritePolicy: overwritePolicy,
        );

        final exampleGenerator = ExampleGenerator(
          fileUtils: fileUtils,
          logger: logger,
        );

        final examplePlan = exampleGenerator.buildPlan(
          options: exampleOptions,
          context: templateContext,
          packageDirectory: targetOutputDir,
        );

        final exampleResult = await exampleGenerator.execute(
          plan: examplePlan,
          dryRun: isDryRun,
        );

        if (!exampleResult.isSuccess) {
          final failure = exampleResult as ExampleGenerationFailure;
          logger.error(
              'Example application generation failed: ${failure.errors.join(', ')}');
          return 1;
        }
      }

      // Execute GitHub Automation if enabled
      final enableGitHub = argResults?['github'] as bool? ?? false;
      if (enableGitHub) {
        final githubOptions = GitHubOptions.fromWizardContext(
          wizardContext,
          owner: argResults?['github-owner'] as String?,
          isPrivate: argResults?['github-private'] as bool?,
        );

        final githubGenerator = GitHubRepositoryGenerator(
          fileUtils: fileUtils,
          logger: logger,
        );

        final githubPlan = await githubGenerator.buildPlan(
          options: githubOptions,
          context: templateContext,
          projectDirectory: targetOutputDir,
        );

        final githubResult = await githubGenerator.execute(
          plan: githubPlan,
          options: githubOptions,
          projectDirectory: targetOutputDir,
          dryRun: isDryRun,
        );

        if (!githubResult.isSuccess) {
          final failure = githubResult as GitHubAutomationFailure;
          logger
              .error('GitHub automation failed: ${failure.errors.join(', ')}');
          return 1;
        }
      }

      if (isDryRun) {
        logger.info(
            '[DRY RUN] Project, repository, example, and GitHub generation preview complete.');
      } else {
        logger.info(
            'Project, repository, example, and GitHub automation completed successfully.');
      }
      return 0;
    } catch (e) {
      logger.error(
          'Project, repository, example, or GitHub automation plan failed: $e');
      return 1;
    }
  }
}

/// Command to audit a Flutter package for structure, rules, and pub.dev score.
class AuditCommand extends FpsCommand {
  @override
  final String name = 'audit';

  @override
  final String description =
      'Audit package structure, standards, and compatibility.';

  AuditCommand() {
    argParser.addOption(
      'target',
      abbr: 't',
      help: 'Target package directory to audit.',
      defaultsTo: '.',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Validation profile (basic, standard, strict, release).',
      defaultsTo: 'standard',
    );
    argParser.addFlag(
      'json',
      defaultsTo: false,
      help: 'Output report in JSON format.',
    );
  }

  @override
  Future<int> run() async {
    final targetDir = argResults?['target'] as String? ?? '.';
    final profile = argResults?['profile'] as String? ?? 'standard';
    final isJson = argResults?['json'] as bool? ?? false;

    logger.info(
        'Executing package audit for "$targetDir" (profile: $profile)...');

    final engine = ValidationEngine(
      fileUtils: const SystemFileUtils(),
      logger: logger,
    );

    final request = ValidationRequest(
      targetDirectory: targetDir,
      profile: profile,
    );

    final report = await engine.validate(request);
    final reporter =
        isJson ? JsonValidationReporter() : TextValidationReporter();

    final output = reporter.render(report);
    if (isJson) {
      print(output);
    } else {
      logger.info('\n$output');
    }

    return report.isValid ? 0 : 1;
  }
}

/// Command to orchestrate package release tagging and changelogs.
class ReleaseCommand extends FpsCommand {
  @override
  final String name = 'release';

  @override
  final String description =
      'Orchestrate package versioning, changelogs, and release tags.';

  @override
  Future<int> run() async {
    logger.info('Executing release pipeline...');
    return 0;
  }
}

/// Command to generate API documentation and markdown docs.
class DocsCommand extends FpsCommand {
  @override
  final String name = 'docs';

  @override
  final String description = 'Generate API documentation and site assets.';

  @override
  Future<int> run() async {
    logger.info('Generating documentation...');
    return 0;
  }
}

/// Command to validate and publish a package to pub.dev.
class PublishCommand extends FpsCommand {
  @override
  final String name = 'publish';

  @override
  final String description =
      'Publish the package to pub.dev or private servers.';

  @override
  Future<int> run() async {
    logger.info('Publishing package...');
    return 0;
  }
}

/// Command to manage workspace templates.
///
/// Delegates to [TemplateCatalogCommand] which hosts the full `list`, `search`,
/// and `info` subcommand family.
///
/// [TemplateCommand] is kept as a type alias for backward compatibility with
/// existing code that registers it by name.
// ignore: camel_case_types
typedef TemplateCommand = TemplateCatalogCommand;

/// Command to manage CLI plugins.
class PluginCommand extends FpsCommand {
  @override
  final String name = 'plugin';

  @override
  final String description = 'Manage extensions and plugin registrations.';

  @override
  Future<int> run() async {
    logger.info('Managing plugins...');
    return 0;
  }
}
