/// Certification status and level domain models for the Template Certification System.
library;

/// Represents overall certification state of a template.
enum TemplateCertificationStatus {
  /// Template fully passed all required certification rules for the target profile.
  certified,

  /// Template passed essential requirements with non-blocking warnings.
  conditionallyCertified,

  /// Template failed mandatory certification rules or contains blocking errors.
  failed,

  /// Template has not undergone evaluation or certification is pending.
  notCertified;

  /// Returns `true` if this status allows project generation.
  bool get isEligibleForGeneration =>
      this == TemplateCertificationStatus.certified ||
      this == TemplateCertificationStatus.conditionallyCertified;
}

/// Certification tier level.
enum TemplateCertificationLevel {
  /// Basic certification tier.
  basic,

  /// Standard production certification tier.
  standard,

  /// Strict quality & security certification tier.
  strict,

  /// Release production deployment certification tier.
  release;

  /// Parses string into [TemplateCertificationLevel], defaulting to [standard].
  static TemplateCertificationLevel fromString(String? value) {
    if (value == null) return TemplateCertificationLevel.standard;
    switch (value.toLowerCase().trim()) {
      case 'basic':
        return TemplateCertificationLevel.basic;
      case 'strict':
        return TemplateCertificationLevel.strict;
      case 'release':
        return TemplateCertificationLevel.release;
      case 'standard':
      default:
        return TemplateCertificationLevel.standard;
    }
  }
}
