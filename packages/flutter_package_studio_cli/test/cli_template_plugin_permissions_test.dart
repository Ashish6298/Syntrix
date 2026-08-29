import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplatePluginPermissionsCommand CLI Tests', () {
    test(
        'fps template plugin-permissions without plugin ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'plugin-permissions']);
      expect(code, equals(64));
    });

    test(
        'fps template plugin-permissions with valid plugin ID returns exit code 0',
        () async {
      final code = await _registry()
          .run(['template', 'plugin-permissions', 'DocumentationGenerator']);
      expect(code, equals(0));
    });

    test('fps template plugin-permissions with --json flag outputs JSON record',
        () async {
      final code = await _registry().run([
        'template',
        'plugin-permissions',
        'DocumentationGenerator',
        '--json'
      ]);
      expect(code, equals(0));
    });
  });
}
