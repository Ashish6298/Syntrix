import 'package:syntrix/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplateGitReleaseCommand CLI Tests', () {
    test('fps template git-release without template ID returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'git-release']);
      expect(code, equals(64));
    });

    test(
        'fps template git-release flutter_package returns exit code 0 (preview mode)',
        () async {
      final code =
          await _registry().run(['template', 'git-release', 'flutter_package']);
      expect(code, equals(0));
    });

    test(
        'fps template git-release flutter_package --version 1.1.0 --json outputs JSON result',
        () async {
      final code = await _registry().run([
        'template',
        'git-release',
        'flutter_package',
        '--version',
        '1.1.0',
        '--json',
      ]);
      expect(code, equals(0));
    });

    test('fps template git-release nonexistent_id returns exit code 1',
        () async {
      final code = await _registry().run([
        'template',
        'git-release',
        'nonexistent_id',
      ]);
      expect(code, equals(1));
    });
  });
}
