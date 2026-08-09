import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('WizardSession, History, Navigator & Flow Tests', () {
    test('WizardSession JSON serialization roundtrip', () {
      final ctx = WizardContext(packageName: 'test_pkg', projectType: 'plugin');
      final session = WizardSession(
        sessionId: 'sess_123',
        currentStepIndex: 2,
        context: ctx,
        completedSteps: {'identity': true, 'author_licensing': true},
      );

      final jsonStr = session.toJson();
      final restored = WizardSession.fromJson(jsonStr);

      expect(restored.sessionId, equals('sess_123'));
      expect(restored.currentStepIndex, equals(2));
      expect(restored.context.packageName, equals('test_pkg'));
      expect(restored.completedSteps['identity'], isTrue);
    });

    test('WizardHistory push, pop and stack length', () {
      final history = WizardHistory();
      expect(history.canGoBack, isFalse);

      history.push(const WizardHistoryEntry(
        stepId: 'step1',
        questionId: 'q1',
        newAnswer: 'ans1',
      ));

      expect(history.canGoBack, isTrue);
      expect(history.length, equals(1));

      final popped = history.pop();
      expect(popped?.questionId, equals('q1'));
      expect(history.canGoBack, isFalse);
    });

    test('WizardNavigator forward, backward, condition skips and jumpTo', () {
      final flow = WizardFlow.standard();
      final ctx = WizardContext(projectType: 'dart_package');
      final session = WizardSession(sessionId: 'nav_sess', context: ctx);
      final navigator = WizardNavigator(flow, session);

      expect(navigator.currentIndex, equals(0));
      expect(navigator.currentStep?.id, equals('identity'));

      // Jump to step
      final jumped = navigator.jumpTo('ci_quality');
      expect(jumped, isTrue);
      expect(navigator.currentStep?.id, equals('ci_quality'));

      // Previous step
      final wentBack = navigator.previous();
      expect(wentBack, isTrue);
      expect(navigator.currentStep?.id, equals('architecture_testing'));
    });
  });
}
