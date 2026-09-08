import 'dart:io' as io;
import 'package:args/command_runner.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

/// Registry responsible for discovering, registering, and executing CLI commands.
class CommandRegistry {
  /// CLI semantic version string.
  static const String version = '1.0.0';

  /// The command runner engine.
  final CommandRunner<int> runner;

  final Logger _logger = Logger('CommandRegistry');

  /// Creates a [CommandRegistry] with executable name and description.
  CommandRegistry({
    String name = 'syntrix',
    String description =
        'Syntrix (Flutter Package Studio): Enterprise-grade tools & AI engineering for Flutter & Dart packages.',
  }) : runner = CommandRunner<int>(name, description) {
    // Add global options.
    runner.argParser.addFlag(
      'version',
      abbr: 'V',
      negatable: false,
      help: 'Print the current Syntrix CLI version.',
    );
    runner.argParser.addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Enable verbose logging output.',
    );
    runner.argParser.addFlag(
      'audit',
      negatable: false,
      help: 'Run the package audit engine against current directory.',
    );
  }

  /// Dynamically registers a new [command].
  void register(FpsCommand command) {
    _logger.debug('Registering CLI command: ${command.name}');
    runner.addCommand(command);
  }

  /// Formats and returns the ASCII / stylized terminal SYNTRIX banner.
  static String getBanner() {
    return '''
========================================================================
   ____  __  __ _   _ _____ ____  ______  __
  / ___| \\ \\/ /| \\ | |_   _|  _ \\|_  _\\ \\/ /
  \\___ \\  \\  / |  \\| | | | | |_) | | |  \\  / 
   ___) | / /  | |\\  | | | |  _ < _| |_ /  \\ 
  |____/ /_/   |_| \\_| |_| |_| \\_\\_____/_/\\_\\
  SYNTRIX — Enterprise-Grade Tools & AI Studio for Flutter & Dart
========================================================================

Welcome to Syntrix! Get started with the following commands:

  1. syntrix --version
     Display the installed Syntrix CLI version.

  2. syntrix --help
     View all available commands, options, and workflows.

Quick Actions:
  • syntrix --audit    Run automated audit checks on current package
  • syntrix create     Create a new production-ready Flutter package
  • syntrix --help     Explore all commands (audit, create, template, plugin, etc.)

''';
  }

  /// Runs the CLI application with the given [arguments].
  ///
  /// Catch and handle exceptions gracefully to prevent application crashes.
  Future<int> run(List<String> arguments) async {
    try {
      // If run with no arguments, display the Syntrix welcome banner with the 2 primary commands.
      if (arguments.isEmpty) {
        print(getBanner());
        return 0;
      }

      if (arguments.contains('--version') || arguments.contains('-V')) {
        print('Syntrix CLI v$version (Flutter Package Studio)');
        return 0;
      }

      if (arguments.contains('--audit')) {
        final auditArgs = List<String>.from(arguments)..remove('--audit');
        final auditCmd = runner.commands['audit'];
        if (auditCmd != null) {
          return await runner.run(['audit', ...auditArgs]) ?? 0;
        }
      }

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

