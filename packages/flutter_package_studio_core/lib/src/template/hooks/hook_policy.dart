/// Hook execution failure policies for the Template Hook System.
library;

/// Defines how the hook engine handles failures during hook execution.
enum TemplateHookPolicy {
  /// Stop pipeline execution immediately if a hook fails or throws an exception.
  failFast,

  /// Log the error diagnostic and continue executing remaining hooks and pipeline steps.
  continueOnError,

  /// Convert errors to warnings, log them, and proceed with pipeline execution.
  warningOnly;

  /// Parses [value] string into [TemplateHookPolicy], defaulting to [failFast].
  static TemplateHookPolicy fromString(String? value) {
    if (value == null) return TemplateHookPolicy.failFast;
    switch (value.toLowerCase().trim()) {
      case 'continue_on_error':
      case 'continueonerror':
        return TemplateHookPolicy.continueOnError;
      case 'warning_only':
      case 'warningonly':
        return TemplateHookPolicy.warningOnly;
      case 'fail_fast':
      case 'failfast':
      default:
        return TemplateHookPolicy.failFast;
    }
  }
}
