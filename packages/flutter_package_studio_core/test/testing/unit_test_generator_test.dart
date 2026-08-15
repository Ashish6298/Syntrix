import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('UnitTestGenerator Unit Tests', () {
    late UnitTestGenerator generator;

    setUp(() {
      generator = UnitTestGenerator();
    });

    test('Plans and generates unit test suite from public API targets', () {
      const options = UnitTestOptions(packageName: 'awesome_pkg');
      final plan = generator.planUnitTests(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.targets.length, equals(2));
      expect(plan.targets.map((t) => t.name), contains('awesome_pkg'));
      expect(plan.targets.map((t) => t.name), contains('initialize'));

      final result = generator.generateUnitTests(plan, options);
      expect(result.files['test/unit/awesome_pkg_api_test.dart'],
          contains('package:flutter_test/flutter_test.dart'));
      expect(result.files['test/unit/awesome_pkg_api_test.dart'],
          contains('awesome_pkg Unit Test Suite'));
      expect(result.files['test/unit/awesome_pkg_api_test.dart'],
          contains('TODO: explicit behavior verification'));
    });

    test('Rejects empty package names', () {
      const options = UnitTestOptions(packageName: '');
      expect(() => generator.planUnitTests(options),
          throwsA(isA<UnitTestGenerationException>()));
    });

    test('Output is 100% deterministic across repeated runs', () {
      const options = UnitTestOptions(packageName: 'det_pkg');

      final plan1 = generator.planUnitTests(options);
      final res1 = generator.generateUnitTests(plan1, options);

      final plan2 = generator.planUnitTests(options);
      final res2 = generator.generateUnitTests(plan2, options);

      expect(res1.files, equals(res2.files));
    });
  });
}
