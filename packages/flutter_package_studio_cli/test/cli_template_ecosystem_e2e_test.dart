import 'package:flutter_package_studio_cli/flutter_package_studio_cli.dart';
import 'package:test/test.dart';

CommandRegistry _buildRegistry() {
  final registry = CommandRegistry();
  registry.register(TemplateCatalogCommand());
  return registry;
}

void main() {
  group('Template Ecosystem CLI E2E Workflow Tests', () {
    late CommandRegistry registry;

    setUp(() {
      registry = _buildRegistry();
    });

    test(
        'Step 0: fps template root displays ecosystem workflow guide and returns 64',
        () async {
      final code = await registry.run(['template']);
      expect(code, equals(64));
    });

    test('Step 1: Discovery - fps template list returns catalog entries',
        () async {
      final code = await registry.run(['template', 'list']);
      expect(code, equals(0));
    });

    test(
        'Step 2: Inspection - fps template info flutter_package returns template details',
        () async {
      final code = await registry.run(['template', 'info', 'flutter_package']);
      expect(code, equals(0));
    });

    test(
        'Step 3: Compatibility Check - fps template check flutter_package passes',
        () async {
      final code = await registry.run(['template', 'check', 'flutter_package']);
      expect(code, equals(0));
    });

    test('Step 4: Composition - fps template compose flutter_package passes',
        () async {
      final code =
          await registry.run(['template', 'compose', 'flutter_package']);
      expect(code, equals(0));
    });

    test(
        'Step 5: Customization - fps template customize flutter_package passes',
        () async {
      final code =
          await registry.run(['template', 'customize', 'flutter_package']);
      expect(code, equals(0));
    });

    test(
        'Step 6: Quality Validation - fps template validate flutter_package passes',
        () async {
      final code =
          await registry.run(['template', 'validate', 'flutter_package']);
      expect(code, equals(0));
    });

    test('Step 7: Lifecycle Hooks - fps template hooks flutter_package passes',
        () async {
      final code = await registry.run(['template', 'hooks', 'flutter_package']);
      expect(code, equals(0));
    });

    test('Step 8: Certification - fps template certify flutter_package passes',
        () async {
      final code =
          await registry.run(['template', 'certify', 'flutter_package']);
      expect(code, equals(0));
    });

    test('Step 9: Testing - fps template test flutter_package passes',
        () async {
      final code = await registry.run(['template', 'test', 'flutter_package']);
      expect(code, equals(0));
    });

    test(
        'Step 10: Migration Preview - fps template migrate my_proj --from 1.0.0 --to 1.1.0 passes',
        () async {
      final code = await registry.run([
        'template',
        'migrate',
        'my_proj',
        '--from',
        '1.0.0',
        '--to',
        '1.1.0',
      ]);
      expect(code, equals(0));
    });
  });
}
