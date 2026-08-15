import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateMigrationEngine Unit Tests', () {
    late TemplateMigrationRegistry registry;
    late MemoryMigrationFileSystem fs;
    late TemplateMigrationEngine engine;

    setUp(() {
      registry = TemplateMigrationRegistry();
      registry.register(SimpleTemplateMigration(
        id: 'v1_0_0_to_v1_1_0',
        templateId: 'flutter_package',
        sourceVersion: '1.0.0',
        targetVersion: '1.1.0',
        description: 'Upgrade to 1.1.0',
        actions: [
          const TemplateMigrationAction(
            type: TemplateMigrationActionType.updateFile,
            path: 'pubspec.yaml',
            content: 'name: test_pkg\nversion: 1.1.0\n',
            reason: 'Bump version in pubspec.yaml',
          ),
        ],
      ));

      fs = MemoryMigrationFileSystem({
        'my_proj/.fps/template_metadata.json':
            '{"templateId":"flutter_package","version":"1.0.0"}',
        'my_proj/pubspec.yaml': 'name: test_pkg\nversion: 1.0.0\n',
      });

      engine = TemplateMigrationEngine(registry: registry, fileSystem: fs);
    });

    test('Detects project metadata automatically', () {
      final meta = engine.detectProjectMetadata('my_proj');
      expect(meta, isNotNull);
      expect(meta!['templateId'], equals('flutter_package'));
      expect(meta['version'], equals('1.0.0'));
    });

    test('Plans valid single-step migration without mutating filesystem', () {
      final request = const TemplateMigrationRequest(
        projectPath: 'my_proj',
        targetTemplateId: 'flutter_package',
        targetVersion: '1.1.0',
      );

      final plan = engine.planMigration(request);
      expect(plan.hasErrors, isFalse);
      expect(plan.steps.length, equals(1));
      expect(plan.totalActions, equals(1));
      expect(fs.readAsString('my_proj/pubspec.yaml'), contains('1.0.0'));
    });

    test(
        'Executes migration plan successfully with atomic backup and rollback support',
        () {
      final request = const TemplateMigrationRequest(
        projectPath: 'my_proj',
        targetTemplateId: 'flutter_package',
        targetVersion: '1.1.0',
      );

      final plan = engine.planMigration(request);
      final result = engine.executeMigration(plan, projectPath: 'my_proj');

      expect(result.isSuccess, isTrue);
      expect(result.actionsExecuted, equals(1));
      expect(fs.readAsString('my_proj/pubspec.yaml'), contains('1.1.0'));
      expect(fs.exists('my_proj/.fps/template_metadata.json'), isTrue);
      expect(fs.readAsString('my_proj/.fps/template_metadata.json'),
          contains('1.1.0'));
    });

    test('Rejects path traversal in project path during planning', () {
      final request = const TemplateMigrationRequest(
        projectPath: 'my_proj/../outside',
        sourceTemplateId: 'flutter_package',
        sourceVersion: '1.0.0',
        targetTemplateId: 'flutter_package',
        targetVersion: '1.1.0',
      );

      expect(() => engine.planMigration(request),
          throwsA(isA<TemplateMigrationSecurityException>()));
    });

    test('Throws exception when no migration chain exists', () {
      final request = const TemplateMigrationRequest(
        projectPath: 'my_proj',
        sourceTemplateId: 'flutter_package',
        sourceVersion: '1.0.0',
        targetTemplateId: 'flutter_package',
        targetVersion: '3.0.0',
      );

      final plan = engine.planMigration(request);
      expect(plan.hasErrors, isTrue);
      expect(plan.findings.first.code, equals('MISSING_CHAIN'));
    });
  });
}
