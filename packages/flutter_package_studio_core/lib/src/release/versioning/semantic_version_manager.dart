import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/release/versioning/semver_models.dart';

/// Core manager service for analyzing, parsing, validating, and incrementing Semantic Versioning 2.0.0 compliance.
class SemanticVersionManager {
  final Logger _logger = Logger('SemanticVersionManager');

  /// Parses and validates a raw version string into a [SemVer] object.
  SemVer parseVersion(String input) {
    return SemVer.parse(input);
  }

  /// Compares two version strings according to SemVer 2.0.0 precedence rules.
  int compareVersions(String a, String b) {
    final verA = parseVersion(a);
    final verB = parseVersion(b);
    return verA.compareTo(verB);
  }

  /// Plans a semantic version transition cleanly without disk mutation or external side-effects.
  SemVerPlan planTransition(SemVerOptions options) {
    _logger.info(
        'Planning version transition for "${options.packageName}" from ${options.currentVersion}');

    if (options.packageName.trim().isEmpty) {
      throw SemanticVersionException('Package name must not be empty.');
    }

    final lowerOutput = options.outputDir.toLowerCase();
    if (lowerOutput.startsWith('/') ||
        lowerOutput.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
      throw SemanticVersionException(
          'Absolute output directory paths are forbidden: "${options.outputDir}". Relative path required.');
    }
    if (lowerOutput.contains('..')) {
      throw SemanticVersionException(
          'Path traversal ("..") is forbidden in output directory path: "${options.outputDir}".');
    }

    final current = SemVer.parse(options.currentVersion);
    final target = _calculateTargetVersion(current, options);

    // Downgrade protection check
    if (target.compareTo(current) < 0 && !options.policy.allowDowngrade) {
      throw SemanticVersionException(
          'Version downgrade rejected: proposed version "$target" is lower than current version "$current".');
    }

    // Same version rejection
    if (target.compareTo(current) == 0 &&
        options.type != SemVerIncrementType.explicit) {
      throw SemanticVersionException(
          'Version transition rejected: proposed version "$target" is identical to current version "$current".');
    }

    // Channel compatibility check (e.g. stable channel forbids prerelease unless policy allows)
    if (options.channel == 'stable' &&
        target.isPrerelease &&
        !options.policy.allowPrerelease) {
      throw SemanticVersionException(
          'Prerelease version "$target" rejected for stable release channel without explicit policy authorization.');
    }

    return SemVerPlan(
      packageName: options.packageName,
      currentVersion: current,
      targetVersion: target,
      type: options.type,
      isValid: true,
      details:
          'SemVer transition from $current to $target planned successfully.',
    );
  }

  /// Executes or applies a planned version transition.
  SemVerResult applyTransition(SemVerPlan plan, {bool writeDisk = false}) {
    _logger.info(
        'Applying version transition for "${plan.packageName}" to ${plan.targetVersion}');

    final cleanName = ReadmeSanitizer.escapeText(plan.packageName);

    return SemVerResult(
      packageName: cleanName,
      previousVersion: plan.currentVersion.toString(),
      newVersion: plan.targetVersion.toString(),
      isApplied: writeDisk,
      details: plan.details,
    );
  }

  SemVer _calculateTargetVersion(SemVer current, SemVerOptions options) {
    final tag = options.prereleaseId ?? 'alpha';

    switch (options.type) {
      case SemVerIncrementType.major:
        return SemVer(major: current.major + 1, minor: 0, patch: 0);

      case SemVerIncrementType.minor:
        return SemVer(major: current.major, minor: current.minor + 1, patch: 0);

      case SemVerIncrementType.patch:
        if (current.isPrerelease) {
          // Promoting a pre-release (e.g. 1.0.0-alpha.1) to stable (1.0.0) without changing major/minor/patch
          return SemVer(
              major: current.major, minor: current.minor, patch: current.patch);
        }
        return SemVer(
            major: current.major,
            minor: current.minor,
            patch: current.patch + 1);

      case SemVerIncrementType.prerelease:
        if (current.isPrerelease) {
          // Increment existing prerelease numeric component if present
          final lastPart = current.prerelease.last;
          if (RegExp(r'^[0-9]+$').hasMatch(lastPart)) {
            final nextNum = int.parse(lastPart) + 1;
            final updatedPre = List<String>.from(current.prerelease)
              ..removeLast()
              ..add(nextNum.toString());
            return SemVer(
              major: current.major,
              minor: current.minor,
              patch: current.patch,
              prerelease: updatedPre,
            );
          } else {
            final updatedPre = List<String>.from(current.prerelease)..add('1');
            return SemVer(
              major: current.major,
              minor: current.minor,
              patch: current.patch,
              prerelease: updatedPre,
            );
          }
        } else {
          // Create new prerelease for next patch
          return SemVer(
            major: current.major,
            minor: current.minor,
            patch: current.patch + 1,
            prerelease: [tag, '1'],
          );
        }

      case SemVerIncrementType.explicit:
        if (options.explicitVersion == null ||
            options.explicitVersion!.trim().isEmpty) {
          throw SemanticVersionException(
              'Explicit version target required when type is explicit.');
        }
        return SemVer.parse(options.explicitVersion!);
    }
  }
}
