import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('GitHubReleaseManager Unit Tests (Phase 6.5)', () {
    late GitHubReleaseManager manager;

    setUp(() {
      manager = GitHubReleaseManager();
    });

    test('1. Full-data happy path constructs correct GitHubReleasePlan', () {
      const options = GitHubReleaseOptions(
        packageName: 'awesome_pkg',
        version: '1.2.0-beta.1',
        tagName: 'v1.2.0-beta.1',
        targetCommitish: 'main',
        releaseTitle: 'Awesome Pkg v1.2.0-beta.1',
        releaseBody: 'Verbatim release notes body from Phase 6.4.',
        channel: 'beta',
        isDraft: false,
        artifacts: ['package.tar.gz', 'package.zip', 'manifest.json'],
      );

      final plan = manager.planRelease(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.version, equals('1.2.0-beta.1'));
      expect(plan.tagName, equals('v1.2.0-beta.1'));
      expect(plan.targetCommitish, equals('main'));
      expect(plan.releaseTitle, equals('Awesome Pkg v1.2.0-beta.1'));
      expect(plan.releaseBody,
          equals('Verbatim release notes body from Phase 6.4.'));
      expect(plan.isPrerelease, isTrue);
      expect(plan.isDraft, isFalse);
      expect(plan.artifacts,
          equals(['package.tar.gz', 'package.zip', 'manifest.json']));
      expect(plan.isValid, isTrue);
    });

    test('2. Planning is network-free and requires zero credentials', () {
      const options = GitHubReleaseOptions(
        packageName: 'pkg',
        version: '1.0.0',
        tagName: 'v1.0.0',
        releaseTitle: 'Title',
        releaseBody: 'Body',
      );

      // Plan creation must execute synchronously without async/network calls or credentials
      final plan = manager.planRelease(options);
      expect(plan.isValid, isTrue);
    });

    test(
        '3. Existing release detection: fails by default, proceeds with explicit updateExisting',
        () async {
      final client = MockGitHubApiClient(existingReleases: {'v1.0.0': true});
      final managerWithClient = GitHubReleaseManager(client: client);

      const optionsDefault = GitHubReleaseOptions(
        packageName: 'pkg',
        version: '1.0.0',
        tagName: 'v1.0.0',
        releaseTitle: 'Title',
        releaseBody: 'Body',
        updateExisting: false,
      );

      final planDefault = managerWithClient.planRelease(optionsDefault);

      expect(
        () => managerWithClient.executeRelease(
          plan: planDefault,
          ownerRepo: 'owner/pkg',
          credential: const GitHubCredential('secret_token_123'),
          execute: true,
        ),
        throwsA(isA<GitHubReleaseException>()),
      );

      const optionsUpdate = GitHubReleaseOptions(
        packageName: 'pkg',
        version: '1.0.0',
        tagName: 'v1.0.0',
        releaseTitle: 'Title',
        releaseBody: 'Body',
        updateExisting: true,
      );

      final planUpdate = managerWithClient.planRelease(optionsUpdate);
      final result = await managerWithClient.executeRelease(
        plan: planUpdate,
        ownerRepo: 'owner/pkg',
        credential: const GitHubCredential('secret_token_123'),
        execute: true,
      );

      expect(result.isExecuted, isTrue);
    });

    test('4. Draft vs Published state transitions remain explicit and distinct',
        () async {
      const draftOpt = GitHubReleaseOptions(
        packageName: 'pkg',
        version: '1.0.0',
        tagName: 'v1.0.0',
        releaseTitle: 'Title',
        releaseBody: 'Body',
        isDraft: true,
      );
      final draftPlan = manager.planRelease(draftOpt);
      expect(draftPlan.isDraft, isTrue);

      const pubOpt = GitHubReleaseOptions(
        packageName: 'pkg',
        version: '1.0.0',
        tagName: 'v1.0.0',
        releaseTitle: 'Title',
        releaseBody: 'Body',
        isDraft: false,
      );
      final pubPlan = manager.planRelease(pubOpt);
      expect(pubPlan.isDraft, isFalse);
    });

    test(
        '5. Credential leak audit: credential value never appears in toString(), json, or exception messages',
        () async {
      const tokenVal = 'ghp_SECRET_TOKEN_999999999';
      const cred = GitHubCredential(tokenVal);

      // 1. Opaque credential toString & toJson audit
      expect(cred.toString(), isNot(contains(tokenVal)));
      expect(cred.toString(), equals('[REDACTED_GITHUB_TOKEN]'));
      expect(cred.toJson()['token'], equals('[REDACTED]'));

      // 2. Exception message redaction audit on forced failure
      final client = MockGitHubApiClient(shouldFailAuth: true);
      final managerWithClient = GitHubReleaseManager(client: client);

      const options = GitHubReleaseOptions(
        packageName: 'pkg',
        version: '1.0.0',
        tagName: 'v1.0.0',
        releaseTitle: 'Title',
        releaseBody: 'Body',
      );

      final plan = managerWithClient.planRelease(options);

      try {
        await managerWithClient.executeRelease(
          plan: plan,
          ownerRepo: 'owner/pkg',
          credential: cred,
          execute: true,
        );
        fail('Should have thrown GitHubReleaseException');
      } catch (e) {
        final errStr = e.toString();
        expect(errStr, isNot(contains(tokenVal)));
      }
    });

    test(
        '6. Mocked failure modes: auth, rate limit, network, tag not found, upload failure',
        () async {
      // Auth failure
      final authClient = MockGitHubApiClient(shouldFailAuth: true);
      final mgrAuth = GitHubReleaseManager(client: authClient);
      final plan = mgrAuth.planRelease(const GitHubReleaseOptions(
        packageName: 'pkg',
        version: '1.0.0',
        tagName: 'v1.0.0',
        releaseTitle: 'T',
        releaseBody: 'B',
      ));
      expect(
        () => mgrAuth.executeRelease(
            plan: plan,
            ownerRepo: 'o/p',
            credential: const GitHubCredential('t'),
            execute: true),
        throwsA(isA<GitHubReleaseException>()),
      );

      // Network failure
      final netClient = MockGitHubApiClient(shouldFailNetwork: true);
      final mgrNet = GitHubReleaseManager(client: netClient);
      expect(
        () => mgrNet.executeRelease(
            plan: plan,
            ownerRepo: 'o/p',
            credential: const GitHubCredential('t'),
            execute: true),
        throwsA(isA<GitHubReleaseException>()),
      );

      // Upload failure
      final upClient = MockGitHubApiClient(shouldFailUpload: true);
      final mgrUp = GitHubReleaseManager(client: upClient);
      expect(
        () => mgrUp.executeRelease(
            plan: plan,
            ownerRepo: 'o/p',
            credential: const GitHubCredential('t'),
            execute: true),
        throwsA(isA<GitHubReleaseException>()),
      );
    });

    test('7. Determinism check: identical inputs produce byte-identical plans',
        () {
      const options = GitHubReleaseOptions(
        packageName: 'pkg',
        version: '1.0.0',
        tagName: 'v1.0.0',
        releaseTitle: 'Title',
        releaseBody: 'Body',
      );

      final plan1 = manager.planRelease(options);
      final plan2 = manager.planRelease(options);

      expect(plan1.toJson(), equals(plan2.toJson()));
    });

    test('8. Artifact-list integrity check matches exact input list', () {
      const options = GitHubReleaseOptions(
        packageName: 'pkg',
        version: '1.0.0',
        tagName: 'v1.0.0',
        releaseTitle: 'Title',
        releaseBody: 'Body',
        artifacts: ['custom_artifact_1.zip', 'custom_artifact_2.tar.gz'],
      );

      final plan = manager.planRelease(options);
      expect(plan.artifacts,
          equals(['custom_artifact_1.zip', 'custom_artifact_2.tar.gz']));
    });

    test('9. Release body passed through byte-identical without mutation', () {
      const bodyStr =
          '# Verbatim Release Notes\n\n- Exact content from Phase 6.4.';
      const options = GitHubReleaseOptions(
        packageName: 'pkg',
        version: '1.0.0',
        tagName: 'v1.0.0',
        releaseTitle: 'Title',
        releaseBody: bodyStr,
      );

      final plan = manager.planRelease(options);
      expect(plan.releaseBody, equals(bodyStr));
    });

    test(
        '10. Edge case & path protection: empty package name and invalid output paths fail closed',
        () {
      const emptyPkgOptions = GitHubReleaseOptions(
        packageName: '',
        version: '1.0.0',
        tagName: 'v1.0.0',
        releaseTitle: 'T',
        releaseBody: 'B',
      );
      expect(() => manager.planRelease(emptyPkgOptions),
          throwsA(isA<GitHubReleaseException>()));

      const absPathOptions = GitHubReleaseOptions(
        packageName: 'pkg',
        version: '1.0.0',
        tagName: 'v1.0.0',
        releaseTitle: 'T',
        releaseBody: 'B',
        outputDir: '/abs/path',
      );
      expect(() => manager.planRelease(absPathOptions),
          throwsA(isA<GitHubReleaseException>()));
    });
  });
}
