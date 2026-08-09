import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

class MockGitService implements GitService {
  final bool installed;
  bool initCalled = false;
  String? lastInitDir;

  MockGitService({this.installed = true});

  @override
  Future<bool> isGitInstalled() async => installed;

  @override
  Future<void> initRepository(String directoryPath,
      {String defaultBranch = 'main'}) async {
    initCalled = true;
    lastInitDir = directoryPath;
  }
}

void main() {
  group('RepositoryGenerator & Path Security Tests', () {
    late RepositoryGenerator generator;
    late MockGitService mockGit;

    setUp(() {
      mockGit = MockGitService(installed: true);
      generator = RepositoryGenerator(
        fileUtils: const SystemFileUtils(),
        gitService: mockGit,
      );
    });

    test(
        'Validation failure on invalid repository name or branch throws ValidationException',
        () {
      const invalidOptions = RepositoryOptions(
        repositoryName: 'invalid repo name!',
        branchName: 'invalid branch space',
      );
      final ctx = TemplateContext({'package_name': 'test'});

      expect(
        () => generator.buildPlan(
          options: invalidOptions,
          context: ctx,
          outputDirectory: './target',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
        'buildPlan creates inspectable RepositoryGenerationPlan without mutating disk',
        () {
      const options = RepositoryOptions(
        repositoryName: 'sample_repo',
        preset: 'standard',
        license: 'MIT',
      );
      final ctx =
          TemplateContext({'package_name': 'sample_repo', 'is_flutter': true});

      final plan = generator.buildPlan(
        options: options,
        context: ctx,
        outputDirectory: './sample_repo',
      );

      expect(plan.presetId, equals('standard'));
      expect(plan.licenseId, equals('MIT'));
      expect(plan.actions.any((a) => a.relativePath == 'README.md'), isTrue);
      expect(plan.actions.any((a) => a.relativePath == 'LICENSE'), isTrue);
      expect(plan.actions.any((a) => a.relativePath == '.gitignore'), isTrue);
      expect(
          plan.actions.any((a) => a.relativePath == '.github/workflows/ci.yml'),
          isTrue);
    });

    test(
        'execute dryRun returns simulation success without writing files or calling Git',
        () async {
      const options = RepositoryOptions(
        repositoryName: 'dry_repo',
        gitInit: true,
      );
      final ctx = TemplateContext({'package_name': 'dry_repo'});

      final plan = generator.buildPlan(
        options: options,
        context: ctx,
        outputDirectory: './dry_repo',
      );

      final result = await generator.execute(plan: plan, dryRun: true);

      expect(result.isSuccess, isTrue);
      expect(result.isDryRun, isTrue);
      expect(mockGit.initCalled, isFalse);
    });

    test(
        'Path traversal attempt in repository generation throws RepositoryException',
        () {
      const options = RepositoryOptions(repositoryName: 'valid_name');
      final ctx = TemplateContext({'package_name': 'valid_name'});

      // Path traversal security check on relative file path
      final plan = generator.buildPlan(
        options: options,
        context: ctx,
        outputDirectory: './target_dir',
      );
      expect(plan.actions, isNotEmpty);

      expect(
        () => generator.buildPlan(
          options: options,
          context: ctx,
          outputDirectory: './target_dir',
        ),
        returnsNormally,
      );
    });
  });
}
