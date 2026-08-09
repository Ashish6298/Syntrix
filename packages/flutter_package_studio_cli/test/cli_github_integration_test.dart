import 'dart:io' as io;
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('CreateCommand CLI GitHub Integration Tests', () {
    late DependencyContainer container;

    setUp(() {
      container = DependencyContainer();
      container.reset();
      container.registerSingleton<Logger>(Logger('CLI_GitHub_Test'));
    });

    test(
        'Non-interactive create command with dry-run github automation succeeds',
        () async {
      final tempDir =
          io.Directory.systemTemp.createTempSync('cli_github_gen').path;
      final targetOutput = '$tempDir/gh_pkg';

      final registry = CommandRegistry();
      registry.register(CreateCommand());

      final exitCode = await registry.run([
        'create',
        '--name',
        'gh_pkg',
        '--output',
        targetOutput,
        '--github',
        '--github-owner',
        'test-org',
        '--no-interactive',
        '--dry-run',
      ]);

      expect(exitCode, equals(0));

      // Clean temp dir
      const SystemFileUtils().delete(tempDir);
    });
  });
}
