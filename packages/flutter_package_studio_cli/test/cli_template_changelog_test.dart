import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateChangelogCommand CLI Tests', () {
    test('fps template changelog without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'changelog']);
      expect(code, equals(64));
    });

    test(
        'fps template changelog flutter_package returns exit code 0 (preview mode)',
        () async {
      final code =
          await _registry().run(['template', 'changelog', 'flutter_package']);
      expect(code, equals(0));
    });

    test(
        'fps template changelog flutter_package --version 1.1.0 --json outputs JSON result',
        () async {
      final code = await _registry().run([
        'template',
        'changelog',
        'flutter_package',
        '--version',
        '1.1.0',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('fps template changelog nonexistent_id returns exit code 1', () async {
      final code = await _registry().run([
        'template',
        'changelog',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
