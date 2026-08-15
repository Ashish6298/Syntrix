/// Aggregated certification report model.
library;

import 'package:flutter_package_studio_core/src/template/certification/certification_finding.dart';
import 'package:flutter_package_studio_core/src/template/certification/certification_profile.dart';
import 'package:flutter_package_studio_core/src/template/certification/certification_status.dart';

/// Aggregated, immutable certification report for a target template.
class TemplateCertificationReport {
  /// Target template identifier.
  final String templateId;

  /// Target template version.
  final String version;

  /// Applied certification profile.
  final TemplateCertificationProfile profile;

  /// Target certification tier level.
  final TemplateCertificationLevel level;

  /// Final certification status.
  final TemplateCertificationStatus status;

  /// List of certification findings sorted deterministically.
  final List<TemplateCertificationFinding> findings;

  /// Total number of evaluated rules that passed cleanly.
  final int passedCheckCount;

  /// Total number of evaluated rules that produced errors.
  final int failedCheckCount;

  /// Total number of rules skipped or deferred.
  final int skippedCheckCount;

  /// Creates a [TemplateCertificationReport].
  const TemplateCertificationReport({
    required this.templateId,
    required this.version,
    required this.profile,
    required this.level,
    required this.status,
    required this.findings,
    this.passedCheckCount = 0,
    this.failedCheckCount = 0,
    this.skippedCheckCount = 0,
  });

  /// Count of error findings.
  int get errorCount => findings
      .where((f) => f.severity == TemplateCertificationSeverity.error)
      .length;

  /// Count of warning findings.
  int get warningCount => findings
      .where((f) => f.severity == TemplateCertificationSeverity.warning)
      .length;

  /// Count of info findings.
  int get infoCount => findings
      .where((f) => f.severity == TemplateCertificationSeverity.info)
      .length;

  /// Returns `true` if certification passed without blocking errors.
  bool get isPassed =>
      status == TemplateCertificationStatus.certified ||
      status == TemplateCertificationStatus.conditionallyCertified;

  /// Returns `true` if template is eligible for generation.
  bool get isGenerationEligible => status.isEligibleForGeneration;

  /// Serializes report to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'templateId': templateId,
      'version': version,
      'profile': profile.name,
      'level': level.name,
      'status': status.name,
      'isPassed': isPassed,
      'isGenerationEligible': isGenerationEligible,
      'errorCount': errorCount,
      'warningCount': warningCount,
      'infoCount': infoCount,
      'passedCheckCount': passedCheckCount,
      'failedCheckCount': failedCheckCount,
      'skippedCheckCount': skippedCheckCount,
      'findings': findings.map((f) => f.toJson()).toList(),
    };
  }
}
