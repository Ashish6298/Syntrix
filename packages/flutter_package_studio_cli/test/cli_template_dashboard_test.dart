import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateReleaseDashboardCommand CLI Tests', () {
    test('fps template dashboard without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'dashboard']);
      expect(code, equals(64));
    });

    test(
        'fps template dashboard flutter_package returns exit code 0 (preview mode)',
        () async {
      final code =
          await _registry().run(['template', 'dashboard', 'flutter_package']);
      expect(code, equals(0));
    });

    test('fps template dashboard flutter_package --json outputs JSON snapshot',
        () async {
      final code = await _registry().run([
        'template',
        'dashboard',
        'flutter_package',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('fps template dashboard nonexistent_id returns exit code 1', () async {
      final code = await _registry().run([
        'template',
        'dashboard',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
