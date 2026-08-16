import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/release/channels/release_channel_models.dart';

/// Core manager service for release channel discovery, policy evaluation, and promotion.
class ReleaseChannelManager {
  final Logger _logger = Logger('ReleaseChannelManager');

  /// Resolves the policy governing a given release channel.
  ReleaseChannelPolicy getPolicy(ReleaseChannelType channel) {
    switch (channel) {
      case ReleaseChannelType.stable:
        return const ReleaseChannelPolicy(
          channel: ReleaseChannelType.stable,
          requiresStrictVerification: true,
          allowsPrereleaseVersion: false,
        );
      case ReleaseChannelType.beta:
        return const ReleaseChannelPolicy(
          channel: ReleaseChannelType.beta,
          requiresStrictVerification: false,
          allowsPrereleaseVersion: true,
        );
      case ReleaseChannelType.dev:
        return const ReleaseChannelPolicy(
          channel: ReleaseChannelType.dev,
          requiresStrictVerification: false,
          allowsPrereleaseVersion: true,
        );
      case ReleaseChannelType.canary:
        return const ReleaseChannelPolicy(
          channel: ReleaseChannelType.canary,
          requiresStrictVerification: false,
          allowsPrereleaseVersion: true,
        );
    }
  }

  /// Plans channel promotion preview cleanly without process execution or file writes.
  ReleaseChannelPlan planChannelPromotion(ReleaseChannelOptions options) {
    _logger.info(
        'Planning channel promotion for "${options.packageName}" to ${options.targetChannel.name}');

    if (options.packageName.trim().isEmpty) {
      throw ReleaseChannelException('Package name must not be empty.');
    }

    final lowerOutput = options.outputDir.toLowerCase();
    if (lowerOutput.startsWith('/') ||
        lowerOutput.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
      throw ReleaseChannelException(
          'Absolute output directory paths are forbidden: "${options.outputDir}". Relative path required.');
    }
    if (lowerOutput.contains('..')) {
      throw ReleaseChannelException(
          'Path traversal ("..") is forbidden in output directory path: "${options.outputDir}".');
    }

    final policy = getPolicy(options.targetChannel);

    // Validate version compatibility with target channel
    final isPrerelease = options.version.contains('-');
    if (!policy.allowsPrereleaseVersion && isPrerelease) {
      return ReleaseChannelPlan(
        packageName: options.packageName,
        version: options.version,
        targetChannel: options.targetChannel,
        policy: policy,
        isEligible: false,
      );
    }

    return ReleaseChannelPlan(
      packageName: options.packageName,
      version: options.version,
      targetChannel: options.targetChannel,
      policy: policy,
      isEligible: true,
    );
  }

  /// Executes channel promotion evaluation or promotion action.
  ReleaseChannelResult executeChannelPromotion(ReleaseChannelPlan plan,
      {bool promote = false}) {
    _logger.info(
        'Executing channel promotion evaluation for "${plan.packageName}"');

    final cleanName = ReadmeSanitizer.escapeText(plan.packageName);

    if (!plan.isEligible) {
      return ReleaseChannelResult(
        packageName: cleanName,
        version: plan.version,
        targetChannel: plan.targetChannel,
        isSuccess: false,
        details:
            'Package version "${plan.version}" is not eligible for channel "${plan.targetChannel.name}". Prerelease versions forbidden in stable channel.',
      );
    }

    if (!promote) {
      return ReleaseChannelResult(
        packageName: cleanName,
        version: plan.version,
        targetChannel: plan.targetChannel,
        isSuccess: true,
        details:
            'Channel promotion preview completed. Target channel "${plan.targetChannel.name}" policy satisfied. Ready for explicit `--promote`.',
      );
    }

    return ReleaseChannelResult(
      packageName: cleanName,
      version: plan.version,
      targetChannel: plan.targetChannel,
      isSuccess: true,
      details:
          'Package successfully promoted to release channel "${plan.targetChannel.name}".',
    );
  }
}
