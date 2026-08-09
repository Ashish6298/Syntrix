import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';
import 'mock_file_utils_helper.dart';

void main() {
  group('Validation Rules Unit Tests', () {
    test('PackageStructureRule detects missing lib/ and pubspec.yaml',
        () async {
      final fileUtils = MapMemoryFileUtils({});
      final rule = PackageStructureRule();

      final issues =
          await rule.validate(targetDirectory: '.', fileUtils: fileUtils);

      expect(issues.any((i) => i.message.contains('pubspec.yaml')), isTrue);
      expect(issues.any((i) => i.message.contains('lib/')), isTrue);
    });

    test('ExampleValidationRule checks for safe path: ../ dependency',
        () async {
      final fileUtils = MapMemoryFileUtils({
        './example/pubspec.yaml': 'name: ex\ndependencies:\n  pkg: ^1.0.0\n',
      });
      final rule = ExampleValidationRule();

      final issues =
          await rule.validate(targetDirectory: '.', fileUtils: fileUtils);

      expect(issues.any((i) => i.message.contains('path: ../')), isTrue);
    });
  });
}
