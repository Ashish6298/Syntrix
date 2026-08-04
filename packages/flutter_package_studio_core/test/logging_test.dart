import 'package:test/test.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';

class MockLogHandler implements LogHandler {
  final List<LogRecord> records = [];
  bool throwOnHandle = false;

  @override
  void handle(LogRecord record) {
    if (throwOnHandle) {
      throw Exception('Handler failed');
    }
    records.add(record);
  }
}

void main() {
  group('Logging Tests', () {
    late MockLogHandler mockHandler;

    setUp(() {
      mockHandler = MockLogHandler();
      Logger.clearHandlers();
      Logger.addHandler(mockHandler);
    });

    tearDown(() {
      Logger.clearHandlers();
    });

    test('Logger filters records by LogLevel', () {
      final logger = Logger('TestLogger', level: LogLevel.warning);

      logger.trace('Trace message');
      logger.debug('Debug message');
      logger.info('Info message');
      expect(mockHandler.records, isEmpty);

      logger.warning('Warning message');
      logger.error('Error message');
      logger.critical('Critical message');

      expect(mockHandler.records.length, 3);
      expect(mockHandler.records[0].level, LogLevel.warning);
      expect(mockHandler.records[0].message, 'Warning message');
      expect(mockHandler.records[1].level, LogLevel.error);
      expect(mockHandler.records[2].level, LogLevel.critical);
    });

    test('Logger logs error objects and stack traces', () {
      final logger = Logger('TestLogger', level: LogLevel.debug);
      final error = StateError('Bad state');
      final stackTrace = StackTrace.current;

      logger.error('An error occurred', error, stackTrace);

      expect(mockHandler.records.length, 1);
      final record = mockHandler.records.first;
      expect(record.level, LogLevel.error);
      expect(record.message, 'An error occurred');
      expect(record.error, same(error));
      expect(record.stackTrace, same(stackTrace));
    });

    test('Log handlers exceptions do not crash logger or app', () {
      mockHandler.throwOnHandle = true;
      final logger = Logger('TestLogger', level: LogLevel.info);

      // Should not throw or crash
      expect(() => logger.info('Test'), returnsNormally);
    });

    test('ConsoleLogHandler formatting', () {
      final consoleHandler = ConsoleLogHandler(enableColor: false);
      final record = LogRecord(
        level: LogLevel.info,
        message: 'Formatting test',
        time: DateTime(2026, 8, 5, 12, 0, 0),
        loggerName: 'TestLogger',
      );

      // Verify that calling handle does not crash
      expect(() => consoleHandler.handle(record), returnsNormally);
    });

    test('ConsoleLogHandler with color and errors formatting', () {
      final consoleHandler = ConsoleLogHandler(enableColor: true);
      final record = LogRecord(
        level: LogLevel.error,
        message: 'Formatting test with error',
        time: DateTime(2026, 8, 5, 12, 0, 0),
        loggerName: 'TestLogger',
        error: 'Sample Error',
        stackTrace: StackTrace.fromString('stacktrace line'),
      );

      expect(() => consoleHandler.handle(record), returnsNormally);
    });

    test('ConsoleLogHandler critical logging with color', () {
      final consoleHandler = ConsoleLogHandler(enableColor: true);
      final record = LogRecord(
        level: LogLevel.critical,
        message: 'Critical error message',
        time: DateTime(2026, 8, 5, 12, 0, 0),
        loggerName: 'TestLogger',
      );
      expect(() => consoleHandler.handle(record), returnsNormally);
    });

    test('Logger removeHandler works', () {
      final logger = Logger('TestLogger', level: LogLevel.info);
      expect(mockHandler.records, isEmpty);

      logger.info('Message 1');
      expect(mockHandler.records.length, 1);

      Logger.removeHandler(mockHandler);
      logger.info('Message 2');
      expect(mockHandler.records.length, 1); // remains 1
    });
  });
}
