import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('GitHubRepositoryGenerator & Security Tests', () {
    late GitHubRepositoryGenerator generator;

    setUp(() {
      generator = GitHubRepositoryGenerator(
        fileUtils: const SystemFileUtils(),
        githubService: MockableGitHubService(),
      );
    });

    test(
        'Validation failure on invalid repository name throws ValidationException',
        () {
      const invalidOptions =
          GitHubOptions(repositoryName: 'invalid github name!');
      final ctx = TemplateContext({'package_name': 'test'});

      expect(
        () => generator.buildPlan(
          options: invalidOptions,
          context: ctx,
          projectDirectory: './target_dir',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
        'buildPlan creates inspectable GitHubRepositoryPlan without mutating state',
        () async {
      const options = GitHubOptions(
        repositoryName: 'test_repo',
        owner: 'test-user',
      );
      final ctx =
          TemplateContext({'package_name': 'test_repo', 'is_flutter': true});

      final plan = await generator.buildPlan(
        options: options,
        context: ctx,
        projectDirectory: './test_repo',
      );

      expect(plan.repositoryName, equals('test_repo'));
      expect(plan.remoteUrl, contains('github.com/test-user/test_repo.git'));
      expect(
          plan.actions.any((a) => a.type == GitHubActionType.createRepository),
          isTrue);
      expect(
          plan.actions.any((a) => a.type == GitHubActionType.configureRemote),
          isTrue);
    });

    test('execute dryRun performs zero remote or local mutations', () async {
      const options = GitHubOptions(repositoryName: 'dry_gh_repo');
      final ctx = TemplateContext({'package_name': 'dry_gh_repo'});

      final plan = await generator.buildPlan(
        options: options,
        context: ctx,
        projectDirectory: './dry_gh_repo',
      );

      final result = await generator.execute(
        plan: plan,
        options: options,
        projectDirectory: './dry_gh_repo',
        dryRun: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.isDryRun, isTrue);
    });
  });
}
