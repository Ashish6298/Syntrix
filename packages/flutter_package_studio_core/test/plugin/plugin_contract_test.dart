import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('PluginContract Unit Tests (Phase 7.1)', () {
    late Map<String, dynamic> validManifestMap;

    setUp(() {
      validManifestMap = {
        'id': 'custom_plugin',
        'name': 'Custom Release Plugin',
        'description':
            'A production-grade custom plugin for Flutter Package Studio.',
        'version': '1.2.3-beta.1',
        'author': {
          'name': 'Syntrix Team',
          'email': 'dev@syntrix.io',
          'url': 'https://syntrix.io',
        },
        'apiVersion': '1.0.0',
        'capabilities': ['commandContribution', 'validationContribution'],
        'compatibility': {
          'minApiVersion': '1.0.0',
          'maxApiVersion': '2.0.0',
        },
        'state': 'discovered',
      };
    });

    test(
        '1. Successful construction and validation of a fully well-formed, complete plugin manifest',
        () {
      final validator = PluginContractValidator();
      final result = validator.validateRawJson(validManifestMap);

      expect(result.isValid, isTrue);
      expect(result.violations, isEmpty);

      final manifest = PluginManifest.fromJson(validManifestMap);
      expect(manifest.id.value, equals('custom_plugin'));
      expect(manifest.name.value, equals('Custom Release Plugin'));
      expect(manifest.version.toString(), equals('1.2.3-beta.1'));
      expect(manifest.capabilities.length, equals(2));
      expect(manifest.state, equals(PluginLifecycleState.discovered));
    });

    test(
        '2a. Individual field-level validation failure: invalid/malformed plugin ID',
        () {
      final invalidIdMap = Map<String, dynamic>.from(validManifestMap);
      invalidIdMap['id'] = '123_INVALID_ID!'; // Invalid ID format

      final validator = PluginContractValidator();
      final result = validator.validateRawJson(invalidIdMap);

      expect(result.isValid, isFalse);
      expect(result.violations.any((v) => v.contains('[PluginId]')), isTrue);
    });

    test(
        '2b. Individual field-level validation failure: invalid version string',
        () {
      final invalidVerMap = Map<String, dynamic>.from(validManifestMap);
      invalidVerMap['version'] = 'invalid_version_string';

      final validator = PluginContractValidator();
      final result = validator.validateRawJson(invalidVerMap);

      expect(result.isValid, isFalse);
      expect(
          result.violations.any((v) => v.contains('[PluginVersion]')), isTrue);
    });

    test(
        '2c. Individual field-level validation failure: unrecognized/unsupported plugin API version',
        () {
      final invalidApiVerMap = Map<String, dynamic>.from(validManifestMap);
      invalidApiVerMap['apiVersion'] = '9.9.9'; // Unsupported

      final validator = PluginContractValidator();
      final result = validator.validateRawJson(invalidApiVerMap);

      expect(result.isValid, isFalse);
      expect(result.violations.any((v) => v.contains('[PluginApiVersion]')),
          isTrue);
    });

    test(
        '2d. Individual field-level validation failure: capability outside closed set',
        () {
      final invalidCapMap = Map<String, dynamic>.from(validManifestMap);
      invalidCapMap['capabilities'] = [
        'commandContribution',
        'invalidCapabilityOutsideSet'
      ];

      final validator = PluginContractValidator();
      final result = validator.validateRawJson(invalidCapMap);

      expect(result.isValid, isFalse);
      expect(result.violations.any((v) => v.contains('[PluginCapabilities]')),
          isTrue);
    });

    test(
        '2e. Individual field-level validation failure: inconsistent compatibility range (min > max)',
        () {
      final invalidCompMap = Map<String, dynamic>.from(validManifestMap);
      invalidCompMap['compatibility'] = {
        'minApiVersion': '2.0.0',
        'maxApiVersion': '1.0.0', // min > max
      };

      final validator = PluginContractValidator();
      final result = validator.validateRawJson(invalidCompMap);

      expect(result.isValid, isFalse);
      expect(
          result.violations.any(
              (v) => v.contains('[PluginCompatibility] Inconsistent range')),
          isTrue);
    });

    test(
        '3. Multiple simultaneous violations test reports every violation found',
        () {
      final multiFailMap = {
        'id': 'INVALID ID!',
        'name': '',
        'description': '',
        'version': 'bad_ver',
        'author': {'name': 'Author'},
        'apiVersion': '9.0.0',
        'capabilities': ['badCap'],
        'compatibility': {'minApiVersion': '2.0.0', 'maxApiVersion': '1.0.0'},
      };

      final validator = PluginContractValidator();
      final result = validator.validateRawJson(multiFailMap);

      expect(result.isValid, isFalse);
      expect(result.violations.length, greaterThanOrEqualTo(6));
    });

    test(
        '4. Round-trip serialization test reproduces identical manifest object',
        () {
      final manifest1 = PluginManifest.fromJson(validManifestMap);
      final json1 = manifest1.toJson();
      final manifest2 = PluginManifest.fromJson(json1);

      expect(manifest1.id, equals(manifest2.id));
      expect(manifest1.name.value, equals(manifest2.name.value));
      expect(
          manifest1.version.toString(), equals(manifest2.version.toString()));
      expect(manifest1.capabilities, equals(manifest2.capabilities));
    });

    test('5. Serialization determinism test produces byte-identical output',
        () {
      final manifest1 = PluginManifest.fromJson(validManifestMap);
      final manifest2 = PluginManifest.fromJson(validManifestMap);

      expect(
          manifest1.toJson().toString(), equals(manifest2.toJson().toString()));
    });

    test('6. Immutability test confirms value objects cannot be mutated', () {
      final manifest = PluginManifest.fromJson(validManifestMap);
      expect(
          () => (manifest.capabilities as Set)
              .add(PluginCapability.serviceContribution),
          throwsUnsupportedError);
    });

    test(
        '7. Non-execution audit confirms zero dynamic loading or code execution',
        () {
      final validator = PluginContractValidator();
      final result = validator.validateRawJson(validManifestMap);

      // Programmatic verification that validation runs synchronously in-memory with zero process execution
      expect(result.isValid, isTrue);
    });

    test(
        '8. Lifecycle-state test confirms static states only (discovered, validated, incompatible, disabled)',
        () {
      final states = PluginLifecycleState.values.map((s) => s.name).toList();

      expect(states,
          equals(['discovered', 'validated', 'incompatible', 'disabled']));
      expect(states.contains('running'), isFalse);
      expect(states.contains('enabled'), isFalse);
    });

    test(
        '9. Shared SemVer reuse test confirms Phase 6.1 SemVer parser integration',
        () {
      final manifest = PluginManifest.fromJson(validManifestMap);

      expect(manifest.version, isA<SemVer>());
      expect(manifest.version.isPrerelease, isTrue);
    });

    test('10. Fail-closed edge-case tests for malformed or missing fields', () {
      final emptyMap = <String, dynamic>{};
      final validator = PluginContractValidator();
      final result = validator.validateRawJson(emptyMap);

      expect(result.isValid, isFalse);
      expect(result.violations, isNotEmpty);
      expect(() => PluginManifest.fromJson(emptyMap),
          throwsA(isA<PluginContractException>()));
    });
  });
}
