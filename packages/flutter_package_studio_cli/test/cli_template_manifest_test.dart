import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateManifestCommand CLI Tests', () {
    test('fps template manifest without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'manifest']);
      expect(code, equals(64));
    });

    test(
        'fps template manifest flutter_package returns exit code 0 (preview mode)',
        () async {
      final code =
          await _registry().run(['template', 'manifest', 'flutter_package']);
      expect(code, equals(0));
    });

    test('fps template manifest flutter_package --json outputs JSON result',
        () async {
      final code = await _registry().run([
        'template',
        'manifest',
        'flutter_package',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('fps template manifest flutter_package --verify succeeds', () async {
      final code = await _registry().run([
        'template',
        'manifest',
        'flutter_package',
        '--verify',
      ]);
      expect(code, equals(0));
    });

    test('fps template manifest nonexistent_id returns exit code 1', () async {
      final code = await _registry().run([
        'template',
        'manifest',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
