import 'package:flutter_package_studio_core/src/validation/validators.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_context.dart';

/// Supported types of wizard questions.
enum WizardQuestionType {
  /// Free-form text input.
  freeText,

  /// Yes/No confirmation prompt.
  confirm,

  /// Single choice from a list of options.
  singleSelect,

  /// Multiple choices from a list of options.
  multiSelect,

  /// Integer or double numeric input.
  numeric,

  /// Semantic version string input.
  semver,

  /// File path input.
  filePath,

  /// Directory path input.
  directoryPath,

  /// Masked/hidden password input.
  hidden,
}

/// Represents a single selectable choice in single/multi select questions.
class WizardOption<T> {
  /// Display label shown to the user.
  final String label;

  /// Underlying value associated with this choice.
  final T value;

  /// Optional description or help text for this option.
  final String? description;

  /// Creates a [WizardOption] choice.
  const WizardOption({
    required this.label,
    required this.value,
    this.description,
  });
}

/// Abstract representation of a wizard question.
class WizardQuestion<T> {
  /// Unique identifier key for storing/retrieving the answer.
  final String id;

  /// The prompt question text displayed to the user.
  final String prompt;

  /// The type of input expected.
  final WizardQuestionType type;

  /// Optional help text or explanation.
  final String? helpText;

  /// Default value if user enters empty input.
  final T? defaultValue;

  /// List of selectable options (for singleSelect and multiSelect).
  final List<WizardOption> options;

  /// Custom validator or core [Validator] used to validate the input value.
  final Validator<T>? validator;

  /// Custom inline validation function.
  final ValidationResult Function(T value)? customValidate;

  /// Predicate determining whether this question is visible based on [WizardContext].
  final bool Function(WizardContext context)? condition;

  /// Function to extract initial value from existing [WizardContext].
  final dynamic Function(WizardContext context)? valueGetter;

  /// Function to apply user answer back into [WizardContext].
  final void Function(WizardContext context, dynamic value)? valueSetter;

  /// Creates a [WizardQuestion] instance.
  const WizardQuestion({
    required this.id,
    required this.prompt,
    required this.type,
    this.helpText,
    this.defaultValue,
    this.options = const [],
    this.validator,
    this.customValidate,
    this.condition,
    this.valueGetter,
    this.valueSetter,
  });

  /// Validates [input] using [validator] or [customValidate].
  ValidationResult validateInput(T input) {
    if (validator != null) {
      final res = validator!.validate(input);
      if (!res.isValid) return res;
    }
    if (customValidate != null) {
      return customValidate!(input);
    }
    return ValidationResult.success();
  }

  /// Determines if this question should be asked given [context].
  bool isVisible(WizardContext context) {
    if (condition != null) {
      return condition!(context);
    }
    return true;
  }
}
