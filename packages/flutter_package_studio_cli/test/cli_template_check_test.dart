import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateCheckCommand CLI Tests', () {
    test('fps template check with no template-id returns code 64 (usage error)',
        () async {
      final code = await _registry().run(['template', 'check']);
      expect(code, equals(64));
    });

    test('fps template check flutter_package returns 0 (compatible)', () async {
      final code =
          await _registry().run(['template', 'check', 'flutter_package']);
      expect(code, equals(0));
    });

    test('fps template check flutter_package --json returns 0', () async {
      final code = await _registry()
          .run(['template', 'check', 'flutter_package', '--json']);
      expect(code, equals(0));
    });

    test(
        'fps template check flutter_package with incompatible mock dart version returns 1',
        () async {
      final code = await _registry().run([
        'template',
        'check',
        'flutter_package',
        '--dart-version',
        '2.19.0',
      ]);
      expect(code, equals(1));
    });

    test('fps template check nonexistent_id returns 1', () async {
      final code = await _registry()
          .run(['template', 'check', 'nonexistent_template_id']);
      expect(code, equals(1));
    });

    test('fps template check with policy release returns 0 when compatible',
        () async {
      final code = await _registry().run([
        'template',
        'check',
        'flutter_package',
        '--policy',
        'release',
      ]);
      expect(code, equals(0));
    });
  });
}
