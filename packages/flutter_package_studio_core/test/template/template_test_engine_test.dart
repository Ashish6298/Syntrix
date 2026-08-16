import 'package:test/test.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';

void main() {
  group('TemplateTestEngine Core Tests', () {
    late TemplateTestEngine engine;

    setUp(() {
      engine = TemplateTestEngine();
    });

    test('tests valid builtin template cleanly', () async {
      final registry = TemplateRegistry();
      BuiltinTemplates.registerDefaultTemplates(registry);
      final template = registry.get('flutter_package')!;

      final req = TemplateTestRequest(
        rawTemplate: template,
        profile: TemplateTestProfile.standard,
      );

      final report = await engine.execute(req);

      expect(report.isPassed, isTrue);
      expect(report.isTested, isTrue);
      expect(report.isEligibleForCertification, isTrue);
      expect(report.status, equals(TemplateTestStatus.passed));
      expect(report.failedCount, equals(0));
    });

    test('detects path security violation in test suite', () async {
      final template = TemplateTestFixture.unsafePathTemplate();

      final req = TemplateTestRequest(
        rawTemplate: template,
        profile: TemplateTestProfile.standard,
      );

      final report = await engine.execute(req);

      expect(report.status, equals(TemplateTestStatus.failed));
      expect(report.isPassed, isFalse);
      expect(report.isEligibleForCertification, isFalse);
      expect(report.failedCount, greaterThan(0));
    });

    test('detects invalid SemVer version in test suite', () async {
      final template = TemplateTestFixture.invalidSemverTemplate();

      final req = TemplateTestRequest(
        rawTemplate: template,
        profile: TemplateTestProfile.standard,
      );

      final report = await engine.execute(req);

      expect(report.status, equals(TemplateTestStatus.failed));
      expect(report.isPassed, isFalse);
      expect(
          report.findings
              .any((f) => f.testId == 'TEST-002-SEMVER-VALIDITY' && f.isError),
          isTrue);
    });

    test('guarantees deterministic finding sorting and JSON serialization',
        () async {
      final registry = TemplateRegistry();
      BuiltinTemplates.registerDefaultTemplates(registry);
      final template = registry.get('flutter_package')!;

      final req = TemplateTestRequest(
        rawTemplate: template,
        profile: TemplateTestProfile.standard,
      );

      final report1 = await engine.execute(req);
      final report2 = await engine.execute(req);

      final map1 = report1.toJson()..remove('totalDurationMs');
      final map2 = report2.toJson()..remove('totalDurationMs');

      for (final item in (map1['results'] as List)) {
        (item as Map).remove('durationMs');
      }
      for (final item in (map2['results'] as List)) {
        (item as Map).remove('durationMs');
      }

      expect(map1, equals(map2));
    });
  });
}
