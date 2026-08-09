import 'dart:io' as io;
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';
import 'e2e_test_harness.dart';

void main() {
  group('E2E Security & Dry-Run Tests', () {
    late String tempDir;
    late E2ETestHarness harness;

    setUp(() {
      tempDir = io.Directory.systemTemp.createTempSync('fps_e2e_dryrun_').path;
      harness = E2ETestHarness();
    });

    tearDown(() {
      const SystemFileUtils().delete(tempDir);
    });

    test('Dry-run execution performs zero filesystem mutations', () async {
      final wizardCtx = WizardContext(packageName: 'dry_pkg');

      final result = await harness.runLifecycle(
        tempDirectory: tempDir,
        wizardContext: wizardCtx,
        isDryRun: true,
      );

      expect(result.projectResult.isDryRun, isTrue);

      // Verify ZERO files written to temp directory
      final entities = io.Directory(tempDir).listSync();
      expect(entities, isEmpty);
    });

    test(
        'EnvironmentGitHubCredentialProvider redacts tokens from error messages',
        () {
      const token = 'ghp_super_secret_token_1234567890';
      final msg =
          'API error occurred with authorization: Bearer ghp_super_secret_token_1234567890';

      final redacted =
          EnvironmentGitHubCredentialProvider.redactSecrets(msg, token);

      expect(redacted, contains('[REDACTED_GITHUB_TOKEN]'));
      expect(redacted, isNot(contains(token)));
    });
  });
}
