import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReleaseRollbackManager Unit Tests', () {
    late ReleaseRollbackManager manager;

    setUp(() {
      manager = ReleaseRollbackManager();
    });

    test('Plans release rollback preview and validates path safety', () {
      const options = RollbackOptions(
          packageName: 'awesome_pkg',
          currentVersion: '1.1.0',
          targetVersion: '1.0.0',
          outputDir: 'doc/release');
      final plan = manager.planRollback(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.currentVersion, equals('1.1.0'));
      expect(plan.target.version, equals('1.0.0'));
      expect(plan.status, equals(RollbackStatus.planned));
    });

    test(
        'Executes rollback dry-run in preview mode by default (recover: false)',
        () {
      const options = RollbackOptions(packageName: 'awesome_pkg');
      final plan = manager.planRollback(options);
      final result = manager.executeRollback(plan, recover: false);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isSuccess, isTrue);
      expect(result.status, equals(RollbackStatus.dryRunSuccess));

      final md = result.toMarkdown();
      expect(md, contains('# Release Rollback & Recovery Report: awesome_pkg'));
      expect(md, contains('DRYRUNSUCCESS'));
    });

    test('Executes recovery when recover flag is true', () {
      const options = RollbackOptions(packageName: 'awesome_pkg');
      final plan = manager.planRollback(options);
      final result = manager.executeRollback(plan, recover: true);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isSuccess, isTrue);
      expect(result.status, equals(RollbackStatus.recovered));
    });

    test('Rejects absolute output directory paths', () {
      const options =
          RollbackOptions(packageName: 'pkg', outputDir: '/etc/rollback');
      expect(() => manager.planRollback(options),
          throwsA(isA<ReleaseRollbackException>()));
    });

    test('Rejects path traversal ".." in output directory', () {
      const options =
          RollbackOptions(packageName: 'pkg', outputDir: '../rollback');
      expect(() => manager.planRollback(options),
          throwsA(isA<ReleaseRollbackException>()));
    });
  });
}
