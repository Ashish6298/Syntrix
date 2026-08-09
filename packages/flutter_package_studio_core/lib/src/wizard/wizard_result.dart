import 'package:flutter_package_studio_core/src/wizard/wizard_context.dart';

/// Sealed-like outcome result of wizard execution.
abstract class WizardResult {
  const WizardResult();

  /// Factory for successful completion with collected [context].
  factory WizardResult.success(WizardContext context) = WizardSuccess;

  /// Factory for user cancellation.
  factory WizardResult.cancelled([String message]) = WizardCancelled;

  /// Factory for failure with error message and optional details.
  factory WizardResult.failure(String message,
      [Object? error, StackTrace? stackTrace]) = WizardFailure;
}

/// Indicates the wizard completed successfully.
class WizardSuccess extends WizardResult {
  /// Final project context.
  final WizardContext context;

  /// Creates a [WizardSuccess] result.
  const WizardSuccess(this.context);
}

/// Indicates the wizard was cancelled by user (e.g., Ctrl+C or 'q').
class WizardCancelled extends WizardResult {
  /// Reason or message for cancellation.
  final String message;

  /// Creates a [WizardCancelled] result.
  const WizardCancelled([this.message = 'Wizard execution cancelled by user.']);
}

/// Indicates an unexpected error or unhandled failure occurred.
class WizardFailure extends WizardResult {
  /// Error message summary.
  final String message;

  /// Optional underlying exception object.
  final Object? error;

  /// Optional stack trace.
  final StackTrace? stackTrace;

  /// Creates a [WizardFailure] result.
  const WizardFailure(this.message, [this.error, this.stackTrace]);
}
