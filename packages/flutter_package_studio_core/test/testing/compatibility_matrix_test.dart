import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('CompatibilityMatrixService Unit Tests', () {
    late CompatibilityMatrixService service;

    setUp(() {
      service = CompatibilityMatrixService();
    });

    test('Plans compatibility matrix', () {
      const options = CompatibilityOptions(packageName: 'awesome_pkg');
      final plan = service.planCompatibilityMatrix(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.platform, equals('all'));
      expect(plan.profile, equals('all'));
    });

    test(
        'Evaluates compatibility matrix cells across SDKs, platforms, and profiles',
        () {
      const options = CompatibilityOptions(packageName: 'awesome_pkg');
      final plan = service.planCompatibilityMatrix(options);
      final result = service.evaluateMatrix(plan);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isFullyCompatible, isTrue);
      expect(
          result.cells.length, equals(27)); // 3 SDKs * 3 platforms * 3 profiles
      expect(result.cells.first.status, equals(MatrixCellStatus.pass));

      final md = result.toMarkdown();
      expect(md, contains('# Compatibility Test Matrix: awesome_pkg'));
      expect(md, contains('| 3.0.0 | android | unit | PASS |'));
    });

    test('Rejects empty package names', () {
      const options = CompatibilityOptions(packageName: '');
      expect(() => service.planCompatibilityMatrix(options),
          throwsA(isA<CompatibilityMatrixException>()));
    });
  });
}
