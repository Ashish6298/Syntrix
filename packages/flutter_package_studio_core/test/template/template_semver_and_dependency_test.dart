import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateSemVer & TemplateDependency Unit Tests', () {
    test('TemplateSemVer parses and compares version numbers correctly', () {
      final v1 = TemplateSemVer.parse('1.0.0');
      final v2 = TemplateSemVer.parse('1.2.0');
      final v3 = TemplateSemVer.parse('2.0.0');

      expect(v1 < v2, isTrue);
      expect(v2 < v3, isTrue);
      expect(v3 > v1, isTrue);
      expect(v1 == TemplateSemVer(1, 0, 0), isTrue);
    });

    test('TemplateSemVer evaluates constraint satisfaction', () {
      final v = TemplateSemVer.parse('1.5.0');

      expect(v.satisfies('>=1.0.0 <2.0.0'), isTrue);
      expect(v.satisfies('^1.0.0'), isTrue);
      expect(v.satisfies('>=2.0.0'), isFalse);
    });

    test('TemplateDependencySolver solves acyclic dependencies', () {
      final base = Template(
        manifest: const TemplateManifest(
          id: 'base_pkg',
          name: 'Base Package',
          displayName: 'Base Package',
          description: 'Base',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.5.0 <4.0.0',
        ),
      );

      final dep1 = Template(
        manifest: const TemplateManifest(
          id: 'logger_module',
          name: 'Logger Module',
          displayName: 'Logger Module',
          description: 'Logger',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.5.0 <4.0.0',
          dependencies: [TemplateDependency(templateId: 'base_pkg')],
        ),
      );

      final order = TemplateDependencySolver.solve(
        root: dep1,
        availableTemplates: {
          'base_pkg': [base],
          'logger_module': [dep1],
        },
      );

      expect(order.map((t) => t.id).toList(),
          equals(['base_pkg', 'logger_module']));
    });

    test(
        'TemplateDependencySolver throws TemplateException on circular dependency',
        () {
      final t1 = Template(
        manifest: const TemplateManifest(
          id: 'a',
          name: 'A',
          displayName: 'A',
          description: 'A',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.5.0 <4.0.0',
          dependencies: [TemplateDependency(templateId: 'b')],
        ),
      );

      final t2 = Template(
        manifest: const TemplateManifest(
          id: 'b',
          name: 'B',
          displayName: 'B',
          description: 'B',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.5.0 <4.0.0',
          dependencies: [TemplateDependency(templateId: 'a')],
        ),
      );

      expect(
        () => TemplateDependencySolver.solve(
          root: t1,
          availableTemplates: {
            'a': [t1],
            'b': [t2],
          },
        ),
        throwsA(isA<TemplateException>()),
      );
    });
  });
}
