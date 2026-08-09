import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';
import 'mock_file_utils_helper.dart';

void main() {
  group('ValidationEngine & Registry Unit Tests', () {
    test('ValidationRuleRegistry resolves default profiles', () {
      final registry = ValidationRuleRegistry();

      final basicRules = registry.resolveProfile('basic');
      expect(basicRules.any((r) => r.id == 'STRUCT_001'), isTrue);

      final standardRules = registry.resolveProfile('standard');
      expect(standardRules.length, greaterThanOrEqualTo(5));
    });

    test('ValidationEngine returns valid report for complete package structure',
        () async {
      final fileUtils = MapMemoryFileUtils({
        './pubspec.yaml':
            'name: test_pkg\nenvironment:\n  sdk: ">=3.5.0 <4.0.0"\n',
        './lib/test_pkg.dart': '// library',
        './README.md': '# Test Pkg',
        './LICENSE': 'MIT',
      });

      final engine = ValidationEngine(fileUtils: fileUtils);
      final request =
          const ValidationRequest(targetDirectory: '.', profile: 'standard');

      final report = await engine.validate(request);

      expect(report.isValid, isTrue);
      expect(report.summary.errorCount, equals(0));
    });

    test('ValidationEngine catches missing pubspec and returns invalid report',
        () async {
      final fileUtils = MapMemoryFileUtils({});
      final engine = ValidationEngine(fileUtils: fileUtils);

      final request =
          const ValidationRequest(targetDirectory: '.', profile: 'standard');
      final report = await engine.validate(request);

      expect(report.isValid, isFalse);
      expect(report.summary.errorCount, greaterThan(0));
    });
  });
}
