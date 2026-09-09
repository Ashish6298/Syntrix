/// Supported release channel types.
enum ReleaseChannelType {
  stable,
  beta,
  dev,
  canary,
}

/// Rules and policies governing a specific release channel.
class ReleaseChannelPolicy {
  final ReleaseChannelType channel;
  final bool requiresStrictVerification;
  final bool allowsPrereleaseVersion;

  const ReleaseChannelPolicy({
    required this.channel,
    required this.requiresStrictVerification,
    required this.allowsPrereleaseVersion,
  });

  Map<String, dynamic> toJson() => {
        'channel': channel.name,
        'requiresStrictVerification': requiresStrictVerification,
        'allowsPrereleaseVersion': allowsPrereleaseVersion,
      };
}

/// Options configuring release channel promotion planning/execution.
class ReleaseChannelOptions {
  final String packageName;
  final String version;
  final ReleaseChannelType targetChannel;
  final bool promote;
  final String outputDir;

  const ReleaseChannelOptions({
    required this.packageName,
    this.version = '1.0.0',
    this.targetChannel = ReleaseChannelType.stable,
    this.promote = false,
    this.outputDir = 'doc/release',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'targetChannel': targetChannel.name,
        'promote': promote,
        'outputDir': outputDir,
      };
}

/// Preview plan of release channel promotion.
class ReleaseChannelPlan {
  final String packageName;
  final String version;
  final ReleaseChannelType targetChannel;
  final ReleaseChannelPolicy policy;
  final bool isEligible;

  const ReleaseChannelPlan({
    required this.packageName,
    required this.version,
    required this.targetChannel,
    required this.policy,
    required this.isEligible,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'targetChannel': targetChannel.name,
        'policy': policy.toJson(),
        'isEligible': isEligible,
      };
}

/// Result of release channel promotion.
class ReleaseChannelResult {
  final String packageName;
  final String version;
  final ReleaseChannelType targetChannel;
  final bool isSuccess;
  final String details;

  const ReleaseChannelResult({
    required this.packageName,
    required this.version,
    required this.targetChannel,
    required this.isSuccess,
    required this.details,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Release Channel Promotion Report: $packageName');
    buf.writeln();
    buf.writeln('**Package Version**: $version');
    buf.writeln('**Target Channel**: ${targetChannel.name.toUpperCase()}');
    buf.writeln(
        '**Promotion Decision**: ${isSuccess ? "PROMOTION APPROVED ✓" : "PROMOTION REJECTED ✗"}');
    buf.writeln();
    buf.writeln('### Details');
    buf.writeln(details);
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'targetChannel': targetChannel.name,
        'isSuccess': isSuccess,
        'details': details,
      };
}
