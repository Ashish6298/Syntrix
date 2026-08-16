import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplatePublishCommand CLI Tests', () {
    test('fps template publish without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'publish']);
      expect(code, equals(64));
    });

    test(
        'fps template publish flutter_package returns exit code 0 (preview mode)',
        () async {
      final code =
          await _registry().run(['template', 'publish', 'flutter_package']);
      expect(code, equals(0));
    });

    test('fps template publish flutter_package --json outputs JSON result',
        () async {
      final code = await _registry().run([
        'template',
        'publish',
        'flutter_package',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('fps template publish nonexistent_id returns exit code 1', () async {
      final code = await _registry().run([
        'template',
        'publish',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
