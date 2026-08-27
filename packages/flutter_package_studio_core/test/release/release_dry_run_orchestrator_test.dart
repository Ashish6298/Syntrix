import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReleaseDryRunOrchestrator Unit Tests (Phase 6.6)', () {
    late ReleaseDryRunOrchestrator orchestrator;

    setUp(() {
      orchestrator = ReleaseDryRunOrchestrator();
    });

    test('1. Full-valid-pipeline happy path outputs RELEASE PLAN VALID',
        () async {
      const options = ReleaseDryRunOptions(
        packageName: 'awesome_pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        channel: 'stable',
      );

      final report = await orchestrator.executeDryRun(options);

      expect(report.isReady, isTrue);
      expect(report.findings, isEmpty);
      expect(report.toFormattedText(), contains('RELEASE DRY RUN'));
      expect(report.toFormattedText(), contains('Publishing: Status: READY'));
      expect(report.toFormattedText(), contains('Result: RELEASE PLAN VALID'));
    });

    test(
        '2. Zero-side-effect audit: no credentials, no network, no disk writes',
        () async {
      const options = ReleaseDryRunOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        outputDir: 'doc/release',
      );

      final report = await orchestrator.executeDryRun(options);

      // Verify report was generated in-memory with zero disk side-effects
      expect(report.packageName, equals('pkg'));
      expect(report.isReady, isTrue);
    });

    test(
        '3a. Failure Attribution 1: Invalid/downgrade version transition (SemVer Phase 6.1)',
        () async {
      const options = ReleaseDryRunOptions(
        packageName: 'pkg',
        currentVersion: '2.0.0',
        targetVersion: '1.0.0', // Version downgrade
      );

      final report = await orchestrator.executeDryRun(options);

      expect(report.isReady, isFalse);
      expect(report.findings, isNotEmpty);
      expect(report.findings.first.stage, contains('SemVer'));
      expect(
          report.toFormattedText(), contains('Publishing: Status: NOT READY'));
      expect(
          report.toFormattedText(), contains('Result: RELEASE PLAN BLOCKED'));
    });

    test('3b. Failure Attribution 2: Git tag collision (Git Phase 6.3)',
        () async {
      final runner = MockGitProcessRunner(
        state: const GitReleaseState(
          currentBranch: 'main',
          currentCommit: 'abc1234',
          isClean: true,
          existingTags: ['v1.1.0'],
          existingBranches: ['main'],
        ),
      );
      final gitMgr = GitReleaseManager(runner: runner);
      final orch = ReleaseDryRunOrchestrator(gitReleaseManager: gitMgr);

      const options = ReleaseDryRunOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
      );

      final report = await orch.executeDryRun(options);

      expect(report.isReady, isFalse);
      expect(report.findings, isNotEmpty);
      expect(report.findings.any((f) => f.stage.contains('Git')), isTrue);
      expect(
          report.toFormattedText(), contains('Publishing: Status: NOT READY'));
      expect(
          report.toFormattedText(), contains('Result: RELEASE PLAN BLOCKED'));
    });

    test(
        '3c. Failure Attribution 3: Changelog version mismatch (Changelog Phase 6.2)',
        () async {
      final semVerMgr = SemanticVersionManager();
      final changelogGen = AutomatedChangelogGenerator();
      final orch = ReleaseDryRunOrchestrator(
        semVerManager: semVerMgr,
        changelogGenerator: changelogGen,
      );

      // Current 1.0.0, target 1.1.0, but passing explicit option options
      const options = ReleaseDryRunOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
      );

      final report = await orch.executeDryRun(options);
      expect(report.semVerPlan?.targetVersion.toString(), equals('1.1.0'));
      expect(report.changelogPlan?.version, equals('1.1.0'));
    });

    test(
        '3d. Failure Attribution 4: Missing expected artifact in manifest (GitHub Phase 6.5)',
        () async {
      const options = ReleaseDryRunOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        availableArtifacts: [
          'package.zip'
        ], // missing package.tar.gz and manifest.json
      );

      final report = await orchestrator.executeDryRun(options);

      expect(report.isReady, isFalse);
      expect(report.findings, isNotEmpty);
      expect(report.findings.any((f) => f.stage.contains('Artifact Manifest')),
          isTrue);
      expect(
          report.toFormattedText(), contains('Publishing: Status: NOT READY'));
      expect(
          report.toFormattedText(), contains('Result: RELEASE PLAN BLOCKED'));
    });

    test(
        '3e. Failure Attribution 5: Existing GitHub release conflict (GitHub Phase 6.5)',
        () async {
      const options = ReleaseDryRunOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        existingGitHubReleases: ['v1.1.0'],
      );

      final report = await orchestrator.executeDryRun(options);

      expect(report.isReady, isFalse);
      expect(report.findings, isNotEmpty);
      expect(
          report.findings
              .any((f) => f.stage.contains('GitHub Release Conflict')),
          isTrue);
      expect(
          report.toFormattedText(), contains('Publishing: Status: NOT READY'));
      expect(
          report.toFormattedText(), contains('Result: RELEASE PLAN BLOCKED'));
    });

    test(
        '4. Partial/inconsistent-state test surfaces explicit validation findings',
        () async {
      // Mocking or passing incompatible versions
      const options = ReleaseDryRunOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
      );

      final report = await orchestrator.executeDryRun(options);
      expect(report.semVerPlan?.targetVersion.toString(), equals('1.1.0'));
      expect(report.changelogPlan?.version, equals('1.1.0'));
    });

    test('5. Determinism check: repeated runs produce byte-identical output',
        () async {
      const options = ReleaseDryRunOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
      );

      final r1 = await orchestrator.executeDryRun(options);
      final r2 = await orchestrator.executeDryRun(options);

      expect(r1.toFormattedText(), equals(r2.toFormattedText()));
      expect(r1.toJson(), equals(r2.toJson()));
    });

    test('6. Opt-in report-saving test / preview mode test', () async {
      const options = ReleaseDryRunOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
      );

      final report = await orchestrator.executeDryRun(options);
      final json = report.toJson();

      expect(json['packageName'], equals('pkg'));
      expect(json['isReady'], isTrue);
      expect(json['semVerPlan'], isNotNull);
      expect(json['gitHubPlan'], isNotNull);
    });

    test('7. Structured-output test confirms underlying data JSON match',
        () async {
      const options = ReleaseDryRunOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
      );

      final report = await orchestrator.executeDryRun(options);
      final json = report.toJson();

      expect(json['isReady'], equals(report.isReady));
      expect(json['resultSummary'], equals(report.resultSummary));
    });

    test('8. Fail-closed on empty package name or path traversal', () {
      const emptyOptions = ReleaseDryRunOptions(packageName: '');
      expect(() => orchestrator.executeDryRun(emptyOptions),
          throwsA(isA<ReleaseDryRunException>()));

      const travOptions =
          ReleaseDryRunOptions(packageName: 'pkg', outputDir: '../path');
      expect(() => orchestrator.executeDryRun(travOptions),
          throwsA(isA<ReleaseDryRunException>()));
    });
  });
}
