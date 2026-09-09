import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('SemanticVersionManager & SemVer 2.0.0 Unit Tests', () {
    late SemanticVersionManager manager;

    setUp(() {
      manager = SemanticVersionManager();
    });

    test('Parses standard semantic versions correctly', () {
      final v = manager.parseVersion('1.2.3');
      expect(v.major, equals(1));
      expect(v.minor, equals(2));
      expect(v.patch, equals(3));
      expect(v.isPrerelease, isFalse);
      expect(v.toString(), equals('1.2.3'));
    });

    test('Parses prerelease versions with dot-separated identifiers', () {
      final v = manager.parseVersion('1.0.0-alpha.1');
      expect(v.major, equals(1));
      expect(v.minor, equals(0));
      expect(v.patch, equals(0));
      expect(v.isPrerelease, isTrue);
      expect(v.prerelease, equals(['alpha', '1']));
      expect(v.toString(), equals('1.0.0-alpha.1'));
    });

    test('Parses build metadata and ignores it in precedence comparison', () {
      final v1 = manager.parseVersion('1.0.0+build.1');
      final v2 = manager.parseVersion('1.0.0+build.999');
      expect(v1.build, equals(['build', '1']));
      expect(v1.compareTo(v2), equals(0));
      expect(v1 == v2, isTrue);
    });

    test('Enforces SemVer 2.0.0 precedence rules correctly', () {
      expect(
          manager.compareVersions('1.0.0-alpha', '1.0.0-alpha.1'), lessThan(0));
      expect(manager.compareVersions('1.0.0-alpha.1', '1.0.0-alpha.beta'),
          lessThan(0));
      expect(manager.compareVersions('1.0.0-alpha.beta', '1.0.0-beta'),
          lessThan(0));
      expect(
          manager.compareVersions('1.0.0-beta', '1.0.0-beta.2'), lessThan(0));
      expect(manager.compareVersions('1.0.0-beta.2', '1.0.0-beta.11'),
          lessThan(0));
      expect(
          manager.compareVersions('1.0.0-beta.11', '1.0.0-rc.1'), lessThan(0));
      expect(manager.compareVersions('1.0.0-rc.1', '1.0.0'), lessThan(0));
    });

    test('Rejects invalid versions and malformed inputs', () {
      expect(() => manager.parseVersion(''),
          throwsA(isA<SemanticVersionException>()));
      expect(() => manager.parseVersion('1.2'),
          throwsA(isA<SemanticVersionException>()));
      expect(() => manager.parseVersion('1.2.3.4'),
          throwsA(isA<SemanticVersionException>()));
      expect(() => manager.parseVersion('01.2.3'),
          throwsA(isA<SemanticVersionException>()));
      expect(() => manager.parseVersion('1.0.0-alpha.01'),
          throwsA(isA<SemanticVersionException>()));
    });

    test('Plans major, minor, patch increments correctly', () {
      const pOptions = SemVerOptions(
          packageName: 'pkg',
          currentVersion: '1.0.0',
          type: SemVerIncrementType.patch);
      expect(manager.planTransition(pOptions).targetVersion.toString(),
          equals('1.0.1'));

      const mOptions = SemVerOptions(
          packageName: 'pkg',
          currentVersion: '1.0.0',
          type: SemVerIncrementType.minor);
      expect(manager.planTransition(mOptions).targetVersion.toString(),
          equals('1.1.0'));

      const majOptions = SemVerOptions(
          packageName: 'pkg',
          currentVersion: '1.0.0',
          type: SemVerIncrementType.major);
      expect(manager.planTransition(majOptions).targetVersion.toString(),
          equals('2.0.0'));
    });

    test('Handles prerelease numeric incrementing and stable promotion', () {
      const pre1Options = SemVerOptions(
          packageName: 'pkg',
          currentVersion: '1.0.0',
          type: SemVerIncrementType.prerelease,
          prereleaseId: 'alpha');
      expect(manager.planTransition(pre1Options).targetVersion.toString(),
          equals('1.0.1-alpha.1'));

      const pre2Options = SemVerOptions(
          packageName: 'pkg',
          currentVersion: '1.0.1-alpha.1',
          type: SemVerIncrementType.prerelease);
      expect(manager.planTransition(pre2Options).targetVersion.toString(),
          equals('1.0.1-alpha.2'));

      // Promoting prerelease 1.0.1-alpha.2 to patch (stable) -> 1.0.1
      const promOptions = SemVerOptions(
          packageName: 'pkg',
          currentVersion: '1.0.1-alpha.2',
          type: SemVerIncrementType.patch);
      expect(manager.planTransition(promOptions).targetVersion.toString(),
          equals('1.0.1'));
    });

    test('Rejects version downgrade attempt', () {
      const options = SemVerOptions(
        packageName: 'pkg',
        currentVersion: '2.0.0',
        type: SemVerIncrementType.explicit,
        explicitVersion: '1.9.9',
      );
      expect(() => manager.planTransition(options),
          throwsA(isA<SemanticVersionException>()));
    });

    test('Rejects absolute output directory paths and path traversal ".." ',
        () {
      const absOptions =
          SemVerOptions(packageName: 'pkg', outputDir: '/etc/release');
      expect(() => manager.planTransition(absOptions),
          throwsA(isA<SemanticVersionException>()));

      const travOptions =
          SemVerOptions(packageName: 'pkg', outputDir: '../release');
      expect(() => manager.planTransition(travOptions),
          throwsA(isA<SemanticVersionException>()));
    });
  });
}
