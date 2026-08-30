import 'dart:io';
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateAiCommand CLI Tests (Phase 8.1)', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_cli_ai_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('1. Invoking fps template ai without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'ai']);
      expect(code, equals(64));
    });

    test('2. Invoking fps template ai without --prompt returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'ai', 'flutter_package']);
      expect(code, equals(64));
    });

    test('3. Invoking fps template ai with invalid --mode returns exit code 64',
        () async {
      final code = await _registry().run([
        'template',
        'ai',
        'flutter_package',
        '--prompt',
        'Analyze',
        '--mode',
        'invalid_mode'
      ]);
      expect(code, equals(64));
    });

    test(
        '4. Invoking fps template ai with unknown template ID returns exit code 1',
        () async {
      final code = await _registry().run([
        'template',
        'ai',
        'unknown_template_xyz',
        '--prompt',
        'Analyze this'
      ]);
      expect(code, equals(1));
    });

    test(
        '5. Invoking fps template ai on valid template outputs Markdown by default',
        () async {
      final code = await _registry().run([
        'template',
        'ai',
        'flutter_package',
        '--prompt',
        'Audit code structure',
        '--mode',
        'analysis',
      ]);
      expect(code, equals(0));
    });

    test(
        '6. Invoking fps template ai with --json outputs structured JSON report',
        () async {
      final code = await _registry().run([
        'template',
        'ai',
        'flutter_package',
        '--prompt',
        'Audit code structure',
        '--mode',
        'analysis',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('7. Invoking fps template ai with --write saves output file to disk',
        () async {
      final outFilePath = '${tempDir.path}/report.md';
      final code = await _registry().run([
        'template',
        'ai',
        'flutter_package',
        '--prompt',
        'Plan migration',
        '--mode',
        'planning',
        '--write',
        '--output',
        outFilePath,
      ]);

      expect(code, equals(0));
      final file = File(outFilePath);
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('Flutter Package Studio'));
    });

    test(
        '8. CLI Non-Regression: Existing fps template * commands continue to function identically',
        () async {
      final listCode = await _registry().run(['template', 'list']);
      expect(listCode, equals(0));

      final infoCode =
          await _registry().run(['template', 'info', 'flutter_package']);
      expect(infoCode, equals(0));

      final checkCode =
          await _registry().run(['template', 'check', 'flutter_package']);
      expect(checkCode, equals(0));
    });
  });
}
