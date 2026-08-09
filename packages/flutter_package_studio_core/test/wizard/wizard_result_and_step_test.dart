import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('WizardResult & Exception Handling Tests', () {
    test('WizardResult.success properties', () {
      final ctx = WizardContext(packageName: 'test');
      final res = WizardResult.success(ctx);
      expect(res, isA<WizardSuccess>());
      expect((res as WizardSuccess).context.packageName, equals('test'));
    });

    test('WizardResult.cancelled properties', () {
      final res = WizardResult.cancelled('User pressed Ctrl+C');
      expect(res, isA<WizardCancelled>());
      expect((res as WizardCancelled).message, contains('Ctrl+C'));
    });

    test('WizardResult.failure properties', () {
      final res = WizardResult.failure('Failed operation', 'Details error');
      expect(res, isA<WizardFailure>());
      expect((res as WizardFailure).message, equals('Failed operation'));
      expect(res.error, equals('Details error'));
    });

    test('WizardStep shouldExecute evaluation', () {
      final step = WizardStep(
        id: 'test_step',
        title: 'Title',
        description: 'Desc',
        condition: (ctx) => ctx.projectType == 'plugin',
        questions: [
          WizardQuestion<String>(
            id: 'q1',
            prompt: 'Prompt',
            type: WizardQuestionType.freeText,
          ),
        ],
      );

      expect(step.shouldExecute(WizardContext(projectType: 'plugin')), isTrue);
      expect(step.shouldExecute(WizardContext(projectType: 'dart_package')),
          isFalse);
    });
  });
}
