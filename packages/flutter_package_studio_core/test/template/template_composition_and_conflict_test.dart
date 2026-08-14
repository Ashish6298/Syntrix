import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('Template Composition & Conflict Resolution Tests', () {
    test(
        'TemplateCompositionEngine composes non-conflicting templates with file provenance',
        () {
      final base = Template(
        manifest: const TemplateManifest(
          id: 'base',
          name: 'Base',
          displayName: 'Base',
          description: 'Base',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.5.0 <4.0.0',
        ),
        fileTemplates: {'lib/main.dart': '// Base main'},
      );

      final ext = Template(
        manifest: const TemplateManifest(
          id: 'feature_auth',
          name: 'Auth Feature',
          displayName: 'Auth Feature',
          description: 'Auth',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.5.0 <4.0.0',
        ),
        fileTemplates: {'lib/auth.dart': '// Auth module'},
      );

      final resolved = TemplateCompositionEngine.compose(
        baseTemplate: base,
        extensions: [ext],
      );

      expect(resolved.files.length, equals(2));
      expect(resolved.fileProvenance['lib/main.dart'], equals('base'));
      expect(resolved.fileProvenance['lib/auth.dart'], equals('feature_auth'));
    });

    test(
        'TemplateCompositionEngine throws TemplateException on collision with OverrideStrategy.fail',
        () {
      final base = Template(
        manifest: const TemplateManifest(
          id: 'base',
          name: 'Base',
          displayName: 'Base',
          description: 'Base',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.5.0 <4.0.0',
        ),
        fileTemplates: {'lib/main.dart': '// Base main'},
      );

      final ext = Template(
        manifest: const TemplateManifest(
          id: 'ext_conflict',
          name: 'Conflict',
          displayName: 'Conflict',
          description: 'Conflict',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.5.0 <4.0.0',
        ),
        fileTemplates: {'lib/main.dart': '// Overwriting main'},
      );

      expect(
        () => TemplateCompositionEngine.compose(
          baseTemplate: base,
          extensions: [ext],
          strategy: OverrideStrategy.fail,
        ),
        throwsA(isA<TemplateException>()),
      );
    });

    test(
        'TemplateCompositionEngine applies override with OverrideStrategy.override',
        () {
      final base = Template(
        manifest: const TemplateManifest(
          id: 'base',
          name: 'Base',
          displayName: 'Base',
          description: 'Base',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.5.0 <4.0.0',
        ),
        fileTemplates: {'lib/main.dart': '// Base main'},
      );

      final ext = Template(
        manifest: const TemplateManifest(
          id: 'ext_override',
          name: 'Override',
          displayName: 'Override',
          description: 'Override',
          version: '1.0.0',
          projectType: 'flutter_package',
          minimumDartSdk: '>=3.5.0 <4.0.0',
        ),
        fileTemplates: {'lib/main.dart': '// New main content'},
      );

      final resolved = TemplateCompositionEngine.compose(
        baseTemplate: base,
        extensions: [ext],
        strategy: OverrideStrategy.override,
      );

      expect(resolved.files.length, equals(1));
      expect(resolved.files['lib/main.dart'], equals('// New main content'));
      expect(resolved.fileProvenance['lib/main.dart'], equals('ext_override'));
    });
  });
}
