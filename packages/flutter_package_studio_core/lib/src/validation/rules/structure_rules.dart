import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/validation/validation_models.dart';
import 'package:flutter_package_studio_core/src/validation/validation_rule.dart';

/// Validates package root structure and pubspec existence (`STRUCT_001`).
class PackageStructureRule implements ValidationRule {
  @override
  String get id => 'STRUCT_001';

  @override
  String get title => 'Package Directory & Pubspec Structure';

  @override
  ValidationCategory get category => ValidationCategory.structure;

  @override
  ValidationSeverity get defaultSeverity => ValidationSeverity.error;

  @override
  Future<List<ValidationIssue>> validate({
    required String targetDirectory,
    required FileUtils fileUtils,
  }) async {
    final issues = <ValidationIssue>[];
    final normTarget = p.normalize(targetDirectory);

    if (!fileUtils.exists(normTarget)) {
      issues.add(ValidationIssue(
        ruleId: id,
        category: category,
        severity: defaultSeverity,
        message: 'Target directory does not exist.',
        filePath: normTarget,
        remediation: 'Ensure the path is correct and accessible.',
      ));
      return issues;
    }

    final pubspecPath = p.normalize(p.join(normTarget, 'pubspec.yaml'));
    if (!fileUtils.exists(pubspecPath)) {
      issues.add(ValidationIssue(
        ruleId: id,
        category: category,
        severity: ValidationSeverity.error,
        message: 'Missing pubspec.yaml file in package root.',
        filePath: 'pubspec.yaml',
        remediation:
            'Add a pubspec.yaml file to mark the directory as a Dart package.',
      ));
    }

    final libPath = p.normalize(p.join(normTarget, 'lib'));
    if (!fileUtils.exists(libPath)) {
      issues.add(ValidationIssue(
        ruleId: id,
        category: category,
        severity: ValidationSeverity.warning,
        message: 'Missing lib/ source directory.',
        filePath: 'lib',
        remediation: 'Create a lib/ directory for package code.',
      ));
    }

    return issues;
  }
}
