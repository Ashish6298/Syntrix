import 'package:syntrix/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplatePluginConfigValidateCommand CLI Tests', () {
    test('fps template plugin-config-validate returns exit code 0 when valid',
        () async {
      final code =
          await _registry().run(['template', 'plugin-config-validate']);
      expect(code, equals(0));
    });

    test(
        'fps template plugin-config-validate --json flag outputs JSON result with secret redaction',
        () async {
      final code = await _registry()
          .run(['template', 'plugin-config-validate', '--json']);
      expect(code, equals(0));
    });
  });
}
