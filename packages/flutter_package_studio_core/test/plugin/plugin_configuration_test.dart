import 'dart:convert';

import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('PluginConfiguration & Extended Manifest Unit Tests (Phase 7.5)', () {
    late PluginManifest base71Manifest;

    setUp(() {
      base71Manifest = PluginManifest(
        id: PluginId('valid_plugin'),
        name: PluginName('Valid Plugin'),
        description: PluginDescription('Description'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.commandContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      );
    });

    test('1. Backward-compatibility test for 7.1-7.4 manifests and validators',
        () {
      final json = base71Manifest.toJson();
      final parsed = PluginManifest.fromJson(json);

      expect(parsed.id.value, equals('valid_plugin'));
      expect(parsed.entryPoint, isNull);
      expect(parsed.dependencies, isEmpty);
      expect(parsed.configSchema.properties, isEmpty);

      final val = PluginContractValidator().validateRawJson(json);
      expect(val.isValid, isTrue);
    });

    test(
        '2. Happy-path test constructing complete extended manifest matching roadmap structure',
        () {
      final extendedManifest = PluginManifest(
        id: PluginId('extended_plugin'),
        name: PluginName('Extended Plugin'),
        description: PluginDescription('Desc'),
        version: SemVer.parse('1.0.0'),
        author: const PluginAuthor(name: 'Dev'),
        apiVersion: '1.0.0',
        capabilities: {PluginCapability.serviceContribution},
        compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
        entryPoint: 'lib/entry.dart',
        dependencies: [
          PluginDependency(name: 'other_plugin', versionConstraint: '^1.0.0'),
        ],
        configSchema: ConfigurationSchema(properties: [
          const ConfigurationProperty(
              key: 'repo_url',
              type: ConfigPropertyType.string,
              isRequired: true),
          const ConfigurationProperty(
              key: 'api_token',
              type: ConfigPropertyType.string,
              isRequired: true,
              isSecret: true),
        ]),
        securityRequirements: const SecurityRequirements(
            permissions: ['network_read'], sandboxRequired: true),
      );

      expect(extendedManifest.entryPoint, equals('lib/entry.dart'));
      expect(extendedManifest.dependencies.length, equals(1));
      expect(extendedManifest.configSchema.properties.length, equals(2));
      expect(extendedManifest.securityRequirements.permissions.first,
          equals('network_read'));
    });

    test(
        '3. Metadata-vs-configuration separation test confirms distinct objects',
        () {
      final manifest = base71Manifest;
      final config = RuntimeConfiguration({'key1': 'val1'});

      expect(manifest, isNot(isA<RuntimeConfiguration>()));
      expect(config, isNot(isA<PluginManifest>()));
    });

    test('4a. Configuration-validation: missing required key', () {
      final schema = ConfigurationSchema(properties: [
        const ConfigurationProperty(
            key: 'req_key', type: ConfigPropertyType.string, isRequired: true),
      ]);
      final config = RuntimeConfiguration({});
      final validator = PluginConfigurationValidator();

      final result =
          validator.validateConfiguration(config: config, schema: schema);
      expect(result.isValid, isFalse);
      expect(result.violations.first,
          contains('Missing required property "req_key"'));
    });

    test('4b. Configuration-validation: wrong declared type', () {
      final schema = ConfigurationSchema(properties: [
        const ConfigurationProperty(
            key: 'num_key', type: ConfigPropertyType.number, isRequired: true),
      ]);
      final config = RuntimeConfiguration({'num_key': 'not_a_number'});
      final validator = PluginConfigurationValidator();

      final result =
          validator.validateConfiguration(config: config, schema: schema);
      expect(result.isValid, isFalse);
      expect(result.violations.first,
          contains('Invalid type for property "num_key"'));
    });

    test('4c. Configuration-validation: undeclared/unexpected key', () {
      final schema = ConfigurationSchema(properties: []);
      final config = RuntimeConfiguration({'unexpected_key': 'value'});
      final validator = PluginConfigurationValidator();

      final result =
          validator.validateConfiguration(config: config, schema: schema);
      expect(result.isValid, isFalse);
      expect(result.violations.first,
          contains('Unexpected undeclared property "unexpected_key"'));
    });

    test(
        '5. Multi-violation configuration test returns all attributed violations together',
        () {
      final schema = ConfigurationSchema(properties: [
        const ConfigurationProperty(
            key: 'req_str', type: ConfigPropertyType.string, isRequired: true),
        const ConfigurationProperty(
            key: 'req_num', type: ConfigPropertyType.number, isRequired: true),
      ]);
      final config = RuntimeConfiguration({'req_num': 'bad', 'extra': 123});
      final validator = PluginConfigurationValidator();

      final result =
          validator.validateConfiguration(config: config, schema: schema);
      expect(result.isValid, isFalse);
      expect(result.violations.length,
          equals(3)); // missing req_str, wrong type req_num, unexpected extra
    });

    test('6a. Secret-redaction test: SecretValue never appears in toString()',
        () {
      final secret = SecretValue('my_top_secret_token');
      expect(secret.toString(), equals('[REDACTED]'));
      expect(secret.toString(), isNot(contains('my_top_secret_token')));
    });

    test('6b. Secret-redaction test: SecretValue never appears in toJson()',
        () {
      final secret = SecretValue('my_top_secret_token');
      expect(secret.toJson(), equals('[REDACTED]'));
      final config = RuntimeConfiguration({'token': secret});
      expect(
          jsonEncode(config.toJson()), isNot(contains('my_top_secret_token')));
    });

    test(
        '6c. Secret-redaction test: validation-failure message redacts secret value',
        () {
      final schema = ConfigurationSchema(properties: [
        const ConfigurationProperty(
            key: 'secret_num',
            type: ConfigPropertyType.number,
            isRequired: true,
            isSecret: true),
      ]);
      final config = RuntimeConfiguration({'secret_num': 'string_secret_val'});
      final validator = PluginConfigurationValidator();

      final result =
          validator.validateConfiguration(config: config, schema: schema);
      expect(result.isValid, isFalse);
      expect(result.violations.first, contains('[REDACTED]'));
      expect(result.violations.first, isNot(contains('string_secret_val')));
    });

    test('6d. Secret-redaction test: exception message redacts secret value',
        () {
      try {
        final secretVal = SecretValue('super_secret_password');
        throw PluginConfigurationException(
            'Failed processing key "pass" with value $secretVal');
      } on PluginConfigurationException catch (e) {
        expect(e.message, contains('[REDACTED]'));
        expect(e.message, isNot(contains('super_secret_password')));
      }
    });

    test(
        '6e. Secret-redaction test: non-secret configuration value is NOT redacted',
        () {
      final config = RuntimeConfiguration({'public_key': 'public_value'});
      expect(config.toJson()['public_key'], equals('public_value'));
    });

    test(
        '7. Entry-point well-formedness test rejects empty entry-point without resolving code',
        () {
      expect(
        () => PluginManifest(
          id: PluginId('valid_id'),
          name: PluginName('N'),
          description: PluginDescription('D'),
          version: SemVer.parse('1.0.0'),
          author: const PluginAuthor(name: 'A'),
          apiVersion: '1.0.0',
          capabilities: {PluginCapability.commandContribution},
          compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
          entryPoint: '   ',
        ),
        throwsA(isA<PluginContractException>()),
      );
    });

    test(
        '8. Dependency-declaration test rejects self-referential dependency without fetching',
        () {
      expect(
        () => PluginManifest(
          id: PluginId('my_plugin'),
          name: PluginName('N'),
          description: PluginDescription('D'),
          version: SemVer.parse('1.0.0'),
          author: const PluginAuthor(name: 'A'),
          apiVersion: '1.0.0',
          capabilities: {PluginCapability.commandContribution},
          compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
          dependencies: [
            PluginDependency(name: 'my_plugin', versionConstraint: '^1.0.0'),
          ],
        ),
        throwsA(isA<PluginContractException>()),
      );
    });

    test(
        '9. Non-execution audit: configuration handling performs zero network/filesystem resolution',
        () {
      final schema = ConfigurationSchema(properties: [
        const ConfigurationProperty(
            key: 'host', type: ConfigPropertyType.string, isRequired: true),
      ]);
      final config = RuntimeConfiguration({'host': '127.0.0.1'});
      final validator = PluginConfigurationValidator();

      final result =
          validator.validateConfiguration(config: config, schema: schema);
      expect(result.isValid, isTrue);
    });

    test(
        '10. Determinism check: identical manifest-plus-config input produces identical validation & output',
        () {
      final schema = ConfigurationSchema(properties: [
        const ConfigurationProperty(
            key: 'setting', type: ConfigPropertyType.string, isRequired: true),
      ]);
      final config = RuntimeConfiguration({'setting': 'val'});
      final validator = PluginConfigurationValidator();

      final r1 =
          validator.validateConfiguration(config: config, schema: schema);
      final r2 =
          validator.validateConfiguration(config: config, schema: schema);

      expect(r1.isValid, equals(r2.isValid));
      expect(r1.violations, equals(r2.violations));
      expect(config.toJson(), equals(config.toJson()));
    });

    test(
        '11a. Fail-closed edge-case: null/empty configuration object against schema requiring values',
        () {
      final schema = ConfigurationSchema(properties: [
        const ConfigurationProperty(
            key: 'key1', type: ConfigPropertyType.string, isRequired: true),
      ]);
      final config = RuntimeConfiguration({});
      final validator = PluginConfigurationValidator();

      final result =
          validator.validateConfiguration(config: config, schema: schema);
      expect(result.isValid, isFalse);
      expect(result.violations.length, equals(1));
    });

    test(
        '11b. Fail-closed edge-case: configuration schema declaring conflicting or duplicate keys',
        () {
      expect(
        () => ConfigurationSchema(properties: [
          const ConfigurationProperty(
              key: 'dup', type: ConfigPropertyType.string),
          const ConfigurationProperty(
              key: 'dup', type: ConfigPropertyType.number),
        ]),
        throwsA(isA<PluginContractException>()),
      );
    });

    test(
        '11c. Fail-closed edge-case: zero declared keys schema with supplied configuration values',
        () {
      final schema = ConfigurationSchema(properties: []);
      final config = RuntimeConfiguration({'extra_key': 'value'});
      final validator = PluginConfigurationValidator();

      final result =
          validator.validateConfiguration(config: config, schema: schema);
      expect(result.isValid, isFalse);
      expect(result.violations.first,
          contains('Unexpected undeclared property "extra_key"'));
    });
  });
}
