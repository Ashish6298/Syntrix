import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateContext & TemplateRenderer Tests', () {
    test(
        'TemplateContext.fromWizardContext converts properties and adds date/year',
        () {
      final wizardCtx = WizardContext(
        packageName: 'super_widget',
        projectType: 'flutter_package',
        description: 'Super awesome widget package',
        orgName: 'dev.syntrix',
        author: 'John Doe',
        email: 'john@example.com',
      );

      final ctx = TemplateContext.fromWizardContext(wizardCtx);

      expect(ctx.get('package_name'), equals('super_widget'));
      expect(ctx.get('package_name_pascal'), equals('SuperWidget'));
      expect(ctx.get('package_name_camel'), equals('superWidget'));
      expect(ctx.get('organization'), equals('dev.syntrix'));
      expect(ctx.get('author'), equals('John Doe'));
      expect(ctx.get('email'), equals('john@example.com'));
      expect(ctx.get('is_flutter'), isTrue);
      expect(ctx.get('is_dart'), isFalse);
      expect(ctx.get('current_year'), equals(DateTime.now().year.toString()));
    });

    test('TemplateRenderer.renderText replaces placeholders', () {
      final renderer = TemplateRenderer();
      final ctx = TemplateContext({
        'name': 'World',
        'item_count': 5,
        'tags': ['dart', 'flutter'],
      });

      final result = renderer.renderText(
          'Hello {{name}}! Count: {{item_count}}, Tags: {{tags}}', ctx);
      expect(result, equals('Hello World! Count: 5, Tags: dart, flutter'));
    });

    test(
        'TemplateRenderer strict mode throws TemplateException on unknown placeholder',
        () {
      final renderer = TemplateRenderer();
      final ctx = TemplateContext({'valid': 'ok'});

      expect(
        () => renderer.renderText('Value: {{unknown_val}}', ctx, strict: true),
        throwsA(isA<TemplateException>()),
      );
    });

    test('TemplateRenderer.renderPath replaces placeholders in file paths', () {
      final renderer = TemplateRenderer();
      final ctx = TemplateContext({'package_name': 'my_core'});

      final renderedPath =
          renderer.renderPath('lib/src/{{package_name}}_base.dart', ctx);
      expect(renderedPath, equals('lib/src/my_core_base.dart'));
    });
  });

  group('TemplateCondition Tests', () {
    final ctx = TemplateContext({
      'is_flutter': true,
      'is_dart': false,
      'project_type': 'flutter_package',
      'env': 'production',
    });

    test('TemplateCondition boolean key evaluation', () {
      expect(TemplateCondition.evaluate('is_flutter', ctx), isTrue);
      expect(TemplateCondition.evaluate('is_dart', ctx), isFalse);
    });

    test('TemplateCondition negation evaluation', () {
      expect(TemplateCondition.evaluate('!is_dart', ctx), isTrue);
      expect(TemplateCondition.evaluate('!is_flutter', ctx), isFalse);
    });

    test('TemplateCondition equality and inequality evaluation', () {
      expect(TemplateCondition.evaluate('project_type == flutter_package', ctx),
          isTrue);
      expect(TemplateCondition.evaluate('project_type == dart_package', ctx),
          isFalse);
      expect(TemplateCondition.evaluate('project_type != dart_package', ctx),
          isTrue);
      expect(TemplateCondition.evaluate('env == production', ctx), isTrue);
    });
  });
}
