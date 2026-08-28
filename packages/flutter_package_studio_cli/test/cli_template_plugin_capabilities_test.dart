import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplatePluginCapabilitiesCommand CLI Tests', () {
    test(
        'fps template plugin-capabilities without argument returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'plugin-capabilities']);
      expect(code, equals(64));
    });

    test('fps template plugin-capabilities with plugin ID returns exit code 0',
        () async {
      final code = await _registry()
          .run(['template', 'plugin-capabilities', 'custom_plugin']);
      expect(code, equals(0));
    });

    test('fps template plugin-capabilities with JSON flag outputs JSON result',
        () async {
      final code = await _registry()
          .run(['template', 'plugin-capabilities', 'custom_plugin', '--json']);
      expect(code, equals(0));
    });
  });
}
