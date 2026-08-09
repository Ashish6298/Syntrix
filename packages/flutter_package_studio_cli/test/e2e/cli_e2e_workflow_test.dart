import 'dart:io' as io;
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('CLI E2E Workflow Tests', () {
    late DependencyContainer container;

    setUp(() {
      container = DependencyContainer();
      container.reset();
      container.registerSingleton<Logger>(Logger('CLI_E2E_Test'));
    });

    test('CLI create -> audit workflow succeeds end-to-end', () async {
      final tempDir =
          io.Directory.systemTemp.createTempSync('cli_e2e_flow_').path;
      final targetOutput = '$tempDir/cli_workflow_pkg';

      // 1. Run `fps create`
      final createRegistry = CommandRegistry();
      createRegistry.register(CreateCommand());

      final createExitCode = await createRegistry.run([
        'create',
        '--name',
        'cli_workflow_pkg',
        '--output',
        targetOutput,
        '--no-interactive',
      ]);

      expect(createExitCode, equals(0));
      expect(
          const SystemFileUtils().exists('$targetOutput/pubspec.yaml'), isTrue);
      expect(
          const SystemFileUtils().exists('$targetOutput/example/pubspec.yaml'),
          isTrue);

      // 2. Run `fps audit` against generated package
      final auditRegistry = CommandRegistry();
      auditRegistry.register(AuditCommand());

      final auditExitCode = await auditRegistry.run([
        'audit',
        '--target',
        targetOutput,
        '--profile',
        'standard',
      ]);

      expect(auditExitCode, equals(0));

      // Clean temp directory
      const SystemFileUtils().delete(tempDir);
    });
  });
}
