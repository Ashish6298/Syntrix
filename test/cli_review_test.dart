import 'dart:io';
import 'package:syntrix/flutter_package_studio_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(ReviewCommand());
  return r;
}

void main() {
  group('ReviewCommand CLI Tests (Phase 8.3)', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_cli_review_test_');

      // Create a sample package in tempDir
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: sample_review_pkg
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

    test('1. fps review on non-existent dir returns exit code 1', () async {
      final code = await _registry().run([
        'review',
        '--dir',
        'non_existent_review_dir_123',
      ]);
      expect(code, equals(1));
    });

    test('2. fps review single-file mode without --file returns exit code 64',
        () async {
      final code = await _registry().run([
        'review',
        '--dir',
        tempDir.path,
        '--mode',
        'single-file',
      ]);
      expect(code, equals(64));
    });

    test(
        '3. fps review default package mode runs preview successfully (exit code 0)',
        () async {
      final code = await _registry().run([
        'review',
        '--dir',
        tempDir.path,
      ]);
      expect(code, equals(0));
    });

    test('4. fps review --json outputs structured JSON review report',
        () async {
      final code = await _registry().run([
        'review',
        '--dir',
        tempDir.path,
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('5. fps review single-file mode with valid --file runs successfully',
        () async {
      final code = await _registry().run([
        'review',
        '--dir',
        tempDir.path,
        '--mode',
        'single-file',
        '--file',
        'lib/main.dart',
      ]);
      expect(code, equals(0));
    });

    test('6. fps review --write writes report to disk file', () async {
      final outPath = p.join(tempDir.path, 'review_out.md');
      final code = await _registry().run([
        'review',
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
          contains('AI Code Analysis & Review Report'));
    });
  });
}
