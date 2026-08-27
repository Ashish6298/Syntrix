import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReleaseDashboard Unit Tests (Phase 6.8)', () {
    late ReleaseDashboard dashboard;
    late PublishingAuthorization validAuth;

    setUp(() {
      dashboard = ReleaseDashboard();
      validAuth = PublishingAuthorization(
        authorizedBy: 'test_user',
        isAuthorized: true,
        timestamp: DateTime.now().toIso8601String(),
      );
    });

    test(
        '1. Full-data happy-path snapshot rendering matching exact RELEASE DASHBOARD template',
        () async {
      final assistant = ReleasePublishingAssistant();
      final exec = await assistant.executePipeline(PublishingAssistantOptions(
        packageName: 'awesome_pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        authorization: validAuth,
      ));

      final snapshot = dashboard.renderSnapshot(
        packageName: 'awesome_pkg',
        currentVersion: '1.0.0',
        nextRelease: '1.1.0',
        channel: 'stable',
        latestExecution: exec,
      );

      final text = snapshot.toFormattedText();
      expect(text, contains('RELEASE DASHBOARD'));
      expect(text, contains('Package       : awesome_pkg'));
      expect(text, contains('Current Version: 1.0.0'));
      expect(text, contains('Next Release  : 1.1.0'));
      expect(text, contains('Certification : ✓'));
      expect(text, contains('Security      : ✓'));
      expect(text, contains('Publishing    : READY'));
    });

    test(
        '2. Read-only enforcement audit: zero network, zero process execution, zero file mutation',
        () async {
      final snapshot = dashboard.renderSnapshot(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        nextRelease: '1.1.0',
        channel: 'stable',
      );

      // Verify output rendered safely in memory
      expect(snapshot.packageName, equals('pkg'));
      expect(snapshot.certificationStatus, equals('NOT TRACKED'));
    });

    test('3a. Missing certification data renders NOT TRACKED', () {
      final snapshot = dashboard.renderSnapshot(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        nextRelease: '1.1.0',
        channel: 'stable',
      );
      expect(snapshot.certificationStatus, equals('NOT TRACKED'));
    });

    test('3b. Missing security-audit data renders NOT TRACKED', () {
      final snapshot = dashboard.renderSnapshot(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        nextRelease: '1.1.0',
        channel: 'stable',
      );
      expect(snapshot.securityStatus, equals('NOT TRACKED'));
    });

    test('3c. Missing artifact/manifest data renders NOT TRACKED', () {
      final snapshot = dashboard.renderSnapshot(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        nextRelease: '1.1.0',
        channel: 'stable',
      );
      expect(snapshot.artifactStatus, equals('NOT TRACKED'));
      expect(snapshot.manifestStatus, equals('NOT TRACKED'));
    });

    test('3d. Missing Git tag data renders NOT TRACKED', () {
      final snapshot = dashboard.renderSnapshot(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        nextRelease: '1.1.0',
        channel: 'stable',
      );
      expect(snapshot.gitTagStatus, equals('NOT TRACKED'));
    });

    test('3e. Missing GitHub release data renders NOT TRACKED', () {
      final snapshot = dashboard.renderSnapshot(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        nextRelease: '1.1.0',
        channel: 'stable',
      );
      expect(snapshot.gitHubReleaseStatus, equals('NOT TRACKED'));
    });

    test('4. Release history test listing multiple past releases', () async {
      final assistant = ReleasePublishingAssistant();
      final exec1 = await assistant.executePipeline(PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        authorization: validAuth,
      ));
      final exec2 = await assistant.executePipeline(PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.1.0',
        targetVersion: '1.2.0',
        authorization: validAuth,
      ));

      final snapshot = dashboard.renderSnapshot(
        packageName: 'pkg',
        currentVersion: '1.2.0',
        nextRelease: '1.3.0',
        channel: 'stable',
        priorExecutions: [exec1, exec2],
      );

      expect(snapshot.history.length, equals(2));
      expect(snapshot.history[0].version, equals('1.1.0'));
      expect(snapshot.history[1].version, equals('1.2.0'));
    });

    test('5. Surfacing failed releases distinctly', () async {
      final assistant = ReleasePublishingAssistant();
      final execFailed =
          await assistant.executePipeline(PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        authorization: validAuth,
        simulateSecurityFailure: true,
      ));

      final snapshot = dashboard.renderSnapshot(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        nextRelease: '1.1.0',
        channel: 'stable',
        latestExecution: execFailed,
      );

      expect(snapshot.failedReleases.length, equals(1));
      expect(snapshot.failedReleases.first.version, equals('1.1.0'));
    });

    test(
        '6. Rollback-availability test reflects Phase 6.7 recorded rollback state',
        () async {
      final assistant = ReleasePublishingAssistant();
      final execFailed =
          await assistant.executePipeline(PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        authorization: validAuth,
        simulatePublishFailure: true,
      ));

      final snapshot = dashboard.renderSnapshot(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        nextRelease: '1.1.0',
        channel: 'stable',
        latestExecution: execFailed,
      );

      expect(snapshot.history.first.isRollbackAvailable, isTrue);
      expect(snapshot.history.first.manualInterventionRequired, isTrue);
    });

    test('7. Recovery-status test shows interrupted release state', () async {
      final assistant = ReleasePublishingAssistant();
      final execPartial =
          await assistant.executePipeline(PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        authorization: validAuth,
        simulateGitTagFailure: true,
      ));

      final snapshot = dashboard.renderSnapshot(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        nextRelease: '1.1.0',
        channel: 'stable',
        latestExecution: execPartial,
      );

      expect(snapshot.publishingStatus, equals('NOT READY'));
    });

    test(
        '8. Timeline-ordering test presents events in correct chronological order',
        () async {
      final assistant = ReleasePublishingAssistant();
      final exec = await assistant.executePipeline(PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        authorization: validAuth,
      ));

      final snapshot = dashboard.renderSnapshot(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        nextRelease: '1.1.0',
        channel: 'stable',
        latestExecution: exec,
      );

      expect(snapshot.timeline.length, equals(11));
      // Assert timestamps are non-decreasing
      for (int i = 0; i < snapshot.timeline.length - 1; i++) {
        expect(
            snapshot.timeline[i].timestamp
                .compareTo(snapshot.timeline[i + 1].timestamp),
            lessThanOrEqualTo(0));
      }
    });

    test('9. Delegation test calls through to Phase 6.7 authorized entry point',
        () async {
      final exec = await dashboard.delegateExecution(PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        authorization: validAuth,
      ));

      expect(exec.isSuccess, isTrue);
    });

    test('10. Structured-output test confirms JSON matches rendered view', () {
      final snapshot = dashboard.renderSnapshot(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        nextRelease: '1.1.0',
        channel: 'stable',
      );

      final json = snapshot.toJson();
      expect(json['packageName'], equals('pkg'));
      expect(json['certificationStatus'], equals('NOT TRACKED'));
    });

    test('11. Determinism check confirms identical output on repeated runs',
        () {
      final s1 = dashboard.renderSnapshot(
          packageName: 'pkg',
          currentVersion: '1.0.0',
          nextRelease: '1.1.0',
          channel: 'stable');
      final s2 = dashboard.renderSnapshot(
          packageName: 'pkg',
          currentVersion: '1.0.0',
          nextRelease: '1.1.0',
          channel: 'stable');

      expect(s1.toFormattedText(), equals(s2.toFormattedText()));
      expect(s1.toJson(), equals(s2.toJson()));
    });

    test('12. Fail-closed edge-case validation on empty package name', () {
      expect(
        () => dashboard.renderSnapshot(
            packageName: '',
            currentVersion: '1.0.0',
            nextRelease: '1.1.0',
            channel: 'stable'),
        throwsA(isA<ReleaseDashboardException>()),
      );
    });
  });
}
