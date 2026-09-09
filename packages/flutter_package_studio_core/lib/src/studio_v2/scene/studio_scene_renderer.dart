/// Multi-format (ASCII Layer Trees, Markdown, JSON) renderer for Phase 10.7: Scene Builder.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/scene/studio_scene_models.dart';
import 'package:flutter_package_studio_core/src/studio_v2/scene/studio_scene_engine.dart';

/// Formatter generating ASCII scene layer trees, Markdown hierarchy summaries, and JSON schemas.
class StudioSceneRenderer {
  /// Render scene as structured JSON.
  static String renderJson(VisualSceneDescriptor scene, {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(scene.toJson());
  }

  /// Render ASCII Scene Layer Tree exactly as specified in Milestone 10.7 mockup.
  static String renderAsciiSceneTree(VisualSceneDescriptor scene) {
    final buffer = StringBuffer();

    buffer.writeln(
        'Scene: ${scene.name} (${scene.width.toInt()}x${scene.height.toInt()})');
    final count = scene.layers.length;

    for (int i = 0; i < count; i++) {
      final layer = scene.layers[i];
      final isLast = (i == count - 1);
      final branch = isLast ? '└──' : '├──';
      final vis = layer.isVisible ? '✓' : '✗';

      buffer.writeln(
          '$branch ${layer.name} [z:${layer.zIndex}, op:${layer.opacity.toStringAsFixed(2)}, vis:$vis]');
      final indent = isLast ? '    ' : '│   ';
      buffer.writeln(
          '$indent└── Ref: ${layer.componentReference} (${layer.layerType.displayName})');
    }

    return buffer.toString();
  }

  /// Render scene hierarchy as clean Markdown documentation.
  static String renderMarkdown(
      VisualSceneDescriptor scene, StudioSceneBuilderEngine engine) {
    final buffer = StringBuffer();

    buffer.writeln('# Visual Scene Builder: ${scene.name}');
    buffer.writeln();
    buffer.writeln('**Scene ID:** `${scene.sceneId}`  ');
    buffer.writeln('**Dimensions:** `${scene.width} x ${scene.height}`  ');
    buffer.writeln('**Total Layers:** `${scene.layers.length}`  ');
    buffer.writeln('**Last Updated:** ${scene.updatedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Layer Hierarchy');
    buffer.writeln();
    buffer.writeln(
        '| Z-Index | Layer Name | Type | Component Reference | Opacity | Visible |');
    buffer.writeln('|:---:|---|---|---|:---:|:---:|');
    for (final l in scene.layers) {
      buffer.writeln(
          '| `${l.zIndex}` | **${l.name}** | `${l.layerType.displayName}` | `${l.componentReference}` | `${(l.opacity * 100).toInt()}%` | ${l.isVisible ? "✓" : "✗"} |');
    }
    buffer.writeln();

    buffer.writeln('## Generated Flutter Composition Code');
    buffer.writeln();
    buffer.writeln('```dart');
    buffer.writeln(engine.generateSceneFlutterCode());
    buffer.writeln('```');
    buffer.writeln();

    return buffer.toString();
  }
}
