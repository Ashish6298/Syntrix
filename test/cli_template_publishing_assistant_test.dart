import 'package:syntrix/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplatePublishingAssistantCommand CLI Tests', () {
    test('fps template assistant without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'assistant']);
      expect(code, equals(64));
    });

    test(
        'fps template assistant flutter_package without --authorize fails with exit code 1',
        () async {
      final code =
          await _registry().run(['template', 'assistant', 'flutter_package']);
      expect(code, equals(1));
    });

    test(
        'fps template assistant flutter_package --authorize test_user returns exit code 0',
        () async {
      final code = await _registry().run([
        'template',
        'assistant',
        'flutter_package',
        '--authorize',
        'test_user',
      ]);
      expect(code, equals(0));
    });

    test(
        'fps template assistant flutter_package --authorize test_user --json outputs JSON report',
        () async {
      final code = await _registry().run([
        'template',
        'assistant',
        'flutter_package',
        '--authorize',
        'test_user',
        '--json',
      ]);
      expect(code, equals(0));
    });
  });
}
