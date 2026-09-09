import 'package:syntrix/src/documentation/readme/readme_sanitizer.dart';
import 'package:syntrix/src/error/exceptions.dart';
import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/release/git/git_process_runner.dart';
import 'package:syntrix/src/release/git/git_release_models.dart';

/// Core manager service for planning and executing Git tagging and release branching operations.
class GitReleaseManager {
  final Logger _logger = Logger('GitReleaseManager');
  final GitProcessRunner _runner;

  GitReleaseManager({GitProcessRunner? runner})
      : _runner = runner ?? MockGitProcessRunner();

  /// Plans Git tag and branch operations cleanly without disk mutation or Git modifications.
  Future<GitReleasePlan> planRelease(GitReleaseOptions options) async {
    _logger.info(
        'Planning Git release for "${options.packageName}" version ${options.version}');

    if (options.packageName.trim().isEmpty) {
      throw GitReleaseException('Package name must not be empty.');
    }

    final lowerOutput = options.outputDir.toLowerCase();
    if (lowerOutput.startsWith('/') ||
        lowerOutput.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
      throw GitReleaseException(
          'Absolute output directory paths are forbidden: "${options.outputDir}". Relative path required.');
    }
    if (lowerOutput.contains('..')) {
      throw GitReleaseException(
          'Path traversal ("..") is forbidden in output directory path: "${options.outputDir}".');
    }

    final state = await _runner.getRepositoryState();

    if (!state.isClean) {
      throw GitReleaseException(
          'Git working tree is dirty (uncommitted changes exist). Release tagging rejected.');
    }

    final tagName = options.tagName ?? 'v${options.version}';
    final branchName = options.branchName ?? 'release/v${options.version}';

    final tagConflict = state.existingTags.contains(tagName);
    if (tagConflict) {
      throw GitReleaseException(
          'Git release tag "$tagName" already exists in repository.');
    }

    final branchConflict = state.existingBranches.contains(branchName);
    if (branchConflict) {
      throw GitReleaseException(
          'Git release branch "$branchName" already exists in repository.');
    }

    return GitReleasePlan(
      packageName: options.packageName,
      targetVersion: options.version,
      tagName: tagName,
      branchName: branchName,
      isClean: state.isClean,
      tagConflict: tagConflict,
      branchConflict: branchConflict,
      isValid: true,
      details:
          'Git release plan valid: tag "$tagName" and branch "$branchName" can be created.',
    );
  }

  /// Executes Git release operations (creates tag and branch) when explicitly authorized.
  Future<GitReleaseResult> executeRelease(GitReleasePlan plan,
      {bool execute = false}) async {
    _logger.info('Executing Git release for "${plan.packageName}"');

    final cleanName = ReadmeSanitizer.escapeText(plan.packageName);

    if (execute) {
      await _runner.createTag(plan.tagName,
          message: 'Release ${plan.packageName} ${plan.targetVersion}');
      await _runner.createBranch(plan.branchName);
    }

    return GitReleaseResult(
      packageName: cleanName,
      tagName: plan.tagName,
      branchName: plan.branchName,
      isExecuted: execute,
      details: execute
          ? 'Git release tag "${plan.tagName}" and branch "${plan.branchName}" created successfully.'
          : plan.details,
    );
  }
}
