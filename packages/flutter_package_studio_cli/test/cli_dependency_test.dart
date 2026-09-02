import 'dart:io';
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('DependencyCommand CLI Tests (Phase 8.8)', () {
    late Directory tempDir;
    late String rootPath;
    late CommandRegistry registry;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_cli_deps_test_');
      rootPath = tempDir.path;
      registry = CommandRegistry()..register(DependencyCommand());

      // Scaffold simple package with a pubspec
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: sample_deps_pkg
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
dependencies:
  meta: ^1.11.0
''');
      final libDir = Directory(p.join(rootPath, 'lib'))
        ..createSync(recursive: true);
      File(p.join(libDir.path, 'sample.dart'))
          .writeAsStringSync('void main() {}');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('1. fps deps on non-existent dir returns exit code 1', () async {
      final code = await registry.run([
        'deps',
        '--dir',
        'non_existent_deps_dir_123',
      ]);
      expect(code, equals(1));
    });

    test(
        '2. fps deps with package scope but missing package argument returns exit code 1',
        () async {
      final code = await registry.run([
        'deps',
        '--scope',
        'package',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(1));
    });

    test('3. fps deps runs successfully on whole project (exit code 0)',
        () async {
      final code = await registry.run([
        'deps',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(0));
    });

    test(
        '4. fps deps with package scope and package argument runs successfully (exit code 0)',
        () async {
      final code = await registry.run([
        'deps',
        '--scope',
        'package',
        '--package',
        'sample_deps_pkg',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(0));
    });

    test('5. fps deps --json outputs structured JSON report', () async {
      final code = await registry.run([
        'deps',
        '--json',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(0));
    });

    test('6. fps deps --write writes report to disk file', () async {
      final outFile = p.join(rootPath, 'deps_report.md');
      final code = await registry.run([
        'deps',
        '--dir',
        rootPath,
        '--write',
        '--output',
        outFile,
      ]);
      expect(code, equals(0));
      expect(File(outFile).existsSync(), isTrue);
      expect(File(outFile).readAsStringSync(),
          contains('AI Dependency & Compatibility Advisory Report'));
    });
  });
}
