import 'dart:io' as io;
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('CreateCommand CLI Example Integration Tests', () {
    late DependencyContainer container;

    setUp(() {
      container = DependencyContainer();
      container.reset();
      container.registerSingleton<Logger>(Logger('CLI_Example_Test'));
    });

    test(
        'Non-interactive create command generates project, repository, and example app',
        () async {
      final tempDir =
          io.Directory.systemTemp.createTempSync('cli_example_gen').path;
      final targetOutput = '$tempDir/example_full_pkg';

      final registry = CommandRegistry();
      registry.register(CreateCommand());

      final exitCode = await registry.run([
        'create',
        '--name',
        'example_full_pkg',
        '--output',
        targetOutput,
        '--example',
        '--no-interactive',
      ]);

      expect(exitCode, equals(0));
      expect(
          const SystemFileUtils().exists('$targetOutput/pubspec.yaml'), isTrue);
      expect(
          const SystemFileUtils().exists('$targetOutput/example/pubspec.yaml'),
          isTrue);
      expect(
          const SystemFileUtils().exists('$targetOutput/example/lib/main.dart'),
          isTrue);
      expect(
          const SystemFileUtils()
              .exists('$targetOutput/example/test/widget_test.dart'),
          isTrue);
      expect(const SystemFileUtils().exists('$targetOutput/example/README.md'),
          isTrue);

      // Clean temp dir
      const SystemFileUtils().delete(tempDir);
    });
  });
}
