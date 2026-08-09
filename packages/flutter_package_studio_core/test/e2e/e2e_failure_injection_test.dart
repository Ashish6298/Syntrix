import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('E2E Failure Injection Tests', () {
    test(
        'Invalid package name throws ValidationException during project plan building',
        () {
      final invalidCtx = WizardContext(packageName: '123_invalid_pkg_name!');
      final templateCtx = TemplateContext.fromWizardContext(invalidCtx);

      final generator = ProjectGenerator();

      expect(
        () => generator.buildPlan(
          template: BuiltinTemplates.flutterPackage,
          context: templateCtx,
          outputDirectory: './target',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
        'Path traversal attempt in example directory name throws ExampleGenerationException',
        () {
      const options = ExampleOptions(
        appName: 'valid_name',
        exampleDirName: '../../escaped_directory',
      );
      final ctx = TemplateContext({'package_name': 'valid_pkg'});
      final generator = ExampleGenerator();

      expect(
        () => generator.buildPlan(
          options: options,
          context: ctx,
          packageDirectory: './valid_pkg',
        ),
        throwsA(isA<ExampleGenerationException>()),
      );
    });
  });
}
