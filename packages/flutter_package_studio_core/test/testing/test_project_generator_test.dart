import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('TestProjectGenerator Unit Tests', () {
    late TestProjectGenerator generator;

    setUp(() {
      generator = TestProjectGenerator();
    });

    test('Plans and generates valid test project structure', () {
      const options = TestProjectOptions(packageName: 'awesome_pkg');
      final plan = generator.planTestProject(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.relativeFilePaths.length, equals(3));
      expect(plan.relativeFilePaths, contains('pubspec.yaml'));
      expect(plan.relativeFilePaths, contains('analysis_options.yaml'));
      expect(plan.relativeFilePaths, contains('test/awesome_pkg_test.dart'));

      final result = generator.generateTestProject(plan, options);
      expect(result.files['pubspec.yaml'], contains('awesome_pkg_test_runner'));
      expect(result.files['test/awesome_pkg_test.dart'],
          contains('awesome_pkg Test Project Suite'));
    });

    test('Rejects empty package names', () {
      const options = TestProjectOptions(packageName: '');
      expect(() => generator.planTestProject(options),
          throwsA(isA<TestProjectGenerationException>()));
    });

    test('Rejects invalid package names', () {
      const options = TestProjectOptions(packageName: 'Invalid-Pkg!');
      expect(() => generator.planTestProject(options),
          throwsA(isA<TestProjectGenerationException>()));
    });

    test('Rejects absolute target directories', () {
      const options = TestProjectOptions(
        packageName: 'pkg',
        targetDir: '/etc/test_project',
      );
      expect(() => generator.planTestProject(options),
          throwsA(isA<TestProjectGenerationException>()));
    });

    test('Rejects path traversal ".." in target directory', () {
      const options = TestProjectOptions(
        packageName: 'pkg',
        targetDir: '../test_project',
      );
      expect(() => generator.planTestProject(options),
          throwsA(isA<TestProjectGenerationException>()));
    });

    test('Output is 100% deterministic across repeated runs', () {
      const options = TestProjectOptions(packageName: 'det_pkg');

      final plan1 = generator.planTestProject(options);
      final res1 = generator.generateTestProject(plan1, options);

      final plan2 = generator.planTestProject(options);
      final res2 = generator.generateTestProject(plan2, options);

      expect(res1.files, equals(res2.files));
    });
  });
}
