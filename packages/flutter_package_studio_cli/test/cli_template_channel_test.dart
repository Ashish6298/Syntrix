import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateChannelCommand CLI Tests', () {
    test('fps template channel without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'channel']);
      expect(code, equals(64));
    });

    test(
        'fps template channel flutter_package returns exit code 0 (preview mode)',
        () async {
      final code =
          await _registry().run(['template', 'channel', 'flutter_package']);
      expect(code, equals(0));
    });

    test(
        'fps template channel flutter_package --channel beta --json outputs JSON result',
        () async {
      final code = await _registry().run([
        'template',
        'channel',
        'flutter_package',
        '--channel',
        'beta',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('fps template channel nonexistent_id returns exit code 1', () async {
      final code = await _registry().run([
        'template',
        'channel',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
