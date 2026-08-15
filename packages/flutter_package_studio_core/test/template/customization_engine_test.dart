import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('CustomizationParameter Tests', () {
    test('Boolean parameter type coercion and validation', () {
      final param = const CustomizationParameter(
        key: 'enable_auth',
        type: CustomizationParameterType.boolean,
        description: 'Toggle authentication module',
        defaultValue: false,
      );

      expect(param.coerceAndValidate(true), isTrue);
      expect(param.coerceAndValidate('true'), isTrue);
      expect(param.coerceAndValidate('YES'), isTrue);
      expect(param.coerceAndValidate('0'), isFalse);
      expect(param.coerceAndValidate(null), isFalse);

      expect(
        () => param.coerceAndValidate('invalid_bool'),
        throwsA(isA<CustomizationValidationException>()),
      );
    });

    test('Integer parameter type coercion and validation', () {
      final param = const CustomizationParameter(
        key: 'max_users',
        type: CustomizationParameterType.integer,
        description: 'Maximum user limit',
        defaultValue: 10,
      );

      expect(param.coerceAndValidate(42), equals(42));
      expect(param.coerceAndValidate('100'), equals(100));

      expect(
        () => param.coerceAndValidate('not_an_int'),
        throwsA(isA<CustomizationValidationException>()),
      );
    });

    test('Select parameter allowedValues enforcement', () {
      final param = const CustomizationParameter(
        key: 'database',
        type: CustomizationParameterType.select,
        description: 'Backend storage engine',
        defaultValue: 'sqlite',
        allowedValues: ['sqlite', 'postgres', 'hive'],
      );

      expect(param.coerceAndValidate('postgres'), equals('postgres'));

      expect(
        () => param.coerceAndValidate('oracle'),
        throwsA(isA<CustomizationValidationException>()),
      );
    });

    test('Required parameter throws exception if missing', () {
      final param = const CustomizationParameter(
        key: 'app_title',
        type: CustomizationParameterType.string,
        description: 'Application title',
        isRequired: true,
      );

      expect(
        () => param.coerceAndValidate(null),
        throwsA(isA<CustomizationValidationException>()),
      );
    });
  });

  group('CustomizationContext Resolution & Precedence Tests', () {
    final schema = CustomizationSchema(
      parameters: {
        'enable_cache': const CustomizationParameter(
          key: 'enable_cache',
          type: CustomizationParameterType.boolean,
          description: 'Enable cache',
          defaultValue: true,
        ),
        'theme': const CustomizationParameter(
          key: 'theme',
          type: CustomizationParameterType.select,
          description: 'UI theme',
          defaultValue: 'light',
          allowedValues: ['light', 'dark', 'system'],
        ),
      },
      presets: {
        'production': const CustomizationPreset(
          name: 'production',
          description: 'Production defaults',
          variables: {'theme': 'dark'},
        ),
      },
    );

    test('Defaults apply when no preset or user input is supplied', () {
      final ctx = CustomizationContext.resolve(schema: schema);
      expect(ctx.get('enable_cache'), isTrue);
      expect(ctx.get('theme'), equals('light'));
    });

    test('Preset overrides parameter defaults', () {
      final ctx = CustomizationContext.resolve(
        schema: schema,
        presetName: 'production',
      );
      expect(ctx.get('theme'), equals('dark'));
    });

    test('User explicit input overrides preset and default values', () {
      final ctx = CustomizationContext.resolve(
        schema: schema,
        presetName: 'production',
        userValues: {'theme': 'system'},
      );
      expect(ctx.get('theme'), equals('system'));
    });

    test('Unknown preset throws CustomizationValidationException', () {
      expect(
        () => CustomizationContext.resolve(
          schema: schema,
          presetName: 'nonexistent_preset',
        ),
        throwsA(isA<CustomizationValidationException>()),
      );
    });
  });

  group('CustomizationEngine & Path Security Tests', () {
    final engine = CustomizationEngine();

    test(
        'Path traversal attempt in path override throws CustomizationPathSecurityException',
        () {
      final schema = CustomizationSchema(
        pathOverrides: {'lib/main.dart': '../outside/main.dart'},
      );

      final template = Template(
        manifest: const TemplateManifest(
          id: 'test_tmpl',
          name: 'test_tmpl',
          displayName: 'Test',
          description: 'Desc',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.0.0',
        ),
        fileTemplates: {'lib/main.dart': '// main content'},
      );

      final resolved = ResolvedTemplate(
        baseTemplate: template,
        extensions: const [],
        effectiveManifest: template.manifest,
        fileProvenance: {'lib/main.dart': 'test_tmpl'},
        files: {'lib/main.dart': '// main content'},
      );

      expect(
        () => engine.customize(resolvedTemplate: resolved, schema: schema),
        throwsA(isA<CustomizationPathSecurityException>()),
      );
    });

    test('Absolute path override throws CustomizationPathSecurityException',
        () {
      final schema = CustomizationSchema(
        pathOverrides: {'lib/main.dart': '/etc/passwd'},
      );

      final template = Template(
        manifest: const TemplateManifest(
          id: 'test_tmpl',
          name: 'test_tmpl',
          displayName: 'Test',
          description: 'Desc',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.0.0',
        ),
        fileTemplates: {'lib/main.dart': '// main content'},
      );

      final resolved = ResolvedTemplate(
        baseTemplate: template,
        extensions: const [],
        effectiveManifest: template.manifest,
        fileProvenance: {'lib/main.dart': 'test_tmpl'},
        files: {'lib/main.dart': '// main content'},
      );

      expect(
        () => engine.customize(resolvedTemplate: resolved, schema: schema),
        throwsA(isA<CustomizationPathSecurityException>()),
      );
    });

    test('Conditional file rule excludes file when condition evaluates false',
        () {
      final schema = CustomizationSchema(
        parameters: {
          'include_docs': const CustomizationParameter(
            key: 'include_docs',
            type: CustomizationParameterType.boolean,
            description: 'Include docs',
            defaultValue: false,
          ),
        },
        conditionalFiles: {
          'DOCS.md': 'include_docs',
        },
      );

      final template = Template(
        manifest: const TemplateManifest(
          id: 'test_tmpl',
          name: 'test_tmpl',
          displayName: 'Test',
          description: 'Desc',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.0.0',
        ),
        fileTemplates: {
          'lib/main.dart': '// main',
          'DOCS.md': '# Documentation',
        },
      );

      final resolved = ResolvedTemplate(
        baseTemplate: template,
        extensions: const [],
        effectiveManifest: template.manifest,
        fileProvenance: {
          'lib/main.dart': 'test_tmpl',
          'DOCS.md': 'test_tmpl',
        },
        files: {
          'lib/main.dart': '// main',
          'DOCS.md': '# Documentation',
        },
      );

      final plan = engine.customize(
        resolvedTemplate: resolved,
        schema: schema,
        userValues: {'include_docs': false},
      );

      expect(plan.excludedFiles, contains('DOCS.md'));
      expect(plan.includedFiles, contains('lib/main.dart'));
      expect(plan.includedFiles.contains('DOCS.md'), isFalse);
    });
  });
}
