import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateArchitectureCommand CLI Tests', () {
    test('fps template architecture returns exit code 0 (preview mode)',
        () async {
      final code = await _registry().run(['template', 'architecture']);
      expect(code, equals(0));
    });

    test('fps template architecture --json outputs JSON result', () async {
      final code = await _registry().run([
        'template',
        'architecture',
        '--json',
      ]);
      expect(code, equals(0));
    });
  });
}
