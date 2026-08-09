import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('WizardQuestion & Validation Tests', () {
    test('FreeText Question validation succeeds for valid string', () {
      final q = WizardQuestion<String>(
        id: 'name',
        prompt: 'Package name',
        type: WizardQuestionType.freeText,
        validator: const PackageNameValidator(),
      );

      final res = q.validateInput('my_package');
      expect(res.isValid, isTrue);
    });

    test('FreeText Question validation fails for invalid string', () {
      final q = WizardQuestion<String>(
        id: 'name',
        prompt: 'Package name',
        type: WizardQuestionType.freeText,
        validator: const PackageNameValidator(),
      );

      final res = q.validateInput('123_invalid');
      expect(res.isValid, isFalse);
      expect(res.errors.first, contains('must consist of only lowercase'));
    });

    test('Custom inline validation takes effect', () {
      final q = WizardQuestion<String>(
        id: 'custom',
        prompt: 'Custom text',
        type: WizardQuestionType.freeText,
        customValidate: (val) {
          if (val != 'magic')
            return ValidationResult.failure(['Must be magic']);
          return ValidationResult.success();
        },
      );

      expect(q.validateInput('wrong').isValid, isFalse);
      expect(q.validateInput('magic').isValid, isTrue);
    });

    test('Question isVisible condition check', () {
      final q = WizardQuestion<String>(
        id: 'flutter_only',
        prompt: 'Flutter SDK',
        type: WizardQuestionType.semver,
        condition: (ctx) => ctx.projectType == 'flutter_package',
      );

      final ctx1 = WizardContext(projectType: 'flutter_package');
      final ctx2 = WizardContext(projectType: 'dart_package');

      expect(q.isVisible(ctx1), isTrue);
      expect(q.isVisible(ctx2), isFalse);
    });
  });

  group('WizardValidator Helpers Tests', () {
    test('requiredString validator', () {
      final v = WizardValidator.requiredString('Title');
      expect(v.validate('   ').isValid, isFalse);
      expect(v.validate('Hello').isValid, isTrue);
    });

    test('numberRange validator', () {
      final v = WizardValidator.numberRange(min: 1, max: 10);
      expect(v.validate(0).isValid, isFalse);
      expect(v.validate(11).isValid, isFalse);
      expect(v.validate(5).isValid, isTrue);
    });

    test('url validator', () {
      final v = WizardValidator.url(required: true);
      expect(v.validate('').isValid, isFalse);
      expect(v.validate('not-a-url').isValid, isFalse);
      expect(v.validate('https://pub.dev').isValid, isTrue);
    });

    test('email validator', () {
      final v = WizardValidator.email(required: true);
      expect(v.validate('bad-email').isValid, isFalse);
      expect(v.validate('dev@example.com').isValid, isTrue);
    });
  });
}
