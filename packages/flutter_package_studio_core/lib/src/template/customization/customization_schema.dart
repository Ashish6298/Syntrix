import 'package:flutter_package_studio_core/src/template/customization/customization_parameter.dart';

/// Named profile preset defining pre-configured customization variable values.
class CustomizationPreset {
  /// Preset unique identifier (e.g. `minimal`, `standard`, `production`).
  final String name;

  /// User-facing description of what this profile configures.
  final String description;

  /// Variable values applied when this profile is active.
  final Map<String, dynamic> variables;

  const CustomizationPreset({
    required this.name,
    required this.description,
    this.variables = const {},
  });

  factory CustomizationPreset.fromMap(String name, Map<String, dynamic> map) {
    return CustomizationPreset(
      name: name,
      description: map['description'] as String? ?? '',
      variables: (map['variables'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'variables': variables,
      };
}

/// Declarative customization schema defined by a template or composite stack.
class CustomizationSchema {
  /// Map of parameter definitions keyed by variable name.
  final Map<String, CustomizationParameter> parameters;

  /// Map of named presets (e.g. `minimal`, `standard`, `production`).
  final Map<String, CustomizationPreset> presets;

  /// Map of file path -> condition string for conditional file inclusion/exclusion.
  final Map<String, String> conditionalFiles;

  /// Map of source asset path -> target override path for customized file routing.
  final Map<String, String> pathOverrides;

  const CustomizationSchema({
    this.parameters = const {},
    this.presets = const {},
    this.conditionalFiles = const {},
    this.pathOverrides = const {},
  });

  factory CustomizationSchema.fromMap(Map<String, dynamic> map) {
    final paramsMap = <String, CustomizationParameter>{};
    if (map['parameters'] is Map<String, dynamic>) {
      (map['parameters'] as Map<String, dynamic>).forEach((k, v) {
        if (v is Map<String, dynamic>) {
          paramsMap[k] = CustomizationParameter.fromMap(k, v);
        }
      });
    }

    final presetsMap = <String, CustomizationPreset>{};
    if (map['presets'] is Map<String, dynamic>) {
      (map['presets'] as Map<String, dynamic>).forEach((k, v) {
        if (v is Map<String, dynamic>) {
          presetsMap[k] = CustomizationPreset.fromMap(k, v);
        }
      });
    }

    return CustomizationSchema(
      parameters: Map.unmodifiable(paramsMap),
      presets: Map.unmodifiable(presetsMap),
      conditionalFiles: Map.unmodifiable(
          (map['conditionalFiles'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, v.toString()),
              ) ??
              const {}),
      pathOverrides:
          Map.unmodifiable((map['pathOverrides'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, v.toString()),
              ) ??
              const {}),
    );
  }

  /// Merges two customization schemas together (e.g. Base + Extensions).
  CustomizationSchema merge(CustomizationSchema other) {
    final mergedParams = Map<String, CustomizationParameter>.from(parameters)
      ..addAll(other.parameters);
    final mergedPresets = Map<String, CustomizationPreset>.from(presets)
      ..addAll(other.presets);
    final mergedConds = Map<String, String>.from(conditionalFiles)
      ..addAll(other.conditionalFiles);
    final mergedPaths = Map<String, String>.from(pathOverrides)
      ..addAll(other.pathOverrides);

    return CustomizationSchema(
      parameters: Map.unmodifiable(mergedParams),
      presets: Map.unmodifiable(mergedPresets),
      conditionalFiles: Map.unmodifiable(mergedConds),
      pathOverrides: Map.unmodifiable(mergedPaths),
    );
  }

  Map<String, dynamic> toMap() => {
        'parameters': parameters.map((k, v) => MapEntry(k, v.toMap())),
        'presets': presets.map((k, v) => MapEntry(k, v.toMap())),
        'conditionalFiles': conditionalFiles,
        'pathOverrides': pathOverrides,
      };
}
