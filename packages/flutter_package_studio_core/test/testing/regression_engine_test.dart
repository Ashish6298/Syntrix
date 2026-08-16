import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('RegressionTestingEngine Unit Tests', () {
    late RegressionTestingEngine engine;

    setUp(() {
      engine = RegressionTestingEngine();
    });

    test('Plans regression check and validates baseline path safety', () {
      const options = RegressionOptions(
          packageName: 'awesome_pkg', baselinePath: 'test/baseline.json');
      final plan = engine.planRegressionTesting(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.baselinePath, equals('test/baseline.json'));
    });

    test('Runs regression check comparing evidence cases', () {
      const options = RegressionOptions(packageName: 'awesome_pkg');
      final plan = engine.planRegressionTesting(options);
      final result = engine.runRegressionCheck(plan);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.hasRegressions, isFalse);
      expect(result.cases.length, equals(3));

      final md = result.toMarkdown();
      expect(md, contains('# Regression Testing Report: awesome_pkg'));
      expect(md, contains('NO REGRESSION ✓'));
    });

    test('Rejects absolute baseline paths', () {
      const options = RegressionOptions(
          packageName: 'pkg', baselinePath: '/etc/baseline.json');
      expect(() => engine.planRegressionTesting(options),
          throwsA(isA<RegressionTestingException>()));
    });

    test('Rejects path traversal ".." in baseline path', () {
      const options = RegressionOptions(
          packageName: 'pkg', baselinePath: '../baseline.json');
      expect(() => engine.planRegressionTesting(options),
          throwsA(isA<RegressionTestingException>()));
    });
  });
}
