import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('IntegrationTestGenerator Unit Tests', () {
    late IntegrationTestGenerator generator;

    setUp(() {
      generator = IntegrationTestGenerator();
    });

    test('Plans and generates integration test suite from interaction targets',
        () {
      const options = IntegrationTestOptions(packageName: 'awesome_pkg');
      final plan = generator.planIntegrationTests(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.targets.length, equals(1));
      expect(plan.targets.first.name, equals('awesome_pkgFullWorkflow'));

      final result = generator.generateIntegrationTests(plan, options);
      expect(result.files['test/integration/awesome_pkg_integration_test.dart'],
          contains('package:integration_test/integration_test.dart'));
      expect(result.files['test/integration/awesome_pkg_integration_test.dart'],
          contains('awesome_pkg Integration Test Suite'));
      expect(result.files['test/integration/awesome_pkg_integration_test.dart'],
          contains('IntegrationTestWidgetsFlutterBinding.ensureInitialized()'));
      expect(result.files['test/integration/awesome_pkg_integration_test.dart'],
          contains('TODO: verify end-to-end multi-component interaction'));
    });

    test('Rejects empty package names', () {
      const options = IntegrationTestOptions(packageName: '');
      expect(() => generator.planIntegrationTests(options),
          throwsA(isA<IntegrationTestGenerationException>()));
    });

    test('Output is 100% deterministic across repeated runs', () {
      const options = IntegrationTestOptions(packageName: 'det_pkg');

      final plan1 = generator.planIntegrationTests(options);
      final res1 = generator.generateIntegrationTests(plan1, options);

      final plan2 = generator.planIntegrationTests(options);
      final res2 = generator.generateIntegrationTests(plan2, options);

      expect(res1.files, equals(res2.files));
    });
  });
}
