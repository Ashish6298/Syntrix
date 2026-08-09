import 'dart:io' as io;
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';

/// Abstract interface for executing local Git commands.
abstract interface class GitService {
  /// Returns `true` if `git` executable is installed and available in environment PATH.
  Future<bool> isGitInstalled();

  /// Initializes a Git repository in [directoryPath] with [defaultBranch].
  /// Throws [GitException] if directory does not exist or Git initialization fails.
  Future<void> initRepository(String directoryPath,
      {String defaultBranch = 'main'});
}

/// Production implementation of [GitService] executing system `git` CLI process.
class SystemGitService implements GitService {
  final Logger _logger;

  /// Creates a [SystemGitService] instance.
  SystemGitService({Logger? logger}) : _logger = logger ?? Logger('GitService');

  @override
  Future<bool> isGitInstalled() async {
    try {
      final res = await io.Process.run('git', ['--version']);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> initRepository(String directoryPath,
      {String defaultBranch = 'main'}) async {
    final dir = io.Directory(directoryPath);
    if (!dir.existsSync()) {
      throw GitException(
          'Cannot initialize Git in non-existent directory: "$directoryPath".');
    }

    final gitDir = io.Directory('${dir.path}/.git');
    if (gitDir.existsSync()) {
      _logger.info(
          'Git repository already exists in "$directoryPath". Skipping re-initialization.');
      return;
    }

    try {
      _logger.debug('Running git init in "$directoryPath"');
      final initRes = await io.Process.run('git', ['init'],
          workingDirectory: directoryPath);
      if (initRes.exitCode != 0) {
        throw GitException('Failed to execute "git init": ${initRes.stderr}');
      }

      _logger.debug(
          'Setting default branch to "$defaultBranch" in "$directoryPath"');
      await io.Process.run('git', ['branch', '-M', defaultBranch],
          workingDirectory: directoryPath);
    } catch (e, st) {
      if (e is GitException) rethrow;
      throw GitException('Git initialization error: $e', e, st);
    }
  }
}
