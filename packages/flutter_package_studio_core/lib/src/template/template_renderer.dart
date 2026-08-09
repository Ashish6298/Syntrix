import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/template/template_context.dart';

/// Deterministic placeholder renderer substituting `{{key}}` variables in text and file paths.
class TemplateRenderer {
  static final RegExp _placeholderRegExp = RegExp(r'\{\{([a-zA-Z0-9_]+)\}\}');

  /// Renders [templateText] replacing placeholders with values from [context].
  /// Throws [TemplateException] if [strict] is true and an unknown placeholder is found.
  String renderText(
    String templateText,
    TemplateContext context, {
    bool strict = false,
  }) {
    if (templateText.isEmpty) return templateText;

    return templateText.replaceAllMapped(_placeholderRegExp, (match) {
      final key = match.group(1)!;
      if (context.contains(key)) {
        final val = context.get(key);
        if (val is List) {
          return val.join(', ');
        }
        return val?.toString() ?? '';
      }
      if (strict) {
        throw TemplateException(
          'Template rendering failure: Unknown placeholder "{{$key}}" encountered.',
        );
      }
      return match.group(0)!; // Leave unrendered if not strict
    });
  }

  /// Renders file path string, replacing placeholders (e.g. `lib/src/{{package_name}}.dart`).
  String renderPath(String pathTemplate, TemplateContext context) {
    return renderText(pathTemplate, context, strict: true);
  }
}
