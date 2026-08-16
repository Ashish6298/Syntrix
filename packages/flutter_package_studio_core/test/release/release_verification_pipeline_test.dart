import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReleaseVerificationPipeline Unit Tests', () {
    late ReleaseVerificationPipeline pipeline;

    setUp(() {
      pipeline = ReleaseVerificationPipeline();
    });

    test('Plans release verification stages and validates output path safety',
        () {
      const options = ReleaseVerificationOptions(
          packageName: 'awesome_pkg',
          version: '1.0.0',
          outputDir: 'doc/release');
      final plan = pipeline.planPipeline(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.version, equals('1.0.0'));
      expect(plan.stages.length, equals(6));
    });

    test(
        'Executes release verification pipeline and returns ready release decision',
        () {
      const options = ReleaseVerificationOptions(packageName: 'awesome_pkg');
      final plan = pipeline.planPipeline(options);
      final result = pipeline.executePipeline(plan);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isReady, isTrue);
      expect(result.stages.length, equals(6));

      final md = result.toMarkdown();
      expect(
          md, contains('# Release Verification Pipeline Report: awesome_pkg'));
      expect(md, contains('READY FOR RELEASE'));
    });

    test('Rejects absolute output directory paths', () {
      const options = ReleaseVerificationOptions(
          packageName: 'pkg', outputDir: '/etc/verification');
      expect(() => pipeline.planPipeline(options),
          throwsA(isA<ReleaseVerificationException>()));
    });

    test('Rejects path traversal ".." in output directory', () {
      const options = ReleaseVerificationOptions(
          packageName: 'pkg', outputDir: '../verification');
      expect(() => pipeline.planPipeline(options),
          throwsA(isA<ReleaseVerificationException>()));
    });
  });
}
