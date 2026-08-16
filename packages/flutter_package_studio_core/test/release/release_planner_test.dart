import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('ReleasePlanner Unit Tests', () {
    late ReleasePlanner planner;

    setUp(() {
      planner = ReleasePlanner();
    });

    test('Creates release plan and validates config path safety', () {
      const options = ReleasePlanningOptions(
          packageName: 'awesome_pkg', configPath: 'release_config.json');
      final plan = planner.createReleasePlan(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.targetVersion, equals('1.0.0'));
      expect(plan.plannedChecks.length, equals(6));
    });

    test('Evaluates release readiness checks and grants readiness decision',
        () {
      const options = ReleasePlanningOptions(packageName: 'awesome_pkg');
      final plan = planner.createReleasePlan(options);
      final result = planner.evaluateReadiness(plan);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isReady, isTrue);
      expect(result.decision, equals(ReleaseDecision.ready));
      expect(result.checks.length, equals(6));

      final md = result.toMarkdown();
      expect(md, contains('# Release Readiness Plan Report: awesome_pkg'));
      expect(md, contains('READY'));
    });

    test('Rejects absolute config paths', () {
      const options = ReleasePlanningOptions(
          packageName: 'pkg', configPath: '/etc/release_config.json');
      expect(() => planner.createReleasePlan(options),
          throwsA(isA<ReleasePlanningException>()));
    });

    test('Rejects path traversal ".." in config path', () {
      const options = ReleasePlanningOptions(
          packageName: 'pkg', configPath: '../release_config.json');
      expect(() => planner.createReleasePlan(options),
          throwsA(isA<ReleasePlanningException>()));
    });
  });
}
