import 'dart:io' as io;
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';

class MockLogHandler extends Mock implements LogHandler {}

class FailingCommand extends FpsCommand {
  @override
  final String name = 'fail';
  @override
  final String description = 'A command that throws a PackageStudioException.';

  @override
  Future<int> run() async {
    throw ValidationException('Validation failed inside command.');
  }
}

class UnexpectedFailingCommand extends FpsCommand {
  @override
  final String name = 'crash';
  @override
  final String description = 'A command that throws an unexpected Exception.';

  @override
  Future<int> run() async {
    throw StateError('Unexpected state crash.');
  }
}

void main() {
  group('CLI CommandRegistry and Execution Tests', () {
    late MockLogHandler mockLogHandler;
    late Logger rootLogger;

    setUp(() {
      mockLogHandler = MockLogHandler();
      Logger.clearHandlers();
      Logger.addHandler(mockLogHandler);

      rootLogger = Logger('FPS', level: LogLevel.info);
      final container = DependencyContainer();
      container.reset();
      container.registerSingleton<Logger>(rootLogger);
    });

    tearDown(() {
      Logger.clearHandlers();
      DependencyContainer().reset();
    });

    test('Register and execute command successfully', () async {
      final registry = CommandRegistry();
      registry.register(CreateCommand());

      final tempDir = io.Directory.systemTemp.createTempSync('cli_test_1').path;
      final exitCode = await registry.run([
        'create',
        '--name',
        'test_pkg',
        '--output',
        '$tempDir/test_pkg',
        '--no-interactive',
        '--dry-run'
      ]);

      expect(exitCode, 0);
    });

    test('Help output and UsageException returning 64', () async {
      final registry = CommandRegistry();

      // Passing invalid option to create a UsageException
      final exitCode = await registry.run(['--invalid-flag-fps']);
      expect(exitCode, 64);
    });

    test('Graceful catching of PackageStudioException', () async {
      final registry = CommandRegistry();
      registry.register(FailingCommand());

      final exitCode = await registry.run(['fail']);
      expect(exitCode, 1);
    });

    test('Graceful catching of unexpected Exceptions', () async {
      final registry = CommandRegistry();
      registry.register(UnexpectedFailingCommand());

      final exitCode = await registry.run(['crash']);
      expect(exitCode, 1);
    });

    test('Global verbose flag updates logger level', () async {
      final registry = CommandRegistry();
      registry.register(CreateCommand());

      expect(rootLogger.level, LogLevel.info);

      final tempDir = io.Directory.systemTemp.createTempSync('cli_test_2').path;
      final exitCode = await registry.run([
        '-v',
        'create',
        '--name',
        'test_pkg',
        '--output',
        '$tempDir/test_pkg',
        '--no-interactive',
        '--dry-run'
      ]);

      expect(exitCode, 0);
      expect(rootLogger.level, LogLevel.trace);
    });

    test('Execute all other placeholder commands and base command resolve',
        () async {
      final registry = CommandRegistry();

      // Register other commands
      registry.register(AuditCommand());
      registry.register(ReleaseCommand());
      registry.register(DocsCommand());
      registry.register(PublishCommand());
      registry.register(TemplateCommand());
      registry.register(PluginCommand());

      expect(await registry.run(['audit']), 0);
      expect(await registry.run(['release']), 0);
      expect(await registry.run(['docs']), 0);
      expect(await registry.run(['publish']), 0);
      // 'template' now has subcommands; calling without one may return 64 (UsageException)
      expect(await registry.run(['template']), isIn([0, 64]));
      expect(await registry.run(['plugin']), 0);

      // Verify that resolve works inside the command context
      final testCommand = CreateCommand();
      DependencyContainer()
          .registerSingleton<PlatformUtils>(const SystemPlatformUtils());
      expect(testCommand.resolve<PlatformUtils>(), isNotNull);
    });
  });
}
