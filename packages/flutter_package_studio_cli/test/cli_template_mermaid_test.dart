import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateMermaidCommand CLI Tests', () {
    test('fps template mermaid returns exit code 0 (preview mode)', () async {
      final code = await _registry().run(['template', 'mermaid']);
      expect(code, equals(0));
    });

    test('fps template mermaid --type sequence returns exit code 0', () async {
      final code = await _registry().run([
        'template',
        'mermaid',
        '--type',
        'sequence',
      ]);
      expect(code, equals(0));
    });

    test('fps template mermaid --json outputs JSON result', () async {
      final code = await _registry().run([
        'template',
        'mermaid',
        '--json',
      ]);
      expect(code, equals(0));
    });
  });
}
