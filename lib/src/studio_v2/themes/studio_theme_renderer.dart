/// Multi-format (ASCII Palette Cards, Markdown, JSON) renderer for Phase 10.6: Theme Studio.
library;

import 'dart:convert';
import 'package:syntrix/src/studio_v2/themes/studio_theme_models.dart';
import 'package:syntrix/src/studio_v2/themes/studio_theme_engine.dart';

/// Formatter generating ASCII visual theme palettes, comparison sheets, and JSON schemas.
class StudioThemeRenderer {
  /// Render theme list as structured JSON.
  static String renderJson(List<StudioThemeDescriptor> themes,
      {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(themes.map((t) => t.toJson()).toList());
  }

  /// Render ASCII visual theme card with color swatch preview.
  static String renderThemeCardAscii(StudioThemeDescriptor theme,
      {bool isActive = false}) {
    final buffer = StringBuffer();
    final activeTag = isActive ? '★ [ACTIVE]' : ' ';

    buffer
        .writeln('┌────────────────────────────────────────────────────────┐');
    buffer.writeln('│ ${theme.name.padRight(40)} ${activeTag.padLeft(12)} │');
    buffer
        .writeln('├────────────────────────────────────────────────────────┤');
    buffer.writeln('│ Background:  ${theme.backgroundColor.padRight(41)} │');
    buffer.writeln('│ Glow Color:  ${theme.particleGlowColor.padRight(41)} │');
    buffer
        .writeln('│ Palette Swatch:                                        │');
    final swatch = theme.palette
        .map((c) => '[${c.role.substring(0, 3).toUpperCase()}: ${c.hex}]')
        .join(' ');
    buffer.writeln('│ ${swatch.padRight(54)} │');
    buffer
        .writeln('├────────────────────────────────────────────────────────┤');
    buffer.writeln(
        '│ Loaders: ${theme.supportedLoaderIds.length} supported | Custom Theme: ${(theme.isCustom ? "Yes" : "Built-in").padRight(16)} │');
    buffer
        .writeln('│ Actions: [Apply]  [Customize]  [Duplicate]  [Gen Code] │');
    buffer
        .writeln('└────────────────────────────────────────────────────────┘');

    return buffer.toString();
  }

  /// Render full theme browser catalog as clean Markdown documentation.
  static String renderMarkdownCatalog(
      List<StudioThemeDescriptor> themes, StudioThemeEngine engine) {
    final buffer = StringBuffer();

    buffer.writeln('# Theme & Visual System Studio Catalog');
    buffer.writeln();
    buffer.writeln('Explore all **${themes.length}** visual theme presets.');
    buffer.writeln();

    buffer.writeln(
        '| Theme Name | ID | Background | Glow Color | Palette Roles | Custom |');
    buffer.writeln('|---|---|:---:|:---:|---|:---:|');
    for (final t in themes) {
      final roles = t.palette.map((c) => '`${c.role}`').join(', ');
      buffer.writeln(
          '| **${t.name}** | `${t.id}` | `${t.backgroundColor}` | `${t.particleGlowColor}` | $roles | ${t.isCustom ? "Yes" : "Built-in"} |');
    }
    buffer.writeln();

    buffer.writeln('## Theme Details & Generated Code Sample');
    buffer.writeln();
    for (final t in themes.take(2)) {
      buffer.writeln('### ${t.name} (`${t.id}`)');
      buffer.writeln('> ${t.description}');
      buffer.writeln();
      buffer.writeln('```dart');
      buffer.writeln(engine.generateThemeCode(t.id));
      buffer.writeln('```');
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Render comparison between two themes as Markdown.
  static String renderComparisonMarkdown(Map<String, dynamic> comp) {
    if (comp.containsKey('error')) return 'Error: ${comp["error"]}';

    final a = comp['theme_a'] as Map<String, dynamic>;
    final b = comp['theme_b'] as Map<String, dynamic>;
    final buffer = StringBuffer();

    buffer.writeln('# Theme Comparison Matrix');
    buffer.writeln();
    buffer.writeln('| Property | ${a["name"]} | ${b["name"]} |');
    buffer.writeln('|---|---|---|');
    buffer.writeln(
        '| **Background** | `${a["background_color"]}` | `${b["background_color"]}` |');
    buffer.writeln(
        '| **Particle Glow** | `${a["particle_glow_color"]}` | `${b["particle_glow_color"]}` |');
    buffer.writeln(
        '| **Particle Size** | `${a["default_particle_size"]}` | `${b["default_particle_size"]}` |');
    buffer.writeln(
        '| **Particle Opacity** | `${a["default_particle_opacity"]}` | `${b["default_particle_opacity"]}` |');
    buffer.writeln();

    return buffer.toString();
  }
}
