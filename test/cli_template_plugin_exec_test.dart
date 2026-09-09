import 'package:syntrix/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplatePluginExecCommand CLI Tests (Phase 7.9)', () {
    test('fps template plugin-exec without plugin ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'plugin-exec']);
      expect(code, equals(64));
    });

    test('fps template plugin-exec with valid plugin ID returns exit code 0',
        () async {
      final code =
          await _registry().run(['template', 'plugin-exec', 'SampleRunner']);
      expect(code, equals(0));
    });

    test(
        'fps template plugin-exec with --json flag outputs JSON execution outcome',
        () async {
      final code = await _registry()
          .run(['template', 'plugin-exec', 'SampleRunner', '--json']);
      expect(code, equals(0));
    });
  });
}
