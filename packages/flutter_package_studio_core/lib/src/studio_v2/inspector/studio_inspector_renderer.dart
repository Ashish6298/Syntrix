/// Multi-format (ASCII Sliders, Markdown, JSON) renderer for Phase 10.4: Visual Configuration Inspector.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/inspector/studio_inspector_models.dart';
import 'package:flutter_package_studio_core/src/studio_v2/inspector/studio_inspector_engine.dart';

/// Formatter generating ASCII slider controls, Markdown property sheets, and JSON schemas.
class StudioInspectorRenderer {
  /// Render inspector values as structured JSON.
  static String renderJson(StudioInspectorEngine engine, {bool pretty = true}) {
    final values = <String, dynamic>{};
    for (final prop in engine.schema.properties) {
      values[prop.propertyKey] = engine.getPropertyValue(prop.propertyKey);
    }
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(values);
  }

  /// Render an ASCII visual inspector control panel exactly as specified in Milestone 10.4.
  static String renderAsciiInspector(StudioInspectorEngine engine) {
    final buffer = StringBuffer();

    buffer
        .writeln('┌────────────────────────────────────────────────────────┐');
    buffer
        .writeln('│           VISUAL CONFIGURATION INSPECTOR               │');
    buffer
        .writeln('├────────────────────────────────────────────────────────┤');

    for (final category in InspectorPropertyCategory.values) {
      final props = engine.schema.getPropertiesByCategory(category);
      if (props.isEmpty) continue;

      buffer.writeln('│ ${category.displayName.padRight(54)} │');
      buffer.writeln(
          '│ ────────────────────────────────────────────────────── │');

      for (final p in props) {
        final val = engine.getPropertyValue(p.propertyKey);

        if (p.controlType == InspectorControlType.slider &&
            p.minValue != null &&
            p.maxValue != null) {
          final sliderTrack =
              _renderSliderTrack(val as num, p.minValue!, p.maxValue!);
          buffer.writeln(
              '│ ${p.label.padRight(12)} $sliderTrack  ${val.toStringAsFixed(1).padLeft(5)} │');
        } else if (p.controlType == InspectorControlType.toggleSwitch) {
          final toggle = (val == true) ? '[ON ]' : '[OFF]';
          buffer
              .writeln('│ ${p.label.padRight(12)} $toggle${"".padRight(28)} │');
        } else {
          buffer.writeln(
              '│ ${p.label.padRight(12)} [${val.toString().padRight(20)}]${"".padRight(11)} │');
        }
      }
      buffer.writeln(
          '│                                                        │');
    }

    buffer
        .writeln('└────────────────────────────────────────────────────────┘');
    return buffer.toString();
  }

  static String _renderSliderTrack(num current, double min, double max,
      {int length = 20}) {
    if (max <= min) return '─────●──────────────';
    final fraction = ((current - min) / (max - min)).clamp(0.0, 1.0);
    final dotPos = (fraction * (length - 1)).round();

    final track = List<String>.filled(length, '─');
    track[dotPos] = '●';
    return track.join('');
  }

  /// Render property sheet as clean Markdown documentation.
  static String renderMarkdown(StudioInspectorEngine engine) {
    final buffer = StringBuffer();

    buffer.writeln('# Visual Configuration Inspector');
    buffer.writeln();
    buffer.writeln(
        'Interactive property controls bound to active Studio v2 preview.');
    buffer.writeln();

    for (final category in InspectorPropertyCategory.values) {
      final props = engine.schema.getPropertiesByCategory(category);
      if (props.isEmpty) continue;

      buffer.writeln('## ${category.displayName}');
      buffer.writeln();
      buffer.writeln(
          '| Property | Control | Value | Bounds / Step | Description |');
      buffer.writeln('|---|:---:|:---:|:---:|---|');

      for (final p in props) {
        final val = engine.getPropertyValue(p.propertyKey);
        final bounds = (p.minValue != null && p.maxValue != null)
            ? '${p.minValue} - ${p.maxValue} (step ${p.step ?? 1})'
            : '—';
        buffer.writeln(
            '| **${p.label}** (`${p.propertyKey}`) | `${p.controlType.id}` | `${val}` | $bounds | ${p.description} |');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
