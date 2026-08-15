/// Core execution engine for Template Certification.
library;

import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/template/certification/certification_finding.dart';
import 'package:flutter_package_studio_core/src/template/certification/certification_report.dart';

import 'package:flutter_package_studio_core/src/template/certification/certification_request.dart';
import 'package:flutter_package_studio_core/src/template/certification/certification_rule_registry.dart';
import 'package:flutter_package_studio_core/src/template/certification/certification_status.dart';

/// Evaluates certification rules against a [TemplateCertificationRequest].
class TemplateCertificationEngine {
  final TemplateCertificationRuleRegistry registry;
  final Logger _logger = Logger('TemplateCertificationEngine');

  /// Creates a [TemplateCertificationEngine] with optional [registry].
  TemplateCertificationEngine({
    TemplateCertificationRuleRegistry? registry,
  }) : registry = registry ?? TemplateCertificationRuleRegistry();

  /// Evaluates certification for [request] and produces a [TemplateCertificationReport].
  TemplateCertificationReport evaluate(TemplateCertificationRequest request) {
    _logger.info(
        'Evaluating template certification for template: ${request.templateId} (profile: ${request.profile.name})');

    final rules = registry.listRules();
    final rawFindings = <TemplateCertificationFinding>[];
    var passedChecks = 0;
    var failedChecks = 0;

    for (final rule in rules) {
      final ruleFindings = rule.evaluate(request);
      if (ruleFindings.isEmpty) {
        passedChecks++;
      } else {
        if (ruleFindings
            .any((f) => f.severity == TemplateCertificationSeverity.error)) {
          failedChecks++;
        } else {
          passedChecks++;
        }
        rawFindings.addAll(ruleFindings);
      }
    }

    // Apply profile severity promotion rules if release profile
    final processedFindings = <TemplateCertificationFinding>[];
    for (final f in rawFindings) {
      if (request.profile.promoteWarningsToErrors &&
          f.severity == TemplateCertificationSeverity.warning) {
        processedFindings.add(TemplateCertificationFinding(
          ruleId: f.ruleId,
          category: f.category,
          severity: TemplateCertificationSeverity.error,
          message: '[RELEASE PROMOTED ERROR] ${f.message}',
          filePath: f.filePath,
          remediationAdvice: f.remediationAdvice,
          evidence: f.evidence,
        ));
      } else {
        processedFindings.add(f);
      }
    }

    // Sort findings deterministically: Severity (error -> warning -> info) -> Rule ID -> Message
    processedFindings.sort((a, b) {
      final sevComp = b.severity.index.compareTo(a.severity.index);
      if (sevComp != 0) return sevComp;
      final ruleComp = a.ruleId.compareTo(b.ruleId);
      if (ruleComp != 0) return ruleComp;
      return a.message.compareTo(b.message);
    });

    final hasError = processedFindings
        .any((f) => f.severity == TemplateCertificationSeverity.error);
    final hasWarning = processedFindings
        .any((f) => f.severity == TemplateCertificationSeverity.warning);

    final status = hasError
        ? TemplateCertificationStatus.failed
        : (hasWarning
            ? TemplateCertificationStatus.conditionallyCertified
            : TemplateCertificationStatus.certified);

    return TemplateCertificationReport(
      templateId: request.templateId,
      version: request.version,
      profile: request.profile,
      level: request.profile.level,
      status: status,
      findings: processedFindings,
      passedCheckCount: passedChecks,
      failedCheckCount: failedChecks,
      skippedCheckCount: 0,
    );
  }
}
