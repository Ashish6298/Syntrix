import 'dart:convert';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReleaseArtifactManifestGenerator Unit Tests', () {
    late ReleaseArtifactManifestGenerator generator;

    setUp(() {
      generator = ReleaseArtifactManifestGenerator();
    });

    test('Plans release artifact manifest entries and computes SHA-256 digests',
        () {
      const options = ManifestOptions(
          packageName: 'awesome_pkg',
          version: '1.0.0',
          artifactDir: 'build/artifacts');
      final plan = generator.planManifest(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.version, equals('1.0.0'));
      expect(plan.entries.length, equals(3));

      final expectedHash = ReleaseArtifactManifestGenerator.calculateSha256(
          utf8.encode('awesome_pkg-1.0.0'));
      expect(plan.entries.first.checksum.value, equals(expectedHash));
    });

    test('Generates release artifact manifest result and verifies integrity',
        () {
      const options = ManifestOptions(packageName: 'awesome_pkg');
      final plan = generator.planManifest(options);
      final result = generator.generateManifest(plan);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isVerified, isTrue);
      expect(result.entries.length, equals(3));
      expect(generator.verifyManifest(result), isTrue);

      final md = result.toMarkdown();
      expect(md, contains('# Release Artifact Manifest Report: awesome_pkg'));
      expect(md, contains('VERIFIED ✓'));
    });

    test('Rejects absolute artifact directory paths', () {
      const options =
          ManifestOptions(packageName: 'pkg', artifactDir: '/etc/artifacts');
      expect(() => generator.planManifest(options),
          throwsA(isA<ReleaseArtifactManifestException>()));
    });

    test('Rejects path traversal ".." in artifact directory', () {
      const options =
          ManifestOptions(packageName: 'pkg', artifactDir: '../artifacts');
      expect(() => generator.planManifest(options),
          throwsA(isA<ReleaseArtifactManifestException>()));
    });

    test('Rejects absolute output directory paths', () {
      const options =
          ManifestOptions(packageName: 'pkg', outputDir: '/etc/release');
      expect(() => generator.planManifest(options),
          throwsA(isA<ReleaseArtifactManifestException>()));
    });
  });
}
