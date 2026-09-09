import 'dart:io';
import 'package:syntrix/flutter_package_studio_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(DebugCommand());
  return r;
}

void main() {
  group('DebugCommand CLI Tests (Phase 8.5)', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_cli_debug_test_');

      // Create a sample package in tempDir
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: sample_debug_pkg
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

    test('1. fps debug on non-existent dir returns exit code 1', () async {
      final code = await _registry().run([
        'debug',
        '--dir',
        'non_existent_debug_dir_123',
      ]);
      expect(code, equals(1));
    });

    test('2. fps debug runs successfully with error string (exit code 0)',
        () async {
      final code = await _registry().run([
        'debug',
        '--dir',
        tempDir.path,
        '--error',
        'NullCheckError at line 42',
      ]);
      expect(code, equals(0));
    });

    test('3. fps debug --json outputs structured JSON diagnosis report',
        () async {
      final code = await _registry().run([
        'debug',
        '--dir',
        tempDir.path,
        '--error',
        'AssertionFailed in widget_test.dart',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('4. fps debug with --stack-trace runs successfully', () async {
      final code = await _registry().run([
        'debug',
        '--dir',
        tempDir.path,
        '--error',
        'LateInitializationError',
        '--stack-trace',
        '#0 init (main.dart:10)',
      ]);
      expect(code, equals(0));
    });

    test('5. fps debug --write writes report to disk file', () async {
      final outPath = p.join(tempDir.path, 'diagnosis_out.md');
      final code = await _registry().run([
        'debug',
        '--dir',
        tempDir.path,
        '--error',
        'SocketException',
        '--write',
        '--output',
        outPath,
      ]);
      expect(code, equals(0));
      final outFile = File(outPath);
      expect(outFile.existsSync(), isTrue);
      expect(
          outFile.readAsStringSync(), contains('AI Failure Diagnosis Report'));
    });
  });
}
