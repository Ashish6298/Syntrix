import 'package:flutter_package_studio_core/src/template/composition/composition_plan.dart';
import 'package:flutter_package_studio_core/src/template/customization/customization_plan.dart';
import 'package:flutter_package_studio_core/src/template/quality/quality_finding.dart';
import 'package:flutter_package_studio_core/src/template/quality/quality_profile.dart';
import 'package:flutter_package_studio_core/src/template/resolved_template.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';

/// Abstract rule contract for template quality inspection.
abstract class TemplateQualityRule {
  String get id;
  TemplateQualityCategory get category;
  String get description;

  /// Returns findings evaluated for a single raw [Template].
  List<TemplateQualityFinding> evaluateTemplate(
      Template template, TemplateQualityProfile profile);

  /// Returns findings evaluated for a [ResolvedTemplate].
  List<TemplateQualityFinding> evaluateResolved(
      ResolvedTemplate resolved, TemplateQualityProfile profile) {
    return evaluateTemplate(resolved.baseTemplate, profile);
  }

  /// Returns findings evaluated for a [CompositionPlan].
  List<TemplateQualityFinding> evaluateComposition(
      CompositionPlan plan, TemplateQualityProfile profile) {
    return evaluateResolved(plan.resolvedTemplate, profile);
  }

  /// Returns findings evaluated for a [CustomizationPlan].
  List<TemplateQualityFinding> evaluateCustomization(
      CustomizationPlan plan, TemplateQualityProfile profile) {
    if (plan.compositionPlan != null) {
      return evaluateComposition(plan.compositionPlan!, profile);
    }
    return const [];
  }
}
