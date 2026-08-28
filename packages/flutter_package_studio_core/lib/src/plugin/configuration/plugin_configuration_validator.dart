import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_models.dart';
import 'package:flutter_package_studio_core/src/plugin/configuration/plugin_configuration_models.dart';

/// Validator assessing runtime configuration against declared configuration schemas with secret redaction.
class PluginConfigurationValidator {
  /// Validates a [RuntimeConfiguration] against a declared [ConfigurationSchema].
  PluginConfigurationValidationResult validateConfiguration({
    required RuntimeConfiguration config,
    required ConfigurationSchema schema,
  }) {
    final violations = <String>[];

    final declaredKeys = <String>{};
    for (final prop in schema.properties) {
      declaredKeys.add(prop.key);

      // Check required property presence
      if (prop.isRequired && !config.containsKey(prop.key)) {
        violations.add(
            '[ConfigurationSchema] Missing required property "${prop.key}".');
        continue;
      }

      if (config.containsKey(prop.key)) {
        final val = config.getValue(prop.key);

        // Check type compatibility
        if (val != null && !_isTypeValid(val, prop.type)) {
          final displayVal = prop.isSecret || val is SecretValue
              ? '[REDACTED]'
              : val.toString();
          violations.add(
              '[ConfigurationSchema] Invalid type for property "${prop.key}": expected ${prop.type.name}, got $displayVal.');
        }
      }
    }

    // Check for undeclared / unexpected configuration keys
    for (final key in config.values.keys) {
      if (!declaredKeys.contains(key)) {
        violations.add(
            '[ConfigurationSchema] Unexpected undeclared property "$key" supplied in configuration.');
      }
    }

    return PluginConfigurationValidationResult(
      isValid: violations.isEmpty,
      violations: List.unmodifiable(violations),
    );
  }

  bool _isTypeValid(dynamic val, ConfigPropertyType expectedType) {
    if (val is SecretValue)
      return true; // Wrapped secrets pass schema validation
    switch (expectedType) {
      case ConfigPropertyType.string:
        return val is String;
      case ConfigPropertyType.number:
        return val is num;
      case ConfigPropertyType.boolean:
        return val is bool;
      case ConfigPropertyType.map:
        return val is Map;
      case ConfigPropertyType.list:
        return val is List;
    }
  }
}
