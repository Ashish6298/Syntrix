import 'package:test/test.dart';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';

void main() {
  group('TemplateHookRegistry', () {
    late TemplateHookRegistry registry;

    setUp(() {
      registry = TemplateHookRegistry();
    });

    test('registers and retrieves hooks', () {
      final hook = FunctionalTemplateHook(
        id: 'hook_1',
        name: 'Hook One',
        supportedPhases: [TemplateHookPhase.preResolution],
        provenance: 'base_template',
        handler: (ctx) => TemplateHookResult.success(
          hookId: 'hook_1',
          phase: ctx.activePhase,
          duration: Duration.zero,
        ),
      );

      registry.register(hook);
      expect(registry.contains('hook_1'), isTrue);
      expect(registry.get('hook_1')?.hook.id, equals('hook_1'));
    });

    test('throws on duplicate hook ID', () {
      final hook1 = FunctionalTemplateHook(
        id: 'dup_hook',
        name: 'Hook 1',
        supportedPhases: [TemplateHookPhase.preGeneration],
        provenance: 'tpl_a',
        handler: (ctx) => TemplateHookResult.skipped(
            hookId: 'dup_hook', phase: ctx.activePhase),
      );
      final hook2 = FunctionalTemplateHook(
        id: 'dup_hook',
        name: 'Hook 2',
        supportedPhases: [TemplateHookPhase.postGeneration],
        provenance: 'tpl_b',
        handler: (ctx) => TemplateHookResult.skipped(
            hookId: 'dup_hook', phase: ctx.activePhase),
      );

      registry.register(hook1);
      expect(() => registry.register(hook2),
          throwsA(isA<TemplateHookValidationException>()));
    });

    test('orders hooks by priority descending and registration index ascending',
        () {
      final hLow = FunctionalTemplateHook(
        id: 'h_low',
        name: 'Low Priority',
        supportedPhases: [TemplateHookPhase.validation],
        provenance: 'tpl',
        priority: 0,
        handler: (ctx) =>
            TemplateHookResult.skipped(hookId: 'h_low', phase: ctx.activePhase),
      );
      final hHigh = FunctionalTemplateHook(
        id: 'h_high',
        name: 'High Priority',
        supportedPhases: [TemplateHookPhase.validation],
        provenance: 'tpl',
        priority: 100,
        handler: (ctx) => TemplateHookResult.skipped(
            hookId: 'h_high', phase: ctx.activePhase),
      );
      final hMed = FunctionalTemplateHook(
        id: 'h_med',
        name: 'Medium Priority',
        supportedPhases: [TemplateHookPhase.validation],
        provenance: 'tpl',
        priority: 50,
        handler: (ctx) =>
            TemplateHookResult.skipped(hookId: 'h_med', phase: ctx.activePhase),
      );

      registry.register(hLow);
      registry.register(hHigh);
      registry.register(hMed);

      final resolved =
          registry.resolveHooksForPhase(TemplateHookPhase.validation);
      expect(resolved.map((h) => h.id).toList(),
          equals(['h_high', 'h_med', 'h_low']));
    });

    test('orders hooks respecting dependencies via topological sort', () {
      final hA = FunctionalTemplateHook(
        id: 'hook_a',
        name: 'Hook A',
        supportedPhases: [TemplateHookPhase.postComposition],
        provenance: 'tpl',
        dependencies: ['hook_b'],
        handler: (ctx) => TemplateHookResult.skipped(
            hookId: 'hook_a', phase: ctx.activePhase),
      );
      final hB = FunctionalTemplateHook(
        id: 'hook_b',
        name: 'Hook B',
        supportedPhases: [TemplateHookPhase.postComposition],
        provenance: 'tpl',
        handler: (ctx) => TemplateHookResult.skipped(
            hookId: 'hook_b', phase: ctx.activePhase),
      );

      registry.register(hA);
      registry.register(hB);

      final resolved =
          registry.resolveHooksForPhase(TemplateHookPhase.postComposition);
      expect(resolved.map((h) => h.id).toList(), equals(['hook_b', 'hook_a']));
    });

    test('throws TemplateHookDependencyException on circular dependencies', () {
      final hA = FunctionalTemplateHook(
        id: 'hook_a',
        name: 'Hook A',
        supportedPhases: [TemplateHookPhase.preCustomization],
        provenance: 'tpl',
        dependencies: ['hook_b'],
        handler: (ctx) => TemplateHookResult.skipped(
            hookId: 'hook_a', phase: ctx.activePhase),
      );
      final hB = FunctionalTemplateHook(
        id: 'hook_b',
        name: 'Hook B',
        supportedPhases: [TemplateHookPhase.preCustomization],
        provenance: 'tpl',
        dependencies: ['hook_a'],
        handler: (ctx) => TemplateHookResult.skipped(
            hookId: 'hook_b', phase: ctx.activePhase),
      );

      registry.register(hA);
      registry.register(hB);

      expect(
          () =>
              registry.resolveHooksForPhase(TemplateHookPhase.preCustomization),
          throwsA(isA<TemplateHookDependencyException>()));
    });
  });

  group('TemplateHookContext Security & Sandbox Bounds', () {
    test('rejects absolute paths in sandbox filesystem access', () {
      final sandbox = SystemHookSandboxFileSystem(rootDirectory: '/app/target');
      expect(() => sandbox.sanitizePath('/etc/passwd'),
          throwsA(isA<TemplateHookSecurityException>()));
      expect(() => sandbox.sanitizePath('C:\\Windows\\System32'),
          throwsA(isA<TemplateHookSecurityException>()));
    });

    test('rejects path traversal attempts outside target directory', () {
      final sandbox = SystemHookSandboxFileSystem(rootDirectory: '/app/target');
      expect(() => sandbox.sanitizePath('../outside.txt'),
          throwsA(isA<TemplateHookSecurityException>()));
    });

    test('redacts secret credentials and tokens from diagnostic strings', () {
      const sensitive =
          'Token ghp_1234567890abcdefghijklmnopqrstuvwxyz12 is secret';
      final redacted = TemplateHookContext.redactSecrets(sensitive);
      expect(redacted, contains('[REDACTED_SECRET]'));
      expect(redacted, isNot(contains('ghp_1234567890')));
    });
  });

  group('TemplateHookEngine Lifecycle Execution', () {
    late TemplateHookRegistry registry;
    late TemplateHookEngine engine;

    setUp(() {
      registry = TemplateHookRegistry();
      engine = TemplateHookEngine(registry: registry);
    });

    test('executes hooks and collects proposed actions', () async {
      final hook = FunctionalTemplateHook(
        id: 'action_hook',
        name: 'Action Provider Hook',
        supportedPhases: [TemplateHookPhase.preGeneration],
        provenance: 'my_template',
        handler: (ctx) {
          ctx.proposeAddFile('lib/generated_meta.dart', '// Generated');
          ctx.proposeVariable('custom_var', 'custom_value');
          return TemplateHookResult.success(
            hookId: 'action_hook',
            phase: ctx.activePhase,
            duration: const Duration(milliseconds: 5),
            proposedActions: ctx.proposedActions,
          );
        },
      );

      registry.register(hook);

      final ctx = TemplateHookContext(
        targetDirectory: '/virtual/project',
        activePhase: TemplateHookPhase.preGeneration,
        metadata: {'templateId': 'my_template'},
        dryRun: true,
      );

      final report = await engine.executePhase(
        phase: TemplateHookPhase.preGeneration,
        context: ctx,
      );

      expect(report.isSuccess, isTrue);
      expect(report.results.length, equals(1));
      expect(report.aggregatedActions.length, equals(2));
      expect(report.aggregatedActions[0].type, equals(HookActionType.addFile));
      expect(report.aggregatedActions[0].relativePath,
          equals('lib/generated_meta.dart'));
    });

    test('handles failFast policy by rethrowing execution exception', () async {
      final hook = FunctionalTemplateHook(
        id: 'failing_hook',
        name: 'Failing Hook',
        supportedPhases: [TemplateHookPhase.validation],
        provenance: 'my_template',
        failurePolicy: TemplateHookPolicy.failFast,
        handler: (ctx) {
          throw Exception('Fatal hook error');
        },
      );

      registry.register(hook);

      final ctx = TemplateHookContext(
        targetDirectory: '/virtual/project',
        activePhase: TemplateHookPhase.validation,
      );

      expect(
          () => engine.executePhase(
                phase: TemplateHookPhase.validation,
                context: ctx,
              ),
          throwsA(isA<TemplateHookExecutionException>()));
    });

    test('handles continueOnError policy by recording failure without throwing',
        () async {
      final hook = FunctionalTemplateHook(
        id: 'lenient_hook',
        name: 'Lenient Hook',
        supportedPhases: [TemplateHookPhase.validation],
        provenance: 'my_template',
        failurePolicy: TemplateHookPolicy.continueOnError,
        handler: (ctx) {
          throw Exception('Non-fatal error');
        },
      );

      registry.register(hook);

      final ctx = TemplateHookContext(
        targetDirectory: '/virtual/project',
        activePhase: TemplateHookPhase.validation,
      );

      final report = await engine.executePhase(
        phase: TemplateHookPhase.validation,
        context: ctx,
      );

      expect(report.isSuccess, isFalse);
      expect(report.results.length, equals(1));
      expect(report.results[0].status, equals(TemplateHookStatus.failed));
    });

    test('handles warningOnly policy by converting error status to warning',
        () async {
      final hook = FunctionalTemplateHook(
        id: 'warn_hook',
        name: 'Warning Hook',
        supportedPhases: [TemplateHookPhase.postCustomization],
        provenance: 'my_template',
        failurePolicy: TemplateHookPolicy.warningOnly,
        handler: (ctx) {
          throw Exception('Minor customization warning');
        },
      );

      registry.register(hook);

      final ctx = TemplateHookContext(
        targetDirectory: '/virtual/project',
        activePhase: TemplateHookPhase.postCustomization,
      );

      final report = await engine.executePhase(
        phase: TemplateHookPhase.postCustomization,
        context: ctx,
      );

      expect(report.results.length, equals(1));
      expect(report.results[0].status, equals(TemplateHookStatus.warning));
    });
  });
}
