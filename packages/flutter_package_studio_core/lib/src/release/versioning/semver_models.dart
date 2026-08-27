import 'package:flutter_package_studio_core/src/error/exceptions.dart';

/// Semantic Versioning 2.0.0 increment types.
enum SemVerIncrementType {
  major,
  minor,
  patch,
  prerelease,
  explicit,
}

/// Represents a parsed Semantic Versioning 2.0.0 compliance object.
class SemVer implements Comparable<SemVer> {
  final int major;
  final int minor;
  final int patch;
  final List<String> prerelease;
  final List<String> build;

  const SemVer({
    required this.major,
    required this.minor,
    required this.patch,
    this.prerelease = const [],
    this.build = const [],
  });

  /// Parses a string into a [SemVer] according to SemVer 2.0.0 rules.
  factory SemVer.parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw SemanticVersionException('Version string cannot be empty.');
    }

    final buildSplit = trimmed.split('+');
    if (buildSplit.length > 2) {
      throw SemanticVersionException(
          'Invalid version "$input": multiple build metadata separators (+).');
    }
    final versionAndPrerelease = buildSplit[0];
    final buildStr = buildSplit.length == 2 ? buildSplit[1] : null;

    final prereleaseSplit = versionAndPrerelease.split('-');
    final coreStr = prereleaseSplit[0];
    final prereleaseStr = prereleaseSplit.length > 1
        ? prereleaseSplit.sublist(1).join('-')
        : null;

    final coreParts = coreStr.split('.');
    if (coreParts.length != 3) {
      throw SemanticVersionException(
          'Invalid SemVer "$input": core version must have 3 numeric components (major.minor.patch).');
    }

    final major = int.tryParse(coreParts[0]);
    final minor = int.tryParse(coreParts[1]);
    final patch = int.tryParse(coreParts[2]);

    if (major == null ||
        major < 0 ||
        coreParts[0].length > 1 && coreParts[0].startsWith('0')) {
      throw SemanticVersionException(
          'Invalid major version in "$input". Numerical leading zeros forbidden.');
    }
    if (minor == null ||
        minor < 0 ||
        coreParts[1].length > 1 && coreParts[1].startsWith('0')) {
      throw SemanticVersionException(
          'Invalid minor version in "$input". Numerical leading zeros forbidden.');
    }
    if (patch == null ||
        patch < 0 ||
        coreParts[2].length > 1 && coreParts[2].startsWith('0')) {
      throw SemanticVersionException(
          'Invalid patch version in "$input". Numerical leading zeros forbidden.');
    }

    List<String> prereleaseList = [];
    if (prereleaseStr != null && prereleaseStr.isNotEmpty) {
      prereleaseList = prereleaseStr.split('.');
      for (final part in prereleaseList) {
        if (part.isEmpty) {
          throw SemanticVersionException(
              'Empty prerelease identifier component in "$input".');
        }
        if (!RegExp(r'^[0-9A-Za-z-]+$').hasMatch(part)) {
          throw SemanticVersionException(
              'Invalid character in prerelease identifier "$part" in "$input".');
        }
        // Numeric identifiers must not have leading zero
        if (RegExp(r'^[0-9]+$').hasMatch(part) &&
            part.length > 1 &&
            part.startsWith('0')) {
          throw SemanticVersionException(
              'Numeric prerelease identifier "$part" must not have leading zero in "$input".');
        }
      }
    }

    List<String> buildList = [];
    if (buildStr != null && buildStr.isNotEmpty) {
      buildList = buildStr.split('.');
      for (final part in buildList) {
        if (part.isEmpty) {
          throw SemanticVersionException(
              'Empty build metadata identifier component in "$input".');
        }
        if (!RegExp(r'^[0-9A-Za-z-]+$').hasMatch(part)) {
          throw SemanticVersionException(
              'Invalid character in build metadata identifier "$part" in "$input".');
        }
      }
    }

    return SemVer(
      major: major,
      minor: minor,
      patch: patch,
      prerelease: List.unmodifiable(prereleaseList),
      build: List.unmodifiable(buildList),
    );
  }

  /// Returns true if this version is a prerelease (has prerelease identifiers).
  bool get isPrerelease => prerelease.isNotEmpty;

  @override
  int compareTo(SemVer other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);

    // When major, minor, patch are equal, a normal version has higher precedence than a pre-release version.
    if (prerelease.isEmpty && other.prerelease.isNotEmpty) return 1;
    if (prerelease.isNotEmpty && other.prerelease.isEmpty) return -1;
    if (prerelease.isEmpty && other.prerelease.isEmpty) return 0;

    // Compare pre-release identifiers component by component
    final minLen = prerelease.length < other.prerelease.length
        ? prerelease.length
        : other.prerelease.length;
    for (int i = 0; i < minLen; i++) {
      final a = prerelease[i];
      final b = other.prerelease[i];
      if (a == b) continue;

      final aIsNum = RegExp(r'^[0-9]+$').hasMatch(a);
      final bIsNum = RegExp(r'^[0-9]+$').hasMatch(b);

      if (aIsNum && bIsNum) {
        final aInt = int.parse(a);
        final bInt = int.parse(b);
        return aInt.compareTo(bInt);
      } else if (aIsNum && !bIsNum) {
        return -1; // Numeric has lower precedence than non-numeric
      } else if (!aIsNum && bIsNum) {
        return 1;
      } else {
        return a.compareTo(b);
      }
    }

    return prerelease.length.compareTo(other.prerelease.length);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SemVer) return false;
    return compareTo(other) == 0;
  }

  @override
  int get hashCode =>
      Object.hash(major, minor, patch, Object.hashAll(prerelease));

  @override
  String toString() {
    final buf = StringBuffer('$major.$minor.$patch');
    if (prerelease.isNotEmpty) {
      buf.write('-${prerelease.join('.')}');
    }
    if (build.isNotEmpty) {
      buf.write('+${build.join('.')}');
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'major': major,
        'minor': minor,
        'patch': patch,
        'prerelease': prerelease,
        'build': build,
        'raw': toString(),
      };
}

