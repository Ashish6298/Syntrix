import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateValidateCommand CLI Tests', () {
    test('fps template validate without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'validate']);
      expect(code, equals(64));
    });

    test('fps template validate flutter_package returns exit code 0', () async {
      final code =
          await _registry().run(['template', 'validate', 'flutter_package']);
      expect(code, equals(0));
    });

    test('fps template validate flutter_package --json outputs JSON report',
        () async {
      final code = await _registry().run([
        'template',
        'validate',
        'flutter_package',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test(
        'fps template validate with profile release returns exit code 0 when clean',
        () async {
      final code = await _registry().run([
        'template',
        'validate',
        'flutter_package',
        '--profile',
        'release',
      ]);
      expect(code, equals(0));
    });

    test('fps template validate nonexistent_id returns exit code 1', () async {
      final code = await _registry().run([
        'template',
        'validate',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
