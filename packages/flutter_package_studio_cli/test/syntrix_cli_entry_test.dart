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
      final banner = CommandRegistry.getBanner();
      expect(banner, contains('SYNTRIX'));
      expect(banner, contains('syntrix --version'));
      expect(banner, contains('syntrix --help'));
      expect(banner, contains('syntrix --audit'));
      expect(banner, contains('syntrix create'));
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

    test('Running syntrix --help outputs runner usage', () async {
      // args CommandRunner handles --help by printing usage and returning null/0
      final exitCode = await registry.run(['--help']);
      expect(exitCode, isIn([0, 64]));
    });
  });
}
