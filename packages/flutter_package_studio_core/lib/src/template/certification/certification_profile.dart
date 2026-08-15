/// Certification profile rules and severity promotion settings.
library;

import 'package:flutter_package_studio_core/src/template/certification/certification_status.dart';

/// Certification policy profile controlling enforcement strictness.
enum TemplateCertificationProfile {
  /// Basic certification: evaluates structural validity, basic manifest integrity.
  basic,

  /// Standard certification: evaluates compatibility, dependencies, placeholder syntax.
  standard,

  /// Strict certification: treats quality warnings strictly, verifies provenance.
  strict,

  /// Release certification: promotes warnings to blocking errors, enforces full security & provenance.
  release;

  /// Corresponding certification level.
  TemplateCertificationLevel get level {
    switch (this) {
      case TemplateCertificationProfile.basic:
        return TemplateCertificationLevel.basic;
      case TemplateCertificationProfile.standard:
        return TemplateCertificationLevel.standard;
      case TemplateCertificationProfile.strict:
        return TemplateCertificationLevel.strict;
      case TemplateCertificationProfile.release:
        return TemplateCertificationLevel.release;
    }
  }

  /// Whether warnings should be promoted to errors under this profile.
  bool get promoteWarningsToErrors =>
      this == TemplateCertificationProfile.release;

  /// Parses string into [TemplateCertificationProfile], defaulting to [standard].
  static TemplateCertificationProfile fromString(String? value) {
    if (value == null) return TemplateCertificationProfile.standard;
    switch (value.toLowerCase().trim()) {
      case 'basic':
        return TemplateCertificationProfile.basic;
      case 'strict':
        return TemplateCertificationProfile.strict;
      case 'release':
        return TemplateCertificationProfile.release;
      case 'standard':
      default:
        return TemplateCertificationProfile.standard;
    }
  }
}
