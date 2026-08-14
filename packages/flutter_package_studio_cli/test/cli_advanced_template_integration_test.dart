import 'dart:io' as io;
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('CLI Advanced Template Integration Tests', () {
    late DependencyContainer container;

    setUp(() {
      container = DependencyContainer();
      container.reset();
      container.registerSingleton<Logger>(Logger('CLI_Advanced_Template_Test'));
    });

    test(
        'CLI create command successfully generates project using advanced template architecture',
        () async {
      final tempDir =
          io.Directory.systemTemp.createTempSync('cli_adv_template_').path;
      final targetOutput = '$tempDir/adv_template_pkg';

      final createRegistry = CommandRegistry();
      createRegistry.register(CreateCommand());

      final exitCode = await createRegistry.run([
        'create',
        '--name',
        'adv_template_pkg',
        '--output',
        targetOutput,
        '--no-interactive',
      ]);

      expect(exitCode, equals(0));
      expect(
          const SystemFileUtils().exists('$targetOutput/pubspec.yaml'), isTrue);

      const SystemFileUtils().delete(tempDir);
    });
  });
}
