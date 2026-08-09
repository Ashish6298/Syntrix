import 'package:flutter_package_studio_core/src/wizard/wizard_context.dart';

/// Immutable configuration options for repository generation.
class RepositoryOptions {
  /// Name of the repository.
  final String repositoryName;

  /// Brief description of the repository.
  final String description;

  /// Author name or organization.
  final String author;

  /// Author email.
  final String email;

  /// Open-source license identifier (e.g. 'MIT', 'Apache-2.0', 'BSD-3-Clause', 'GPL-3.0', 'none').
  final String license;

  /// Primary git branch name (e.g. 'main', 'master').
  final String branchName;

  /// Remote repository URL.
  final String repositoryUrl;

  /// Homepage URL.
  final String homepageUrl;

  /// Issue tracker URL.
  final String issueTrackerUrl;

  /// Documentation URL.
  final String documentationUrl;

  /// Preset profile identifier ('minimal', 'standard', 'open_source', 'production', 'maintainer').
  final String preset;

  /// Whether to run `git init` locally.
  final bool gitInit;

  /// Whether to generate README.md.
  final bool generateReadme;

  /// Whether to generate CHANGELOG.md.
  final bool generateChangelog;

  /// Whether to generate CONTRIBUTING.md.
  final bool generateContributing;

  /// Whether to generate CODE_OF_CONDUCT.md.
  final bool generateCodeOfConduct;

  /// Whether to generate SECURITY.md.
  final bool generateSecurity;

  /// Whether to generate CI workflow (e.g. GitHub Actions).
  final bool generateCi;

  /// Whether to generate .gitignore.
  final bool generateGitignore;

  /// Creates a [RepositoryOptions] instance.
  const RepositoryOptions({
    required this.repositoryName,
    this.description = '',
    this.author = '',
    this.email = '',
    this.license = 'MIT',
    this.branchName = 'main',
    this.repositoryUrl = '',
    this.homepageUrl = '',
    this.issueTrackerUrl = '',
    this.documentationUrl = '',
    this.preset = 'standard',
    this.gitInit = true,
    this.generateReadme = true,
    this.generateChangelog = true,
    this.generateContributing = true,
    this.generateCodeOfConduct = true,
    this.generateSecurity = true,
    this.generateCi = true,
    this.generateGitignore = true,
  });

  /// Constructs [RepositoryOptions] from a [WizardContext].
  factory RepositoryOptions.fromWizardContext(
    WizardContext wizardContext, {
    String? preset,
    String? license,
    bool? gitInit,
    bool? generateCi,
  }) {
    final name = wizardContext.packageName.isNotEmpty
        ? wizardContext.packageName
        : 'my_repository';
    final selectedLicense = license ??
        (wizardContext.license.isNotEmpty ? wizardContext.license : 'MIT');

    return RepositoryOptions(
      repositoryName: name,
      description: wizardContext.description,
      author: wizardContext.author,
      email: wizardContext.email,
      license: selectedLicense,
      repositoryUrl: wizardContext.repoUrl,
      homepageUrl: wizardContext.homepage,
      issueTrackerUrl: wizardContext.issueTrackerUrl,
      documentationUrl: wizardContext.documentationUrl,
      preset: preset ?? 'standard',
      gitInit: gitInit ?? true,
      generateCi: generateCi ?? true,
    );
  }
}
