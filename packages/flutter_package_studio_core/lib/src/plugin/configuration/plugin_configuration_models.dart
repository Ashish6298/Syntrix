import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_models.dart';

/// Dedicated wrapper for secret-classified configuration values guaranteeing zero exposure in stringification/serialization.
class SecretValue {
  final String _rawSecret;

  SecretValue(this._rawSecret);

  /// Raw secret getter available for secure downstream transport only.
  String get rawSecret => _rawSecret;

  /// Returns fixed redacted placeholder, never the raw secret.
  @override
  String toString() => '[REDACTED]';

  /// Serializes to fixed redacted placeholder.
  String toJson() => '[REDACTED]';
}

/// Runtime configuration object carrying environment-specific key-value settings.
class RuntimeConfiguration {
  final Map<String, dynamic> _values;

  RuntimeConfiguration(Map<String, dynamic> values)
      : _values = Map.unmodifiable(values);

  Map<String, dynamic> get values => _values;

  dynamic getValue(String key) => _values[key];

  bool containsKey(String key) => _values.containsKey(key);

  /// Converts values map to JSON, automatically redacting secret values.
  Map<String, dynamic> toJson({ConfigurationSchema? schema}) {
    final result = <String, dynamic>{};
    for (final entry in _values.entries) {
      final isSecret =
          schema?.properties.any((p) => p.key == entry.key && p.isSecret) ??
              false;
      if (isSecret || entry.value is SecretValue) {
        result[entry.key] = '[REDACTED]';
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  @override
  String toString() => toJson().toString();
}

/// Structured validation result listing attributed violations for runtime configuration.
class PluginConfigurationValidationResult {
  final bool isValid;
  final List<String> violations;

  const PluginConfigurationValidationResult({
    required this.isValid,
    required this.violations,
  });

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'violations': violations,
      };
}
