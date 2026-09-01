import 'dart:io';
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(ProjectCommand());
  return r;
}

void main() {
  group('ProjectContextCommand CLI Tests (Phase 8.2)', () {
    late Directory tempDir;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('fps_cli_project_ctx_test_');

      // Create a sample package in tempDir
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: sample_cli_pkg
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

    test('1. fps project context on non-existent dir returns exit code 1',
        () async {
      final code = await _registry().run([
        'project',
        'context',
        '--dir',
        'non_existent_dir_12345',
      ]);
      expect(code, equals(1));
    });

    test('2. fps project context --inventory-only discovers project structure',
        () async {
      final code = await _registry().run([
        'project',
        'context',
        '--dir',
        tempDir.path,
        '--inventory-only',
      ]);
      expect(code, equals(0));
    });

    test(
        '3. fps project context --inventory-only --json outputs structured JSON',
        () async {
      final code = await _registry().run([
        'project',
        'context',
        '--dir',
        tempDir.path,
        '--inventory-only',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test(
        '4. fps project context default preview runs successfully (exit code 0)',
        () async {
      final code = await _registry().run([
        'project',
        'context',
        '--dir',
        tempDir.path,
        '--query',
        'Inspect sample_cli_pkg structure',
      ]);
      expect(code, equals(0));
    });

    test('5. fps project context --json outputs full assembled context JSON',
        () async {
      final code = await _registry().run([
        'project',
        'context',
        '--dir',
        tempDir.path,
        '--query',
        'Inspect sample_cli_pkg',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test(
        '6. fps project context --write writes report to specified output path',
        () async {
      final outPath = p.join(tempDir.path, 'context_out.md');
      final code = await _registry().run([
        'project',
        'context',
        '--dir',
        tempDir.path,
        '--query',
        'Audit sample_cli_pkg',
        '--write',
        '--output',
        outPath,
      ]);
      expect(code, equals(0));
      final outFile = File(outPath);
      expect(outFile.existsSync(), isTrue);
      expect(outFile.readAsStringSync(),
          contains('Project Context & Codebase Intelligence'));
    });
  });
}
