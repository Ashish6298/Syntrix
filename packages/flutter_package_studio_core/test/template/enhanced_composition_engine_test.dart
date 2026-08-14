import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

Template _createTemplate({
  required String id,
  required String version,
  Map<String, String> files = const {},
  List<TemplateDependency> dependencies = const [],
  List<String> capabilities = const ['package'],
  String minimumDartSdk = '>=3.0.0',
}) {
  return Template(
    manifest: TemplateManifest(
      id: id,
      name: id,
      displayName: id,
      description: 'Test template $id',
      version: version,
      projectType: 'flutter_package',
      minimumDartSdk: minimumDartSdk,
      capabilities: capabilities,
      dependencies: dependencies,
    ),
    fileTemplates: files,
  );
}

void main() {
  group('EnhancedCompositionEngine Tests', () {
    late TemplateRegistry registry;
    late EnhancedCompositionEngine engine;

    setUp(() {
      registry = TemplateRegistry();
      engine = EnhancedCompositionEngine();

      registry.register(_createTemplate(
        id: 'base_template',
        version: '1.0.0',
        files: {'lib/main.dart': '// Base main', 'README.md': '# Base'},
      ));

      registry.register(_createTemplate(
        id: 'feature_auth',
        version: '1.0.0',
        files: {'lib/src/auth.dart': '// Auth module'},
      ));

      registry.register(_createTemplate(
        id: 'feature_override',
        version: '1.0.0',
        files: {'README.md': '# Overridden README'},
      ));
    });

    test('Single base template composition succeeds with correct provenance',
        () {
      final plan = engine.composePlan(
        request: const CompositionRequest(baseTemplateId: 'base_template'),
        registry: registry,
      );

      expect(plan.baseTemplateId, equals('base_template'));
      expect(plan.layers.length, equals(1));
      expect(plan.resolvedTemplate.files.length, equals(2));
      expect(plan.provenanceRecords.length, equals(2));
      expect(plan.provenanceRecords.first.action, equals('created'));
    });

    test('Base plus non-colliding feature extension composes cleanly', () {
      final plan = engine.composePlan(
        request: const CompositionRequest(
          baseTemplateId: 'base_template',
          extensionIds: ['feature_auth'],
        ),
        registry: registry,
      );

      expect(plan.layers.length, equals(2));
      expect(plan.resolvedTemplate.files.length, equals(3));
      expect(
          plan.resolvedTemplate.files.containsKey('lib/src/auth.dart'), isTrue);
      expect(plan.resolvedTemplate.fileProvenance['lib/src/auth.dart'],
          equals('feature_auth'));
    });

    test(
        'File collision with OverrideStrategy.fail throws CompositionConflictException',
        () {
      expect(
        () => engine.composePlan(
          request: const CompositionRequest(
            baseTemplateId: 'base_template',
            extensionIds: ['feature_override'],
            conflictPolicy: OverrideStrategy.fail,
          ),
          registry: registry,
        ),
        throwsA(isA<CompositionConflictException>()),
      );
    });

    test(
        'File collision with OverrideStrategy.override overwrites existing asset',
        () {
      final plan = engine.composePlan(
        request: const CompositionRequest(
          baseTemplateId: 'base_template',
          extensionIds: ['feature_override'],
          conflictPolicy: OverrideStrategy.override,
        ),
        registry: registry,
      );

      expect(plan.resolvedTemplate.files['README.md'],
          equals('# Overridden README'));
      expect(plan.overrideCount, equals(1));
      expect(plan.conflicts.length, equals(1));
      expect(plan.conflicts.first.resolutionPolicy,
          equals(OverrideStrategy.override));
    });

    test('File collision with OverrideStrategy.skip keeps original base asset',
        () {
      final plan = engine.composePlan(
        request: const CompositionRequest(
          baseTemplateId: 'base_template',
          extensionIds: ['feature_override'],
          conflictPolicy: OverrideStrategy.skip,
        ),
        registry: registry,
      );

      expect(plan.resolvedTemplate.files['README.md'], equals('# Base'));
      expect(plan.skipCount, equals(1));
      expect(plan.resolvedTemplate.fileProvenance['README.md'],
          equals('base_template'));
    });

    test(
        'Path traversal attempt in file template path throws PathSecurityException',
        () {
      final badRegistry = TemplateRegistry();
      badRegistry.register(_createTemplate(
        id: 'bad_path_template',
        version: '1.0.0',
        files: {'../outside.txt': 'malicious content'},
      ));

      expect(
        () => engine.composePlan(
          request:
              const CompositionRequest(baseTemplateId: 'bad_path_template'),
          registry: badRegistry,
        ),
        throwsA(isA<PathSecurityException>()),
      );
    });

    test(
        'Absolute path reference in file template throws PathSecurityException',
        () {
      final badRegistry = TemplateRegistry();
      badRegistry.register(_createTemplate(
        id: 'abs_path_template',
        version: '1.0.0',
        files: {'/etc/passwd': 'malicious content'},
      ));

      expect(
        () => engine.composePlan(
          request:
              const CompositionRequest(baseTemplateId: 'abs_path_template'),
          registry: badRegistry,
        ),
        throwsA(isA<PathSecurityException>()),
      );
    });

    test('Dependencies are automatically resolved into composition layers', () {
      final depRegistry = TemplateRegistry();
      depRegistry.register(_createTemplate(
        id: 'dep_template',
        version: '1.0.0',
        files: {'lib/src/dep.dart': '// dep'},
      ));

      depRegistry.register(_createTemplate(
        id: 'root_template',
        version: '1.0.0',
        files: {'lib/main.dart': '// main'},
        dependencies: [
          const TemplateDependency(
              templateId: 'dep_template', versionConstraint: '>=1.0.0'),
        ],
      ));

      final plan = engine.composePlan(
        request: const CompositionRequest(baseTemplateId: 'root_template'),
        registry: depRegistry,
      );

      expect(plan.layers.length, equals(2));
      expect(plan.layers[1].templateId, equals('dep_template'));
      expect(plan.layers[1].layerType, equals(LayerType.dependency));
    });

    test('CompositionPlan exports valid JSON dictionary', () {
      final plan = engine.composePlan(
        request: const CompositionRequest(baseTemplateId: 'base_template'),
        registry: registry,
      );

      final json = plan.toJson();
      expect(json['baseTemplateId'], equals('base_template'));
      expect(json['fileCount'], equals(2));
      expect(json['layers'], isA<List>());
    });
  });
}
