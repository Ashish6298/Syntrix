import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExampleProjectValidator Tests', () {
    late ExampleProjectValidator validator;

    setUp(() {
      validator = const ExampleProjectValidator(fileUtils: SystemFileUtils());
    });

    test('Validation fails if example directory does not exist', () {
      final res = validator.validate('./non_existent_example_dir',
          expectedPackageName: 'my_pkg');
      expect(res.isValid, isFalse);
      expect(res.errors.first, contains('does not exist'));
    });
  });
}
