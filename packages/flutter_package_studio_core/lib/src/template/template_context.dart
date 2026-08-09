import 'package:flutter_package_studio_core/src/utils/string_utils.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_context.dart';

/// Normalized context providing template variables for placeholder rendering.
class TemplateContext {
  final Map<String, dynamic> _variables;

  /// Creates a [TemplateContext] wrapping [_variables].
  TemplateContext([Map<String, dynamic>? variables])
      : _variables = Map<String, dynamic>.from(variables ?? {});

  /// Creates a normalized [TemplateContext] from a [WizardContext].
  factory TemplateContext.fromWizardContext(WizardContext wizardCtx) {
    final now = DateTime.now();
    final packageName = wizardCtx.packageName.trim();

    return TemplateContext({
      'package_name': packageName,
      'packageName': packageName,
      'package_name_pascal': StringUtils.toPascalCase(packageName),
      'package_name_camel': StringUtils.toCamelCase(packageName),
      'package_name_snake': StringUtils.toSnakeCase(packageName),
      'package_name_kebab': StringUtils.toKebabCase(packageName),
      'display_name': StringUtils.capitalize(packageName.replaceAll('_', ' ')),
      'project_type': wizardCtx.projectType,
      'description': wizardCtx.description,
      'organization': wizardCtx.orgName,
      'org_name': wizardCtx.orgName,
      'author': wizardCtx.author,
      'author_email': wizardCtx.email,
      'email': wizardCtx.email,
      'license': wizardCtx.license,
      'repository': wizardCtx.repoUrl,
      'repo_url': wizardCtx.repoUrl,
      'homepage': wizardCtx.homepage,
      'issue_tracker': wizardCtx.issueTrackerUrl,
      'documentation_url': wizardCtx.documentationUrl,
      'dart_sdk_constraint': wizardCtx.dartSdkConstraint,
      'flutter_sdk_constraint': wizardCtx.flutterSdkConstraint,
      'supported_platforms': wizardCtx.platforms,
      'preferred_architecture': wizardCtx.preferredArchitecture,
      'testing_preferences': wizardCtx.testingPreferences,
      'ci_cd_preferences': wizardCtx.ciCdPreferences,
      'code_quality_options': wizardCtx.codeQualityOptions,
      'doc_gen_preferences': wizardCtx.docGenPreferences,
      'package_visibility': wizardCtx.packageVisibility,
      'template_selection': wizardCtx.templateSelection,
      'output_directory': wizardCtx.outputDirectory,
      'current_year': now.year.toString(),
      'year': now.year.toString(),
      'current_date':
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'date':
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'version': '0.1.0',
      'is_flutter': wizardCtx.projectType != 'dart_package',
      'is_dart': wizardCtx.projectType == 'dart_package',
      'is_plugin': wizardCtx.projectType == 'plugin',
      'has_github_actions': wizardCtx.ciCdPreferences == 'github_actions',
      ...wizardCtx.extraMetadata,
    });
  }

  /// Sets a variable value.
  void set(String key, dynamic value) => _variables[key] = value;

  /// Gets variable by [key], returning null if absent.
  dynamic get(String key) => _variables[key];

  /// Checks if [key] is present in context.
  bool contains(String key) => _variables.containsKey(key);

  /// Map view of all variables.
  Map<String, dynamic> toMap() => Map.unmodifiable(_variables);
}
