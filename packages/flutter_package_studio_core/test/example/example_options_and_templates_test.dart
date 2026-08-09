import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExampleOptions & ExampleTemplate Registry Tests', () {
    test('ExampleOptions initializes with expected default values', () {
      const options = ExampleOptions(
        appName: 'my_pkg_example',
      );

      expect(options.exampleDirName, equals('example'));
      expect(options.appName, equals('my_pkg_example'));
      expect(options.templateId, equals('standard'));
      expect(options.generateReadme, isTrue);
      expect(options.generateTests, isTrue);
    });

    test('ExampleOptions.fromWizardContext converts WizardContext properties',
        () {
      final wizardCtx = WizardContext(
        packageName: 'super_widget',
        orgName: 'dev.syntrix',
      );

      final options = ExampleOptions.fromWizardContext(wizardCtx);

      expect(options.appName, equals('super_widget_example'));
      expect(options.orgName, equals('dev.syntrix'));
      expect(options.description, contains('super_widget'));
    });

    test(
        'ExampleTemplateRegistry resolves registered templates or throws ExampleTemplateException',
        () {
      final registry = ExampleTemplateRegistry();

      final standard = registry.get('standard');
      expect(standard.id, equals('standard'));
      expect(standard.mainDartTemplate, contains('MaterialApp'));

      final minimal = registry.get('minimal');
      expect(minimal.id, equals('minimal'));

      expect(
        () => registry.get('unknown_template_id'),
        throwsA(isA<ExampleTemplateException>()),
      );
    });
  });
}
