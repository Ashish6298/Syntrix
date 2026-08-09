import 'dart:io' as io;
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';
import 'e2e_test_harness.dart';

void main() {
  group('E2E Full Successful Generation Pipeline Tests', () {
    late String tempDir;
    late E2ETestHarness harness;

    setUp(() {
      tempDir = io.Directory.systemTemp.createTempSync('fps_e2e_full_').path;
      harness = E2ETestHarness();
    });

    tearDown(() {
      const SystemFileUtils().delete(tempDir);
    });

    test(
        'Complete pipeline generates valid package, repo assets, example app, and passes validation',
        () async {
      final wizardCtx = WizardContext(
        packageName: 'super_logger',
        orgName: 'dev.syntrix',
        description: 'Super awesome logger package for Flutter and Dart.',
        author: 'Syntrix Core Team',
        email: 'team@syntrix.dev',
      );

      final result = await harness.runLifecycle(
        tempDirectory: tempDir,
        wizardContext: wizardCtx,
        repositoryPreset: 'standard',
        validationProfile: 'standard',
      );

      expect(result.isOverallSuccess, isTrue);

      // Verify Package Files
      expect(const SystemFileUtils().exists('$tempDir/pubspec.yaml'), isTrue);
      expect(const SystemFileUtils().exists('$tempDir/lib/super_logger.dart'),
          isTrue);

      // Verify Pubspec Content
      final pubspec =
          const SystemFileUtils().readAsString('$tempDir/pubspec.yaml');
      expect(pubspec, contains('name: super_logger'));
      expect(pubspec, contains('description: Super awesome logger'));

      // Verify Repository Assets
      expect(const SystemFileUtils().exists('$tempDir/README.md'), isTrue);
      expect(const SystemFileUtils().exists('$tempDir/LICENSE'), isTrue);
      expect(const SystemFileUtils().exists('$tempDir/CHANGELOG.md'), isTrue);
      expect(const SystemFileUtils().exists('$tempDir/.gitignore'), isTrue);

      // Verify Example App Assets
      expect(const SystemFileUtils().exists('$tempDir/example/pubspec.yaml'),
          isTrue);
      expect(const SystemFileUtils().exists('$tempDir/example/lib/main.dart'),
          isTrue);

      // Verify Example pubspec path dependency
      final exPubspec =
          const SystemFileUtils().readAsString('$tempDir/example/pubspec.yaml');
      expect(exPubspec, contains('super_logger:'));
      expect(exPubspec, contains('path: ../'));

      // Verify Validation Report
      expect(result.validationReport.isValid, isTrue);
      expect(result.validationReport.summary.errorCount, equals(0));

      // Verify GitHub Result
      expect(result.githubResult.isSuccess, isTrue);
    });
  });
}
