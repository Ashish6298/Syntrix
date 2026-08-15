import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateTestCommand CLI Tests', () {
    test('fps template test without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'test']);
      expect(code, equals(64));
    });

    test('fps template test flutter_package returns exit code 0', () async {
      final code =
          await _registry().run(['template', 'test', 'flutter_package']);
      expect(code, equals(0));
    });

    test('fps template test flutter_package --json outputs JSON report',
        () async {
      final code = await _registry().run([
        'template',
        'test',
        'flutter_package',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test(
        'fps template test flutter_package --profile release returns exit code 0 when clean',
        () async {
      final code = await _registry().run([
        'template',
        'test',
        'flutter_package',
        '--profile',
        'release',
      ]);
      expect(code, equals(0));
    });

    test('fps template test nonexistent_id returns exit code 1', () async {
      final code = await _registry().run([
        'template',
        'test',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
