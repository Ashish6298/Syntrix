import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateMigrateCommand CLI Tests', () {
    test('fps template migrate without target path returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'migrate']);
      expect(code, equals(64));
    });

    test(
        'fps template migrate my_proj --from 1.0.0 --to 1.1.0 returns exit code 0 (dry-run)',
        () async {
      final code = await _registry().run([
        'template',
        'migrate',
        'my_proj',
        '--from',
        '1.0.0',
        '--to',
        '1.1.0',
      ]);
      expect(code, equals(0));
    });

    test(
        'fps template migrate my_proj --from 1.0.0 --to 1.1.0 --json outputs JSON plan preview',
        () async {
      final code = await _registry().run([
        'template',
        'migrate',
        'my_proj',
        '--from',
        '1.0.0',
        '--to',
        '1.1.0',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test(
        'fps template migrate my_proj --from 1.0.0 --to 3.0.0 returns exit code 1 when no path exists',
        () async {
      final code = await _registry().run([
        'template',
        'migrate',
        'my_proj',
        '--from',
        '1.0.0',
        '--to',
        '3.0.0',
      ]);
      expect(code, equals(1));
    });
  });
}
