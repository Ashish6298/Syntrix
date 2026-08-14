import 'package:flutter_package_studio_core/src/compatibility/compatibility_evaluator.dart';
import 'package:flutter_package_studio_core/src/compatibility/compatibility_result.dart';
import 'package:flutter_package_studio_core/src/compatibility/sdk_environment.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/template/composition/composition_layer.dart';
import 'package:flutter_package_studio_core/src/template/composition/composition_plan.dart';
import 'package:flutter_package_studio_core/src/template/composition/composition_provenance.dart';
import 'package:flutter_package_studio_core/src/template/composition/composition_request.dart';
import 'package:flutter_package_studio_core/src/template/resolved_template.dart';
import 'package:flutter_package_studio_core/src/template/template_composition.dart';
import 'package:flutter_package_studio_core/src/template/template_dependency.dart';
import 'package:flutter_package_studio_core/src/template/template_manifest.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';
import 'package:flutter_package_studio_core/src/template/template_registry.dart';

/// Advanced, deterministic template composition engine.
///
/// [EnhancedCompositionEngine] combines a base template with multiple feature
/// extensions and dependencies in memory, verifying security path boundaries,
/// executing compatibility checks, resolving file collisions, and maintaining
/// complete file provenance.
class EnhancedCompositionEngine {
  final Logger _logger = Logger('EnhancedCompositionEngine');

  /// Executes composition according to [request] using [registry] and optional [environment].
  CompositionPlan composePlan({
    required CompositionRequest request,
    required TemplateRegistry registry,
    SdkEnvironment environment = MockSdkEnvironment.standard,
  }) {
    _logger.info('Starting composition plan: ${request.baseTemplateId}');

    // 1. Evaluate base template compatibility & selection
    final evaluator = CompatibilityEvaluator(
      environment: environment,
      policy: request.compatibilityPolicy,
    );

    final baseTemplate = evaluator.selectBestCompatibleVersion(
      request.baseTemplateId,
      registry,
      versionConstraint: request.baseVersionConstraint,
      requiredProjectType: request.targetProjectType,
      requiredCapabilities: request.requiredCapabilities,
    );

    if (baseTemplate == null) {
      if (!registry.contains(request.baseTemplateId)) {
        throw TemplateException(
            'Base template "${request.baseTemplateId}" not found in registry.');
      }
      throw CompatibilityException(
          'Base template "${request.baseTemplateId}" (${request.baseVersionConstraint}) '
          'is incompatible with environment.');
    }

    // 2. Select compatible feature extensions
    final extensionTemplates = <Template>[];
    for (final extId in request.extensionIds) {
      final ext = evaluator.selectBestCompatibleVersion(
        extId,
        registry,
      );
      if (ext == null) {
        if (!registry.contains(extId)) {
          throw TemplateException(
              'Extension template "$extId" not found in registry.');
        }
        throw CompatibilityException(
            'Extension template "$extId" is incompatible with environment.');
      }
      extensionTemplates.add(ext);
    }

    // 3. Resolve dependencies (topological sort)
    final allAvailable = <String, List<Template>>{};
    for (final t in registry.listAll()) {
      allAvailable.putIfAbsent(t.id, () => []).add(t);
    }

    final solvedDependencies = TemplateDependencySolver.solve(
      root: baseTemplate,
      availableTemplates: allAvailable,
    );

    // 4. Build deterministic composition layers (Base = Layer 0, Extensions/Deps = Layer 1..N)
    final layers = <CompositionLayer>[];
    final addedIds = <String>{};

    int layerIdx = 0;
    // Add base template first
    layers.add(CompositionLayer(
      layerIndex: layerIdx++,
      template: baseTemplate,
      layerType: LayerType.base,
    ));
    addedIds.add(baseTemplate.id);

    // Add resolved dependencies (excluding base if present)
    for (final dep in solvedDependencies) {
      if (!addedIds.contains(dep.id)) {
        layers.add(CompositionLayer(
          layerIndex: layerIdx++,
          template: dep,
          layerType: LayerType.dependency,
        ));
        addedIds.add(dep.id);
      }
    }

    // Add feature extensions
    for (final ext in extensionTemplates) {
      if (!addedIds.contains(ext.id)) {
        layers.add(CompositionLayer(
          layerIndex: layerIdx++,
          template: ext,
          layerType: LayerType.extension,
        ));
        addedIds.add(ext.id);
      }
    }

    // 5. Evaluate compatibility for all layers
    final compatResults = <CompatibilityResult>[];
    for (final layer in layers) {
      final res =
          evaluator.evaluate(layer.template, availableTemplates: registry);
      compatResults.add(res);
      if (!res.isCompatible) {
        throw CompatibilityException(
            'Layer "${layer.templateId}" is incompatible: ${res.errors.first.message}');
      }
    }

    // 6. Compose file assets with path security & collision resolution
    final fileMap = <String, String>{};
    final fileProvenanceMap = <String, String>{};
    final provenanceRecords = <FileProvenanceRecord>[];
    final conflicts = <CompositionConflict>[];
    final layerMap = <String, CompositionLayer>{};

    for (final layer in layers) {
      final tmpl = layer.template;
      tmpl.fileTemplates.forEach((rawPath, content) {
        // Enforce path sanitization & traversal security
        final path = _sanitizeAndValidatePath(rawPath);

        if (fileMap.containsKey(path)) {
          final existingLayer = layerMap[path]!;
          final conflict = CompositionConflict(
            path: path,
            existingSourceId: existingLayer.templateId,
            existingLayerIndex: existingLayer.layerIndex,
            incomingSourceId: layer.templateId,
            incomingLayerIndex: layer.layerIndex,
            resolutionPolicy: request.conflictPolicy,
          );
          conflicts.add(conflict);

          if (request.conflictPolicy == OverrideStrategy.fail) {
            throw CompositionConflictException(
              'Composition collision at "$path": incoming "${layer.templateId}" '
              '[Layer #${layer.layerIndex}] conflicts with existing "${existingLayer.templateId}" '
              '[Layer #${existingLayer.layerIndex}].',
            );
          } else if (request.conflictPolicy == OverrideStrategy.skip) {
            provenanceRecords.add(FileProvenanceRecord(
              path: path,
              sourceTemplateId: existingLayer.templateId,
              sourceVersion: existingLayer.version,
              layerIndex: existingLayer.layerIndex,
              action: 'skipped',
              overriddenTemplateId: layer.templateId,
            ));
            return;
          } else if (request.conflictPolicy == OverrideStrategy.override) {
            provenanceRecords.add(FileProvenanceRecord(
              path: path,
              sourceTemplateId: layer.templateId,
              sourceVersion: layer.version,
              layerIndex: layer.layerIndex,
              action: 'overridden',
              overriddenTemplateId: existingLayer.templateId,
            ));
          }
        } else {
          provenanceRecords.add(FileProvenanceRecord(
            path: path,
            sourceTemplateId: layer.templateId,
            sourceVersion: layer.version,
            layerIndex: layer.layerIndex,
            action: 'created',
          ));
        }

        fileMap[path] = content;
        fileProvenanceMap[path] = layer.templateId;
        layerMap[path] = layer;
      });
    }

    // 7. Aggregate effective manifest
    final effectiveManifest =
        _aggregateManifests(baseTemplate.manifest, layers);

    final resolvedTemplate = ResolvedTemplate(
      baseTemplate: baseTemplate,
      extensions: extensionTemplates,
      effectiveManifest: effectiveManifest,
      fileProvenance: fileProvenanceMap,
      files: Map.unmodifiable(fileMap),
    );

    return CompositionPlan(
      baseTemplateId: baseTemplate.id,
      layers: List.unmodifiable(layers),
      resolvedTemplate: resolvedTemplate,
      provenanceRecords: List.unmodifiable(provenanceRecords),
      conflicts: List.unmodifiable(conflicts),
      compatibilityResults: List.unmodifiable(compatResults),
      conflictPolicy: request.conflictPolicy,
    );
  }

