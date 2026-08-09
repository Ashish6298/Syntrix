import 'package:flutter_package_studio_core/src/template/project_generator.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_context.dart';

/// Immutable configuration options for generating a Flutter example application.
class ExampleOptions {
  /// Name of the example directory relative to package root (default: 'example').
  final String exampleDirName;

  /// Application display name for the example app.
  final String appName;

  /// Organization prefix for the example app.
  final String orgName;

  /// Description of the example application.
  final String description;

  /// Selected example template identifier ('standard', 'minimal', 'interactive').
  final String templateId;

  /// Relative path to the target package root (e.g. '../').
  final String relativePackagePath;

  /// Whether to include platform folders (android, ios, web, etc.).
  final bool includePlatformFolders;

  /// Whether to generate an example README.md documentation file.
  final bool generateReadme;

  /// Whether to generate a sample widget test.
  final bool generateTests;

  /// Overwrite policy for existing files (fail, skip, overwrite).
  final OverwritePolicy overwritePolicy;

  /// Creates an [ExampleOptions] instance.
  const ExampleOptions({
    this.exampleDirName = 'example',
    required this.appName,
    this.orgName = 'com.example',
    this.description = '',
    this.templateId = 'standard',
    this.relativePackagePath = '../',
    this.includePlatformFolders = true,
    this.generateReadme = true,
    this.generateTests = true,
    this.overwritePolicy = OverwritePolicy.fail,
  });

  /// Constructs [ExampleOptions] from a [WizardContext].
  factory ExampleOptions.fromWizardContext(
    WizardContext wizardContext, {
    String? exampleDirName,
    String? templateId,
    bool? includePlatformFolders,
    bool? generateReadme,
    bool? generateTests,
    OverwritePolicy? overwritePolicy,
  }) {
    final pkgName = wizardContext.packageName.isNotEmpty
        ? wizardContext.packageName
        : 'my_package';
    final appName = '${pkgName}_example';

    return ExampleOptions(
      exampleDirName: exampleDirName ?? 'example',
      appName: appName,
      orgName: wizardContext.orgName.isNotEmpty
          ? wizardContext.orgName
          : 'com.example',
      description: 'Example application demonstrating the $pkgName package.',
      templateId: templateId ?? 'standard',
      relativePackagePath: '../',
      includePlatformFolders: includePlatformFolders ?? true,
      generateReadme: generateReadme ?? true,
      generateTests: generateTests ?? true,
      overwritePolicy: overwritePolicy ?? OverwritePolicy.fail,
    );
  }
}
