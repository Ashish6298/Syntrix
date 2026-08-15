import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateCertifyCommand CLI Tests', () {
    test('fps template certify without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'certify']);
      expect(code, equals(64));
    });

    test('fps template certify flutter_package returns exit code 0', () async {
      final code =
          await _registry().run(['template', 'certify', 'flutter_package']);
      expect(code, equals(0));
    });

    test('fps template certify flutter_package --json outputs JSON report',
        () async {
      final code = await _registry().run([
        'template',
        'certify',
        'flutter_package',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test(
        'fps template certify flutter_package --profile release returns exit code 0 when clean',
        () async {
      final code = await _registry().run([
        'template',
        'certify',
        'flutter_package',
        '--profile',
        'release',
      ]);
      expect(code, equals(0));
    });

    test('fps template certify nonexistent_id returns exit code 1', () async {
      final code = await _registry().run([
        'template',
        'certify',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
