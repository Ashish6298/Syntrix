/// Multi-format (ASCII Preset Tree, Markdown, JSON) renderer for Phase 10.11: Configuration Preset System.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/presets/studio_preset_models.dart';

/// Formatter generating ASCII Preset trees, Markdown preset tables, and JSON export schemas.
class StudioPresetRenderer {
  /// Render preset array as structured JSON.
  static String renderJson(List<StudioConfigurationPreset> presets, {bool pretty = true}) {
    final encoder = pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(presets.map((p) => p.toJson()).toList());
  }

  /// Render an individual preset as ASCII hierarchy tree exactly as specified in Phase 10.11.
  static String renderAsciiPresetTree(StudioConfigurationPreset preset) {
    final buffer = StringBuffer();
    final cfg = preset.configuration;

    buffer.writeln('Preset: ${preset.name} (${preset.presetId})');
    buffer.writeln('├── Loader:      ${preset.targetLoaderId}');
    buffer.writeln('├── Theme:       ${preset.selectedThemeId}');
    buffer.writeln('├── Animation:   Speed ${cfg.animationSpeed}x, Intensity ${cfg.intensity}, Scale ${cfg.scale}x');
    buffer.writeln('├── Particles:   Count ${cfg.particleCount}, Size ${cfg.particleSize}, Opacity ${cfg.particleOpacity}');
    buffer.writeln('├── Physics:     Gravity ${cfg.gravity}, Velocity ${cfg.velocity}');
    buffer.writeln('├── Rendering:   Shaders ${cfg.shadersEnabled ? "ON" : "OFF"}');
    buffer.writeln('└── Interaction: Gestures ${cfg.isInteractive ? "ON" : "OFF"}');

    return buffer.toString();
  }

  /// Render full preset library as clean Markdown documentation.
  static String renderMarkdownCatalog(List<StudioConfigurationPreset> presets) {
    final buffer = StringBuffer();

    buffer.writeln('# Studio Configuration Presets');
    buffer.writeln();
    buffer.writeln('Showing **${presets.length}** saved configuration presets.');
    buffer.writeln();

    buffer.writeln('| Preset Name | ID | Loader | Theme | Particles | Speed | Type |');
    buffer.writeln('|---|---|---|---|:---:|:---:|:---:|');
    for (final p in presets) {
      buffer.writeln('| **${p.name}** | `${p.presetId}` | `${p.targetLoaderId}` | `${p.selectedThemeId}` | `${p.configuration.particleCount}` | `${p.configuration.animationSpeed}x` | ${p.isBuiltIn ? "Built-in" : "User"} |');
    }
    buffer.writeln();

    buffer.writeln('## Preset Tree Representations');
    buffer.writeln();
    for (final p in presets) {
      buffer.writeln('```text');
      buffer.writeln(renderAsciiPresetTree(p));
      buffer.writeln('```');
      buffer.writeln();
    }

    return buffer.toString();
  }
}
