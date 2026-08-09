import 'package:flutter_package_studio_core/src/repository/repository_options.dart';

/// Predefined repository configuration preset profile.
class RepositoryPreset {
  /// Unique identifier of the preset.
  final String id;

  /// Display name of the preset profile.
  final String name;

  /// Description of the preset workflow.
  final String description;

  /// Default flags and values associated with this profile.
  final RepositoryOptions options;

  /// Creates a [RepositoryPreset] instance.
  const RepositoryPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.options,
  });

  /// Minimal repository preset (README, LICENSE, gitignore only).
  static const RepositoryPreset minimal = RepositoryPreset(
    id: 'minimal',
    name: 'Minimal Package Repository',
    description:
        'Basic repository with essential README, LICENSE, and .gitignore.',
    options: RepositoryOptions(
      repositoryName: 'minimal_package',
      preset: 'minimal',
      generateReadme: true,
      generateChangelog: false,
      generateContributing: false,
      generateCodeOfConduct: false,
      generateSecurity: false,
      generateCi: false,
      generateGitignore: true,
    ),
  );

  /// Standard Flutter/Dart package repository preset.
  static const RepositoryPreset standard = RepositoryPreset(
    id: 'standard',
    name: 'Standard Package Repository',
    description:
        'Standard open-source package repository with CI and CHANGELOG.',
    options: RepositoryOptions(
      repositoryName: 'standard_package',
      preset: 'standard',
      generateReadme: true,
      generateChangelog: true,
      generateContributing: false,
      generateCodeOfConduct: false,
      generateSecurity: false,
      generateCi: true,
      generateGitignore: true,
    ),
  );

  /// Open-source Flutter package preset.
  static const RepositoryPreset openSource = RepositoryPreset(
    id: 'open_source',
    name: 'Open Source Package Repository',
    description:
        'Full open-source setup including CONTRIBUTING guide and CODE_OF_CONDUCT.',
    options: RepositoryOptions(
      repositoryName: 'opensource_package',
      preset: 'open_source',
      generateReadme: true,
      generateChangelog: true,
      generateContributing: true,
      generateCodeOfConduct: true,
      generateSecurity: false,
      generateCi: true,
      generateGitignore: true,
    ),
  );

  /// Advanced maintainer repository preset.
  static const RepositoryPreset maintainer = RepositoryPreset(
    id: 'maintainer',
    name: 'Maintainer Package Repository',
    description:
        'Comprehensive repository setup with SECURITY policy and strict CI checks.',
    options: RepositoryOptions(
      repositoryName: 'maintainer_package',
      preset: 'maintainer',
      generateReadme: true,
      generateChangelog: true,
      generateContributing: true,
      generateCodeOfConduct: true,
      generateSecurity: true,
      generateCi: true,
      generateGitignore: true,
    ),
  );

  /// All supported repository preset profiles.
  static final Map<String, RepositoryPreset> presets = {
    minimal.id: minimal,
    standard.id: standard,
    openSource.id: openSource,
    maintainer.id: maintainer,
  };

  /// Resolves a [RepositoryPreset] by [presetId]. Returns `standard` if not found.
  static RepositoryPreset resolve(String presetId) {
    return presets[presetId.toLowerCase()] ?? standard;
  }
}
