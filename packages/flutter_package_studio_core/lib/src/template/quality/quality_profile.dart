import 'package:flutter_package_studio_core/src/template/quality/quality_finding.dart';

/// Preset quality enforcement profiles.
enum TemplateQualityProfile {
  /// Basic integrity checks (manifest required fields, critical security).
  basic,

  /// Standard quality checks (placeholders, metadata, schema consistency).
  standard,

  /// Strict quality checks (dependency validation, path style, capability checks).
  strict,

  /// Release gate quality profile (promotes all warnings to errors).
  release,
}

extension TemplateQualityProfileX on TemplateQualityProfile {
  /// Whether warnings are promoted to error severity under this profile.
  bool get warningsAreErrors => this == TemplateQualityProfile.release;

  /// Applies severity promotions according to profile rules.
  List<TemplateQualityFinding> applyPromotions(
      List<TemplateQualityFinding> findings) {
    if (!warningsAreErrors) return findings;
    return findings.map((f) {
      if (f.severity == TemplateQualitySeverity.warning) {
        return TemplateQualityFinding(
          ruleId: f.ruleId,
          category: f.category,
          severity: TemplateQualitySeverity.error,
          message: '[Release profile] ${f.message}',
          filePath: f.filePath,
          remediation: f.remediation,
        );
      }
      return f;
    }).toList();
  }

  static TemplateQualityProfile fromString(String name) {
    switch (name.toLowerCase().trim()) {
      case 'basic':
        return TemplateQualityProfile.basic;
      case 'standard':
        return TemplateQualityProfile.standard;
      case 'strict':
        return TemplateQualityProfile.strict;
      case 'release':
        return TemplateQualityProfile.release;
      default:
        return TemplateQualityProfile.standard;
    }
  }
}
