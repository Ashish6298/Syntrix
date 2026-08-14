import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateResolver & TemplateRegistry Integration Tests', () {
    late TemplateRegistry registry;
    late TemplateResolver resolver;

    setUp(() {
      registry = TemplateRegistry();
      resolver = TemplateResolver(registry: registry);

      final v1 = Template(
        manifest: const TemplateManifest(
          id: 'standard_pkg',
          name: 'Standard Package',
          displayName: 'Standard Package',
          description: 'Standard',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.5.0 <4.0.0',
          capabilities: ['package', 'library'],
          tags: ['core'],
        ),
      );

      final v2 = Template(
        manifest: const TemplateManifest(
          id: 'standard_pkg',
          name: 'Standard Package',
          displayName: 'Standard Package',
          description: 'Standard V2',
          version: '2.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.5.0 <4.0.0',
          capabilities: ['package', 'library'],
          tags: ['core'],
        ),
      );

      registry.register(v1);
      registry.register(v2);
    });

    test('Registry resolves highest matching version by default', () {
      final t = registry.resolve('standard_pkg');
      expect(t, isNotNull);
      expect(t!.version, equals('2.0.0'));
    });

    test('Registry resolves version matching constraint', () {
      final t =
          registry.resolve('standard_pkg', versionConstraint: '>=1.0.0 <2.0.0');
      expect(t, isNotNull);
      expect(t!.version, equals('1.0.0'));
    });

    test('TemplateResolver resolves base template into ResolvedTemplate', () {
      final resolved = resolver.resolve(
          templateId: 'standard_pkg', versionConstraint: '^1.0.0');
      expect(resolved.id, equals('standard_pkg'));
      expect(resolved.version, equals('1.0.0'));
    });

    test(
        'ProjectGenerator builds plan from ResolvedTemplate with file provenance',
        () {
      final t = registry.resolve('standard_pkg')!;
      final resolved = TemplateCompositionEngine.compose(baseTemplate: t);

      final generator = ProjectGenerator();
      final plan = generator.buildPlanFromResolved(
        resolvedTemplate: resolved,
        context: TemplateContext({'package_name': 'test_resolved'}),
        outputDirectory: './target',
      );

      expect(plan.templateId, equals('standard_pkg'));
      expect(plan.targetDirectory, isNotEmpty);
    });
  });
}
