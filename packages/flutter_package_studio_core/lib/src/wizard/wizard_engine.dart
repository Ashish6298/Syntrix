import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_flow.dart';

import 'package:flutter_package_studio_core/src/wizard/wizard_history.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_navigator.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_renderer.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_result.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_session.dart';

/// Orchestrates wizard workflow execution, managing steps, retries, navigation, and rendering.
class WizardEngine {
  final Logger _logger = Logger('WizardEngine');
  final WizardRenderer renderer;

  /// Creates a [WizardEngine] instance.
  WizardEngine({WizardRenderer? renderer})
      : renderer = renderer ?? WizardRenderer();

  /// Executes the wizard flow with [session].
  Future<WizardResult> run({
    required WizardFlow flow,
    required WizardSession session,
  }) async {
    _logger.info('Starting interactive project wizard: ${flow.name}');
    final navigator = WizardNavigator(flow, session);
    final history = WizardHistory();

    try {
      renderer.renderHeader();

      int stepCounter = 1;
      while (true) {
        final step = navigator.currentStep;
        if (step == null) break;

        if (step.shouldExecute(session.context)) {
          renderer.renderStepHeader(step, stepCounter, navigator.totalSteps);

          for (final question in step.questions) {
            if (!question.isVisible(session.context)) continue;

            final initialVal = question.valueGetter?.call(session.context);
            final answer = renderer.renderQuestion(question, initialVal);

            if (answer == null) {
              _logger.info('Wizard execution cancelled by user input EOF.');
              return WizardResult.cancelled('Session cancelled by user.');
            }

            if (answer == ':b') {
              if (history.canGoBack) {
                final last = history.pop();
                if (last != null) {
                  _logger.debug(
                      'Navigating back in history for question ${last.questionId}');
                }
              } else if (navigator.hasPrevious) {
                navigator.previous();
              }
              break; // Restart loop for previous step/question
            }

            // Save history and update context
            history.push(WizardHistoryEntry(
              stepId: step.id,
              questionId: question.id,
              previousValue: initialVal,
              newAnswer: answer,
            ));

            question.valueSetter?.call(session.context, answer);
          }
        }

        if (navigator.hasNext) {
          navigator.next();
          stepCounter++;
        } else {
          break; // Reached end of steps
        }
      }

      // Render summary confirmation screen
      final confirmed = renderer.renderSummaryAndConfirm(session.context);
      if (!confirmed) {
        _logger.info('User declined project creation on confirmation summary.');
        return WizardResult.cancelled(
            'Project generation cancelled on summary.');
      }

      renderer.renderSuccess('Wizard completed successfully!');
      return WizardResult.success(session.context);
    } catch (e, st) {
      _logger.error(
          'Error occurred during wizard execution: $e (StackTrace: $st)',
          e,
          st);
      return WizardResult.failure(
          'An unexpected error occurred during wizard session: $e', e, st);
    }
  }
}
