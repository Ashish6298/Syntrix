import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReleaseDocumentationGenerator Unit Tests', () {
    late ReleaseDocumentationGenerator generator;

    setUp(() {
      generator = ReleaseDocumentationGenerator();
    });

    test(
        'Plans release documentation sections and validates output path safety',
        () {
      const options = ReleaseDocumentationOptions(
          packageName: 'awesome_pkg',
          version: '1.0.0',
          outputDir: 'doc/release');
      final plan = generator.planDocumentation(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.version, equals('1.0.0'));
      expect(plan.sections.length, equals(4));
    });

    test(
        'Generates release documentation result and renders Markdown bundle report',
        () {
      const options = ReleaseDocumentationOptions(packageName: 'awesome_pkg');
      final plan = generator.planDocumentation(options);
      final result = generator.generateDocumentation(plan);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isSuccess, isTrue);
      expect(result.sections.length, equals(4));

      final md = result.toMarkdown();
      expect(md, contains('# Release Documentation Bundle: awesome_pkg'));
      expect(md, contains('DOCUMENTATION BUNDLE GENERATED ✓'));
    });

    test('Rejects absolute output directory paths', () {
      const options = ReleaseDocumentationOptions(
          packageName: 'pkg', outputDir: '/etc/notes');
      expect(() => generator.planDocumentation(options),
          throwsA(isA<ReleaseDocumentationException>()));
    });

    test('Rejects path traversal ".." in output directory', () {
      const options = ReleaseDocumentationOptions(
          packageName: 'pkg', outputDir: '../notes');
      expect(() => generator.planDocumentation(options),
          throwsA(isA<ReleaseDocumentationException>()));
    });
  });
}
