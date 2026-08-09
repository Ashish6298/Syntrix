import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/validation/validation_models.dart';
import 'package:flutter_package_studio_core/src/validation/validation_rule.dart';

/// Validates repository files (.gitignore, README, LICENSE) (`REPO_001`).
class RepositoryAssetRule implements ValidationRule {
  @override
  String get id => 'REPO_001';

  @override
  String get title => 'Repository Assets & Documentation';

  @override
  ValidationCategory get category => ValidationCategory.repository;

  @override
  ValidationSeverity get defaultSeverity => ValidationSeverity.info;

  @override
  Future<List<ValidationIssue>> validate({
    required String targetDirectory,
    required FileUtils fileUtils,
  }) async {
    final issues = <ValidationIssue>[];

    final readmePath = '$targetDirectory/README.md';
    if (!fileUtils.exists(readmePath)) {
      issues.add(ValidationIssue(
        ruleId: id,
        category: category,
        severity: ValidationSeverity.warning,
        message: 'Missing README.md file in package root.',
        filePath: 'README.md',
        remediation: 'Add a README.md file describing the package.',
      ));
    }

    final licensePath = '$targetDirectory/LICENSE';
    if (!fileUtils.exists(licensePath)) {
      issues.add(ValidationIssue(
        ruleId: id,
        category: category,
        severity: ValidationSeverity.info,
        message: 'Missing LICENSE file in package root.',
        filePath: 'LICENSE',
        remediation: 'Add an open-source LICENSE file.',
      ));
    }

    return issues;
  }
}
