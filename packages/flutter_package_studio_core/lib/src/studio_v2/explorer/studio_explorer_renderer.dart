/// Multi-format (ASCII Cards, Markdown, JSON) renderer for Phase 10.3: Advanced Loader Explorer.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/explorer/studio_explorer_models.dart';

/// Renderer generating visual explorer cards, comparison matrices, and JSON schemas.
class StudioExplorerRenderer {
  /// Render loader list as structured JSON.
  static String renderJson(List<LoaderMetadataEntry> loaders,
      {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(loaders.map((l) => l.toJson()).toList());
  }

  /// Render individual loader card in ASCII text format as specified in Phase 10.3.
  static String renderLoaderCardAscii(LoaderMetadataEntry loader,
      {bool isFavorite = false}) {
    final buffer = StringBuffer();
    final fav = isFavorite ? '★ [FAVORITE]' : ' ';

    buffer
        .writeln('┌────────────────────────────────────────────────────────┐');
    buffer.writeln('│ ${loader.name.padRight(40)} ${fav.padLeft(12)} │');
    buffer
        .writeln('├────────────────────────────────────────────────────────┤');
    buffer.writeln(
        '│ Category:    ${loader.category.displayName.padRight(41)} │');
    buffer.writeln('│ Complexity:  ${loader.complexity.label.padRight(41)} │');
    buffer.writeln(
        '│ Particles:   ${(loader.hasParticles ? "✓ Enabled" : "✗ None").padRight(41)} │');
    buffer.writeln(
        '│ Physics:     ${(loader.hasPhysics ? "✓ Active" : "✗ None").padRight(41)} │');
    buffer.writeln(
        '│ Shaders:     ${(loader.hasShaders ? "✓ GPU Accelerated" : "✗ Standard Canvas").padRight(41)} │');
    buffer.writeln(
        '│ Interactive: ${(loader.isInteractive ? "✓ Gesture Enabled" : "✗ Static Loop").padRight(41)} │');
    buffer
        .writeln('├────────────────────────────────────────────────────────┤');
    buffer.writeln(
        '│ Actions: [Preview]  [Configure]  [Generate Code] [Export] │');
    buffer
        .writeln('└────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render catalog query results as a clean Markdown explorer table and card list.
  static String renderMarkdownCatalog(List<LoaderMetadataEntry> loaders,
      {Set<String> favorites = const {}}) {
    final buffer = StringBuffer();

    buffer.writeln('# Loader Explorer Catalog');
    buffer.writeln();
    buffer.writeln('Showing **${loaders.length}** discoverable loaders.');
    buffer.writeln();

    buffer.writeln(
        '| Loader Name | Category | Complexity | Particles | Physics | Shaders | Interactive | Favorite |');
    buffer.writeln('|---|---|:---:|:---:|:---:|:---:|:---:|:---:|');
    for (final l in loaders) {
      final isFav = favorites.contains(l.id) ? '★' : '☆';
      buffer.writeln(
          '| **${l.name}** (`${l.id}`) | ${l.category.displayName} | `${l.complexity.label}` | ${l.hasParticles ? "✓" : "—"} | ${l.hasPhysics ? "✓" : "—"} | ${l.hasShaders ? "✓" : "—"} | ${l.isInteractive ? "✓" : "—"} | $isFav |');
    }
    buffer.writeln();

    buffer.writeln('## Detailed Loader Cards');
    buffer.writeln();
    for (final l in loaders) {
      buffer.writeln('### ${l.name}');
      buffer.writeln('> ${l.description}');
      buffer.writeln();
      buffer.writeln('- **Category:** ${l.category.displayName}');
      buffer.writeln('- **Complexity:** `${l.complexity.label}`');
      buffer.writeln(
          '- **Supported Themes:** ${l.supportedThemes.map((t) => "`$t`").join(", ")}');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Render side-by-side comparison matrix between two loaders.
  static String renderComparisonMarkdown(
      Map<String, dynamic> comparisonResult) {
    if (comparisonResult.containsKey('error')) {
      return 'Error: ${comparisonResult["error"]}';
    }

    final a = comparisonResult['loader_a'] as Map<String, dynamic>;
    final b = comparisonResult['loader_b'] as Map<String, dynamic>;
    final buffer = StringBuffer();

    buffer.writeln('# Loader Comparison Matrix');
    buffer.writeln();
    buffer.writeln('| Feature / Capability | ${a["name"]} | ${b["name"]} |');
    buffer.writeln('|---|---|---|');
    buffer.writeln('| **Category** | ${a["category"]} | ${b["category"]} |');
    buffer.writeln(
        '| **Complexity** | ${a["complexity"]} | ${b["complexity"]} |');
    buffer.writeln(
        '| **Particles** | ${a["has_particles"] == true ? "✓" : "—"} | ${b["has_particles"] == true ? "✓" : "—"} |');
    buffer.writeln(
        '| **Physics** | ${a["has_physics"] == true ? "✓" : "—"} | ${b["has_physics"] == true ? "✓" : "—"} |');
    buffer.writeln(
        '| **Shaders** | ${a["has_shaders"] == true ? "✓" : "—"} | ${b["has_shaders"] == true ? "✓" : "—"} |');
    buffer.writeln(
        '| **Interactive** | ${a["is_interactive"] == true ? "✓" : "—"} | ${b["is_interactive"] == true ? "✓" : "—"} |');
    buffer.writeln();

    return buffer.toString();
  }
}
