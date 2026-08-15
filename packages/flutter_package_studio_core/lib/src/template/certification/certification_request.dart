/// Certification request model wrapping target template and optional pipeline state.
library;

import 'package:flutter_package_studio_core/src/template/composition/composition_plan.dart';
import 'package:flutter_package_studio_core/src/template/customization/customization_plan.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_result.dart';

import 'package:flutter_package_studio_core/src/template/resolved_template.dart';
import 'package:flutter_package_studio_core/src/template/template_context.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';
import 'package:flutter_package_studio_core/src/template/certification/certification_profile.dart';

/// Holds the input state to be evaluated during certification.
class TemplateCertificationRequest {
  /// Base raw template (if certifying a single raw template).
  final Template? rawTemplate;

  /// Composed resolved template (if certifying a resolved template).
  final ResolvedTemplate? resolvedTemplate;

  /// Target certification profile.
  final TemplateCertificationProfile profile;

  /// Optional context variables.
  final TemplateContext? context;

  /// Optional composition plan details.
  final CompositionPlan? compositionPlan;

  /// Optional customization plan details.
  final CustomizationPlan? customizationPlan;

  /// Optional hook lifecycle report details.
  final TemplateHookLifecycleReport? hookReport;

  /// Creates a [TemplateCertificationRequest].
  const TemplateCertificationRequest({
    this.rawTemplate,
    this.resolvedTemplate,
    this.profile = TemplateCertificationProfile.standard,
    this.context,
    this.compositionPlan,
    this.customizationPlan,
    this.hookReport,
  });

  /// Target template identifier.
  String get templateId =>
      resolvedTemplate?.id ?? rawTemplate?.id ?? 'unknown_template';

  /// Target template version.
  String get version =>
      resolvedTemplate?.version ?? rawTemplate?.version ?? '1.0.0';

  /// Primary manifest.
  dynamic get manifest =>
      resolvedTemplate?.effectiveManifest ?? rawTemplate?.manifest;
}
