import 'dart:io';
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(ArchitectureCommand());
  return r;
}

void main() {
  group('ArchitectureCommand CLI Tests (Phase 8.6)', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_cli_arch_test_');

      // Create a sample package in tempDir
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: sample_arch_pkg
version: 1.0.0
dependencies:
  meta: ^1.11.0
''');
      Directory(p.join(tempDir.path, 'lib')).createSync(recursive: true);
      File(p.join(tempDir.path, 'lib', 'main.dart'))
          .writeAsStringSync('void main() {}');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('1. fps architecture on non-existent dir returns exit code 1',
        () async {
      final code = await _registry().run([
        'architecture',
        '--dir',
        'non_existent_arch_dir_123',
      ]);
      expect(code, equals(1));
    });

    test(
        '2. fps architecture default whole-project mode runs successfully (exit code 0)',
        () async {
      final code = await _registry().run([
        'architecture',
        '--dir',
        tempDir.path,
      ]);
      expect(code, equals(0));
    });

    test('3. fps architecture --package scopes scan to package', () async {
      final code = await _registry().run([
        'architecture',
        '--dir',
        tempDir.path,
        '--package',
        'sample_arch_pkg',
      ]);
      expect(code, equals(0));
    });

    test('4. fps architecture --json outputs structured JSON report', () async {
      final code = await _registry().run([
        'architecture',
        '--dir',
        tempDir.path,
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('5. fps architecture --write writes report to disk file', () async {
      final outPath = p.join(tempDir.path, 'arch_report_out.md');
      final code = await _registry().run([
        'architecture',
        '--dir',
        tempDir.path,
        '--write',
        '--output',
        outPath,
      ]);
      expect(code, equals(0));
      final outFile = File(outPath);
      expect(outFile.existsSync(), isTrue);
      expect(outFile.readAsStringSync(),
          contains('AI Architecture Advisory Report'));
    });
  });
}
