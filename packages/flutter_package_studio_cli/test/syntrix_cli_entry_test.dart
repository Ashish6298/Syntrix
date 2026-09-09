import 'dart:io' as io;
import 'package:test/test.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';

void main() {
  group('Syntrix Terminal Banner & CLI Entry Tests', () {
    late CommandRegistry registry;

    setUp(() {
      final container = DependencyContainer();
      container.reset();
      container.registerSingleton<Logger>(Logger('SyntrixTest', level: LogLevel.error));

      registry = CommandRegistry();
      registry.register(CreateCommand());
      registry.register(AuditCommand());
      registry.register(ReleaseCommand());
      registry.register(DocsCommand());
      registry.register(PublishCommand());
      registry.register(TemplateCommand());
      registry.register(PluginCommand());
      registry.register(RegistryCommand());
      registry.register(ProjectCommand());
      registry.register(ReviewCommand());
      registry.register(DebugCommand());
      registry.register(AiTestCommand());
      registry.register(ArchitectureCommand());
      registry.register(DocumentationCommand());
      registry.register(DependencyCommand());
      registry.register(SecurityCommand());
      registry.register(ReleaseReadinessCommand());
      registry.register(PlanCommand());
      registry.register(MemoryCommand());
      registry.register(ModifyCommand());
      registry.register(AiCommand());
    });

    tearDown(() {
      DependencyContainer().reset();
    });

    test('getBanner contains SYNTRIX and primary commands', () {
      final banner = CommandRegistry.getBanner(enableColor: false);
      expect(banner, contains('S Y N T R I X'));
      expect(banner, contains('Enterprise tools & AI studio for Flutter and Dart'));
      expect(banner, contains('Quick Actions:'));
      expect(banner, contains('create'));
      expect(banner, contains('--audit'));
      expect(banner, contains('template'));
      expect(banner, contains('plugin'));
      expect(banner, contains('--help'));
    });



    test('Running syntrix with empty arguments prints banner and exits 0', () async {
      final exitCode = await registry.run([]);
      expect(exitCode, 0);
    });

    test('Running syntrix --version prints version and exits 0', () async {
      final exitCode = await registry.run(['--version']);
      expect(exitCode, 0);
    });

    test('Running syntrix --audit executes audit command', () async {
      // Create a temporary valid package structure so audit completes
      final tempDir = io.Directory.systemTemp.createTempSync('syntrix_audit_test');
      io.File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: test_audit_pkg
description: Test package for audit validation.
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');
      io.Directory('${tempDir.path}/lib').createSync();
      io.File('${tempDir.path}/lib/test_audit_pkg.dart').writeAsStringSync('void main() {}');

      final exitCode = await registry.run(['--audit', '--target', tempDir.path]);
      expect(exitCode, 0);

      tempDir.deleteSync(recursive: true);
    });

    test('getHelp contains all categories and commands', () {
      final help = CommandRegistry.getHelp(enableColor: false);
      expect(help, contains('Global options'));
      expect(help, contains('Package & templates'));
      expect(help, contains('AI engineering'));
      expect(help, contains('Analysis & audit'));
      expect(help, contains('Release & publishing'));

      // Check commands exist in help
      expect(help, contains('create'));
      expect(help, contains('template'));
      expect(help, contains('plugin'));
      expect(help, contains('registry'));

      expect(help, contains('ai'));
      expect(help, contains('review'));
      expect(help, contains('debug'));
      expect(help, contains('plan'));
      expect(help, contains('modify'));
      expect(help, contains('doc'));
      expect(help, contains('docs'));
      expect(help, contains('memory'));
      expect(help, contains('project'));

      expect(help, contains('audit'));
      expect(help, contains('architecture'));
      expect(help, contains('deps'));
      expect(help, contains('security'));
      expect(help, contains('test'));
      expect(help, contains('release-readiness'));

      expect(help, contains('release'));
      expect(help, contains('publish'));
    });

    test('Running syntrix --help outputs custom styled help and exits 0', () async {
      final exitCode = await registry.run(['--help']);
      expect(exitCode, 0);
    });

    test('Deep execution test for all registered commands in help list', () async {
      // 1. Package & templates
      expect(await registry.run(['template', 'list']), 0);
      expect(await registry.run(['plugin', 'list']), 0);
      expect(await registry.run(['registry', 'list']), 0);

      // 2. AI engineering
      expect(await registry.run(['project', '--help']), 0);
      expect(await registry.run(['project', 'context', '--help']), 0);
      expect(await registry.run(['docs']), 0);
      expect(await registry.run(['doc', '--help']), 0);
      expect(await registry.run(['ai', '--help']), 0);
      expect(await registry.run(['review', '--help']), 0);
      expect(await registry.run(['debug', '--help']), 0);
      expect(await registry.run(['plan', '--help']), 0);
      expect(await registry.run(['modify', '--help']), 0);
      expect(await registry.run(['memory', '--help']), 0);

      // 3. Analysis & audit
      expect(await registry.run(['architecture', '--help']), 0);
      expect(await registry.run(['deps', '--help']), 0);
      expect(await registry.run(['security', '--help']), 0);
      expect(await registry.run(['test', '--help']), 0);
      expect(await registry.run(['release-readiness', '--help']), 0);

      // 4. Release & publishing
      expect(await registry.run(['release']), 0);
      expect(await registry.run(['publish']), 0);
    });
  });
}

