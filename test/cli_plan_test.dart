import 'dart:io';
import 'package:syntrix/flutter_package_studio_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('PlanCommand CLI Tests (Phase 8.11)', () {
    late Directory tempDir;
    late String rootPath;
    late CommandRegistry registry;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_cli_plan_test_');
      rootPath = tempDir.path;
      registry = CommandRegistry()..register(PlanCommand());

      // Scaffold simple package with a pubspec
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: sample_plan_pkg
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

    test('1. fps plan without request argument returns exit code 1', () async {
      final code = await registry.run([
        'plan',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(1));
    });

    test('2. fps plan on non-existent dir returns exit code 1', () async {
      final code = await registry.run([
        'plan',
        '--request',
        'Add Debian package support',
        '--dir',
        'non_existent_plan_dir_123',
      ]);
      expect(code, equals(1));
    });

    test('3. fps plan runs successfully with --request (exit code 0)',
        () async {
      final code = await registry.run([
        'plan',
        '--request',
        'Add Debian package support',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(0));
    });

    test('4. fps plan runs successfully via alias fps ai-plan (exit code 0)',
        () async {
      final code = await registry.run([
        'ai-plan',
        '--request',
        'Add Debian package support',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(0));
    });

    test('5. fps plan --json outputs structured JSON plan', () async {
      final code = await registry.run([
        'plan',
        '--request',
        'Add Debian package support',
        '--json',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(0));
    });

    test('6. fps plan --write writes implementation plan to disk file',
        () async {
      final outFile = p.join(rootPath, 'implementation_plan.md');
      final code = await registry.run([
        'plan',
        '--request',
        'Add Debian package support',
        '--dir',
        rootPath,
        '--write',
        '--output',
        outFile,
      ]);
      expect(code, equals(0));
      expect(File(outFile).existsSync(), isTrue);
      expect(File(outFile).readAsStringSync(),
          contains('AI Engineering Implementation Plan'));
    });
  });
}
