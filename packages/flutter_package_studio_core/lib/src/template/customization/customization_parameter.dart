import 'package:flutter_package_studio_core/src/error/exceptions.dart';

/// Data types supported for template customization parameters.
enum CustomizationParameterType {
  string,
  boolean,
  integer,
  select,
  list,
}

/// Declaration of a single customization parameter supported by a template.
class CustomizationParameter {
  /// Unique variable key identifier (e.g. `enable_auth`).
  final String key;

  /// Parameter data type.
  final CustomizationParameterType type;

  /// Human-readable label or description.
  final String description;

  /// Default fallback value.
  final dynamic defaultValue;

  /// Allowed options for `select` / `enum` types or restricted list values.
  final List<dynamic> allowedValues;

  /// Whether providing a non-null value is mandatory.
  final bool isRequired;

  /// Whether this parameter acts as a feature toggle.
  final bool isFeatureFlag;

  const CustomizationParameter({
    required this.key,
    required this.type,
    required this.description,
    this.defaultValue,
    this.allowedValues = const [],
    this.isRequired = false,
    this.isFeatureFlag = false,
  });

  /// Deserializes a parameter definition from a map.
  factory CustomizationParameter.fromMap(String key, Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'string';
    final type = _parseType(typeStr);

    return CustomizationParameter(
      key: key,
      type: type,
      description: map['description'] as String? ?? '',
      defaultValue: map['default'],
      allowedValues: (map['allowedValues'] as List<dynamic>?) ??
          (map['allowed'] as List<dynamic>?) ??
          const [],
      isRequired: map['required'] as bool? ?? false,
      isFeatureFlag: map['isFeatureFlag'] as bool? ??
          (type == CustomizationParameterType.boolean),
    );
  }

  /// Validates and normalizes an input [rawValue] against this parameter definition.
  dynamic coerceAndValidate(dynamic rawValue) {
    final value = rawValue ?? defaultValue;

    if (value == null) {
      if (isRequired) {
        throw CustomizationValidationException(
            'Customization parameter "$key" is required but no value was provided.');
      }
      return null;
    }

    switch (type) {
      case CustomizationParameterType.boolean:
        if (value is bool) return value;
        if (value is String) {
          final lower = value.trim().toLowerCase();
          if (lower == 'true' || lower == 'yes' || lower == '1') return true;
          if (lower == 'false' || lower == 'no' || lower == '0') return false;
        }
        throw CustomizationValidationException(
            'Invalid boolean value "$value" for parameter "$key".');

      case CustomizationParameterType.integer:
        if (value is int) return value;
        if (value is String) {
          final parsed = int.tryParse(value.trim());
          if (parsed != null) return parsed;
        }
        throw CustomizationValidationException(
            'Invalid integer value "$value" for parameter "$key".');

      case CustomizationParameterType.select:
        final strVal = value.toString().trim();
        if (allowedValues.isNotEmpty &&
            !allowedValues.map((v) => v.toString()).contains(strVal)) {
          throw CustomizationValidationException(
              'Invalid choice "$strVal" for parameter "$key". '
              'Allowed values: [${allowedValues.join(', ')}].');
        }
        return strVal;

      case CustomizationParameterType.list:
        if (value is List) return value.map((e) => e.toString()).toList();
        if (value is String) {
          return value
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
        throw CustomizationValidationException(
            'Invalid list value "$value" for parameter "$key".');

      case CustomizationParameterType.string:
        final strVal = value.toString();
        if (allowedValues.isNotEmpty &&
            !allowedValues.map((v) => v.toString()).contains(strVal)) {
          throw CustomizationValidationException(
              'Value "$strVal" for parameter "$key" is not in allowed list: [${allowedValues.join(', ')}].');
        }
        return strVal;
    }
  }

  static CustomizationParameterType _parseType(String typeStr) {
    switch (typeStr.toLowerCase().trim()) {
      case 'bool':
      case 'boolean':
        return CustomizationParameterType.boolean;
      case 'int':
      case 'integer':
        return CustomizationParameterType.integer;
      case 'enum':
      case 'select':
        return CustomizationParameterType.select;
      case 'list':
      case 'array':
        return CustomizationParameterType.list;
      case 'string':
      default:
        return CustomizationParameterType.string;
    }
  }

  Map<String, dynamic> toMap() => {
        'key': key,
        'type': type.name,
        'description': description,
        'default': defaultValue,
        'allowedValues': allowedValues,
        'required': isRequired,
        'isFeatureFlag': isFeatureFlag,
      };
}
