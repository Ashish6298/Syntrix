import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('WidgetTestGenerator Unit Tests', () {
    late WidgetTestGenerator generator;

    setUp(() {
      generator = WidgetTestGenerator();
    });

    test('Plans and generates widget test suite from public widget targets',
        () {
      const options = WidgetTestOptions(packageName: 'awesome_pkg');
      final plan = generator.planWidgetTests(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.targets.length, equals(1));
      expect(plan.targets.first.name, equals('awesome_pkgWidget'));
      expect(plan.targets.first.widgetKind, equals('StatelessWidget'));

      final result = generator.generateWidgetTests(plan, options);
      expect(result.files['test/widget/awesome_pkg_widget_test.dart'],
          contains('package:flutter_test/flutter_test.dart'));
      expect(result.files['test/widget/awesome_pkg_widget_test.dart'],
          contains('awesome_pkg Widget Test Suite'));
      expect(result.files['test/widget/awesome_pkg_widget_test.dart'],
          contains('testWidgets'));
      expect(result.files['test/widget/awesome_pkg_widget_test.dart'],
          contains('TODO: verify interactive'));
    });

    test('Rejects empty package names', () {
      const options = WidgetTestOptions(packageName: '');
      expect(() => generator.planWidgetTests(options),
          throwsA(isA<WidgetTestGenerationException>()));
    });

    test('Output is 100% deterministic across repeated runs', () {
      const options = WidgetTestOptions(packageName: 'det_pkg');

      final plan1 = generator.planWidgetTests(options);
      final res1 = generator.generateWidgetTests(plan1, options);

      final plan2 = generator.planWidgetTests(options);
      final res2 = generator.generateWidgetTests(plan2, options);

      expect(res1.files, equals(res2.files));
    });
  });
}
