import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

Template _createTestTemplate({
  String id = 'test_pkg',
  String version = '1.0.0',
  String minimumDartSdk = '>=2.19.0 <4.0.0',
  String? minimumFlutterSdk = '>=3.22.0',
  List<String> supportedPlatforms = const ['android', 'ios', 'linux'],
  String projectType = 'flutter_package',
  List<String> capabilities = const ['package'],
  List<TemplateDependency> dependencies = const [],
}) {
  return Template(
    manifest: TemplateManifest(
      id: id,
      name: id,
      displayName: 'Test Package $id',
      description: 'Test template description',
      version: version,
      projectType: projectType,
      minimumDartSdk: minimumDartSdk,
      minimumFlutterSdk: minimumFlutterSdk,
      supportedPlatforms: supportedPlatforms,
      capabilities: capabilities,
      dependencies: dependencies,
    ),
  );
}

void main() {
  group('CompatibilityEvaluator Tests', () {
    late MockSdkEnvironment stdEnv;

    setUp(() {
      stdEnv = const MockSdkEnvironment(
        dartVersion: '3.5.0',
        flutterVersion: '3.22.0',
        operatingSystem: 'linux',
      );
    });

    test('Compatible template passes evaluation with zero errors', () {
      final template = _createTestTemplate();
      final evaluator = CompatibilityEvaluator(
        environment: stdEnv,
        policy: CompatibilityPolicy.standard,
      );

      final result = evaluator.evaluate(template);
      expect(result.isCompatible, isTrue);
      expect(result.errorCount, equals(0));
      expect(result.templateId, equals('test_pkg'));
      expect(result.templateVersion, equals('1.0.0'));
    });

    test('Incompatible Dart SDK fails evaluation', () {
      final template = _createTestTemplate(minimumDartSdk: '>=3.6.0');
      final evaluator = CompatibilityEvaluator(
        environment: stdEnv,
        policy: CompatibilityPolicy.standard,
      );

      final result = evaluator.evaluate(template);
      expect(result.isCompatible, isFalse);
      expect(result.errorCount, equals(1));
      expect(result.errors.first.axis, equals(CompatibilityIssueAxis.dartSdk));
      expect(result.errors.first.message, contains('Dart SDK 3.5.0'));
    });

    test(
        'Missing Flutter SDK in Dart-only environment fails when Flutter SDK is required',
        () {
      final template = _createTestTemplate(minimumFlutterSdk: '>=3.22.0');
      final evaluator = CompatibilityEvaluator(
        environment: MockSdkEnvironment.dartOnly,
        policy: CompatibilityPolicy.standard,
      );

      final result = evaluator.evaluate(template);
      expect(result.isCompatible, isFalse);
      expect(
          result.errors.first.axis, equals(CompatibilityIssueAxis.flutterSdk));
      expect(result.errors.first.message, contains('Flutter is not available'));
    });

    test('Requested project type mismatch generates error', () {
      final template = _createTestTemplate(projectType: 'flutter_package');
      final evaluator = CompatibilityEvaluator(
        environment: stdEnv,
        policy: CompatibilityPolicy.standard,
      );

      final result =
          evaluator.evaluate(template, requiredProjectType: 'dart_cli');
      expect(result.isCompatible, isFalse);
      expect(
          result.errors.first.axis, equals(CompatibilityIssueAxis.projectType));
    });

    test('Platform mismatch under strict policy generates warning', () {
      final template =
          _createTestTemplate(supportedPlatforms: ['android', 'ios']);
      final evaluator = CompatibilityEvaluator(
        environment: stdEnv, // OS is linux
        policy: CompatibilityPolicy.strict,
      );

      final result = evaluator.evaluate(template);
      expect(result.isCompatible,
          isTrue); // Warning does not block compatibility in strict mode
      expect(result.warningCount, equals(1));
      expect(
          result.warnings.first.axis, equals(CompatibilityIssueAxis.platform));
    });

    test('Platform mismatch under release policy generates error', () {
      final template =
          _createTestTemplate(supportedPlatforms: ['android', 'ios']);
      final evaluator = CompatibilityEvaluator(
        environment: stdEnv, // OS is linux
        policy: CompatibilityPolicy.release,
      );

      final result = evaluator.evaluate(template);
      expect(result.isCompatible,
          isFalse); // Release policy promotes warning to error
      expect(result.errorCount, equals(1));
    });

    test('Missing capability under strict policy generates error', () {
      final template = _createTestTemplate(capabilities: ['package']);
      final evaluator = CompatibilityEvaluator(
        environment: stdEnv,
        policy: CompatibilityPolicy.strict,
      );

      final result = evaluator.evaluate(
        template,
        requiredCapabilities: ['federated_plugin'],
      );

      expect(result.isCompatible, isFalse);
      expect(
          result.errors.first.axis, equals(CompatibilityIssueAxis.capability));
    });

    test(
        'Unsatisfied required template dependency under strict policy generates error',
        () {
      final template = _createTestTemplate(
        dependencies: [
          const TemplateDependency(
              templateId: 'base_template', versionConstraint: '>=2.0.0'),
        ],
      );

      final registry = TemplateRegistry();
      registry
          .register(_createTestTemplate(id: 'base_template', version: '1.0.0'));

      final evaluator = CompatibilityEvaluator(
        environment: stdEnv,
        policy: CompatibilityPolicy.strict,
      );

      final result = evaluator.evaluate(template, availableTemplates: registry);
      expect(result.isCompatible, isFalse);
      expect(
          result.errors.first.axis, equals(CompatibilityIssueAxis.dependency));
    });

    test(
        'Permissive policy ignores Flutter SDK, platform, and capability checks',
        () {
      final template = _createTestTemplate(
        minimumDartSdk: '>=3.0.0',
        minimumFlutterSdk: '>=9.9.9', // Impossible Flutter version
        supportedPlatforms: ['windows'],
      );

      final evaluator = CompatibilityEvaluator(
        environment: MockSdkEnvironment.dartOnly, // OS linux, no Flutter
        policy: CompatibilityPolicy.permissive,
      );

      final result = evaluator.evaluate(
        template,
        requiredProjectType: 'different_type',
        requiredCapabilities: ['missing_cap'],
      );

      expect(result.isCompatible, isTrue);
      expect(result.issues, isEmpty);
    });

    test('evaluateAllVersions groups results by version', () {
      final registry = TemplateRegistry();
      registry.register(
          _createTestTemplate(version: '1.0.0', minimumDartSdk: '>=3.0.0'));
      registry.register(
          _createTestTemplate(version: '2.0.0', minimumDartSdk: '>=3.6.0'));

      final evaluator = CompatibilityEvaluator(
        environment: stdEnv, // Dart 3.5.0
        policy: CompatibilityPolicy.standard,
      );

      final multiRes = evaluator.evaluateAllVersions('test_pkg', registry);
      expect(multiRes.templateId, equals('test_pkg'));
      expect(multiRes.resultsByVersion.length, equals(2));
      expect(multiRes.resultsByVersion['1.0.0']!.isCompatible, isTrue);
      expect(multiRes.resultsByVersion['2.0.0']!.isCompatible, isFalse);
      expect(multiRes.compatibleVersions, equals(['1.0.0']));
      expect(multiRes.highestCompatibleVersion, equals('1.0.0'));
    });

    test('selectBestCompatibleVersion picks highest compatible version', () {
      final registry = TemplateRegistry();
      registry.register(
          _createTestTemplate(version: '1.0.0', minimumDartSdk: '>=3.0.0'));
      registry.register(
          _createTestTemplate(version: '1.5.0', minimumDartSdk: '>=3.0.0'));
      registry.register(_createTestTemplate(
          version: '2.0.0', minimumDartSdk: '>=3.9.0')); // Incompatible

      final evaluator = CompatibilityEvaluator(
        environment: stdEnv, // Dart 3.5.0
        policy: CompatibilityPolicy.standard,
      );

      final selected =
          evaluator.selectBestCompatibleVersion('test_pkg', registry);
      expect(selected, isNotNull);
      expect(selected!.version, equals('1.5.0'));
    });
  });
}
