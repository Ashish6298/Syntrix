import 'package:flutter_package_studio_core/src/template/template_context.dart';

/// Safe evaluator determining whether a conditional template file or directory should be generated.
class TemplateCondition {
  /// Evaluates [condition] string against [context].
  /// Supports variable existence, boolean flags (e.g. `is_flutter`, `!is_dart`), and equality (`key==val`).
  static bool evaluate(String condition, TemplateContext context) {
    final trimmed = condition.trim();
    if (trimmed.isEmpty) return true;

    // Negated flag
    if (trimmed.startsWith('!')) {
      final key = trimmed.substring(1).trim();
      return !evaluate(key, context);
    }

    // Equality expression (e.g. `project_type == flutter_package`)
    if (trimmed.contains('==')) {
      final parts = trimmed.split('==').map((s) => s.trim()).toList();
      final key = parts[0];
      final expected = parts[1];
      final val = context.get(key)?.toString();
      return val == expected;
    }

    // Inequality expression (e.g. `project_type != dart_package`)
    if (trimmed.contains('!=')) {
      final parts = trimmed.split('!=').map((s) => s.trim()).toList();
      final key = parts[0];
      final expected = parts[1];
      final val = context.get(key)?.toString();
      return val != expected;
    }

    // Boolean key lookup
    if (context.contains(trimmed)) {
      final val = context.get(trimmed);
      if (val is bool) return val;
      if (val is String) return val.toLowerCase() == 'true';
      return val != null;
    }

    return false;
  }
}
