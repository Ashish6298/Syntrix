import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('TestRunner Unit Tests', () {
    late TestRunner runner;

    setUp(() {
      runner = TestRunner();
    });

    test('Plans test execution for profile "all"', () {
      const options =
          TestExecutionOptions(packageName: 'awesome_pkg', profile: 'all');
      final plan = runner.planTestExecution(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.suites.length, equals(3));
      expect(plan.suites.map((s) => s.type), contains('unit'));
      expect(plan.suites.map((s) => s.type), contains('widget'));
      expect(plan.suites.map((s) => s.type), contains('integration'));
    });

    test('Plans test execution for profile "unit"', () {
      const options =
          TestExecutionOptions(packageName: 'awesome_pkg', profile: 'unit');
      final plan = runner.planTestExecution(options);

      expect(plan.suites.length, equals(1));
      expect(plan.suites.first.type, equals('unit'));
    });

    test('Executes test suites and returns structured result', () {
      const options = TestExecutionOptions(packageName: 'awesome_pkg');
      final plan = runner.planTestExecution(options);
      final result = runner.executeTests(plan, options);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.success, isTrue);
      expect(result.passedCount, equals(3));
      expect(result.failedCount, equals(0));
    });

    test('Rejects empty package names', () {
      const options = TestExecutionOptions(packageName: '');
      expect(() => runner.planTestExecution(options),
          throwsA(isA<TestExecutionException>()));
    });
  });
}
