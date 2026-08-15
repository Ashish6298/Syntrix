import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateCustomizeCommand CLI Tests', () {
    test('fps template customize without template ID returns code 64',
        () async {
      final code = await _registry().run(['template', 'customize']);
      expect(code, equals(64));
    });

    test('fps template customize flutter_package returns exit code 0',
        () async {
      final code =
          await _registry().run(['template', 'customize', 'flutter_package']);
      expect(code, equals(0));
    });

    test('fps template customize flutter_package --json outputs JSON plan',
        () async {
      final code = await _registry().run([
        'template',
        'customize',
        'flutter_package',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test(
        'fps template customize flutter_package with --var user variable returns 0',
        () async {
      final code = await _registry().run([
        'template',
        'customize',
        'flutter_package',
        '--var',
        'custom_key=custom_val',
      ]);
      expect(code, equals(0));
    });

    test('fps template customize nonexistent_id returns exit code 1', () async {
      final code = await _registry().run([
        'template',
        'customize',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
