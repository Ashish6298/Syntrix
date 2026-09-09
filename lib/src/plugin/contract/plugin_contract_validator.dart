import 'package:syntrix/src/plugin/contract/plugin_contract_models.dart';
import 'package:syntrix/src/release/versioning/semver_models.dart';

/// Structured result listing every violation found during manifest validation.
class PluginValidationResult {
  final bool isValid;
  final List<String> violations;

  const PluginValidationResult({
    required this.isValid,
    required this.violations,
  });

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'violations': violations,
      };
}

/// Static contract validator evaluating raw manifest inputs with zero code execution.
class PluginContractValidator {
  static const Set<String> supportedApiVersions = {'1.0.0', '1.1.0'};

  /// Evaluates an untrusted raw manifest map or parsed object and returns every violation found.
  PluginValidationResult validateRawJson(Map<String, dynamic> json) {
    final violations = <String>[];

    // Field 1: Plugin ID validation
    final rawId = json['id'] as String?;
    if (rawId == null || rawId.trim().isEmpty) {
      violations.add('[PluginId] Missing required field "id".');
    } else {
      final regex = RegExp(r'^[a-z][a-z0-9_]{2,63}$');
      if (!regex.hasMatch(rawId.trim())) {
        violations.add(
            '[PluginId] Invalid format for "id" ("$rawId"): must be lowercase alphanumeric/underscore, start with a letter, length 3-64.');
      }
    }

    // Field 2: Display Name & Description
    final rawName = json['name'] as String?;
    if (rawName == null || rawName.trim().isEmpty) {
      violations.add('[PluginName] Missing required field "name".');
    }
    final rawDesc = json['description'] as String?;
    if (rawDesc == null || rawDesc.trim().isEmpty) {
      violations
          .add('[PluginDescription] Missing required field "description".');
    }

    // Field 3: Shared SemVer reuse check (Phase 6.1 SemVer parser)
    final rawVer = json['version'] as String?;
    if (rawVer == null || rawVer.trim().isEmpty) {
      violations.add('[PluginVersion] Missing required field "version".');
    } else {
      try {
        SemVer.parse(rawVer);
      } catch (e) {
        violations.add('[PluginVersion] Invalid semver string ("$rawVer"): $e');
      }
    }

    // Field 4: API Version check
    final rawApiVer = json['apiVersion'] as String?;
    if (rawApiVer == null || rawApiVer.trim().isEmpty) {
      violations.add('[PluginApiVersion] Missing required field "apiVersion".');
    } else if (!supportedApiVersions.contains(rawApiVer.trim())) {
      violations.add(
          '[PluginApiVersion] Unsupported plugin API version "$rawApiVer". Supported versions: ${supportedApiVersions.join(", ")}.');
    }

    // Field 5: Capabilities closed set check
    final rawCaps = json['capabilities'] as List<dynamic>?;
    if (rawCaps == null || rawCaps.isEmpty) {
      violations.add(
          '[PluginCapabilities] Missing or empty required field "capabilities".');
    } else {
      for (final cap in rawCaps) {
        final match =
            PluginCapability.values.where((c) => c.name == cap.toString());
        if (match.isEmpty) {
          violations.add(
              '[PluginCapabilities] Unrecognized capability "$cap" outside closed set.');
        }
      }
    }

    // Field 6: Compatibility range check (min > max check)
    final rawComp = json['compatibility'] as Map<String, dynamic>?;
    if (rawComp == null) {
      violations
          .add('[PluginCompatibility] Missing required field "compatibility".');
    } else {
      final minStr = rawComp['minApiVersion'] as String?;
      final maxStr = rawComp['maxApiVersion'] as String?;

      if (minStr == null || minStr.trim().isEmpty) {
        violations.add('[PluginCompatibility] Missing "minApiVersion".');
      } else {
        try {
          final minVer = SemVer.parse(minStr);
          if (maxStr != null && maxStr.trim().isNotEmpty) {
            final maxVer = SemVer.parse(maxStr);
            if (minVer.compareTo(maxVer) > 0) {
              violations.add(
                  '[PluginCompatibility] Inconsistent range: minApiVersion ($minStr) > maxApiVersion ($maxStr).');
            }
          }
        } catch (e) {
          violations.add(
              '[PluginCompatibility] Invalid version in compatibility range: $e');
        }
      }
    }

    return PluginValidationResult(
      isValid: violations.isEmpty,
      violations: List.unmodifiable(violations),
    );
  }
}
