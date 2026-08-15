/// Test execution status and test profile domain models.
library;

/// Execution status of an individual template test case or test suite.
enum TemplateTestStatus {
  /// Test executed and all assertions passed.
  passed,

  /// Test executed and one or more assertions failed.
  failed,

  /// Test was skipped based on profile or condition.
  skipped,

  /// Test execution encountered an unhandled error.
  error;

  /// Returns `true` if this status indicates a successful test run.
  bool get isSuccessful =>
      this == TemplateTestStatus.passed || this == TemplateTestStatus.skipped;
}

/// Testing profile controlling test selection and enforcement strictness.
enum TemplateTestProfile {
  /// Basic testing profile: structural schema & manifest sanity checks.
  basic,

  /// Standard testing profile: compatibility, dependencies, placeholder checks.
  standard,

  /// Strict testing profile: quality engine, composition provenance, hook security checks.
  strict,

  /// Release testing profile: full certification eligibility verification.
  release;

  /// Parses string into [TemplateTestProfile], defaulting to [standard].
  static TemplateTestProfile fromString(String? value) {
    if (value == null) return TemplateTestProfile.standard;
    switch (value.toLowerCase().trim()) {
      case 'basic':
        return TemplateTestProfile.basic;
      case 'strict':
        return TemplateTestProfile.strict;
      case 'release':
        return TemplateTestProfile.release;
      case 'standard':
      default:
        return TemplateTestProfile.standard;
    }
  }
}