/// Policy constraints governing semantic version transitions and release channels.
class SemVerPolicy {
  final bool allowDowngrade;
  final bool allowPrerelease;
  final bool requireChannelMatch;

  const SemVerPolicy({
    this.allowDowngrade = false,
    this.allowPrerelease = true,
    this.requireChannelMatch = false,
  });

  Map<String, dynamic> toJson() => {
        'allowDowngrade': allowDowngrade,
        'allowPrerelease': allowPrerelease,
        'requireChannelMatch': requireChannelMatch,
      };
}

/// Options for configuring Semantic Version Manager transitions.
class SemVerOptions {
  final String packageName;
  final String currentVersion;
  final SemVerIncrementType type;
  final String? explicitVersion;
  final String? prereleaseId;
  final String channel;
  final SemVerPolicy policy;
  final String outputDir;

  const SemVerOptions({
    required this.packageName,
    this.currentVersion = '1.0.0',
    this.type = SemVerIncrementType.patch,
    this.explicitVersion,
    this.prereleaseId,
    this.channel = 'stable',
    this.policy = const SemVerPolicy(),
    this.outputDir = 'doc/release',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'currentVersion': currentVersion,
        'type': type.name,
        if (explicitVersion != null) 'explicitVersion': explicitVersion,
        if (prereleaseId != null) 'prereleaseId': prereleaseId,
        'channel': channel,
        'policy': policy.toJson(),
        'outputDir': outputDir,
      };
}

/// Plan describing a proposed semantic version transition.
class SemVerPlan {
  final String packageName;
  final SemVer currentVersion;
  final SemVer targetVersion;
  final SemVerIncrementType type;
  final bool isValid;
  final String details;

  const SemVerPlan({
    required this.packageName,
    required this.currentVersion,
    required this.targetVersion,
    required this.type,
    required this.isValid,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'currentVersion': currentVersion.toString(),
        'targetVersion': targetVersion.toString(),
        'type': type.name,
        'isValid': isValid,
        'details': details,
      };
}

/// Result of evaluating or executing a semantic version transition.
class SemVerResult {
  final String packageName;
  final String previousVersion;
  final String newVersion;
  final bool isApplied;
  final String details;

  const SemVerResult({
    required this.packageName,
    required this.previousVersion,
    required this.newVersion,
    required this.isApplied,
    required this.details,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Semantic Version Report: $packageName');
    buf.writeln();
    buf.writeln('**Previous Version**: $previousVersion');
    buf.writeln('**New Version**: $newVersion');
    buf.writeln(
        '**Status**: ${isApplied ? "APPLIED ✓" : "PREVIEW DRY-RUN (NOT APPLIED)"}');
    buf.writeln();
    buf.writeln('### Details');
    buf.writeln(details);
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'previousVersion': previousVersion,
        'newVersion': newVersion,
        'isApplied': isApplied,
        'details': details,
      };
}
