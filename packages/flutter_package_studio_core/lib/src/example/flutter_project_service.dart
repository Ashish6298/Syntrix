import 'dart:io' as io;
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';

/// Abstract interface for executing Flutter CLI tooling on example applications.
abstract interface class FlutterProjectService {
  /// Returns `true` if `flutter` executable is available on PATH.
  Future<bool> isFlutterInstalled();

  /// Runs `flutter pub get` in [directoryPath].
  Future<void> pubGet(String directoryPath);
}

/// Production implementation of [FlutterProjectService] executing system `flutter` CLI.
class SystemFlutterProjectService implements FlutterProjectService {
  final Logger _logger;

  /// Creates a [SystemFlutterProjectService] instance.
  SystemFlutterProjectService({Logger? logger})
      : _logger = logger ?? Logger('FlutterProjectService');

  @override
  Future<bool> isFlutterInstalled() async {
    try {
      final res = await io.Process.run('flutter', ['--version']);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> pubGet(String directoryPath) async {
    final dir = io.Directory(directoryPath);
    if (!dir.existsSync()) {
      throw ExampleGenerationException(
          'Cannot run pub get in non-existent directory: "$directoryPath".');
    }

    try {
      _logger.debug('Running "flutter pub get" in "$directoryPath"');
      final res = await io.Process.run('flutter', ['pub', 'get'],
          workingDirectory: directoryPath);
      if (res.exitCode != 0) {
        throw ExampleGenerationException(
            'flutter pub get failed: ${res.stderr}');
      }
    } catch (e, st) {
      if (e is ExampleGenerationException) rethrow;
      throw ExampleGenerationException(
          'Flutter CLI execution failed: $e', e, st);
    }
  }
}
