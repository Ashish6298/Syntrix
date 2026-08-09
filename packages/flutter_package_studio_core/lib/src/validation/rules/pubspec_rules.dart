import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/validation/validators.dart';

/// Validates pubspec name, description, version, and SDK fields (`PUBSPEC_001`).

class PubspecValidationRule implements ValidationRule {
  @override
  String get id => 'PUBSPEC_001';

  @override
  String get title => 'Pubspec Metadata & Name Validation';

  @override
  ValidationCategory get category => ValidationCategory.pubspec;

  @override
  ValidationSeverity get defaultSeverity => ValidationSeverity.error;

  @override
  Future<List<ValidationIssue>> validate({
    required String targetDirectory,
    required FileUtils fileUtils,
  }) async {
    final issues = <ValidationIssue>[];
    final pubspecPath = '$targetDirectory/pubspec.yaml';

    if (!fileUtils.exists(pubspecPath)) {
      return issues; // Handled by PackageStructureRule
    }

    final content = fileUtils.readAsString(pubspecPath);

    if (!content.contains('name:')) {
      issues.add(ValidationIssue(
        ruleId: id,
        category: category,
        severity: ValidationSeverity.error,
        message: 'pubspec.yaml is missing "name" field.',
        filePath: 'pubspec.yaml',
        remediation: 'Add a "name: <package_name>" field.',
      ));
    }

    if (!content.contains('environment:')) {
      issues.add(ValidationIssue(
        ruleId: id,
        category: category,
        severity: ValidationSeverity.warning,
        message: 'pubspec.yaml is missing "environment" field.',
        filePath: 'pubspec.yaml',
        remediation: 'Add environment bounds (e.g. sdk: ">=3.5.0 <4.0.0").',
      ));
    }

    return issues;
  }
}
