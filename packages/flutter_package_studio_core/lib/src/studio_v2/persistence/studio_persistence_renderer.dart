/// Multi-format (Markdown Summary, JSON, ASCII Status) renderer for Phase 10.12: Workspace Persistence.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/persistence/studio_persistence_models.dart';

/// Formatter generating Markdown state summaries, ASCII project cards, and JSON persistence schemas.
class StudioPersistenceRenderer {
  /// Render project state as structured JSON.
  static String renderJson(StudioPersistentProjectState state, {bool pretty = true}) {
    final encoder = pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(state.toJson());
  }

  /// Render ASCII Project State status card.
  static String renderAsciiProjectCard(StudioPersistentProjectState state) {
    final buffer = StringBuffer();
    final cfg = state.configuration;

    buffer.writeln('┌────────────────────────────────────────────────────────┐');
    buffer.writeln('│ PERSISTENT STUDIO PROJECT: ${state.name.padRight(27)} │');
    buffer.writeln('├────────────────────────────────────────────────────────┤');
    buffer.writeln('│ Project ID:       ${state.projectId.padRight(36)} │');
    buffer.writeln('│ Active Section:   ${state.activeSection.padRight(36)} │');
    buffer.writeln('│ Selected Loader:  ${state.selectedLoaderId.padRight(36)} │');
    buffer.writeln('│ Selected Theme:   ${state.selectedThemeId.padRight(36)} │');
    buffer.writeln('│ Scene:            ${state.activeScene.name.padRight(36)} │');
    buffer.writeln('│ Presets Loaded:   ${state.presets.length.toString().padRight(36)} │');
    buffer.writeln('│ Last Saved:       ${state.lastSavedAt.toIso8601String().padRight(36)} │');
    buffer.writeln('├────────────────────────────────────────────────────────┤');
    buffer.writeln('│ Config: Speed ${cfg.animationSpeed}x | Particles ${cfg.particleCount} | Shaders ${cfg.shadersEnabled ? "ON" : "OFF"}  │');
    buffer.writeln('│ Actions: [Save State]  [Load Project]  [Export JSON]   │');
    buffer.writeln('└────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render project state as clean Markdown documentation.
  static String renderMarkdown(StudioPersistentProjectState state) {
    final buffer = StringBuffer();
    final cfg = state.configuration;

    buffer.writeln('# Studio Persistent Project State: ${state.name}');
    buffer.writeln();
    buffer.writeln('**Project ID:** `${state.projectId}`  ');
    buffer.writeln('**Active Navigation Section:** `${state.activeSection}`  ');
    buffer.writeln('**Selected Loader:** `${state.selectedLoaderId}`  ');
    buffer.writeln('**Selected Theme:** `${state.selectedThemeId}`  ');
    buffer.writeln('**Active Scene:** `${state.activeScene.name}` (`${state.activeScene.layers.length}` layers)  ');
    buffer.writeln('**Presets Bundled:** `${state.presets.length}`  ');
    buffer.writeln('**Last Saved:** ${state.lastSavedAt.toIso8601String()}');
    buffer.writeln();

    buffer.writeln('## Restored Parameter Snapshot');
    buffer.writeln();
    buffer.writeln('| Parameter | Value |');
    buffer.writeln('|---|---|');
    buffer.writeln('| **Animation Speed** | `${cfg.animationSpeed}x` |');
    buffer.writeln('| **Intensity** | `${cfg.intensity}` |');
    buffer.writeln('| **Scale** | `${cfg.scale}` |');
    buffer.writeln('| **Particle Count** | `${cfg.particleCount}` |');
    buffer.writeln('| **Gravity** | `${cfg.gravity}` |');
    buffer.writeln('| **Shaders** | `${cfg.shadersEnabled ? "Enabled" : "Disabled"}` |');
    buffer.writeln('| **Interactive** | `${cfg.isInteractive ? "Enabled" : "Disabled"}` |');
    buffer.writeln();

    return buffer.toString();
  }
}
