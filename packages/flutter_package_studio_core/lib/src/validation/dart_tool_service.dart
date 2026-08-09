import 'dart:io' as io;
import 'package:flutter_package_studio_core/src/logging/logger.dart';

/// Abstract interface for running Dart / Flutter CLI verification tooling safely.
abstract interface class DartToolService {
  /// Runs `dart analyze` in [directoryPath].
  Future<bool> runAnalyze(String directoryPath);

  /// Runs `dart test` in [directoryPath].
  Future<bool> runTest(String directoryPath);
}

/// System process implementation of [DartToolService].
class SystemDartToolService implements DartToolService {
  final Logger _logger;

  SystemDartToolService({Logger? logger})
      : _logger = logger ?? Logger('SystemDartToolService');

  @override
  Future<bool> runAnalyze(String directoryPath) async {
    try {
      final res = await io.Process.run('dart', ['analyze'],
          workingDirectory: directoryPath);
      return res.exitCode == 0;
    } catch (e) {
      _logger.warning('dart analyze failed or tool missing: $e');
      return false;
    }
  }

  @override
  Future<bool> runTest(String directoryPath) async {
    try {
      final res = await io.Process.run('dart', ['test'],
          workingDirectory: directoryPath);
      return res.exitCode == 0;
    } catch (e) {
      _logger.warning('dart test failed or tool missing: $e');
      return false;
    }
  }
}
