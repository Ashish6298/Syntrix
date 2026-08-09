import 'dart:io' as io;
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('CreateCommand CLI Repository Integration Tests', () {
    late DependencyContainer container;

    setUp(() {
      container = DependencyContainer();
      container.reset();
      container.registerSingleton<Logger>(Logger('CLI_Repo_Test'));
    });

    test(
        'Non-interactive create command generates project and repository assets',
        () async {
      final tempDir =
          io.Directory.systemTemp.createTempSync('cli_repo_gen').path;
      final targetOutput = '$tempDir/repo_pkg';

      final registry = CommandRegistry();
      registry.register(CreateCommand());

      final exitCode = await registry.run([
        'create',
        '--name',
        'repo_pkg',
        '--output',
        targetOutput,
        '--license',
        'MIT',
        '--preset',
        'standard',
        '--no-interactive',
      ]);

      expect(exitCode, equals(0));
      expect(
          const SystemFileUtils().exists('$targetOutput/pubspec.yaml'), isTrue);
      expect(const SystemFileUtils().exists('$targetOutput/README.md'), isTrue);
      expect(const SystemFileUtils().exists('$targetOutput/LICENSE'), isTrue);
      expect(
          const SystemFileUtils().exists('$targetOutput/.gitignore'), isTrue);
      expect(
          const SystemFileUtils()
              .exists('$targetOutput/.github/workflows/ci.yml'),
          isTrue);

      // Clean temp dir
      const SystemFileUtils().delete(tempDir);
    });
  });
}
