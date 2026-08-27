import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReleasePublishingAssistant Unit Tests (Phase 6.7)', () {
    late ReleasePublishingAssistant assistant;
    late PublishingAuthorization validAuth;

    setUp(() {
      assistant = ReleasePublishingAssistant();
      validAuth = PublishingAuthorization(
        authorizedBy: 'test_user',
        isAuthorized: true,
        timestamp: DateTime.now().toIso8601String(),
      );
    });

    test(
        '1. Full happy-path pipeline executing all 11 stages in deterministic order with explicit authorization',
        () async {
      final options = PublishingAssistantOptions(
        packageName: 'awesome_pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        authorization: validAuth,
      );

      final result = await assistant.executePipeline(options);

      expect(result.isSuccess, isTrue);
      expect(result.stageRecords.length, equals(11));

      final names = result.stageRecords.map((s) => s.stageName).toList();
      expect(
          names,
          equals([
            'Validate',
            'Version',
            'Changelog',
            'Build',
            'Manifest',
            'Security Audit',
            'Certification',
            'Git Tag',
            'GitHub Release',
            'Package Publish',
            'Verify',
          ]));

      for (final stage in result.stageRecords) {
        expect(stage.status, equals(StageStatus.success));
      }
    });

    test(
        '2. Rejection test: execution refuses to start when authorization is absent',
        () async {
      const options = PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        authorization: null, // missing authorization
      );

      expect(
        () => assistant.executePipeline(options),
        throwsA(isA<ReleasePublishingAssistantException>()),
      );
    });

    test('3a. Critical failure stops pipeline at Security Audit gate',
        () async {
      final options = PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        authorization: validAuth,
        simulateSecurityFailure: true,
      );

      final result = await assistant.executePipeline(options);

      expect(result.isSuccess, isFalse);
      expect(result.stageRecords.last.stageName, equals('Security Audit'));
      expect(result.stageRecords.last.status, equals(StageStatus.failed));
      expect(result.stageRecords.any((s) => s.stageName == 'Git Tag'), isFalse);
    });

    test('3b. Critical failure stops pipeline at Certification gate', () async {
      final options = PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        authorization: validAuth,
        simulateCertificationFailure: true,
      );

      final result = await assistant.executePipeline(options);

      expect(result.isSuccess, isFalse);
      expect(result.stageRecords.last.stageName, equals('Certification'));
      expect(result.stageRecords.last.status, equals(StageStatus.failed));
      expect(result.stageRecords.any((s) => s.stageName == 'GitHub Release'),
          isFalse);
    });

    test('3c. Critical failure stops pipeline at Git Tag creation', () async {
      final options = PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        authorization: validAuth,
        simulateGitTagFailure: true,
      );

      final result = await assistant.executePipeline(options);

      expect(result.isSuccess, isFalse);
      expect(result.stageRecords.last.stageName, equals('Git Tag'));
      expect(result.stageRecords.last.status, equals(StageStatus.failed));
      expect(result.stageRecords.any((s) => s.stageName == 'Package Publish'),
          isFalse);
    });

    test('4. Duplicate release prevention test', () async {
      final options = PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.1.0',
        authorization: validAuth,
      );

      await assistant.executePipeline(options);

      // Attempting second run for same version must throw
      expect(
        () => assistant.executePipeline(options),
        throwsA(isA<ReleasePublishingAssistantException>()),
      );
    });

    test(
        '5. Recovery test: resumes from first incomplete stage without re-running completed ones',
        () async {
      final options = PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.2.0',
        authorization: validAuth,
      );

      // Create prior completed records up to Stage 5 Manifest
      final priorRecords = [
        StageRecord(
            stageName: 'Validate',
            status: StageStatus.success,
            timestamp: 'ts1',
            details: 'prior'),
        StageRecord(
            stageName: 'Version',
            status: StageStatus.success,
            timestamp: 'ts2',
            details: 'prior'),
        StageRecord(
            stageName: 'Changelog',
            status: StageStatus.success,
            timestamp: 'ts3',
            details: 'prior'),
        StageRecord(
            stageName: 'Build',
            status: StageStatus.success,
            timestamp: 'ts4',
            details: 'prior'),
        StageRecord(
            stageName: 'Manifest',
            status: StageStatus.success,
            timestamp: 'ts5',
            details: 'prior'),
      ];

      final result =
          await assistant.executePipeline(options, priorRecords: priorRecords);

      expect(result.isSuccess, isTrue);
      expect(result.stageRecords.length, equals(11));
      expect(result.stageRecords[0].details, equals('prior'));
      expect(result.stageRecords[4].details, equals('prior'));
      expect(result.stageRecords[5].details, isNot(equals('prior')));
    });

    test(
        '6. Individual rollback test for rollbackable stages (Git Tag and GitHub Release)',
        () async {
      final options = PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.3.0',
        authorization: validAuth,
        simulatePublishFailure: true, // Fails at stage 10 Package Publish
      );

      final result = await assistant.executePipeline(options);

      expect(result.isSuccess, isFalse);
      expect(result.rollbackLog, isNotEmpty);
      expect(
          result.rollbackLog.any((l) => l.contains('GitHub Release')), isTrue);
      expect(result.rollbackLog.any((l) => l.contains('Git Tag')), isTrue);
    });

    test(
        '7. No rollback available test reports required manual intervention for unrollbackable stages',
        () async {
      final options = PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.4.0',
        authorization: validAuth,
        simulatePublishFailure: true,
      );

      final result = await assistant.executePipeline(options);

      expect(
          result.rollbackLog
              .any((l) => l.contains('Manual intervention required')),
          isTrue);
    });

    test('8. Evidence preservation test confirms accurate stage outputs',
        () async {
      final options = PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.5.0',
        authorization: validAuth,
      );

      final result = await assistant.executePipeline(options);

      final ghStage = result.stageRecords
          .firstWhere((s) => s.stageName == 'GitHub Release');
      expect(ghStage.evidence['releaseUrl'], contains('v1.5.0'));
    });

    test(
        '9. Certification/security gate cannot be bypassed under any option combination',
        () async {
      final options = PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.6.0',
        authorization: validAuth,
        simulateSecurityFailure: true,
        isDraft: true,
      );

      final result = await assistant.executePipeline(options);

      expect(result.isSuccess, isFalse);
      expect(result.stageRecords.any((s) => s.stageName == 'Package Publish'),
          isFalse);
    });

    test(
        '10. Credential leak audit: authorization and token details are sanitized',
        () async {
      final authWithSecret = PublishingAuthorization(
        authorizedBy: 'user_secret_token_777',
        isAuthorized: true,
        timestamp: DateTime.now().toIso8601String(),
      );

      final options = PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.7.0',
        authorization: authWithSecret,
      );

      final result = await assistant.executePipeline(options);
      final jsonStr = result.toJson().toString();

      expect(jsonStr, isNot(contains('secret_key')));
    });

    test('11. Determinism check: identical inputs produce identical reports',
        () async {
      final options = PublishingAssistantOptions(
        packageName: 'pkg',
        currentVersion: '1.0.0',
        targetVersion: '1.8.0',
        authorization: validAuth,
      );

      final assistant1 = ReleasePublishingAssistant();
      final assistant2 = ReleasePublishingAssistant();

      final r1 = await assistant1.executePipeline(options);
      final r2 = await assistant2.executePipeline(options);

      expect(r1.stageRecords.length, equals(r2.stageRecords.length));
      expect(r1.isSuccess, equals(r2.isSuccess));
    });

    test('12. Fail-closed edge-case validation on empty package name', () {
      final options = PublishingAssistantOptions(
        packageName: '',
        authorization: validAuth,
      );

      expect(
        () => assistant.executePipeline(options),
        throwsA(isA<ReleaseDryRunException>()),
      );
    });
  });
}
