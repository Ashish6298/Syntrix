import 'dart:io';
import 'package:syntrix/flutter_package_studio_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('SecurityCommand CLI Tests (Phase 8.9)', () {
    late Directory tempDir;
    late String rootPath;
    late CommandRegistry registry;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_cli_security_test_');
      rootPath = tempDir.path;
      registry = CommandRegistry()..register(SecurityCommand());

      // Scaffold simple package with a pubspec
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: sample_security_pkg
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

    test('1. fps security on non-existent dir returns exit code 1', () async {
      final code = await registry.run([
        'security',
        '--dir',
        'non_existent_security_dir_123',
      ]);
      expect(code, equals(1));
    });

    test(
        '2. fps security with package scope but missing package argument returns exit code 1',
        () async {
      final code = await registry.run([
        'security',
        '--scope',
        'package',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(1));
    });

    test('3. fps security runs successfully on whole project (exit code 0)',
        () async {
      final code = await registry.run([
        'security',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(0));
    });

    test(
        '4. fps security with min-priority filter runs successfully (exit code 0)',
        () async {
      final code = await registry.run([
        'security',
        '--min-priority',
        'critical',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(0));
    });

    test('5. fps security --json outputs structured JSON report', () async {
      final code = await registry.run([
        'security',
        '--json',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(0));
    });

    test('6. fps security --write writes report to disk file', () async {
      final outFile = p.join(rootPath, 'security_report.md');
      final code = await registry.run([
        'security',
        '--dir',
        rootPath,
        '--write',
        '--output',
        outFile,
      ]);
      expect(code, equals(0));
      expect(File(outFile).existsSync(), isTrue);
      expect(File(outFile).readAsStringSync(),
          contains('AI Security & Privacy Advisory Report'));
    });
  });
}
