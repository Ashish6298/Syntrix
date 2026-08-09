import 'package:flutter_package_studio_core/src/utils/terminal_utils.dart';

/// Defines terminal styles, ANSI colors, and glyph fallbacks for the wizard.
class WizardTheme {
  /// Whether ANSI escape sequences are enabled.
  final bool enableAnsi;

  /// Creates a [WizardTheme] instance.
  const WizardTheme({this.enableAnsi = true});

  /// Creates a [WizardTheme] based on [TerminalUtils] capabilities.
  factory WizardTheme.fromTerminal(TerminalUtils terminal) {
    return WizardTheme(enableAnsi: terminal.supportsAnsi);
  }

  // ANSI escape codes
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String italic = '\x1B[3m';
  static const String underline = '\x1B[4m';

  static const String fgCyan = '\x1B[36m';
  static const String fgGreen = '\x1B[32m';
  static const String fgYellow = '\x1B[33m';
  static const String fgRed = '\x1B[31m';
  static const String fgMagenta = '\x1B[35m';
  static const String fgBlue = '\x1B[34m';
  static const String fgGray = '\x1B[90m';
  static const String fgWhite = '\x1B[97m';

  /// Wraps [text] in primary color style (Cyan/Bold).
  String primary(String text) => enableAnsi ? '$fgCyan$bold$text$reset' : text;

  /// Wraps [text] in secondary color style (Magenta).
  String secondary(String text) => enableAnsi ? '$fgMagenta$text$reset' : text;

  /// Wraps [text] in success style (Green/Bold).
  String success(String text) => enableAnsi ? '$fgGreen$bold$text$reset' : text;

  /// Wraps [text] in warning style (Yellow).
  String warning(String text) => enableAnsi ? '$fgYellow$text$reset' : text;

  /// Wraps [text] in error style (Red/Bold).
  String error(String text) => enableAnsi ? '$fgRed$bold$text$reset' : text;

  /// Wraps [text] in muted/dim style (Gray).
  String muted(String text) => enableAnsi ? '$fgGray$text$reset' : text;

  /// Wraps [text] in bold style.
  String highlight(String text) => enableAnsi ? '$bold$text$reset' : text;

  /// Prompt symbol (e.g. "?").
  String get promptSymbol => enableAnsi ? '$fgCyan?$reset' : '?';

  /// Pointer/bullet symbol for selections (e.g. "❯" or ">").
  String get pointerSymbol => enableAnsi ? '$fgCyan❯$reset' : '>';

  /// Success checkmark (e.g. "✔" or `[v]`).
  String get successSymbol => enableAnsi ? '$fgGreen✔$reset' : '[v]';

  /// Error symbol (e.g. "✖" or `[x]`).
  String get errorSymbol => enableAnsi ? '$fgRed✖$reset' : '[x]';

  /// Bullet point (e.g. "•" or "*").
  String get bulletSymbol => enableAnsi ? '$fgCyan•$reset' : '*';
}
