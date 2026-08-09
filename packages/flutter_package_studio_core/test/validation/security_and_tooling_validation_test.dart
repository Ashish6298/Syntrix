import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';
import 'mock_file_utils_helper.dart';

void main() {
  group('Security & Tooling Validation Tests', () {
    test('SecurityValidationRule flags exposed GitHub tokens', () async {
      final fileUtils = MapMemoryFileUtils({
        './pubspec.yaml':
            'name: sec_pkg\n# secret token: ghp_123456789012345678901234567890123456\n',
      });
      final rule = SecurityValidationRule();

      final issues =
          await rule.validate(targetDirectory: '.', fileUtils: fileUtils);

      expect(issues.any((i) => i.severity == ValidationSeverity.error), isTrue);
      expect(issues.first.message, contains('GitHub token'));
    });

    test('JsonValidationReporter serializes report cleanly without secrets',
        () {
      const report = ValidationReport(
        targetDirectory: '.',
        profile: 'standard',
        duration: Duration(milliseconds: 10),
        issues: [
          ValidationIssue(
            ruleId: 'SEC_001',
            category: ValidationCategory.security,
            severity: ValidationSeverity.error,
            message: 'Security token detected',
          ),
        ],
        summary: ValidationSummary(
          totalRulesExecuted: 5,
          passedRulesCount: 4,
          infoCount: 0,
          warningCount: 0,
          errorCount: 1,
        ),
      );

      final reporter = JsonValidationReporter();
      final jsonStr = reporter.render(report);

      expect(jsonStr, contains('"ruleId": "SEC_001"'));
      expect(jsonStr, contains('"isValid": false'));
    });
  });
}
