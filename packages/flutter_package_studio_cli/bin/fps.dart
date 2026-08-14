import 'dart:io' as io;
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';

Future<void> main(List<String> arguments) async {
  // 1. Setup DI container
  final container = DependencyContainer();

  final platformUtils = const SystemPlatformUtils();
  final fileUtils = const SystemFileUtils();
  final terminalUtils = const SystemTerminalUtils();

  container.registerSingleton<PlatformUtils>(platformUtils);
  container.registerSingleton<FileUtils>(fileUtils);
  container.registerSingleton<TerminalUtils>(terminalUtils);

  // 2. Setup Logging
  final rootLogger = Logger('FPS', level: LogLevel.info);
  Logger.addHandler(ConsoleLogHandler(enableColor: terminalUtils.supportsAnsi));
  container.registerSingleton<Logger>(rootLogger);

  // 3. Load configuration
  final configLoader = ConfigLoader(fileUtils, platformUtils);
  final config = configLoader.load();
  container.registerSingleton<FpsConfig>(config);

  if (config.verbose) {
    rootLogger.level = LogLevel.trace;
  }

  // 4. Command Registration
  final registry = CommandRegistry();
  registry.register(CreateCommand());
  registry.register(AuditCommand());
  registry.register(ReleaseCommand());
  registry.register(DocsCommand());
  registry.register(PublishCommand());
  registry.register(TemplateCommand());
  registry.register(PluginCommand());
  registry.register(RegistryCommand());

  // 5. Run Command
  final exitCode = await registry.run(arguments);
  io.exit(exitCode);
}
