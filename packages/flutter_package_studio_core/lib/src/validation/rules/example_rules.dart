import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/validation/validation_models.dart';
import 'package:flutter_package_studio_core/src/validation/validation_rule.dart';

/// Validates existence and local path dependency format in `example/` directory (`EX_001`).
class ExampleValidationRule implements ValidationRule {
  @override
  String get id => 'EX_001';

  @override
  String get title => 'Example Application Integrity';

  @override
  ValidationCategory get category => ValidationCategory.example;

  @override
  ValidationSeverity get defaultSeverity => ValidationSeverity.warning;

  @override
  Future<List<ValidationIssue>> validate({
    required String targetDirectory,
    required FileUtils fileUtils,
  }) async {
    final issues = <ValidationIssue>[];
    final examplePath = p.normalize(p.join(targetDirectory, 'example'));

    if (fileUtils.exists(examplePath)) {
      final pubspecPath = p.normalize(p.join(examplePath, 'pubspec.yaml'));
      if (!fileUtils.exists(pubspecPath)) {
        issues.add(ValidationIssue(
          ruleId: id,
          category: category,
          severity: ValidationSeverity.error,
          message:
              'Missing pubspec.yaml inside example/ application directory.',
          filePath: 'example/pubspec.yaml',
          remediation:
              'Generate or add a valid pubspec.yaml for the example app.',
        ));
      } else {
        final content = fileUtils.readAsString(pubspecPath);
        if (!content.contains('path: ../')) {
          issues.add(ValidationIssue(
            ruleId: id,
            category: category,
            severity: ValidationSeverity.error,
            message:
                'example/pubspec.yaml does not contain safe relative dependency "path: ../".',
            filePath: 'example/pubspec.yaml',
            remediation: 'Add "path: ../" under dependencies.',
          ));
        }
      }
    }

    return issues;
  }
}
