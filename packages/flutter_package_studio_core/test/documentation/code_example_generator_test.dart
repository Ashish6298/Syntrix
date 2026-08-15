import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('CodeExampleGenerator Unit Tests', () {
    late CodeExampleGenerator generator;

    setUp(() {
      generator = CodeExampleGenerator();
    });

    test(
        'Generates valid basic usage example with correct imports and main method',
        () {
      const options = CodeExampleOptions(
        packageName: 'awesome_package',
        exampleType: CodeExampleType.basicUsage,
      );

      final plan = generator.planExample(options);
      final result = generator.generateExample(plan);

      expect(result.code,
          contains('import \'package:awesome_package/awesome_package.dart\';'));
      expect(result.code, contains('void main() async {'));
      expect(result.code, contains('final client = AwesomePackageClient();'));
    });

    test('Generates valid full Flutter application example', () {
      const options = CodeExampleOptions(
        packageName: 'flutter_app',
        exampleType: CodeExampleType.fullExample,
      );

      final plan = generator.planExample(options);
      final result = generator.generateExample(plan);

      expect(result.code, contains('void main() async {'));
      expect(
          result.code, contains('WidgetsFlutterBinding.ensureInitialized();'));
      expect(result.code, contains('runApp(app);'));
    });

    test('Output is 100% deterministic across repeated runs', () {
      const options = CodeExampleOptions(
        packageName: 'demo_pkg',
        exampleType: CodeExampleType.configuration,
      );

      final plan1 = generator.planExample(options);
      final res1 = generator.generateExample(plan1);

      final plan2 = generator.planExample(options);
      final res2 = generator.generateExample(plan2);

      expect(res1.code, equals(res2.code));
    });
  });
}
