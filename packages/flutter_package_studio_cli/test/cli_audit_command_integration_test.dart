import 'dart:io' as io;
import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('AuditCommand CLI Integration Tests', () {
    late DependencyContainer container;

    setUp(() {
      container = DependencyContainer();
      container.reset();
      container.registerSingleton<Logger>(Logger('CLI_Audit_Test'));
    });

    test('AuditCommand executes validation report against generated package',
        () async {
      final tempDir =
          io.Directory.systemTemp.createTempSync('cli_audit_gen').path;
      final targetOutput = '$tempDir/audit_pkg';

      // 1. Create a generated package first
      final createRegistry = CommandRegistry();
      createRegistry.register(CreateCommand());
      await createRegistry.run([
        'create',
        '--name',
        'audit_pkg',
        '--output',
        targetOutput,
        '--no-interactive',
      ]);

      // 2. Audit the created package
      final auditRegistry = CommandRegistry();
      auditRegistry.register(AuditCommand());

      final exitCode = await auditRegistry.run([
        'audit',
        '--target',
        targetOutput,
        '--profile',
        'standard',
      ]);

      expect(exitCode, equals(0));

      // Clean temp dir
      const SystemFileUtils().delete(tempDir);
    });
  });
}
