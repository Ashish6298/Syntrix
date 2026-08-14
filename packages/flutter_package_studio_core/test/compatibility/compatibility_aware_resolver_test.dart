import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

Template _createTemplate({
  required String id,
  required String version,
  String minimumDartSdk = '>=3.0.0',
}) {
  return Template(
    manifest: TemplateManifest(
      id: id,
      name: id,
      displayName: id,
      description: 'Desc',
      version: version,
      projectType: 'flutter_package',
      minimumDartSdk: minimumDartSdk,
    ),
    fileTemplates: {'lib/$id.dart': '// content'},
  );
}

void main() {
  group('CompatibilityAwareResolver Tests', () {
    late TemplateRegistry registry;
    late MockSdkEnvironment stdEnv;

    setUp(() {
      registry = TemplateRegistry();
      stdEnv = const MockSdkEnvironment(
        dartVersion: '3.5.0',
        flutterVersion: '3.22.0',
        operatingSystem: 'linux',
      );

      registry.register(_createTemplate(id: 'base_pkg', version: '1.0.0'));
      registry.register(_createTemplate(id: 'base_pkg', version: '1.2.0'));
      registry.register(_createTemplate(
          id: 'base_pkg',
          version: '2.0.0',
          minimumDartSdk: '>=3.8.0')); // Incompatible
      registry.register(_createTemplate(id: 'ext_pkg', version: '1.0.0'));
    });

    test('resolve selects highest compatible version', () {
      final resolver = CompatibilityAwareResolver(
        registry: registry,
        environment: stdEnv,
      );

      final resolved = resolver.resolve(templateId: 'base_pkg');
      expect(resolved.baseTemplate.version, equals('1.2.0'));
    });

    test('resolve respects explicit versionConstraint when compatible', () {
      final resolver = CompatibilityAwareResolver(
        registry: registry,
        environment: stdEnv,
      );

      final resolved = resolver.resolve(
        templateId: 'base_pkg',
        versionConstraint: '^1.0.0',
      );
      expect(resolved.baseTemplate.version, equals('1.2.0'));
    });

    test(
        'resolve throws CompatibilityException when requested template has no compatible version',
        () {
      final resolver = CompatibilityAwareResolver(
        registry: registry,
        environment: const MockSdkEnvironment(
            dartVersion: '2.19.0'), // Incompatible with all
      );

      expect(
        () => resolver.resolve(templateId: 'base_pkg'),
        throwsA(isA<CompatibilityException>()),
      );
    });

    test('resolve throws TemplateException when template ID does not exist',
        () {
      final resolver = CompatibilityAwareResolver(
        registry: registry,
        environment: stdEnv,
      );

      expect(
        () => resolver.resolve(templateId: 'nonexistent_id'),
        throwsA(isA<TemplateException>()),
      );
    });

    test('resolve handles extensions with compatibility checks', () {
      final resolver = CompatibilityAwareResolver(
        registry: registry,
        environment: stdEnv,
      );

      final resolved = resolver.resolve(
        templateId: 'base_pkg',
        extensionIds: ['ext_pkg'],
      );

      expect(resolved.baseTemplate.id, equals('base_pkg'));
      expect(resolved.extensions.length, equals(1));
      expect(resolved.extensions.first.id, equals('ext_pkg'));
    });

    test('evaluateTemplate provides diagnostic report without resolving', () {
      final resolver = CompatibilityAwareResolver(
        registry: registry,
        environment: stdEnv,
      );

      final report =
          resolver.evaluateTemplate('base_pkg', versionConstraint: '2.0.0');
      expect(report.isCompatible, isFalse);
      expect(report.templateVersion, equals('2.0.0'));
      expect(report.errors.first.axis, equals(CompatibilityIssueAxis.dartSdk));
    });
  });
}
