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

  /// Formats and returns the stylized terminal SYNTRIX splash banner matching the approved design.
  static String getBanner({bool enableColor = true}) {
    // Exact hex color styling helper (ANSI truecolor \x1B[38;2;R;G;Bm)
    String hex(String hexCode, String text, {bool bold = false}) {
      if (!enableColor) return text;
      final clean = hexCode.replaceAll('#', '');
      final r = int.parse(clean.substring(0, 2), radix: 16);
      final g = int.parse(clean.substring(2, 4), radix: 16);
      final b = int.parse(clean.substring(4, 6), radix: 16);
      final boldCode = bold ? '\x1B[1m' : '';
      return '\x1B[38;2;$r;$g;${b}m$boldCode$text\x1B[0m';
    }

    final purple = (String t) => hex('#AFA9EC', t);
    final purpleDim = (String t) => hex('#7F77DD', t, bold: true);
    final muted = (String t) => hex('#8a8d90', t);
    final desc = (String t) => hex('#9a9d9f', t);
    final footer = (String t) => hex('#5f6265', t);
    final white = (String t) => hex('#f2f1ec', t, bold: true);

    // Filled hexagon reads heavier/bigger than outline version, bolded for extra weight
    final glyph = purpleDim('⬢');

    String pad(String label, [int width = 10]) {
      return label + ' ' * (width - label.length > 0 ? width - label.length : 1);
    }

    final commands = [
      ['create', 'scaffold a new production-ready package'],
      ['--audit', 'run automated audit checks'],
      ['template', 'manage templates'],
      ['plugin', 'manage plugins'],
      ['--help', 'explore all commands'],
    ];

    final buffer = StringBuffer();
    buffer.writeln();
    buffer.writeln('                 $glyph  ${white('S Y N T R I X')}');
    buffer.writeln();
    buffer.writeln('     ${muted('Enterprise tools & AI studio for Flutter and Dart')}');
    buffer.writeln('     ${footer('─' * 50)}');
    buffer.writeln();
    buffer.writeln('     ${white('Quick Actions:')}');
    buffer.writeln();

    for (final pair in commands) {
      final cmd = pair[0];
      final description = pair[1];
      buffer.writeln('     ${purple('• ${pad(cmd)}')}${desc(description)}');
    }

    buffer.writeln();
    buffer.writeln('     ${footer('─' * 50)}');
    buffer.writeln(
        '     ${footer('v$version')}    ${footer('dart 3.5.0')}    ${footer('flutter 3.24.0')}');
    buffer.writeln();

    return buffer.toString();
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