  String _sanitizeAndValidatePath(String pathStr) {
    final trimmed = pathStr.trim();
    if (trimmed.isEmpty) {
      throw PathSecurityException('File template path cannot be empty.');
    }

    // Reject absolute paths
    if (trimmed.startsWith('/') ||
        trimmed.startsWith('\\') ||
        RegExp(r'^[a-zA-Z]:').hasMatch(trimmed)) {
      throw PathSecurityException(
          'Security error: Absolute path "$trimmed" is forbidden in template composition.');
    }

    // Reject path traversal
    if (trimmed.contains('../') ||
        trimmed.contains('..\\') ||
        trimmed == '..' ||
        trimmed.endsWith('/..') ||
        trimmed.endsWith('\\..')) {
      throw PathSecurityException(
          'Security error: Path traversal ".." in "$trimmed" is forbidden.');
    }

    // Normalize separators to forward slashes and strip leading ./
    var normalized = trimmed.replaceAll('\\', '/');
    while (normalized.startsWith('./')) {
      normalized = normalized.substring(2);
    }

    if (normalized.isEmpty) {
      throw PathSecurityException('Invalid relative path "$pathStr".');
    }

    return normalized;
  }

  TemplateManifest _aggregateManifests(
    TemplateManifest base,
    List<CompositionLayer> layers,
  ) {
    final combinedVars =
        Map<String, TemplateVariableDefinition>.from(base.variables);
    final combinedDirs = Set<String>.from(base.directories);
    final combinedPlatforms = Set<String>.from(base.supportedPlatforms);
    final combinedCapabilities = Set<String>.from(base.capabilities);
    final combinedTags = Set<String>.from(base.tags);

    for (final layer in layers.skip(1)) {
      final m = layer.template.manifest;
      combinedVars.addAll(m.variables);
      combinedDirs.addAll(m.directories);
      combinedPlatforms.addAll(m.supportedPlatforms);
      combinedCapabilities.addAll(m.capabilities);
      combinedTags.addAll(m.tags);
    }

    return TemplateManifest(
      id: base.id,
      name: base.name,
      displayName: base.displayName,
      description: base.description,
      version: base.version,
      projectType: base.projectType,
      minimumDartSdk: base.minimumDartSdk,
      minimumFlutterSdk: base.minimumFlutterSdk,
      supportedPlatforms: combinedPlatforms.toList(),
      variables: combinedVars,
      directories: combinedDirs.toList(),
      files: base.files,
      binaryAssets: base.binaryAssets,
      conditions: base.conditions,
      extraMetadata: base.extraMetadata,
      dependencies: base.dependencies,
      capabilities: combinedCapabilities.toList(),
      tags: combinedTags.toList(),
    );
  }
}
