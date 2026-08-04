import 'package:args/command_runner.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

/// Registry responsible for discovering, registering, and executing CLI commands.
class CommandRegistry {
  /// The command runner engine.
  final CommandRunner<int> runner;

  final Logger _logger = Logger('CommandRegistry');

  /// Creates a [CommandRegistry] with executable name and description.
  CommandRegistry({
    String name = 'fps',
    String description =
        'Flutter Package Studio: Enterprise-grade tools for Flutter packages.',
  }) : runner = CommandRunner<int>(name, description) {
    // Add global options if any.
    runner.argParser.addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Enable verbose logging output.',
    );
  }

  /// Dynamically registers a new [command].
  void register(FpsCommand command) {
    _logger.debug('Registering CLI command: ${command.name}');
    runner.addCommand(command);
  }

  /// Runs the CLI application with the given [arguments].
  ///
  /// Catch and handle exceptions gracefully to prevent application crashes.
  Future<int> run(List<String> arguments) async {
    try {
      final argResults = runner.parse(arguments);

      // Update verbosity level if verbose flag is set.
      if (argResults['verbose'] == true) {
        final container = DependencyContainer();
        if (container.isRegistered<Logger>()) {
          container.resolve<Logger>().level = LogLevel.trace;
        }
      }

      final exitCode = await runner.run(arguments);
      return exitCode ?? 0;
    } on UsageException catch (e) {
      _logger.warning(e.message);
      _logger.info(e.usage);
      return 64; // Exit code for incorrect usage
    } on PackageStudioException catch (e) {
      _logger.error(e.message);
      if (e.details != null) {
        _logger.debug('Error Details: ${e.details}');
      }
      return 1;
    } catch (e, st) {
      _logger.critical('An unexpected error occurred: $e', e, st);
      return 1;
    }
  }
}
