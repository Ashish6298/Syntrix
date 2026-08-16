import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('PackagePublishingManager Unit Tests', () {
    late PackagePublishingManager manager;

    setUp(() {
      manager = PackagePublishingManager();
    });

    test('Plans package publishing and validates output path safety', () {
      const options = PublishingOptions(
          packageName: 'awesome_pkg',
          version: '1.0.0',
          outputDir: 'doc/release');
      final plan = manager.planPublishing(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.version, equals('1.0.0'));
      expect(plan.target.name, contains('pub.dev'));
      expect(plan.status, equals(PublishingStatus.planned));
    });

    test(
        'Executes publishing dry-run in preview mode by default (publish: false)',
        () {
      const options = PublishingOptions(packageName: 'awesome_pkg');
      final plan = manager.planPublishing(options);
      final result = manager.executePublishing(plan, publish: false);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isSuccess, isTrue);
      expect(result.status, equals(PublishingStatus.dryRunSuccess));

      final md = result.toMarkdown();
      expect(md, contains('# Package Publishing Report: awesome_pkg'));
      expect(md, contains('DRYRUNSUCCESS'));
    });

    test('Executes publication when publish flag is true', () {
      const options = PublishingOptions(packageName: 'awesome_pkg');
      final plan = manager.planPublishing(options);
      final result = manager.executePublishing(plan, publish: true);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isSuccess, isTrue);
      expect(result.status, equals(PublishingStatus.published));
    });

    test('Rejects absolute output directory paths', () {
      const options =
          PublishingOptions(packageName: 'pkg', outputDir: '/etc/publish');
      expect(() => manager.planPublishing(options),
          throwsA(isA<PackagePublishingException>()));
    });

    test('Rejects path traversal ".." in output directory', () {
      const options =
          PublishingOptions(packageName: 'pkg', outputDir: '../publish');
      expect(() => manager.planPublishing(options),
          throwsA(isA<PackagePublishingException>()));
    });
  });
}
