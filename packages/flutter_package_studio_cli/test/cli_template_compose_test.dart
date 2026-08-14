import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateComposeCommand CLI Tests', () {
    test('fps template compose without arguments returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'compose']);
      expect(code, equals(64));
    });

    test('fps template compose flutter_package returns exit code 0', () async {
      final code =
          await _registry().run(['template', 'compose', 'flutter_package']);
      expect(code, equals(0));
    });

    test('fps template compose flutter_package --json outputs valid JSON plan',
        () async {
      final code = await _registry().run([
        'template',
        'compose',
        'flutter_package',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('fps template compose with nonexistent base template ID returns 1',
        () async {
      final code = await _registry().run([
        'template',
        'compose',
        'nonexistent_base_id',
      ]);
      expect(code, equals(1));
    });

    test('fps template compose with conflict-policy override returns 0',
        () async {
      final code = await _registry().run([
        'template',
        'compose',
        'flutter_package',
        '--conflict-policy',
        'override',
      ]);
      expect(code, equals(0));
    });
  });
}
