import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

Template _createTestTemplate({
  String id = 'test_pkg',
  String version = '1.0.0',
  String minimumDartSdk = '>=3.0.0',
  String description = 'Valid description',
  Map<String, String> files = const {'lib/main.dart': '// content'},
}) {
  return Template(
    manifest: TemplateManifest(
      id: id,
      name: id,
      displayName: id,
      description: description,
      version: version,
      projectType: 'flutter_package',
      minimumDartSdk: minimumDartSdk,
    ),
    fileTemplates: files,
  );
}

void main() {
  group('TemplateQualityEngine Tests', () {
    late TemplateQualityEngine engine;

    setUp(() {
      engine = TemplateQualityEngine();
    });

    test('Valid template passes standard and release quality profile checks',
        () {
      final tmpl = _createTestTemplate();
      final report = engine.evaluateTemplate(tmpl,
          profile: TemplateQualityProfile.standard);

      expect(report.isPassed, isTrue);
      expect(report.errorCount, equals(0));
      expect(report.findings, isEmpty);
    });

    test('Missing minimumDartSdk triggers error finding under basic profile',
        () {
      final tmpl = _createTestTemplate(minimumDartSdk: '');
      final report =
          engine.evaluateTemplate(tmpl, profile: TemplateQualityProfile.basic);

      expect(report.isPassed, isFalse);
      expect(report.errorCount, equals(1));
      expect(report.findings.first.category,
          equals(TemplateQualityCategory.manifest));
    });

    test('Absolute asset path triggers security violation error finding', () {
      final tmpl = _createTestTemplate(files: {
        '/etc/passwd': 'bad content',
      });
      final report =
          engine.evaluateTemplate(tmpl, profile: TemplateQualityProfile.basic);

      expect(report.isPassed, isFalse);
      expect(report.errorCount, equals(1));
      expect(report.findings.first.category,
          equals(TemplateQualityCategory.pathSecurity));
    });

    test(
        'Path traversal in asset path triggers security violation error finding',
        () {
      final tmpl = _createTestTemplate(files: {
        '../outside.txt': 'bad content',
      });
      final report =
          engine.evaluateTemplate(tmpl, profile: TemplateQualityProfile.basic);

      expect(report.isPassed, isFalse);
      expect(report.errorCount, equals(1));
      expect(report.findings.first.category,
          equals(TemplateQualityCategory.pathSecurity));
    });

    test(
        'Empty description generates warning under strict profile and error under release profile',
        () {
      final tmpl = _createTestTemplate(description: '');

      final strictReport =
          engine.evaluateTemplate(tmpl, profile: TemplateQualityProfile.strict);
      expect(strictReport.isPassed, isTrue);
      expect(strictReport.warningCount, equals(1));

      final releaseReport = engine.evaluateTemplate(tmpl,
          profile: TemplateQualityProfile.release);
      expect(releaseReport.isPassed, isFalse);
      expect(releaseReport.errorCount, equals(1));
    });

    test('TemplateQualityReport exports valid JSON dictionary', () {
      final tmpl = _createTestTemplate();
      final report = engine.evaluateTemplate(tmpl);

      final json = report.toJson();
      expect(json['templateId'], equals('test_pkg'));
      expect(json['version'], equals('1.0.0'));
      expect(json['isPassed'], isTrue);
      expect(json['findings'], isA<List>());
    });
  });
}
