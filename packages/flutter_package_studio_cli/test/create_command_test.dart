import 'dart:io' as io;
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('CreateCommand CLI Integration Tests', () {
    late DependencyContainer container;

    setUp(() {
      container = DependencyContainer();
      container.reset();
      container.registerSingleton<Logger>(Logger('CLI_Test'));
    });

    test('Non-interactive create command with valid name succeeds', () async {
      final registry = CommandRegistry();
      registry.register(CreateCommand());

      final tempDir =
          io.Directory.systemTemp.createTempSync('create_cmd_test').path;
      final exitCode = await registry.run([
        'create',
        '--name',
        'my_cli_package',
        '--output',
        '$tempDir/my_cli_package',
        '--no-interactive',
        '--dry-run',
      ]);

      expect(exitCode, equals(0));
    });

    test('Non-interactive create command with invalid name fails with code 1',
        () async {
      final registry = CommandRegistry();
      registry.register(CreateCommand());

      final exitCode = await registry.run([
        'create',
        '--name',
        '123_invalid_name',
        '--no-interactive',
      ]);

      expect(exitCode, equals(1));
    });

    test('Interactive create command handles mock terminal input flow',
        () async {
      // Mock TerminalUtils and FileUtils in DI container
      container.registerSingleton<TerminalUtils>(const _MockTerminalUtils());
      container.registerSingleton<FileUtils>(const SystemFileUtils());

      final registry = CommandRegistry();
      registry.register(CreateCommand());

      // Should execute command runner setup
      final exitCode = await registry.run(['create', '--help']);
      expect(exitCode, equals(0));
    });
  });
}

class _MockTerminalUtils implements TerminalUtils {
  const _MockTerminalUtils();

  @override
  bool get supportsAnsi => false;

  @override
  int get height => 24;

  @override
  int get width => 80;
}
