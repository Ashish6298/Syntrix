import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/validation/validators.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_question.dart';

import 'package:flutter_package_studio_core/src/wizard/wizard_step.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_validator.dart';

/// Defines wizard flows and step sequences.
class WizardFlow {
  /// Name of the flow.
  final String name;

  /// Ordered list of steps in the flow.
  final List<WizardStep> steps;

  /// Creates a [WizardFlow] instance.
  const WizardFlow({
    required this.name,
    required this.steps,
  });

  /// Builds the standard Flutter Package Studio creation flow.
  factory WizardFlow.standard({FileUtils fileUtils = const SystemFileUtils()}) {
    return WizardFlow(
      name: 'Standard Package Creation Flow',
      steps: [
        WizardStep(
          id: 'identity',
          title: 'Project Identity & Metadata',
          description: 'Basic identification details for pubspec.yaml',
          questions: [
            WizardQuestion<String>(
              id: 'packageName',
              prompt: 'Package name',
              type: WizardQuestionType.freeText,
              helpText:
                  'Unique Dart/Flutter identifier (e.g., my_awesome_package)',
              validator: const PackageNameValidator(),
              valueGetter: (ctx) => ctx.packageName,
              valueSetter: (ctx, val) => ctx.packageName = val,
            ),
            WizardQuestion<String>(
              id: 'projectType',
              prompt: 'Project type',
              type: WizardQuestionType.singleSelect,
              helpText: 'Select package distribution archetype',
              defaultValue: 'flutter_package',
              options: const [
                WizardOption(
                  label: 'Flutter Package',
                  value: 'flutter_package',
                  description:
                      'A package containing Flutter widgets or utilities',
                ),
                WizardOption(
                  label: 'Pure Dart Package',
                  value: 'dart_package',
                  description:
                      'General Dart code usable on server, web, or CLI',
                ),
                WizardOption(
                  label: 'Flutter Plugin',
                  value: 'plugin',
                  description:
                      'Native code bindings for iOS, Android, Desktop, or Web',
                ),
              ],
              valueGetter: (ctx) => ctx.projectType,
              valueSetter: (ctx, val) => ctx.projectType = val,
            ),
            WizardQuestion<String>(
              id: 'description',
              prompt: 'Description',
              type: WizardQuestionType.freeText,
              helpText: 'Short description of the package for pub.dev',
              defaultValue:
                  'A production-ready Flutter/Dart package created with FPS.',
              validator: WizardValidator.requiredString('Description'),
              valueGetter: (ctx) => ctx.description,
              valueSetter: (ctx, val) => ctx.description = val,
            ),
            WizardQuestion<String>(
              id: 'orgName',
              prompt: 'Organization domain prefix',
              type: WizardQuestionType.freeText,
              helpText: 'Reverse domain string (e.g. com.example)',
              defaultValue: 'com.example',
              valueGetter: (ctx) => ctx.orgName,
              valueSetter: (ctx, val) => ctx.orgName = val,
            ),
          ],
        ),
        WizardStep(
          id: 'author_licensing',
          title: 'Author & Licensing Details',
          description:
              'Publisher information and open-source license configuration',
          questions: [
            WizardQuestion<String>(
              id: 'author',
              prompt: 'Author name',
              type: WizardQuestionType.freeText,
              helpText: 'Developer or organization name',
              valueGetter: (ctx) => ctx.author,
              valueSetter: (ctx, val) => ctx.author = val,
            ),
            WizardQuestion<String>(
              id: 'email',
              prompt: 'Author email',
              type: WizardQuestionType.freeText,
              helpText: 'Contact email address',
              validator: WizardValidator.email(),
              valueGetter: (ctx) => ctx.email,
              valueSetter: (ctx, val) => ctx.email = val,
            ),
            WizardQuestion<String>(
              id: 'license',
              prompt: 'License type',
              type: WizardQuestionType.singleSelect,
              defaultValue: 'MIT',
              options: const [
                WizardOption(label: 'MIT License', value: 'MIT'),
                WizardOption(label: 'BSD 3-Clause', value: 'BSD-3-Clause'),
                WizardOption(label: 'Apache 2.0', value: 'Apache-2.0'),
                WizardOption(
                    label: 'Proprietary / Private', value: 'Proprietary'),
              ],
              valueGetter: (ctx) => ctx.license,
              valueSetter: (ctx, val) => ctx.license = val,
            ),
          ],
        ),
        WizardStep(
          id: 'repository_urls',
          title: 'Repository & Links',
          description:
              'URLs for source control, issue tracking, and documentation',
          questions: [
            WizardQuestion<String>(
              id: 'repoUrl',
              prompt: 'Repository URL',
              type: WizardQuestionType.freeText,
              helpText: 'GitHub or GitLab repository link',
              validator: WizardValidator.url(),
              valueGetter: (ctx) => ctx.repoUrl,
              valueSetter: (ctx, val) => ctx.repoUrl = val,
            ),
            WizardQuestion<String>(
              id: 'homepage',
              prompt: 'Homepage URL',
              type: WizardQuestionType.freeText,
              validator: WizardValidator.url(),
              valueGetter: (ctx) => ctx.homepage,
              valueSetter: (ctx, val) => ctx.homepage = val,
            ),
            WizardQuestion<String>(
              id: 'issueTrackerUrl',
              prompt: 'Issue tracker URL',
              type: WizardQuestionType.freeText,
              validator: WizardValidator.url(),
              valueGetter: (ctx) => ctx.issueTrackerUrl,
              valueSetter: (ctx, val) => ctx.issueTrackerUrl = val,
            ),
            WizardQuestion<String>(
              id: 'documentationUrl',
              prompt: 'Documentation URL',
              type: WizardQuestionType.freeText,
              validator: WizardValidator.url(),
              valueGetter: (ctx) => ctx.documentationUrl,
              valueSetter: (ctx, val) => ctx.documentationUrl = val,
            ),
          ],
        ),
        WizardStep(
          id: 'sdk_platforms',
          title: 'SDK Constraints & Target Platforms',
          description:
              'Language boundaries and target operating system platforms',
          questions: [
            WizardQuestion<String>(
              id: 'dartSdkConstraint',
              prompt: 'Dart SDK constraint',
              type: WizardQuestionType.semver,
              defaultValue: '>=3.5.0 <4.0.0',
              valueGetter: (ctx) => ctx.dartSdkConstraint,
              valueSetter: (ctx, val) => ctx.dartSdkConstraint = val,
            ),
            WizardQuestion<String>(
              id: 'flutterSdkConstraint',
              prompt: 'Flutter SDK constraint',
              type: WizardQuestionType.semver,
              defaultValue: '>=3.22.0',
              condition: (ctx) => ctx.projectType != 'dart_package',
              valueGetter: (ctx) => ctx.flutterSdkConstraint,
              valueSetter: (ctx, val) => ctx.flutterSdkConstraint = val,
            ),
            WizardQuestion<List<String>>(
              id: 'platforms',
              prompt: 'Supported platforms',
              type: WizardQuestionType.multiSelect,
              defaultValue: const [
                'android',
                'ios',
                'web',
                'windows',
                'macos',
                'linux'
              ],
              condition: (ctx) => ctx.projectType != 'dart_package',
              options: const [
                WizardOption(label: 'Android', value: 'android'),
                WizardOption(label: 'iOS', value: 'ios'),
                WizardOption(label: 'Web', value: 'web'),
                WizardOption(label: 'Windows', value: 'windows'),
                WizardOption(label: 'macOS', value: 'macos'),
                WizardOption(label: 'Linux', value: 'linux'),
              ],
              valueGetter: (ctx) => ctx.platforms,
              valueSetter: (ctx, val) =>
                  ctx.platforms = (val as List).cast<String>(),
            ),
          ],
        ),
        WizardStep(
          id: 'architecture_testing',
          title: 'Architecture & Testing Setup',
          description:
              'Code structure patterns and automated testing configuration',
          questions: [
            WizardQuestion<String>(
              id: 'preferredArchitecture',
              prompt: 'Architecture pattern',
              type: WizardQuestionType.singleSelect,
              defaultValue: 'feature_first',
              options: const [
                WizardOption(
                  label: 'Feature-First',
                  value: 'feature_first',
                  description: 'Organized by domain features',
                ),
                WizardOption(
                  label: 'Clean Architecture',
                  value: 'clean_architecture',
                  description:
                      'Strict separation of domain, data, and presentation',
                ),
                WizardOption(
                  label: 'Simple Monolithic',
                  value: 'simple',
                  description: 'Minimal structure for small utility libraries',
                ),
              ],
              valueGetter: (ctx) => ctx.preferredArchitecture,
              valueSetter: (ctx, val) =>
                  ctx.preferredArchitecture = val.toString(),
            ),
            WizardQuestion<List<String>>(
              id: 'testingPreferences',
              prompt: 'Testing suites to generate',
              type: WizardQuestionType.multiSelect,
              defaultValue: const ['unit'],
              options: const [
                WizardOption(label: 'Unit Tests', value: 'unit'),
                WizardOption(label: 'Widget Tests', value: 'widget'),
                WizardOption(label: 'Integration Tests', value: 'integration'),
                WizardOption(label: 'Golden Tests', value: 'golden'),
              ],
              valueGetter: (ctx) => ctx.testingPreferences,
              valueSetter: (ctx, val) =>
                  ctx.testingPreferences = (val as List).cast<String>(),
            ),
          ],
        ),
        WizardStep(
          id: 'ci_quality',
          title: 'CI/CD & Quality Control',
          description: 'Continuous integration workflows and linter presets',
          questions: [
            WizardQuestion<String>(
              id: 'ciCdPreferences',
              prompt: 'CI/CD Workflow provider',
              type: WizardQuestionType.singleSelect,
              defaultValue: 'github_actions',
              options: const [
                WizardOption(label: 'GitHub Actions', value: 'github_actions'),
                WizardOption(label: 'GitLab CI', value: 'gitlab_ci'),
                WizardOption(label: 'None', value: 'none'),
              ],
              valueGetter: (ctx) => ctx.ciCdPreferences,
              valueSetter: (ctx, val) => ctx.ciCdPreferences = val,
            ),
            WizardQuestion<String>(
              id: 'codeQualityOptions',
              prompt: 'Linter rules preset',
              type: WizardQuestionType.singleSelect,
              defaultValue: 'very_good_analysis',
              options: const [
                WizardOption(
                    label: 'Very Good Analysis', value: 'very_good_analysis'),
                WizardOption(
                    label: 'Standard Flutter Lints', value: 'standard'),
                WizardOption(label: 'Pedantic Strict', value: 'pedantic'),
              ],
              valueGetter: (ctx) => ctx.codeQualityOptions,
              valueSetter: (ctx, val) => ctx.codeQualityOptions = val,
            ),
            WizardQuestion<String>(
              id: 'docGenPreferences',
              prompt: 'Documentation generation engine',
              type: WizardQuestionType.singleSelect,
              defaultValue: 'dartdoc',
              options: const [
                WizardOption(label: 'DartDoc API HTML', value: 'dartdoc'),
                WizardOption(label: 'Custom Markdown Site', value: 'custom'),
                WizardOption(label: 'None', value: 'none'),
              ],
              valueGetter: (ctx) => ctx.docGenPreferences,
              valueSetter: (ctx, val) => ctx.docGenPreferences = val,
            ),
            WizardQuestion<String>(
              id: 'packageVisibility',
              prompt: 'Package visibility',
              type: WizardQuestionType.singleSelect,
              defaultValue: 'public',
              options: const [
                WizardOption(label: 'Public (pub.dev ready)', value: 'public'),
                WizardOption(
                    label: 'Private (internal / enterprise)', value: 'private'),
              ],
              valueGetter: (ctx) => ctx.packageVisibility,
              valueSetter: (ctx, val) => ctx.packageVisibility = val,
            ),
            WizardQuestion<String>(
              id: 'templateSelection',
              prompt: 'Template archetype',
              type: WizardQuestionType.singleSelect,
              defaultValue: 'standard',
              options: const [
                WizardOption(
                    label: 'Standard Production Ready', value: 'standard'),
                WizardOption(label: 'Minimal Core Package', value: 'minimal'),
                WizardOption(
                    label: 'Enterprise Monorepo Library', value: 'advanced'),
              ],
              valueGetter: (ctx) => ctx.templateSelection,
              valueSetter: (ctx, val) => ctx.templateSelection = val,
            ),
            WizardQuestion<String>(
              id: 'outputDirectory',
              prompt: 'Output directory',
              type: WizardQuestionType.directoryPath,
              defaultValue: '.',
              validator: DirectoryExistsValidator(fileUtils),
              valueGetter: (ctx) => ctx.outputDirectory,
              valueSetter: (ctx, val) => ctx.outputDirectory = val,
            ),
          ],
        ),
      ],
    );
  }
}
