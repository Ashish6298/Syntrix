import 'package:flutter_package_studio_core/src/error/exceptions.dart';

/// Represents the definition of a variable expected or used by a template.
class TemplateVariableDefinition {
  /// Unique variable key identifier (e.g. `package_name`).
  final String key;

  /// Human-readable label or description.
  final String description;

  /// Whether providing this variable is mandatory for rendering.
  final bool isRequired;

  /// Default fallback value if not specified in context.
  final dynamic defaultValue;

  /// Creates a [TemplateVariableDefinition] instance.
  const TemplateVariableDefinition({
    required this.key,
    required this.description,
    this.isRequired = false,
    this.defaultValue,
  });

  /// Deserializes a variable definition from a raw map.
  factory TemplateVariableDefinition.fromMap(
      String key, Map<String, dynamic> map) {
    return TemplateVariableDefinition(
      key: key,
      description: map['description'] as String? ?? '',
      isRequired: map['required'] as bool? ?? false,
      defaultValue: map['default'],
    );
  }

  /// Serializes variable definition to a map.
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'required': isRequired,
      'default': defaultValue,
    };
  }
}

/// Machine-readable manifest defining template metadata, variables, files, and rules.
class TemplateManifest {
  /// Unique template identifier (e.g. `flutter_package`).
  final String id;

  /// Human-readable name.
  final String name;

  /// User-facing display title.
  final String displayName;

  /// Short description of what the template generates.
  final String description;

  /// Template semantic version string (e.g. `1.0.0`).
  final String version;

  /// Project archetype (`flutter_package`, `dart_package`, `plugin`, `module`).
  final String projectType;

  /// Minimum required Dart SDK version constraint.
  final String minimumDartSdk;

  /// Minimum required Flutter SDK version constraint (optional for pure Dart).
  final String? minimumFlutterSdk;

  /// List of target operating system platforms supported.
  final List<String> supportedPlatforms;

  /// Variable definitions expected by this template.
  final Map<String, TemplateVariableDefinition> variables;

  /// Explicit relative directory paths to create.
  final List<String> directories;

  /// Map of output target relative file path to source template file path or content.
  final Map<String, String> files;

  /// List of binary asset file paths to copy verbatim without placeholder substitution.
  final List<String> binaryAssets;

  /// Map of output relative file path to condition string (e.g. `is_flutter`).
  final Map<String, String> conditions;

  /// Optional extra metadata key-values.
  final Map<String, dynamic> extraMetadata;

  /// Creates a [TemplateManifest] instance.
  const TemplateManifest({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.version,
    required this.projectType,
    required this.minimumDartSdk,
    this.minimumFlutterSdk,
    this.supportedPlatforms = const [],
    this.variables = const {},
    this.directories = const [],
    this.files = const {},
    this.binaryAssets = const [],
    this.conditions = const {},
    this.extraMetadata = const {},
  });

  /// Deserializes and validates a [TemplateManifest] from a raw map.
  /// Throws [TemplateException] if required manifest fields are missing or invalid.
  factory TemplateManifest.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String?;
    if (id == null || id.trim().isEmpty) {
      throw TemplateException(
          'Template manifest error: "id" field is required.');
    }

    final name = map['name'] as String? ?? id;
    final displayName = map['displayName'] as String? ?? name;
    final description = map['description'] as String? ?? '';
    final version = map['version'] as String? ?? '1.0.0';
    final projectType = map['projectType'] as String? ?? 'flutter_package';
    final minimumDartSdk = map['minimumDartSdk'] as String? ?? '>=3.5.0 <4.0.0';
    final minimumFlutterSdk = map['minimumFlutterSdk'] as String?;

    final supportedPlatforms = (map['supportedPlatforms'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    final rawVars = map['variables'] as Map<String, dynamic>? ?? {};
    final variables = <String, TemplateVariableDefinition>{};
    rawVars.forEach((key, val) {
      if (val is Map<String, dynamic>) {
        variables[key] = TemplateVariableDefinition.fromMap(key, val);
      } else {
        variables[key] = TemplateVariableDefinition(
          key: key,
          description: val.toString(),
        );
      }
    });

    final directories =
        (map['directories'] as List?)?.map((e) => e.toString()).toList() ??
            const [];

    final rawFiles = map['files'];
    final files = <String, String>{};
    if (rawFiles is Map) {
      rawFiles.forEach((k, v) => files[k.toString()] = v.toString());
    } else if (rawFiles is List) {
      for (final item in rawFiles) {
        files[item.toString()] = item.toString();
      }
    }

    final binaryAssets =
        (map['binaryAssets'] as List?)?.map((e) => e.toString()).toList() ??
            const [];

    final rawConditions = map['conditions'] as Map?;
    final conditions = <String, String>{};
    if (rawConditions != null) {
      rawConditions.forEach((k, v) => conditions[k.toString()] = v.toString());
    }

    final extraMetadata =
        (map['extraMetadata'] as Map?)?.cast<String, dynamic>() ?? const {};

    return TemplateManifest(
      id: id.trim(),
      name: name,
      displayName: displayName,
      description: description,
      version: version,
      projectType: projectType,
      minimumDartSdk: minimumDartSdk,
      minimumFlutterSdk: minimumFlutterSdk,
      supportedPlatforms: supportedPlatforms,
      variables: variables,
      directories: directories,
      files: files,
      binaryAssets: binaryAssets,
      conditions: conditions,
      extraMetadata: extraMetadata,
    );
  }

  /// Serializes [TemplateManifest] to map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'description': description,
      'version': version,
      'projectType': projectType,
      'minimumDartSdk': minimumDartSdk,
      if (minimumFlutterSdk != null) 'minimumFlutterSdk': minimumFlutterSdk,
      'supportedPlatforms': supportedPlatforms,
      'variables': variables.map((k, v) => MapEntry(k, v.toMap())),
      'directories': directories,
      'files': files,
      'binaryAssets': binaryAssets,
      'conditions': conditions,
      'extraMetadata': extraMetadata,
    };
  }
}
