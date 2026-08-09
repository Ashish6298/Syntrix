import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateManifest & VariableDefinition Tests', () {
    test('TemplateManifest.fromMap parses valid manifest map', () {
      final manifestMap = {
        'id': 'my_template',
        'name': 'My Template',
        'displayName': 'My Custom Template',
        'description': 'Description text',
        'version': '1.2.0',
        'projectType': 'flutter_package',
        'minimumDartSdk': '>=3.0.0 <4.0.0',
        'minimumFlutterSdk': '>=3.20.0',
        'supportedPlatforms': ['android', 'ios'],
        'variables': {
          'author': {'description': 'Author name', 'required': true},
        },
        'directories': ['lib', 'test'],
        'files': {
          'pubspec.yaml': 'name: {{package_name}}',
        },
      };

      final manifest = TemplateManifest.fromMap(manifestMap);

      expect(manifest.id, equals('my_template'));
      expect(manifest.displayName, equals('My Custom Template'));
      expect(manifest.version, equals('1.2.0'));
      expect(manifest.supportedPlatforms, containsAll(['android', 'ios']));
      expect(manifest.variables.containsKey('author'), isTrue);
      expect(manifest.variables['author']?.isRequired, isTrue);
      expect(manifest.directories, equals(['lib', 'test']));
      expect(manifest.files['pubspec.yaml'], equals('name: {{package_name}}'));
    });

    test(
        'TemplateManifest throws TemplateException when id is missing or empty',
        () {
      expect(
        () => TemplateManifest.fromMap({'name': 'No ID'}),
        throwsA(isA<TemplateException>()),
      );
      expect(
        () => TemplateManifest.fromMap({'id': '   '}),
        throwsA(isA<TemplateException>()),
      );
    });

    test('TemplateManifest.toMap roundtrip', () {
      const manifest = TemplateManifest(
        id: 'roundtrip_template',
        name: 'Roundtrip',
        displayName: 'Roundtrip Display',
        description: 'Desc',
        version: '2.0.0',
        projectType: 'dart_package',
        minimumDartSdk: '>=3.5.0 <4.0.0',
      );

      final map = manifest.toMap();
      final restored = TemplateManifest.fromMap(map);

      expect(restored.id, equals('roundtrip_template'));
      expect(restored.projectType, equals('dart_package'));
      expect(restored.version, equals('2.0.0'));
    });
  });

  group('TemplateRegistry Tests', () {
    late TemplateRegistry registry;

    setUp(() {
      registry = TemplateRegistry();
      BuiltinTemplates.registerDefaultTemplates(registry);
    });

    test('Default builtin template registration', () {
      expect(registry.contains('flutter_package'), isTrue);
      expect(registry.length, equals(1));

      final template = registry.get('flutter_package');
      expect(template, isNotNull);
      expect(template?.displayName, contains('Flutter Package'));
    });

    test('Register duplicate template ID throws TemplateException', () {
      final duplicate = Template(
        manifest: const TemplateManifest(
          id: 'flutter_package',
          name: 'Dup',
          displayName: 'Dup',
          description: '',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.0.0',
        ),
      );

      expect(
        () => registry.register(duplicate),
        throwsA(isA<TemplateException>()),
      );
    });

    test('Unregister and search functionality', () {
      final custom = Template(
        manifest: const TemplateManifest(
          id: 'custom_plugin',
          name: 'Custom Plugin',
          displayName: 'Custom Plugin Template',
          description: 'Generates native plugin',
          version: '1.0.0',
          projectType: 'plugin',
          minimumDartSdk: '>=3.0.0',
        ),
      );

      registry.register(custom);
      expect(registry.length, equals(2));

      final searchResults = registry.search('plugin');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.id, equals('custom_plugin'));

      final unreg = registry.unregister('custom_plugin');
      expect(unreg, isTrue);
      expect(registry.length, equals(1));
    });

    test('Filter by projectType', () {
      final dartTemplate = Template(
        manifest: const TemplateManifest(
          id: 'pure_dart',
          name: 'Pure Dart',
          displayName: 'Dart Package',
          description: '',
          version: '1.0.0',
          projectType: 'dart_package',
          minimumDartSdk: '>=3.0.0',
        ),
      );
      registry.register(dartTemplate);

      final flutterPkgs = registry.filterByProjectType('flutter_package');
      final dartPkgs = registry.filterByProjectType('dart_package');

      expect(flutterPkgs.length, equals(1));
      expect(dartPkgs.length, equals(1));
      expect(dartPkgs.first.id, equals('pure_dart'));
    });
  });
}
