import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExampleGenerator & Path Security Tests', () {
    late ExampleGenerator generator;

    setUp(() {
      generator = ExampleGenerator(fileUtils: const SystemFileUtils());
    });

    test(
        'Validation failure on invalid example application name throws ValidationException',
        () {
      const invalidOptions = ExampleOptions(appName: '123_invalid app name!');
      final ctx = TemplateContext({'package_name': 'test'});

      expect(
        () => generator.buildPlan(
          options: invalidOptions,
          context: ctx,
          packageDirectory: './target_pkg',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
        'buildPlan creates inspectable ExampleGenerationPlan without mutating disk',
        () {
      const options = ExampleOptions(appName: 'sample_pkg_example');
      final ctx = TemplateContext(
          {'package_name': 'sample_pkg', 'package_name_pascal': 'SamplePkg'});

      final plan = generator.buildPlan(
        options: options,
        context: ctx,
        packageDirectory: './sample_pkg',
      );

      expect(plan.templateId, equals('standard'));
      expect(plan.actions.any((a) => a.relativePath == 'pubspec.yaml'), isTrue);
      expect(
          plan.actions.any((a) => a.relativePath == 'lib/main.dart'), isTrue);
      expect(plan.actions.any((a) => a.relativePath == 'test/widget_test.dart'),
          isTrue);
      expect(plan.actions.any((a) => a.relativePath == 'README.md'), isTrue);

      final pubspecAction =
          plan.actions.firstWhere((a) => a.relativePath == 'pubspec.yaml');
      expect(pubspecAction.textContent, contains('sample_pkg:'));
      expect(pubspecAction.textContent, contains('path: ../'));
    });

    test('execute dryRun returns simulation success without writing files',
        () async {
      const options = ExampleOptions(appName: 'dry_pkg_example');
      final ctx = TemplateContext({'package_name': 'dry_pkg'});

      final plan = generator.buildPlan(
        options: options,
        context: ctx,
        packageDirectory: './dry_pkg',
      );

      final result = await generator.execute(plan: plan, dryRun: true);

      expect(result.isSuccess, isTrue);
      expect(result.isDryRun, isTrue);
    });

    test(
        'Path traversal attempt in example directory name throws ExampleGenerationException',
        () {
      const options = ExampleOptions(
        appName: 'valid_example',
        exampleDirName: '../../outside_example',
      );
      final ctx = TemplateContext({'package_name': 'valid_pkg'});

      expect(
        () => generator.buildPlan(
          options: options,
          context: ctx,
          packageDirectory: './target_pkg',
        ),
        throwsA(isA<ExampleGenerationException>()),
      );
    });
  });
}
