import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/template/composition/composition_plan.dart';
import 'package:flutter_package_studio_core/src/template/customization/customization_context.dart';
import 'package:flutter_package_studio_core/src/template/customization/customization_plan.dart';
import 'package:flutter_package_studio_core/src/template/customization/customization_schema.dart';
import 'package:flutter_package_studio_core/src/template/resolved_template.dart';
import 'package:flutter_package_studio_core/src/template/template_condition.dart';
import 'package:flutter_package_studio_core/src/template/template_renderer.dart';

/// Core evaluator executing template customization logic.
class CustomizationEngine {
  final Logger _logger = Logger('CustomizationEngine');

  /// Applies customization schema, context, and condition rules to a [ResolvedTemplate] or [CompositionPlan].
  CustomizationPlan customize({
    required ResolvedTemplate resolvedTemplate,
    CompositionPlan? compositionPlan,
    CustomizationSchema? schema,
    String? presetName,
    Map<String, dynamic> userValues = const {},
  }) {
    _logger.info('Customizing template "${resolvedTemplate.id}"');

    // Extract manifest schema or merge with provided schema
    final manifestSchema = _extractSchemaFromManifest(resolvedTemplate);
    final effectiveSchema =
        schema != null ? manifestSchema.merge(schema) : manifestSchema;

    // Resolve customization context (defaults -> preset -> user input)
    final custContext = CustomizationContext.resolve(
      schema: effectiveSchema,
      presetName: presetName,
      userValues: userValues,
    );

    final tmplContext = custContext.toTemplateContext();

    // Evaluate conditional file rules and path overrides
    final includedFiles = <String>[];
    final excludedFiles = <String>[];
    final activePathOverrides = <String, String>{};

    resolvedTemplate.files.forEach((rawPath, content) {
      // 1. Check manifest & customization conditional rules
      final condition =
          resolvedTemplate.effectiveManifest.conditions[rawPath] ??
              effectiveSchema.conditionalFiles[rawPath];

      if (condition != null && condition.trim().isNotEmpty) {
        final isEnabled = TemplateCondition.evaluate(condition, tmplContext);
        if (!isEnabled) {
          excludedFiles.add(rawPath);
          return;
        }
      }

      // 2. Check path overrides with path security validation
      var targetPath = rawPath;
      if (effectiveSchema.pathOverrides.containsKey(rawPath)) {
        final overrideTarget = effectiveSchema.pathOverrides[rawPath]!;
        targetPath = _validatePathOverride(rawPath, overrideTarget);
        activePathOverrides[rawPath] = targetPath;
      }

      includedFiles.add(targetPath);
    });

    return CustomizationPlan(
      templateId: resolvedTemplate.id,
      activePreset: presetName,
      compositionPlan: compositionPlan,
      schema: effectiveSchema,
      context: custContext,
      includedFiles: List.unmodifiable(includedFiles),
      excludedFiles: List.unmodifiable(excludedFiles),
      activePathOverrides: Map.unmodifiable(activePathOverrides),
    );
  }

  /// Transforms a customized [ResolvedTemplate] by applying file exclusions and path overrides in memory.
  ResolvedTemplate applyCustomizationToResolved({
    required ResolvedTemplate resolvedTemplate,
    required CustomizationPlan plan,
  }) {
    final customizedFiles = <String, String>{};
    final customizedProv = <String, String>{};
    final tmplContext = plan.context.toTemplateContext();
    final renderer = TemplateRenderer();

    resolvedTemplate.files.forEach((rawPath, content) {
      if (plan.excludedFiles.contains(rawPath)) return;

      final targetPath = plan.activePathOverrides[rawPath] ?? rawPath;
      final renderedPath = renderer.renderPath(targetPath, tmplContext);
      final renderedContent = renderer.renderText(content, tmplContext);

      customizedFiles[renderedPath] = renderedContent;
      customizedProv[renderedPath] =
          resolvedTemplate.fileProvenance[rawPath] ?? resolvedTemplate.id;
    });

    return ResolvedTemplate(
      baseTemplate: resolvedTemplate.baseTemplate,
      extensions: resolvedTemplate.extensions,
      effectiveManifest: resolvedTemplate.effectiveManifest,
      fileProvenance: Map.unmodifiable(customizedProv),
      files: Map.unmodifiable(customizedFiles),
    );
  }

  CustomizationSchema _extractSchemaFromManifest(ResolvedTemplate template) {
    final map = template.effectiveManifest.extraMetadata['customization'];
    if (map is Map<String, dynamic>) {
      return CustomizationSchema.fromMap(map);
    }
    return const CustomizationSchema();
  }

  String _validatePathOverride(String sourcePath, String targetPath) {
    final trimmed = targetPath.trim();
    if (trimmed.isEmpty) {
      throw CustomizationPathSecurityException(
          'Path override for "$sourcePath" cannot be empty.');
    }

    if (trimmed.startsWith('/') ||
        trimmed.startsWith('\\') ||
        RegExp(r'^[a-zA-Z]:').hasMatch(trimmed)) {
      throw CustomizationPathSecurityException(
          'Security error: Absolute path override "$trimmed" for "$sourcePath" is forbidden.');
    }

    if (trimmed.contains('../') ||
        trimmed.contains('..\\') ||
        trimmed == '..' ||
        trimmed.endsWith('/..') ||
        trimmed.endsWith('\\..')) {
      throw CustomizationPathSecurityException(
          'Security error: Path traversal ".." in override "$trimmed" is forbidden.');
    }

    var normalized = trimmed.replaceAll('\\', '/');
    while (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }
    return normalized;
  }
}
