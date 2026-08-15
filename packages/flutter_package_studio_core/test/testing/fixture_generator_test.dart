import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('TestFixtureGenerator Unit Tests', () {
    late TestFixtureGenerator generator;

    setUp(() {
      generator = TestFixtureGenerator();
    });

    test('Plans and generates test fixtures & mocks', () {
      const options = FixtureOptions(packageName: 'awesome_pkg');
      final plan = generator.planFixtures(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.fixtureTargets.length, equals(1));
      expect(plan.mockTargets.length, equals(1));
      expect(plan.fixtureTargets.first.name, equals('awesome_pkgConfig'));
      expect(plan.mockTargets.first.name, equals('awesome_pkgService'));

      final result = generator.generateFixtures(plan, options);
      expect(result.files['test/fixtures/awesome_pkg_fixtures.dart'],
          contains('awesome_pkgTestFixtures'));
      expect(result.files['test/mocks/awesome_pkg_mocks.dart'],
          contains('Mockawesome_pkgService'));
      expect(result.files['test/mocks/awesome_pkg_mocks.dart'],
          contains('TODO: Add custom stub behavior overrides'));
    });

    test('Rejects empty package names', () {
      const options = FixtureOptions(packageName: '');
      expect(() => generator.planFixtures(options),
          throwsA(isA<TestFixtureGenerationException>()));
    });

    test('Output is 100% deterministic across repeated runs', () {
      const options = FixtureOptions(packageName: 'det_pkg');

      final plan1 = generator.planFixtures(options);
      final res1 = generator.generateFixtures(plan1, options);

      final plan2 = generator.planFixtures(options);
      final res2 = generator.generateFixtures(plan2, options);

      expect(res1.files, equals(res2.files));
    });
  });
}
