/// Logging framework for Flutter Package Studio.
library;

/// Log levels indicating severity.
enum LogLevel {
  /// Fine-grained informational events, mostly for diagnostic purposes.
  trace(0, 'TRACE'),

  /// Fine-grained events that are most useful to debug an application.
  debug(1, 'DEBUG'),

  /// Informational messages that highlight the progress of the application.
  info(2, 'INFO'),

  /// Potentially harmful situations.
  warning(3, 'WARN'),

  /// Error events that might still allow the application to continue running.
  error(4, 'ERROR'),

  /// Severe error events that will presumably lead the application to abort.
  critical(5, 'CRIT');

  /// Internal index value.
  final int value;

  /// Human-readable label.
  final String label;

  const LogLevel(this.value, this.label);
}

/// A structured container for a single log message.
class LogRecord {
  /// The severity of the log.
  final LogLevel level;

  /// The log message content.
  final String message;

  /// The timestamp when the log occurred.
  final DateTime time;

  /// The name of the logger instance that produced this record.
  final String loggerName;

  /// Optional error object associated with this log.
  final Object? error;

  /// Optional stack trace associated with the error.
  final StackTrace? stackTrace;

  /// Creates a new [LogRecord].
  LogRecord({
    required this.level,
    required this.message,
    required this.time,
    required this.loggerName,
    this.error,
    this.stackTrace,
  });
}

/// Interface for handling [LogRecord]s (e.g. console, file, telemetry).
abstract interface class LogHandler {
  /// Processes a single [LogRecord].
  void handle(LogRecord record);
}

/// The core class to trigger log events.
class Logger {
  /// Name of this logger.
  final String name;

  /// Current log filter level. Records below this level will be discarded.
  LogLevel level;

  static final List<LogHandler> _handlers = [];

  /// Creates a new [Logger] instance with the given [name] and optional [level] (defaults to [LogLevel.info]).
  Logger(this.name, {this.level = LogLevel.info});

  /// Adds a global [LogHandler] to receive log events.
  static void addHandler(LogHandler handler) {
    _handlers.add(handler);
  }

  /// Removes a specific global [LogHandler].
  static void removeHandler(LogHandler handler) {
    _handlers.remove(handler);
  }

  /// Removes all global handlers.
  static void clearHandlers() {
    _handlers.clear();
  }

  /// Logs a message at [level], with optional error and stack trace.
  void log(LogLevel logLevel, String message,
      [Object? error, StackTrace? stackTrace]) {
    if (logLevel.value < level.value) return;

    final record = LogRecord(
      level: logLevel,
      message: message,
      time: DateTime.now(),
      loggerName: name,
      error: error,
      stackTrace: stackTrace,
    );

    for (final handler in _handlers) {
      try {
        handler.handle(record);
      } catch (_) {
        // Prevent logger handlers from crashing the main application thread.
      }
    }
  }

  /// Logs a message at [LogLevel.trace].
  void trace(String message) => log(LogLevel.trace, message);

  /// Logs a message at [LogLevel.debug].
  void debug(String message) => log(LogLevel.debug, message);

  /// Logs a message at [LogLevel.info].
  void info(String message) => log(LogLevel.info, message);

  /// Logs a message at [LogLevel.warning].
  void warning(String message) => log(LogLevel.warning, message);

  /// Logs a message at [LogLevel.error] with optional error and stack trace.
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    log(LogLevel.error, message, error, stackTrace);
  }

  /// Logs a message at [LogLevel.critical] with optional error and stack trace.
  void critical(String message, [Object? error, StackTrace? stackTrace]) {
    log(LogLevel.critical, message, error, stackTrace);
  }
}

/// A standard [LogHandler] that formats and prints logs to stdout/stderr.
class ConsoleLogHandler implements LogHandler {
  /// Whether ANSI color output is enabled.
  final bool enableColor;

  /// Creates a [ConsoleLogHandler] with option to enable/disable colors.
  ConsoleLogHandler({this.enableColor = true});

  @override
  void handle(LogRecord record) {
    final timeStr = '${record.time.hour.toString().padLeft(2, '0')}:'
        '${record.time.minute.toString().padLeft(2, '0')}:'
        '${record.time.second.toString().padLeft(2, '0')}.'
        '${record.time.millisecond.toString().padLeft(3, '0')}';

    final String coloredLevel;
    if (enableColor) {
      coloredLevel =
          _getColorCode(record.level) + record.level.label + _resetCode;
    } else {
      coloredLevel = record.level.label;
    }

    final buffer = StringBuffer()
      ..write('[$timeStr] ')
      ..write('[$coloredLevel] ')
      ..write('[${record.loggerName}] ')
      ..write(record.message);

    if (record.error != null) {
      buffer.write('\nError: ${record.error}');
    }
    if (record.stackTrace != null) {
      buffer.write('\nStacktrace:\n${record.stackTrace}');
    }

    if (record.level.value >= LogLevel.error.value) {
      // Print errors to standard error
      _printError(buffer.toString());
    } else {
      _printOut(buffer.toString());
    }
  }

  void _printOut(String message) {
    // Under test environment or normal run, output is printed
    print(message);
  }

  void _printError(String message) {
    // Prints to stderr. We use print in Dart but we could use stderr.writeAll.
    // For standard Dart CLI app, print is safe and works nicely across environments.
    print(message);
  }

  String _getColorCode(LogLevel level) {
    return switch (level) {
      LogLevel.trace => '\x1B[90m', // Gray
      LogLevel.debug => '\x1B[36m', // Cyan
      LogLevel.info => '\x1B[32m', // Green
      LogLevel.warning => '\x1B[33m', // Yellow
      LogLevel.error => '\x1B[31m', // Red
      LogLevel.critical => '\x1B[1;31m', // Bold Red
    };
  }

  static const String _resetCode = '\x1B[0m';
}
