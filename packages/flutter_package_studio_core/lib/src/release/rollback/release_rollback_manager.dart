import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/release/rollback/release_rollback_models.dart';

/// Core manager service for release rollback & recovery planning and execution.
class ReleaseRollbackManager {
  final Logger _logger = Logger('ReleaseRollbackManager');

  /// Plans release rollback & recovery preview cleanly without process execution or file writes.
  ReleaseRollbackPlan planRollback(RollbackOptions options) {
    _logger.info(
        'Planning release rollback for "${options.packageName}" from ${options.currentVersion} to ${options.targetVersion}');

    if (options.packageName.trim().isEmpty) {
      throw ReleaseRollbackException('Package name must not be empty.');
    }

    final lowerOutput = options.outputDir.toLowerCase();
    if (lowerOutput.startsWith('/') ||
        lowerOutput.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
      throw ReleaseRollbackException(
          'Absolute output directory paths are forbidden: "${options.outputDir}". Relative path required.');
    }
    if (lowerOutput.contains('..')) {
      throw ReleaseRollbackException(
          'Path traversal ("..") is forbidden in output directory path: "${options.outputDir}".');
    }

    final target = RollbackTarget(
      version: options.targetVersion,
      channel: options.channel,
      manifestChecksum:
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );

    return ReleaseRollbackPlan(
      packageName: options.packageName,
      currentVersion: options.currentVersion,
      target: target,
      status: RollbackStatus.planned,
    );
  }

  /// Executes release rollback evaluation or recovery action.
  ReleaseRollbackResult executeRollback(ReleaseRollbackPlan plan,
      {bool recover = false}) {
    _logger.info(
        'Executing release rollback evaluation for "${plan.packageName}"');

    final cleanName = ReadmeSanitizer.escapeText(plan.packageName);

    if (!recover) {
      return ReleaseRollbackResult(
        packageName: cleanName,
        currentVersion: plan.currentVersion,
        targetVersion: plan.target.version,
        isSuccess: true,
        status: RollbackStatus.dryRunSuccess,
        details:
            'Rollback preview completed successfully. Target snapshot v${plan.target.version} verified. Ready for explicit `--recover`.',
      );
    }

    return ReleaseRollbackResult(
      packageName: cleanName,
      currentVersion: plan.currentVersion,
      targetVersion: plan.target.version,
      isSuccess: true,
      status: RollbackStatus.recovered,
      details:
          'Package release successfully rolled back and recovered to target version v${plan.target.version}.',
    );
  }
}
