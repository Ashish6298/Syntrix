import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

void main() {
  group('TemplateCatalogCommand CLI Tests', () {
    late CommandRegistry registry;

    setUp(() {
      registry = CommandRegistry();
      registry.register(TemplateCatalogCommand());
    });

    // ── Parent command ────────────────────────────────────────────────────

    test('fps template (no subcommand) returns usage code (0 or 64)', () async {
      final exitCode = await registry.run(['template']);
      // args package may return 0 (run() called) or 64 (UsageException) when
      // a parent command is invoked without a subcommand, depending on version.
      expect(exitCode, isIn([0, 64]));
    });

    // ── template list ─────────────────────────────────────────────────────

    test('fps template list returns 0 and lists builtin template', () async {
      final exitCode = await registry.run(['template', 'list']);
      expect(exitCode, equals(0));
    });

    test('fps template list --project-type flutter_package returns 0',
        () async {
      final exitCode = await registry
          .run(['template', 'list', '--project-type', 'flutter_package']);
      expect(exitCode, equals(0));
    });

    test('fps template list --project-type nonexistent returns 0', () async {
      final exitCode = await registry
          .run(['template', 'list', '--project-type', 'nonexistent_type']);
      expect(exitCode, equals(0));
    });

    test('fps template list --limit 1 returns 0', () async {
      final exitCode = await registry.run(['template', 'list', '--limit', '1']);
      expect(exitCode, equals(0));
    });

    test('fps template list --sort version returns 0', () async {
      final exitCode =
          await registry.run(['template', 'list', '--sort', 'version']);
      expect(exitCode, equals(0));
    });

    test('fps template list --sort rating returns 0', () async {
      final exitCode =
          await registry.run(['template', 'list', '--sort', 'rating']);
      expect(exitCode, equals(0));
    });

    test('fps template list --sort downloads returns 0', () async {
      final exitCode =
          await registry.run(['template', 'list', '--sort', 'downloads']);
      expect(exitCode, equals(0));
    });

    test('fps template list --sort recent returns 0', () async {
      final exitCode =
          await registry.run(['template', 'list', '--sort', 'recent']);
      expect(exitCode, equals(0));
    });

    test('fps template list --json returns 0', () async {
      final exitCode = await registry.run(['template', 'list', '--json']);
      expect(exitCode, equals(0));
    });

    test('fps template list --category builtin returns 0', () async {
      final exitCode =
          await registry.run(['template', 'list', '--category', 'builtin']);
      expect(exitCode, equals(0));
    });

    // ── template search ───────────────────────────────────────────────────

    test('fps template search flutter returns 0', () async {
      final exitCode = await registry.run(['template', 'search', 'flutter']);
      expect(exitCode, equals(0));
    });

    test('fps template search with no args returns usage error 64', () async {
      final exitCode = await registry.run(['template', 'search']);
      expect(exitCode, equals(64));
    });

    test('fps template search "xyz_nonexistent" returns 0 (no results)',
        () async {
      final exitCode =
          await registry.run(['template', 'search', 'xyz_nonexistent_zzz']);
      expect(exitCode, equals(0));
    });

    test('fps template search --limit 1 flutter returns 0', () async {
      final exitCode =
          await registry.run(['template', 'search', '--limit', '1', 'flutter']);
      expect(exitCode, equals(0));
    });

    test('fps template search --json flutter returns 0', () async {
      final exitCode =
          await registry.run(['template', 'search', '--json', 'production']);
      expect(exitCode, equals(0));
    });

    // ── template info ─────────────────────────────────────────────────────

    test('fps template info flutter_package returns 0', () async {
      final exitCode =
          await registry.run(['template', 'info', 'flutter_package']);
      expect(exitCode, equals(0));
    });

    test('fps template info with no args returns usage error 64', () async {
      final exitCode = await registry.run(['template', 'info']);
      expect(exitCode, equals(64));
    });

    test('fps template info nonexistent_id returns 1', () async {
      final exitCode =
          await registry.run(['template', 'info', 'nonexistent_id_xyz']);
      expect(exitCode, equals(1));
    });

    test('fps template info flutter_package --json returns 0', () async {
      final exitCode =
          await registry.run(['template', 'info', 'flutter_package', '--json']);
      expect(exitCode, equals(0));
    });

    test('fps template info flutter_package --version 1.0.0 returns 0',
        () async {
      final exitCode = await registry
          .run(['template', 'info', 'flutter_package', '--version', '1.0.0']);
      expect(exitCode, equals(0));
    });

    test(
        'fps template info flutter_package --version 99.0.0 (missing) returns 1',
        () async {
      final exitCode = await registry
          .run(['template', 'info', 'flutter_package', '--version', '99.0.0']);
      expect(exitCode, equals(1));
    });
  });

  // ── TemplateCommand backward-compat alias ─────────────────────────────────

  group('TemplateCommand Type Alias Tests', () {
    test('TemplateCommand is the same type as TemplateCatalogCommand', () {
      // Ensure the typedef works correctly
      final cmd = TemplateCommand();
      expect(cmd, isA<TemplateCatalogCommand>());
      expect(cmd.name, equals('template'));
    });
  });
}
