import 'package:syntrix/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateVersionPlanCommand CLI Tests', () {
    test('fps template version-plan without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'version-plan']);
      expect(code, equals(64));
    });

    test(
        'fps template version-plan flutter_package returns exit code 0 (preview mode)',
        () async {
      final code = await _registry()
          .run(['template', 'version-plan', 'flutter_package']);
      expect(code, equals(0));
    });

    test(
        'fps template version-plan flutter_package --type minor --json outputs JSON result',
        () async {
      final code = await _registry().run([
        'template',
        'version-plan',
        'flutter_package',
        '--type',
        'minor',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('fps template version-plan nonexistent_id returns exit code 1',
        () async {
      final code = await _registry().run([
        'template',
        'version-plan',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
