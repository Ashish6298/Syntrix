import 'package:syntrix/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplatePluginLifecycleStatusCommand CLI Tests', () {
    test('fps template plugin-lifecycle-status returns exit code 0', () async {
      final code =
          await _registry().run(['template', 'plugin-lifecycle-status']);
      expect(code, equals(0));
    });

    test(
        'fps template plugin-lifecycle-status with --json flag outputs JSON record',
        () async {
      final code = await _registry()
          .run(['template', 'plugin-lifecycle-status', '--json']);
      expect(code, equals(0));
    });
  });
}
