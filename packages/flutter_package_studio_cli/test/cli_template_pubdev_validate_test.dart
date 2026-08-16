import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplatePubDevValidateCommand CLI Tests', () {
    test(
        'fps template pubdev-validate without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'pubdev-validate']);
      expect(code, equals(64));
    });

    test(
        'fps template pubdev-validate flutter_package returns exit code 0 (preview mode)',
        () async {
      final code = await _registry()
          .run(['template', 'pubdev-validate', 'flutter_package']);
      expect(code, equals(0));
    });

    test(
        'fps template pubdev-validate flutter_package --json outputs JSON result',
        () async {
      final code = await _registry().run([
        'template',
        'pubdev-validate',
        'flutter_package',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('fps template pubdev-validate nonexistent_id returns exit code 1',
        () async {
      final code = await _registry().run([
        'template',
        'pubdev-validate',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
