import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/template/customization/customization_schema.dart';
import 'package:flutter_package_studio_core/src/template/template_context.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_context.dart';

/// Resolved customization context holding finalized variable values.
///
/// Precedence Order (lowest to highest):
/// 1. Parameter default values
/// 2. Active Preset variable values
/// 3. User explicit input variable values
class CustomizationContext {
  final Map<String, dynamic> _resolvedValues;
  final CustomizationSchema schema;
  final String? activePresetName;

  CustomizationContext._({
    required Map<String, dynamic> resolvedValues,
    required this.schema,
    this.activePresetName,
  }) : _resolvedValues = Map.unmodifiable(resolvedValues);

  /// Resolves a [CustomizationContext] given [schema], optional [presetName], and [userValues].
  factory CustomizationContext.resolve({
    required CustomizationSchema schema,
    String? presetName,
    Map<String, dynamic> userValues = const {},
  }) {
    final finalValues = <String, dynamic>{};

    // 1. Parameter defaults
    schema.parameters.forEach((key, param) {
      if (param.defaultValue != null) {
        finalValues[key] = param.defaultValue;
      }
    });

    // 2. Preset values
    if (presetName != null && presetName.trim().isNotEmpty) {
      final presetKey = presetName.trim().toLowerCase();
      final preset = schema.presets[presetKey];
      if (preset == null) {
        throw CustomizationValidationException(
            'Unknown customization preset "$presetName". Available: [${schema.presets.keys.join(', ')}].');
      }
      preset.variables.forEach((key, value) {
        finalValues[key] = value;
      });
    }

    // 3. User explicit inputs
    userValues.forEach((key, value) {
      finalValues[key] = value;
    });

    // 4. Coerce & validate against schema parameters
    final validatedMap = <String, dynamic>{};
    schema.parameters.forEach((key, param) {
      final raw = finalValues[key];
      final coerced = param.coerceAndValidate(raw);
      if (coerced != null) {
        validatedMap[key] = coerced;
      }
    });

    // Keep non-schema extra user values as well
    userValues.forEach((k, v) {
      if (!validatedMap.containsKey(k)) {
        validatedMap[k] = v;
      }
    });

    return CustomizationContext._(
      resolvedValues: validatedMap,
      schema: schema,
      activePresetName: presetName,
    );
  }

  /// Gets variable value.
  dynamic get(String key) => _resolvedValues[key];

  /// Returns true if key is set.
  bool contains(String key) => _resolvedValues.containsKey(key);

  /// Map view of all resolved customization variables.
  Map<String, dynamic> toMap() => _resolvedValues;

  /// Bridges resolved customization variables into an existing [TemplateContext].
  TemplateContext toTemplateContext([WizardContext? wizardCtx]) {
    final baseCtx = wizardCtx != null
        ? TemplateContext.fromWizardContext(wizardCtx)
        : TemplateContext();

    _resolvedValues.forEach((k, v) {
      baseCtx.set(k, v);
    });

    return baseCtx;
  }
}
