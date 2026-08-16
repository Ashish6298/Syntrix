import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('PackageArtifactGenerator Unit Tests', () {
    late PackageArtifactGenerator generator;

    setUp(() {
      generator = PackageArtifactGenerator();
    });

    test('Plans artifact targets and validates output directory safety', () {
      const options = ArtifactOptions(
          packageName: 'awesome_pkg',
          version: '1.0.0',
          outputDir: 'build/artifacts');
      final plan = generator.planArtifactGeneration(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.version, equals('1.0.0'));
      expect(plan.targets.length, equals(3));
    });

    test('Generates artifact results and renders Markdown report', () {
      const options = ArtifactOptions(packageName: 'awesome_pkg');
      final plan = generator.planArtifactGeneration(options);
      final result = generator.generateArtifacts(plan);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isSuccess, isTrue);
      expect(result.generatedArtifacts.length, equals(3));

      final md = result.toMarkdown();
      expect(md, contains('# Package Build & Artifact Report: awesome_pkg'));
      expect(md, contains('SUCCESS ✓'));
    });

    test('Rejects absolute output directory paths', () {
      const options =
          ArtifactOptions(packageName: 'pkg', outputDir: '/etc/artifacts');
      expect(() => generator.planArtifactGeneration(options),
          throwsA(isA<ArtifactGenerationException>()));
    });

    test('Rejects path traversal ".." in output directory', () {
      const options =
          ArtifactOptions(packageName: 'pkg', outputDir: '../artifacts');
      expect(() => generator.planArtifactGeneration(options),
          throwsA(isA<ArtifactGenerationException>()));
    });
  });
}
