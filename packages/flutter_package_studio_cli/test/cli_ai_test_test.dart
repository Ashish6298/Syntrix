import 'dart:io';
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(AiTestCommand());
  return r;
}

void main() {
  group('AiTestCommand CLI Tests (Phase 8.4)', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_cli_ai_test_');

      // Create a sample package in tempDir
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: sample_test_pkg
version: 1.0.0
dependencies:
  meta: ^1.11.0
''');
      Directory(p.join(tempDir.path, 'lib')).createSync(recursive: true);
      Directory(p.join(tempDir.path, 'test')).createSync(recursive: true);
      File(p.join(tempDir.path, 'lib', 'main.dart'))
          .writeAsStringSync('void main() {}');
      File(p.join(tempDir.path, 'test', 'main_test.dart'))
          .writeAsStringSync('import "package:test/test.dart"; void main() {}');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('1. fps test on non-existent dir returns exit code 1', () async {
      final code = await _registry().run([
        'test',
        '--dir',
        'non_existent_test_dir_123',
      ]);
      expect(code, equals(1));
    });

    test('2. fps test default mode runs analysis successfully (exit code 0)',
        () async {
      final code = await _registry().run([
        'test',
        '--dir',
        tempDir.path,
      ]);
      expect(code, equals(0));
    });

    test('3. fps test --json outputs structured JSON report', () async {
      final code = await _registry().run([
        'test',
        '--dir',
        tempDir.path,
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('4. fps test --proposals includes proposal generation', () async {
      final code = await _registry().run([
        'test',
        '--dir',
        tempDir.path,
        '--proposals',
      ]);
      expect(code, equals(0));
    });

    test('5. fps test --write writes report to disk file', () async {
      final outPath = p.join(tempDir.path, 'test_intel_out.md');
      final code = await _registry().run([
        'test',
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
          contains('Test Generation & Test Intelligence Report'));
    });
  });
}
