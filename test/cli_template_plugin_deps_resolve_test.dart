import 'dart:io';

import 'package:syntrix/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _registry() {
  final r = CommandRegistry();
  r.register(TemplateCatalogCommand());
  return r;
}

void main() {
  group('TemplatePluginDepsResolveCommand CLI Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fps_cli_deps_test_');
      final p1 = Directory('${tempDir.path}/plugin_a');
      await p1.create();
      await File('${p1.path}/plugin.json').writeAsString(
          '{"id":"plugin_a","name":"A","description":"D","version":"1.0.0","author":{"name":"X"},"apiVersion":"1.0.0","capabilities":["commandContribution"],"compatibility":{"minApiVersion":"1.0.0"}}');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
        'fps template plugin-deps-resolve without directory argument returns exit code 64',
        () async {
      final code = await _registry().run(['template', 'plugin-deps-resolve']);
      expect(code, equals(64));
    });

    test(
        'fps template plugin-deps-resolve with valid directory returns exit code 0',
        () async {
      final code = await _registry()
          .run(['template', 'plugin-deps-resolve', tempDir.path]);
      expect(code, equals(0));
    });

    test(
        'fps template plugin-deps-resolve with --json flag outputs JSON result',
        () async {
      final code = await _registry()
          .run(['template', 'plugin-deps-resolve', tempDir.path, '--json']);
      expect(code, equals(0));
    });
  });
}
