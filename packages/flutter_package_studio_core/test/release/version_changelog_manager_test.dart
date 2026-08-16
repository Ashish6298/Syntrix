import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('VersionChangelogManager Unit Tests', () {
    late VersionChangelogManager manager;

    setUp(() {
      manager = VersionChangelogManager();
    });

    test('Plans version bump for patch, minor, and major correctly', () {
      const patchOptions = VersionOptions(
          packageName: 'awesome_pkg',
          currentVersion: '1.0.0',
          type: VersionChangeType.patch);
      final patchPlan = manager.planVersionBump(patchOptions);
      expect(patchPlan.targetVersion, equals('1.0.1'));

      const minorOptions = VersionOptions(
          packageName: 'awesome_pkg',
          currentVersion: '1.0.0',
          type: VersionChangeType.minor);
      final minorPlan = manager.planVersionBump(minorOptions);
      expect(minorPlan.targetVersion, equals('1.1.0'));

      const majorOptions = VersionOptions(
          packageName: 'awesome_pkg',
          currentVersion: '1.0.0',
          type: VersionChangeType.major);
      final majorPlan = manager.planVersionBump(majorOptions);
      expect(majorPlan.targetVersion, equals('2.0.0'));
    });

    test('Rejects version downgrade attempt', () {
      const options = VersionOptions(
        packageName: 'awesome_pkg',
        currentVersion: '2.0.0',
        type: VersionChangeType.explicit,
        explicitVersion: '1.5.0',
      );

      expect(() => manager.planVersionBump(options),
          throwsA(isA<VersioningException>()));
    });

    test('Rejects absolute changelog paths', () {
      const options = VersionOptions(
          packageName: 'pkg', changelogPath: '/etc/CHANGELOG.md');
      expect(() => manager.planVersionBump(options),
          throwsA(isA<VersioningException>()));
    });

    test('Rejects path traversal ".." in changelog path', () {
      const options =
          VersionOptions(packageName: 'pkg', changelogPath: '../CHANGELOG.md');
      expect(() => manager.planVersionBump(options),
          throwsA(isA<VersioningException>()));
    });
  });
}
