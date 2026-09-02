import 'dart:io';
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('DocumentationCommand CLI Tests (Phase 8.7)', () {
    late Directory tempDir;
    late String rootPath;
    late CommandRegistry registry;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_cli_doc_test_');
      rootPath = tempDir.path;
      registry = CommandRegistry()..register(DocumentationCommand());

      // Scaffold simple package with a doc and a code file
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: sample_doc_pkg
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');
      final libDir = Directory(p.join(rootPath, 'lib'))
        ..createSync(recursive: true);
      File(p.join(libDir.path, 'sample_service.dart')).writeAsStringSync('''
class SampleService {
  void executeWork() {}
}
''');
      File(p.join(rootPath, 'README.md')).writeAsStringSync('''
# Sample Doc Package
Usage guide.
''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('1. fps doc on non-existent dir returns exit code 1', () async {
      final code = await registry.run([
        'doc',
        '--target',
        'SampleService',
        '--dir',
        'non_existent_doc_dir_123',
      ]);
      expect(code, equals(1));
    });

    test('2. fps doc without target argument returns exit code 1', () async {
      final code = await registry.run([
        'doc',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(1));
    });

    test(
        '3. fps doc with target generates documentation successfully (exit code 0)',
        () async {
      final code = await registry.run([
        'doc',
        '--target',
        'SampleService',
        '--type',
        'api-doc',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(0));
    });

    test('4. fps doc --check-consistency runs consistency audit (exit code 0)',
        () async {
      final code = await registry.run([
        'doc',
        '--check-consistency',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(0));
    });

    test('5. fps doc --json outputs structured JSON', () async {
      final code = await registry.run([
        'doc',
        '--check-consistency',
        '--json',
        '--dir',
        rootPath,
      ]);
      expect(code, equals(0));
    });

    test('6. fps doc --write writes generated content to disk', () async {
      final outFile = p.join(rootPath, 'generated_doc.md');
      final code = await registry.run([
        'doc',
        '--target',
        'SampleService',
        '--dir',
        rootPath,
        '--write',
        '--output',
        outFile,
      ]);
      expect(code, equals(0));
      expect(File(outFile).existsSync(), isTrue);
      expect(File(outFile).readAsStringSync(), isNotEmpty);
    });
  });
}
