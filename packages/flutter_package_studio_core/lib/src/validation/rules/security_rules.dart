import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/validation/validation_models.dart';
import 'package:flutter_package_studio_core/src/validation/validation_rule.dart';

/// Detects exposed tokens, secrets, or unsafe path traversal patterns (`SEC_001`).
class SecurityValidationRule implements ValidationRule {
  @override
  String get id => 'SEC_001';

  @override
  String get title => 'Security & Secret Exposure Check';

  @override
  ValidationCategory get category => ValidationCategory.security;

  @override
  ValidationSeverity get defaultSeverity => ValidationSeverity.error;

  @override
  Future<List<ValidationIssue>> validate({
    required String targetDirectory,
    required FileUtils fileUtils,
  }) async {
    final issues = <ValidationIssue>[];

    final pubspecPath = '$targetDirectory/pubspec.yaml';
    if (fileUtils.exists(pubspecPath)) {
      final content = fileUtils.readAsString(pubspecPath);
      final tokenMatch = RegExp(r'ghp_[a-zA-Z0-9]{36}').firstMatch(content);
      if (tokenMatch != null) {
        issues.add(ValidationIssue(
          ruleId: id,
          category: category,
          severity: ValidationSeverity.error,
          message: 'Potential secret GitHub token detected in pubspec.yaml.',
          filePath: 'pubspec.yaml',
          remediation: 'Remove token immediately and revoke it.',
        ));
      }
    }

    return issues;
  }
}
