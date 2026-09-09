import 'package:syntrix/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateGitHubReleaseCommand CLI Tests', () {
    test('fps template github-release without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'github-release']);
      expect(code, equals(64));
    });

    test(
        'fps template github-release flutter_package returns exit code 0 (preview mode)',
        () async {
      final code = await _registry()
          .run(['template', 'github-release', 'flutter_package']);
      expect(code, equals(0));
    });

    test(
        'fps template github-release flutter_package --version 1.1.0 --json outputs JSON result',
        () async {
      final code = await _registry().run([
        'template',
        'github-release',
        'flutter_package',
        '--version',
        '1.1.0',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('fps template github-release nonexistent_id returns exit code 1',
        () async {
      final code = await _registry().run([
        'template',
        'github-release',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
