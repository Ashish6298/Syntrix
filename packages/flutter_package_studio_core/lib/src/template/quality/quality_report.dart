import 'package:flutter_package_studio_core/src/template/quality/quality_finding.dart';
import 'package:flutter_package_studio_core/src/template/quality/quality_profile.dart';

/// Aggregated, immutable quality evaluation report.
class TemplateQualityReport {
  final String templateId;
  final String version;
  final TemplateQualityProfile profile;
  final List<TemplateQualityFinding> findings;

  TemplateQualityReport({
    required this.templateId,
    required this.version,
    required this.profile,
    required List<TemplateQualityFinding> findings,
  }) : findings = _sorted(findings);

  /// Whether template passed validation under [profile].
  bool get isPassed => errorCount == 0;

  /// Count of findings with severity == error.
  int get errorCount =>
      findings.where((f) => f.severity == TemplateQualitySeverity.error).length;

  /// Count of findings with severity == warning.
  int get warningCount => findings
      .where((f) => f.severity == TemplateQualitySeverity.warning)
      .length;

  /// Count of findings with severity == info.
  int get infoCount =>
      findings.where((f) => f.severity == TemplateQualitySeverity.info).length;

  static List<TemplateQualityFinding> _sorted(
      List<TemplateQualityFinding> list) {
    final copy = List<TemplateQualityFinding>.from(list);
    copy.sort();
    return List.unmodifiable(copy);
  }

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'version': version,
        'profile': profile.name,
        'isPassed': isPassed,
        'errorCount': errorCount,
        'warningCount': warningCount,
        'infoCount': infoCount,
        'findings': findings.map((f) => f.toJson()).toList(),
      };
}
