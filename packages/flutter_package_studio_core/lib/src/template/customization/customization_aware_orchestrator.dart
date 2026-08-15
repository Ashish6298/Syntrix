import 'package:flutter_package_studio_core/src/compatibility/compatibility_policy.dart';
import 'package:flutter_package_studio_core/src/compatibility/sdk_environment.dart';
import 'package:flutter_package_studio_core/src/template/composition/composition_request.dart';
import 'package:flutter_package_studio_core/src/template/composition/enhanced_composition_engine.dart';
import 'package:flutter_package_studio_core/src/template/customization/customization_engine.dart';
import 'package:flutter_package_studio_core/src/template/customization/customization_plan.dart';
import 'package:flutter_package_studio_core/src/template/customization/customization_schema.dart';
import 'package:flutter_package_studio_core/src/template/generation_plan.dart';
import 'package:flutter_package_studio_core/src/template/project_generator.dart';
import 'package:flutter_package_studio_core/src/template/template_composition.dart';
import 'package:flutter_package_studio_core/src/template/template_registry.dart';
import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_context.dart';

/// Orchestrates the complete generation pipeline:
/// Discovery → Compatibility → Resolution → Composition → Customization → GenerationPlan.
class CustomizationAwareOrchestrator {
  final TemplateRegistry registry;
  final SdkEnvironment environment;

  CustomizationAwareOrchestrator({
    required this.registry,
    this.environment = MockSdkEnvironment.standard,
  });

  /// Executes full pipeline in memory and returns a [GenerationPlan].
  GenerationPlan orchestrateGenerationPlan({
    required String templateId,
    String versionConstraint = '*',
    List<String> extensionIds = const [],
    OverrideStrategy conflictPolicy = OverrideStrategy.fail,
    CompatibilityPolicy compatibilityPolicy = CompatibilityPolicy.standard,
    CustomizationSchema? schema,
    String? presetName,
    Map<String, dynamic> userValues = const {},
    WizardContext? wizardContext,
    required String outputDirectory,
    OverwritePolicy overwritePolicy = OverwritePolicy.fail,
    FileUtils fileUtils = const SystemFileUtils(),
  }) {
    // 1. Resolution & Composition
    final compEngine = EnhancedCompositionEngine();
    final compRequest = CompositionRequest(
      baseTemplateId: templateId,
      baseVersionConstraint: versionConstraint,
      extensionIds: extensionIds,
      conflictPolicy: conflictPolicy,
      compatibilityPolicy: compatibilityPolicy,
    );

    final compPlan = compEngine.composePlan(
      request: compRequest,
      registry: registry,
      environment: environment,
    );

    // 2. Customization
    final custEngine = CustomizationEngine();
    final custPlan = custEngine.customize(
      resolvedTemplate: compPlan.resolvedTemplate,
      compositionPlan: compPlan,
      schema: schema,
      presetName: presetName,
      userValues: userValues,
    );

    // 3. Apply customization to resolved template
    final customizedResolved = custEngine.applyCustomizationToResolved(
      resolvedTemplate: compPlan.resolvedTemplate,
      plan: custPlan,
    );

    // 4. Construct final TemplateContext
    final tmplContext = custPlan.context.toTemplateContext(wizardContext);

    // 5. Construct GenerationPlan
    final generator = ProjectGenerator(fileUtils: fileUtils);
    return generator.buildPlanFromResolved(
      resolvedTemplate: customizedResolved,
      context: tmplContext,
      outputDirectory: outputDirectory,
      overwritePolicy: overwritePolicy,
    );
  }

  /// Builds a [CustomizationPlan] preview without constructing a GenerationPlan.
  CustomizationPlan buildCustomizationPlan({
    required String templateId,
    String versionConstraint = '*',
    List<String> extensionIds = const [],
    OverrideStrategy conflictPolicy = OverrideStrategy.fail,
    CompatibilityPolicy compatibilityPolicy = CompatibilityPolicy.standard,
    CustomizationSchema? schema,
    String? presetName,
    Map<String, dynamic> userValues = const {},
  }) {
    final compEngine = EnhancedCompositionEngine();
    final compRequest = CompositionRequest(
      baseTemplateId: templateId,
      baseVersionConstraint: versionConstraint,
      extensionIds: extensionIds,
      conflictPolicy: conflictPolicy,
      compatibilityPolicy: compatibilityPolicy,
    );

    final compPlan = compEngine.composePlan(
      request: compRequest,
      registry: registry,
      environment: environment,
    );

    final custEngine = CustomizationEngine();
    return custEngine.customize(
      resolvedTemplate: compPlan.resolvedTemplate,
      compositionPlan: compPlan,
      schema: schema,
      presetName: presetName,
      userValues: userValues,
    );
  }
}
