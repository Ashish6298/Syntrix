import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';

/// Structured result summary produced by [E2ETestHarness].
class E2ETestResult {
  final String targetDirectory;
  final GenerationResult projectResult;
  final RepositoryGenerationResult repoResult;
  final ExampleGenerationResult exampleResult;
  final ValidationReport validationReport;
  final GitHubAutomationResult githubResult;

  const E2ETestResult({
    required this.targetDirectory,
    required this.projectResult,
    required this.repoResult,
    required this.exampleResult,
    required this.validationReport,
    required this.githubResult,
  });

  bool get isOverallSuccess =>
      projectResult.isSuccess &&
      repoResult.isSuccess &&
      exampleResult.isSuccess &&
      validationReport.isValid &&
      githubResult.isSuccess;
}

/// Orchestrator harness for end-to-end FPS project creation and verification.
class E2ETestHarness {
  final FileUtils fileUtils;
  final Logger logger;

  E2ETestHarness({
    FileUtils? fileUtils,
    Logger? logger,
  })  : fileUtils = fileUtils ?? const SystemFileUtils(),
        logger = logger ?? Logger('E2ETestHarness');

  /// Runs complete end-to-end generation lifecycle inside [tempDirectory].
  Future<E2ETestResult> runLifecycle({
    required String tempDirectory,
    required WizardContext wizardContext,
    String repositoryPreset = 'standard',
    String exampleTemplateId = 'standard',
    String validationProfile = 'standard',
    bool isDryRun = false,
  }) async {
    final rootDir = p.normalize(p.absolute(tempDirectory));
    final templateContext = TemplateContext.fromWizardContext(wizardContext);

    // 1. Project Generator
    final template = BuiltinTemplates.flutterPackage;
    final projectGenerator = ProjectGenerator(fileUtils: fileUtils);

    final projectPlan = projectGenerator.buildPlan(
      template: template,
      context: templateContext,
      outputDirectory: rootDir,
    );
    final projectResult = await projectGenerator.execute(
      plan: projectPlan,
      dryRun: isDryRun,
    );

    // 2. Repository Generator
    final repoOptions = RepositoryOptions.fromWizardContext(wizardContext,
        preset: repositoryPreset);
    final repoGenerator = RepositoryGenerator(fileUtils: fileUtils);
    final repoPlan = repoGenerator.buildPlan(
      options: repoOptions,
      context: templateContext,
      outputDirectory: rootDir,
    );
    final repoResult = await repoGenerator.execute(
      plan: repoPlan,
      dryRun: isDryRun,
    );

    // 3. Example Generator
    final exampleOptions = ExampleOptions.fromWizardContext(wizardContext,
        templateId: exampleTemplateId);
    final exampleGenerator = ExampleGenerator(fileUtils: fileUtils);
    final examplePlan = exampleGenerator.buildPlan(
      options: exampleOptions,
      context: templateContext,
      packageDirectory: rootDir,
    );
    final exampleResult = await exampleGenerator.execute(
      plan: examplePlan,
      dryRun: isDryRun,
    );

    // 4. Validation Engine
    final validationEngine = ValidationEngine(fileUtils: fileUtils);
    final validationRequest = ValidationRequest(
      targetDirectory: rootDir,
      profile: validationProfile,
    );
    final validationReport = await validationEngine.validate(validationRequest);

    // 5. GitHub Generator (Mocked)
    final githubOptions = GitHubOptions.fromWizardContext(wizardContext);
    final githubGenerator = GitHubRepositoryGenerator(
      fileUtils: fileUtils,
      githubService: MockableGitHubService(),
    );
    final githubPlan = await githubGenerator.buildPlan(
      options: githubOptions,
      context: templateContext,
      projectDirectory: rootDir,
    );
    final githubResult = await githubGenerator.execute(
      plan: githubPlan,
      options: githubOptions,
      projectDirectory: rootDir,
      dryRun: isDryRun,
    );

    return E2ETestResult(
      targetDirectory: rootDir,
      projectResult: projectResult,
      repoResult: repoResult,
      exampleResult: exampleResult,
      validationReport: validationReport,
      githubResult: githubResult,
    );
  }
}
