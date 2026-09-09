import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('GitReleaseManager Unit Tests', () {
    test('Plans Git release tag and branch creation correctly', () async {
      final runner = MockGitProcessRunner(
        state: const GitReleaseState(
          currentBranch: 'main',
          currentCommit: 'abc1234',
          isClean: true,
          existingTags: ['v0.9.0'],
          existingBranches: ['main'],
        ),
      );
      final manager = GitReleaseManager(runner: runner);

      const options = GitReleaseOptions(
        packageName: 'awesome_pkg',
        version: '1.0.0',
      );

      final plan = await manager.planRelease(options);
      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.targetVersion, equals('1.0.0'));
      expect(plan.tagName, equals('v1.0.0'));
      expect(plan.branchName, equals('release/v1.0.0'));
      expect(plan.isClean, isTrue);
      expect(plan.isValid, isTrue);
    });

    test('Rejects release planning when working tree is dirty', () async {
      final runner = MockGitProcessRunner(
        state: const GitReleaseState(
          currentBranch: 'main',
          currentCommit: 'abc1234',
          isClean: false,
          existingTags: [],
          existingBranches: ['main'],
        ),
      );
      final manager = GitReleaseManager(runner: runner);

      const options = GitReleaseOptions(
        packageName: 'pkg',
        version: '1.0.0',
      );

      expect(() => manager.planRelease(options),
          throwsA(isA<GitReleaseException>()));
    });

    test('Rejects existing tag conflict', () async {
      final runner = MockGitProcessRunner(
        state: const GitReleaseState(
          currentBranch: 'main',
          currentCommit: 'abc1234',
          isClean: true,
          existingTags: ['v1.0.0'],
          existingBranches: ['main'],
        ),
      );
      final manager = GitReleaseManager(runner: runner);

      const options = GitReleaseOptions(
        packageName: 'pkg',
        version: '1.0.0',
      );

      expect(() => manager.planRelease(options),
          throwsA(isA<GitReleaseException>()));
    });

    test('Executes tag and branch creation via runner when execute is true',
        () async {
      final runner = MockGitProcessRunner();
      final manager = GitReleaseManager(runner: runner);

      const options = GitReleaseOptions(
        packageName: 'pkg',
        version: '1.0.0',
        execute: true,
      );

      final plan = await manager.planRelease(options);
      final result = await manager.executeRelease(plan, execute: true);

      expect(result.isExecuted, isTrue);
      expect(runner.createdTags, contains('v1.0.0'));
      expect(runner.createdBranches, contains('release/v1.0.0'));
    });

    test('Rejects absolute output directory paths and path traversal ".." ',
        () {
      final manager = GitReleaseManager();
      const absOptions =
          GitReleaseOptions(packageName: 'pkg', outputDir: '/etc/release');
      expect(() => manager.planRelease(absOptions),
          throwsA(isA<GitReleaseException>()));

      const travOptions =
          GitReleaseOptions(packageName: 'pkg', outputDir: '../release');
      expect(() => manager.planRelease(travOptions),
          throwsA(isA<GitReleaseException>()));
    });
  });
}
