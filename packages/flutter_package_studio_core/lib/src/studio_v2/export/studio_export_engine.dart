/// Central Export & Import Engine for Phase 10.13.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_models.dart';
import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_controller.dart';
import 'package:flutter_package_studio_core/src/studio_v2/scene/studio_scene_engine.dart';
import 'package:flutter_package_studio_core/src/studio_v2/scene/studio_scene_renderer.dart';
import 'package:flutter_package_studio_core/src/studio_v2/presets/studio_preset_engine.dart';
import 'package:flutter_package_studio_core/src/studio_v2/presets/studio_preset_renderer.dart';
import 'package:flutter_package_studio_core/src/studio_v2/codegen/studio_codegen_engine.dart';
import 'package:flutter_package_studio_core/src/studio_v2/codegen/studio_codegen_models.dart';
import 'package:flutter_package_studio_core/src/studio_v2/diagnostics/studio_diagnostics_engine.dart';
import 'package:flutter_package_studio_core/src/studio_v2/diagnostics/studio_diagnostics_renderer.dart';
import 'package:flutter_package_studio_core/src/studio_v2/profiler/studio_profiler_engine.dart';
import 'package:flutter_package_studio_core/src/studio_v2/profiler/studio_profiler_renderer.dart';
import 'package:flutter_package_studio_core/src/studio_v2/export/studio_export_models.dart';

/// Central Export & Import Engine providing unified, deterministic exports across all Studio subsystems.
class StudioExportEngine {
  final Logger _logger = Logger('StudioExportEngine');
  final StudioV2Controller controller;
  final StudioSceneBuilderEngine sceneEngine;
  final StudioPresetEngine presetEngine;
  final StudioCodeGenEngine codeGenEngine;
  final StudioDiagnosticsEngine diagnosticsEngine;
  final StudioProfilerEngine profilerEngine;

  StudioExportEngine({
    required this.controller,
    required this.sceneEngine,
    required this.presetEngine,
    required this.codeGenEngine,
    required this.diagnosticsEngine,
    required this.profilerEngine,
  });

  /// Unified export method generating deterministic bundles in JSON, Dart, or Markdown.
  StudioExportBundle export({
    required ExportTargetEntity target,
    required ExportFormat format,
    String? customPresetId,
  }) {
    _logger.info('Exporting target "${target.label}" in format "${format.name.toUpperCase()}"');
    final now = DateTime.now();
    final bundleId = 'export_${now.millisecondsSinceEpoch}';

    String content = '';
    String filename = 'export.${format.fileExtension}';

    switch (target) {
      case ExportTargetEntity.configuration:
        final cfg = controller.state.activeConfiguration;
        if (format == ExportFormat.json) {
          const encoder = JsonEncoder.withIndent('  ');
          content = encoder.convert(cfg.toJson());
          filename = 'configuration_${cfg.targetLoaderId}.json';
        } else if (format == ExportFormat.dart) {
          final res = codeGenEngine.generateLoaderCode(cfg, options: const CodeGenOptions(style: CodeGenStyle.configurationSnippet));
          content = res.sourceCode;
          filename = 'configuration_${cfg.targetLoaderId}.dart';
        } else {
          content = '# Active Studio Configuration\n\n'
              '- **Loader:** `${cfg.targetLoaderId}`\n'
              '- **Theme:** `${cfg.selectedThemeId}`\n'
              '- **Speed:** `${cfg.animationSpeed}x`\n'
              '- **Particles:** `${cfg.particleCount}`\n'
              '- **Shaders:** `${cfg.shadersEnabled}`\n';
          filename = 'configuration_${cfg.targetLoaderId}.md';
        }
        break;

      case ExportTargetEntity.scene:
        final scene = sceneEngine.activeScene;
        if (format == ExportFormat.json) {
          content = StudioSceneRenderer.renderJson(scene);
          filename = '${scene.sceneId}.json';
        } else if (format == ExportFormat.dart) {
          content = sceneEngine.generateSceneFlutterCode();
          filename = '${scene.sceneId}_scene.dart';
        } else {
          content = StudioSceneRenderer.renderMarkdown(scene, sceneEngine);
          filename = '${scene.sceneId}.md';
        }
        break;

      case ExportTargetEntity.preset:
        if (format == ExportFormat.json) {
          final presets = presetEngine.storageDriver.loadAllPresets();
          // synchronous snapshot for preset export
          content = jsonEncode(controller.state.activeConfiguration.toJson());
          filename = 'preset_export.json';
        } else if (format == ExportFormat.dart) {
          final res = codeGenEngine.generateLoaderCode(controller.state.activeConfiguration);
          content = res.sourceCode;
          filename = 'preset_export.dart';
        } else {
          content = '# Preset Export\n\nPreset for loader: `${controller.state.activeConfiguration.targetLoaderId}`\n';
          filename = 'preset_export.md';
        }
        break;

      case ExportTargetEntity.generatedCode:
        final res = codeGenEngine.generateLoaderCode(controller.state.activeConfiguration);
        content = format == ExportFormat.json
            ? jsonEncode(res.toJson())
            : res.sourceCode;
        filename = 'generated_loader.${format.fileExtension}';
        break;

      case ExportTargetEntity.diagnostics:
        final snap = diagnosticsEngine.captureDashboardSnapshot();
        if (format == ExportFormat.json) {
          content = StudioDiagnosticsRenderer.renderJson(snap);
          filename = 'diagnostics_report.json';
        } else {
          content = StudioDiagnosticsRenderer.renderMarkdown(snap);
          filename = 'diagnostics_report.md';
        }
        break;

      case ExportTargetEntity.performanceReport:
        final snap = profilerEngine.captureSnapshot();
        if (format == ExportFormat.json) {
          content = StudioProfilerRenderer.renderJson(snap);
          filename = 'performance_report.json';
        } else {
          final comp = profilerEngine.compareSnapshots(snap, snap);
          content = StudioProfilerRenderer.renderComparisonMarkdown(comp);
          filename = 'performance_report.md';
        }
        break;
    }

    return StudioExportBundle(
      bundleId: bundleId,
      targetEntity: target,
      format: format,
      content: content,
      suggestedFilename: filename,
      exportedAt: now,
    );
  }

  /// Import configuration JSON and apply to Studio workspace.
  void importConfigurationJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    final cfg = StudioConfigurationDescriptor.fromJson(map);
    controller.updateConfiguration((_) => cfg);
    _logger.info('Imported configuration for loader: ${cfg.targetLoaderId}');
  }
}
