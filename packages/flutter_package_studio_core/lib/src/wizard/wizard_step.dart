import 'package:flutter_package_studio_core/src/wizard/wizard_context.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_question.dart';

/// Represents a single logical step in the wizard workflow containing one or more questions.
class WizardStep {
  /// Unique step identifier (e.g. `metadata`, `sdk_config`, `architecture`).
  final String id;

  /// Display title for the step section header.
  final String title;

  /// Optional description explaining the step's scope.
  final String description;

  /// List of questions asked within this step.
  final List<WizardQuestion> questions;

  /// Optional predicate determining if this step should be rendered/executed.
  final bool Function(WizardContext context)? condition;

  /// Creates a [WizardStep] instance.
  const WizardStep({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    this.condition,
  });

  /// Evaluates whether this step should be executed given [context].
  bool shouldExecute(WizardContext context) {
    if (condition != null && !condition!(context)) {
      return false;
    }
    // Step executes if condition is met and at least one question is visible.
    return questions.any((q) => q.isVisible(context));
  }
}
