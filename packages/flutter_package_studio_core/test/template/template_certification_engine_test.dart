import 'package:test/test.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';

void main() {
  group('TemplateCertificationEngine Core Tests', () {
    late TemplateCertificationEngine engine;

    setUp(() {
      engine = TemplateCertificationEngine();
    });

    test('certifies standard valid builtin template with standard profile', () {
      final registry = TemplateRegistry();
      BuiltinTemplates.registerDefaultTemplates(registry);
      final template = registry.get('flutter_package')!;

      final req = TemplateCertificationRequest(
        rawTemplate: template,
        profile: TemplateCertificationProfile.standard,
      );

      final report = engine.evaluate(req);

      expect(report.isPassed, isTrue);
      expect(report.isGenerationEligible, isTrue);
      expect(report.status, equals(TemplateCertificationStatus.certified));
      expect(report.errorCount, equals(0));
    });

    test('evaluates release profile promoting warnings to blocking errors', () {
      final manifest = TemplateManifest(
        id: 'test_template',
        name: 'Test Template',
        displayName: 'Test Template',
        description: 'Valid description string',
        version: '1.0.0',
        projectType: 'flutter_package',
        minimumDartSdk: '>=3.5.0 <4.0.0',
      );
      final template = Template(manifest: manifest);

      final resolvedTemplate = ResolvedTemplate(
        baseTemplate: template,
        extensions: const [],
        effectiveManifest: manifest,
        fileProvenance: const {},
        files: const {'lib/main.dart': 'void main() {}'},
      );

      final compositionPlan = CompositionPlan(
        baseTemplateId: 'test_template',
        conflictPolicy: OverrideStrategy.override,
        layers: const [],
        resolvedTemplate: resolvedTemplate,
        provenanceRecords: const [],
        conflicts: const [
          CompositionConflict(
            path: 'lib/main.dart',
            existingSourceId: 'base',
            existingLayerIndex: 0,
            incomingSourceId: 'ext',
            incomingLayerIndex: 1,
            resolutionPolicy: OverrideStrategy.override,
          )
        ],
        compatibilityResults: const [],
      );

      final req = TemplateCertificationRequest(
        rawTemplate: template,
        compositionPlan: compositionPlan,
        profile: TemplateCertificationProfile.release,
      );

      final report = engine.evaluate(req);

      expect(report.profile, equals(TemplateCertificationProfile.release));
      expect(
          report.findings
              .any((f) => f.message.contains('[RELEASE PROMOTED ERROR]')),
          isTrue);
      expect(report.status, equals(TemplateCertificationStatus.failed));
      expect(report.isGenerationEligible, isFalse);
    });

    test('detects path security violation with absolute paths', () {
      final manifest = TemplateManifest(
        id: 'bad_path_template',
        name: 'Bad Path Template',
        displayName: 'Bad Path Template',
        description: 'A template with absolute path security issues.',
        version: '1.0.0',
        projectType: 'flutter_package',
        minimumDartSdk: '>=3.5.0 <4.0.0',
        files: {'/etc/passwd': 'root'},
      );
      final template = Template(manifest: manifest);

      final req = TemplateCertificationRequest(
        rawTemplate: template,
        profile: TemplateCertificationProfile.standard,
      );

      final report = engine.evaluate(req);

      expect(report.status, equals(TemplateCertificationStatus.failed));
      expect(report.errorCount, greaterThan(0));
      expect(
          report.findings
              .any((f) => f.ruleId == 'CERT-004-PATH-SECURITY' && f.isError),
          isTrue);
    });

    test('detects path security violation with directory traversal', () {
      final manifest = TemplateManifest(
        id: 'traversal_template',
        name: 'Traversal Template',
        displayName: 'Traversal Template',
        description: 'A template with path traversal sequences.',
        version: '1.0.0',
        projectType: 'flutter_package',
        minimumDartSdk: '>=3.5.0 <4.0.0',
        files: {'../outside.txt': 'data'},
      );
      final template = Template(manifest: manifest);

      final req = TemplateCertificationRequest(
        rawTemplate: template,
        profile: TemplateCertificationProfile.standard,
      );

      final report = engine.evaluate(req);

      expect(report.status, equals(TemplateCertificationStatus.failed));
      expect(
          report.findings
              .any((f) => f.ruleId == 'CERT-004-PATH-SECURITY' && f.isError),
          isTrue);
    });

    test('evaluates invalid SemVer version in manifest identity rule', () {
      final manifest = TemplateManifest(
        id: 'invalid_ver_template',
        name: 'Invalid Ver',
        displayName: 'Invalid Ver',
        description: 'Template with bad version string.',
        version: 'v1.0-invalid',
        projectType: 'flutter_package',
        minimumDartSdk: '>=3.5.0 <4.0.0',
      );
      final template = Template(manifest: manifest);

      final req = TemplateCertificationRequest(
        rawTemplate: template,
        profile: TemplateCertificationProfile.standard,
      );

      final report = engine.evaluate(req);

      expect(report.status, equals(TemplateCertificationStatus.failed));
      expect(
          report.findings.any(
              (f) => f.ruleId == 'CERT-001-MANIFEST-IDENTITY' && f.isError),
          isTrue);
    });

    test('evaluates hook security and failure report in certification', () {
      final manifest = TemplateManifest(
        id: 'hook_tpl',
        name: 'Hook Template',
        displayName: 'Hook Template',
        description: 'Template with failing hook report.',
        version: '1.0.0',
        projectType: 'flutter_package',
        minimumDartSdk: '>=3.5.0 <4.0.0',
      );
      final template = Template(manifest: manifest);

      final hookReport = TemplateHookLifecycleReport(
        templateId: 'hook_tpl',
        isSuccess: false,
        isDryRun: true,
        results: [
          TemplateHookResult.failure(
            hookId: 'failing_hook',
            phase: TemplateHookPhase.preGeneration,
            duration: Duration.zero,
            error: 'Hook execution failed',
          )
        ],
        aggregatedActions: [],
        totalDuration: Duration.zero,
      );

      final req = TemplateCertificationRequest(
        rawTemplate: template,
        hookReport: hookReport,
        profile: TemplateCertificationProfile.standard,
      );

      final report = engine.evaluate(req);

      expect(report.status, equals(TemplateCertificationStatus.failed));
      expect(
          report.findings
              .any((f) => f.ruleId == 'CERT-007-HOOK-SECURITY' && f.isError),
          isTrue);
    });

    test('guarantees deterministic finding sorting and JSON serialization', () {
      final registry = TemplateRegistry();
      BuiltinTemplates.registerDefaultTemplates(registry);
      final template = registry.get('flutter_package')!;

      final req = TemplateCertificationRequest(
        rawTemplate: template,
        profile: TemplateCertificationProfile.standard,
      );

      final report1 = engine.evaluate(req);
      final report2 = engine.evaluate(req);

      expect(report1.toJson(), equals(report2.toJson()));
    });
  });
}
