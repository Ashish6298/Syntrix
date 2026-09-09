import 'dart:io' as io;

/// Interface for terminal capability detection.
abstract interface class TerminalUtils {
  /// Whether the standard output supports ANSI escape sequences.
  bool get supportsAnsi;

  /// The width of the terminal in columns. Returns 80 as fallback if unavailable.
  int get width;

  /// The height of the terminal in lines. Returns 24 as fallback if unavailable.
  int get height;
}

/// Production implementation of [TerminalUtils] delegating to [io.stdout].
class SystemTerminalUtils implements TerminalUtils {
  /// Creates a [SystemTerminalUtils] instance.
  const SystemTerminalUtils();

  @override
  bool get supportsAnsi {
    try {
      return io.stdout.supportsAnsiEscapes;
    } catch (_) {
      return false;
    }
  }

  @override
  int get width {
    try {
      if (io.stdout.hasTerminal) {
        return io.stdout.terminalColumns;
      }
    } catch (_) {
      // Fallback
    }
    return 80;
  }

  @override
  int get height {
    try {
      if (io.stdout.hasTerminal) {
        return io.stdout.terminalLines;
      }
    } catch (_) {
      // Fallback
    }
    return 24;
  }
}
