import 'package:flutter_package_studio_core/src/release/changelog/automated_changelog_models.dart';
import 'package:flutter_package_studio_core/src/release/git/git_release_models.dart';
import 'package:flutter_package_studio_core/src/release/versioning/semver_models.dart';

/// Container for structured input evidence consumed by [ReleaseNotesGenerator].
class ReleaseNotesInputs {
  final String packageName;
  final SemVer version;
  final AutomatedChangelogPlan changelogPlan;
  final GitReleasePlan gitPlan;
  final String channel;
  final Map<String, dynamic>? certificationData;
  final Map<String, dynamic>? compatibilityData;
  final Map<String, dynamic>? securityData;
  final Map<String, dynamic>? artifactData;

  const ReleaseNotesInputs({
    required this.packageName,
    required this.version,
    required this.changelogPlan,
    required this.gitPlan,
    this.channel = 'stable',
    this.certificationData,
    this.compatibilityData,
    this.securityData,
    this.artifactData,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version.toString(),
        'changelogPlan': changelogPlan.toJson(),
        'gitPlan': gitPlan.toJson(),
        'channel': channel,
        if (certificationData != null) 'certificationData': certificationData,
        if (compatibilityData != null) 'compatibilityData': compatibilityData,
        if (securityData != null) 'securityData': securityData,
        if (artifactData != null) 'artifactData': artifactData,
      };
}

/// Options configuring release notes document generation.
class ReleaseNotesOptions {
  final String outputDir;
  final bool writeDisk;
  final bool overwrite;
  final bool omitMissingEvidence;

  const ReleaseNotesOptions({
    this.outputDir = 'release_notes',
    this.writeDisk = false,
    this.overwrite = false,
    this.omitMissingEvidence = true,
  });

  Map<String, dynamic> toJson() => {
        'outputDir': outputDir,
        'writeDisk': writeDisk,
        'overwrite': overwrite,
        'omitMissingEvidence': omitMissingEvidence,
      };
}

/// Plan for release notes document generation.
class ReleaseNotesPlan {
  final ReleaseNotesInputs inputs;
  final ReleaseNotesOptions options;
  final String targetPath;
  final bool isValid;
  final String details;

  const ReleaseNotesPlan({
    required this.inputs,
    required this.options,
    required this.targetPath,
    required this.isValid,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'inputs': inputs.toJson(),
        'options': options.toJson(),
        'targetPath': targetPath,
        'isValid': isValid,
        'details': details,
      };
}

/// Result of executing release notes document generation.
class ReleaseNotesResult {
  final String packageName;
  final String version;
  final String markdownContent;
  final bool isApplied;
  final String filePath;

  const ReleaseNotesResult({
    required this.packageName,
    required this.version,
    required this.markdownContent,
    required this.isApplied,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'isApplied': isApplied,
        'filePath': filePath,
        'markdownContent': markdownContent,
      };
}
