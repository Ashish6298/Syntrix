import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/template/composition/composition_plan.dart';
import 'package:flutter_package_studio_core/src/template/customization/customization_plan.dart';
import 'package:flutter_package_studio_core/src/template/quality/quality_finding.dart';
import 'package:flutter_package_studio_core/src/template/quality/quality_profile.dart';
import 'package:flutter_package_studio_core/src/template/quality/quality_report.dart';
import 'package:flutter_package_studio_core/src/template/quality/quality_rule_registry.dart';
import 'package:flutter_package_studio_core/src/template/resolved_template.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';

/// Core Quality Assurance & Validation Engine.
class TemplateQualityEngine {
  final QualityRuleRegistry registry;
  final Logger _logger = Logger('TemplateQualityEngine');

  TemplateQualityEngine({QualityRuleRegistry? registry})
      : registry = registry ?? QualityRuleRegistry();

  /// Evaluates quality of a single [Template].
  TemplateQualityReport evaluateTemplate(
    Template template, {
    TemplateQualityProfile profile = TemplateQualityProfile.standard,
  }) {
    _logger.info(
        'Evaluating quality for template "${template.id}" profile=${profile.name}');
    final rawFindings = <TemplateQualityFinding>[];

    for (final rule in registry.allRules) {
      rawFindings.addAll(rule.evaluateTemplate(template, profile));
    }

    final promoted = profile.applyPromotions(rawFindings);

    return TemplateQualityReport(
      templateId: template.id,
      version: template.version,
      profile: profile,
      findings: promoted,
    );
  }

  /// Evaluates quality of a [ResolvedTemplate].
  TemplateQualityReport evaluateResolved(
    ResolvedTemplate resolvedTemplate, {
    TemplateQualityProfile profile = TemplateQualityProfile.standard,
  }) {
    final rawFindings = <TemplateQualityFinding>[];

    for (final rule in registry.allRules) {
      rawFindings.addAll(rule.evaluateResolved(resolvedTemplate, profile));
    }

    final promoted = profile.applyPromotions(rawFindings);

    return TemplateQualityReport(
      templateId: resolvedTemplate.id,
      version: resolvedTemplate.version,
      profile: profile,
      findings: promoted,
    );
  }

  /// Evaluates quality of a [CompositionPlan].
  TemplateQualityReport evaluateComposition(
    CompositionPlan plan, {
    TemplateQualityProfile profile = TemplateQualityProfile.standard,
  }) {
    final rawFindings = <TemplateQualityFinding>[];

    for (final rule in registry.allRules) {
      rawFindings.addAll(rule.evaluateComposition(plan, profile));
    }

    final promoted = profile.applyPromotions(rawFindings);

    return TemplateQualityReport(
      templateId: plan.baseTemplateId,
      version: plan.resolvedTemplate.version,
      profile: profile,
      findings: promoted,
    );
  }

  /// Evaluates quality of a [CustomizationPlan].
  TemplateQualityReport evaluateCustomization(
    CustomizationPlan plan, {
    TemplateQualityProfile profile = TemplateQualityProfile.standard,
  }) {
    final rawFindings = <TemplateQualityFinding>[];

    for (final rule in registry.allRules) {
      rawFindings.addAll(rule.evaluateCustomization(plan, profile));
    }

    final promoted = profile.applyPromotions(rawFindings);

    return TemplateQualityReport(
      templateId: plan.templateId,
      version: plan.compositionPlan?.resolvedTemplate.version ?? '1.0.0',
      profile: profile,
      findings: promoted,
    );
  }
}
