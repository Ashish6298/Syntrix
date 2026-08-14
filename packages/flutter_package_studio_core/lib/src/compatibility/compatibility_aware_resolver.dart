import 'package:flutter_package_studio_core/src/compatibility/compatibility_evaluator.dart';
import 'package:flutter_package_studio_core/src/compatibility/compatibility_policy.dart';
import 'package:flutter_package_studio_core/src/compatibility/compatibility_result.dart';
import 'package:flutter_package_studio_core/src/compatibility/sdk_environment.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/template/composition/composition.dart';
import 'package:flutter_package_studio_core/src/template/resolved_template.dart';
import 'package:flutter_package_studio_core/src/template/template_composition.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';
import 'package:flutter_package_studio_core/src/template/template_resolver.dart';

/// Extension of [TemplateResolver] that incorporates compatibility evaluation
/// and version-aware selection prior to template composition.
class CompatibilityAwareResolver extends TemplateResolver {
  final SdkEnvironment environment;
  final CompatibilityPolicy policy;
  late final CompatibilityEvaluator _evaluator;

  /// Creates a [CompatibilityAwareResolver].
  CompatibilityAwareResolver({
    required super.registry,
    required this.environment,
    this.policy = CompatibilityPolicy.standard,
  }) {
    _evaluator = CompatibilityEvaluator(
      environment: environment,
      policy: policy,
    );
  }

  /// Resolves [templateId] to a compatible [ResolvedTemplate].
  ///
  /// Integrates compatibility filtering:
  /// 1. Finds candidate templates matching [templateId] and [versionConstraint].
  /// 2. Evaluates compatibility for candidate templates using [_evaluator].
  /// 3. Selects the highest compatible version.
  /// 4. Resolves extensions and checks their compatibility.
  /// 5. Composes final template or throws [CompatibilityException] / [TemplateException].
  @override
  ResolvedTemplate resolve({
    required String templateId,
    String versionConstraint = '*',
    List<String> extensionIds = const [],
    OverrideStrategy overrideStrategy = OverrideStrategy.fail,
  }) {
    // 1. Select highest compatible version for root template
    final base = _evaluator.selectBestCompatibleVersion(
      templateId,
      registry,
      versionConstraint: versionConstraint,
    );

    if (base == null) {
      // Check if template exists at all to provide precise diagnostic
      final allCandidates =
          registry.listAll().where((t) => t.id == templateId).toList();

      if (allCandidates.isEmpty) {
        throw TemplateException(
            'Template "$templateId" ($versionConstraint) not found in registry.');
      }

      // Template exists, but none are compatible under current policy/environment
      final evalResult = _evaluator.evaluateAllVersions(templateId, registry);
      final issueMsgs = <String>[];
      evalResult.resultsByVersion.forEach((ver, res) {
        if (!res.isCompatible) {
          final errStr = res.errors.map((e) => e.message).join('; ');
          issueMsgs.add('v$ver: $errStr');
        }
      });

      throw CompatibilityException(
        'No compatible version of template "$templateId" ($versionConstraint) '
        'found for environment [${environment.dartVersion}]. '
        'Diagnostics: ${issueMsgs.join(' | ')}',
      );
    }

    // 2. Validate requested extensions and ensure compatibility
    final extensions = <Template>[];
    for (final extId in extensionIds) {
      final ext = _evaluator.selectBestCompatibleVersion(
        extId,
        registry,
      );

      if (ext == null) {
        final extExists = registry.contains(extId);
        if (!extExists) {
          throw TemplateException(
              'Extension template "$extId" not found in registry.');
        }
        throw CompatibilityException(
            'Extension template "$extId" is incompatible with the current environment.');
      }
      extensions.add(ext);
    }

    // 3. Delegate to super's composition mechanism
    // Ensure all selected compatible extension templates are in the registry
    for (final ext in extensions) {
      if (!registry.contains(ext.id)) {
        registry.register(ext);
      }
    }

    return super.resolve(
      templateId: base.id,
      versionConstraint: base.version,
      extensionIds: extensions.map((e) => e.id).toList(),
      overrideStrategy: overrideStrategy,
    );
  }

  /// Evaluates compatibility of a template ID without resolving or composing.
  CompatibilityResult evaluateTemplate(String templateId,
      {String versionConstraint = '*'}) {
    final template =
        registry.resolve(templateId, versionConstraint: versionConstraint);
    if (template == null) {
      throw TemplateException(
          'Template "$templateId" ($versionConstraint) not found.');
    }
    return _evaluator.evaluate(template, availableTemplates: registry);
  }

  /// Evaluates and generates a complete [CompositionPlan] for [request].
  CompositionPlan composePlan(CompositionRequest request) {
    final engine = EnhancedCompositionEngine();
    return engine.composePlan(
      request: request,
      registry: registry,
      environment: environment,
    );
  }
}
