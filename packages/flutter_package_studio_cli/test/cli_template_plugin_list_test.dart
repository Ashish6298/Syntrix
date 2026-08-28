import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplatePluginListCommand CLI Tests', () {
    test('fps template plugin-list returns exit code 0', () async {
      final code = await _registry().run(['template', 'plugin-list']);
      expect(code, equals(0));
    });

    test('fps template plugin-list --json outputs JSON plugins list', () async {
      final code = await _registry().run(['template', 'plugin-list', '--json']);
      expect(code, equals(0));
    });
  });
}
