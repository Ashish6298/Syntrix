import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplatePluginValidateCommand CLI Tests', () {
    test(
        'fps template plugin-validate without manifest argument returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'plugin-validate']);
      expect(code, equals(64));
    });

    test(
        'fps template plugin-validate with valid JSON string returns exit code 0',
        () async {
      const validJson =
          '{"id":"custom_plugin","name":"Name","description":"Desc","version":"1.0.0","author":{"name":"A"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}';
      final code =
          await _registry().run(['template', 'plugin-validate', validJson]);
      expect(code, equals(0));
    });

    test(
        'fps template plugin-validate with valid JSON and --json flag outputs JSON result',
        () async {
      const validJson =
          '{"id":"custom_plugin","name":"Name","description":"Desc","version":"1.0.0","author":{"name":"A"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}';
      final code = await _registry()
          .run(['template', 'plugin-validate', validJson, '--json']);
      expect(code, equals(0));
    });

    test('fps template plugin-validate with invalid JSON returns exit code 1',
        () async {
      const invalidJson = '{"id":"INVALID_ID!"}';
      final code =
          await _registry().run(['template', 'plugin-validate', invalidJson]);
      expect(code, equals(1));
    });
  });
}
