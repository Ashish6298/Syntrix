import 'dart:io' as io;
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('CreateCommand CLI Template Integration Tests', () {
    late DependencyContainer container;

    setUp(() {
      container = DependencyContainer();
      container.reset();
      container.registerSingleton<Logger>(Logger('CLI_Template_Test'));
    });

    test('Non-interactive create command executes dry-run generation',
        () async {
      final registry = CommandRegistry();
      registry.register(CreateCommand());

      final exitCode = await registry.run([
        'create',
        '--name',
        'dry_run_pkg',
        '--no-interactive',
        '--dry-run',
      ]);

      expect(exitCode, equals(0));
    });

    test(
        'Non-interactive create command generates project files into temp directory',
        () async {
      final tempDir =
          io.Directory.systemTemp.createTempSync('cli_gen_test').path;
      final targetOutput = '$tempDir/generated_pkg';

      final registry = CommandRegistry();
      registry.register(CreateCommand());

      final exitCode = await registry.run([
        'create',
        '--name',
        'generated_pkg',
        '--output',
        targetOutput,
        '--no-interactive',
      ]);

      expect(exitCode, equals(0));
      expect(
          const SystemFileUtils().exists('$targetOutput/pubspec.yaml'), isTrue);
      expect(
          const SystemFileUtils()
              .exists('$targetOutput/lib/generated_pkg.dart'),
          isTrue);

      // Clean temp output
      const SystemFileUtils().delete(tempDir);
    });
  });
}
