import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateHooksCommand CLI Tests', () {
    test('fps template hooks without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'hooks']);
      expect(code, equals(64));
    });

    test('fps template hooks flutter_package returns exit code 0', () async {
      final code =
          await _registry().run(['template', 'hooks', 'flutter_package']);
      expect(code, equals(0));
    });

    test('fps template hooks flutter_package --json outputs JSON report',
        () async {
      final code = await _registry().run([
        'template',
        'hooks',
        'flutter_package',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('fps template hooks flutter_package --dry-run returns exit code 0',
        () async {
      final code = await _registry().run([
        'template',
        'hooks',
        'flutter_package',
        '--dry-run',
      ]);
      expect(code, equals(0));
    });

    test(
        'fps template hooks flutter_package --phase validation returns exit code 0',
        () async {
      final code = await _registry().run([
        'template',
        'hooks',
        'flutter_package',
        '--phase',
        'validation',
      ]);
      expect(code, equals(0));
    });

    test('fps template hooks nonexistent_id returns exit code 1', () async {
      final code = await _registry().run([
        'template',
        'hooks',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
