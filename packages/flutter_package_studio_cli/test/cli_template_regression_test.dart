import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateRegressionCommand CLI Tests', () {
    test('fps template regression without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'regression']);
      expect(code, equals(64));
    });

    test(
        'fps template regression flutter_package returns exit code 0 (preview mode)',
        () async {
      final code =
          await _registry().run(['template', 'regression', 'flutter_package']);
      expect(code, equals(0));
    });

    test('fps template regression flutter_package --json outputs JSON result',
        () async {
      final code = await _registry().run([
        'template',
        'regression',
        'flutter_package',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('fps template regression nonexistent_id returns exit code 1',
        () async {
      final code = await _registry().run([
        'template',
        'regression',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
