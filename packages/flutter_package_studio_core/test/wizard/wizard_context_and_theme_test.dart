import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('WizardTheme Tests', () {
    test('ANSI enabled formatting', () {
      const theme = WizardTheme(enableAnsi: true);
      expect(theme.primary('Test'), contains('\x1B[36m'));
      expect(theme.success('Ok'), contains('\x1B[32m'));
      expect(theme.error('Err'), contains('\x1B[31m'));
      expect(theme.warning('Warn'), contains('\x1B[33m'));
      expect(theme.secondary('Sec'), contains('\x1B[35m'));
      expect(theme.muted('Dim'), contains('\x1B[90m'));
      expect(theme.promptSymbol, contains('?'));
      expect(theme.pointerSymbol, contains('❯'));
      expect(theme.successSymbol, contains('✔'));
      expect(theme.errorSymbol, contains('✖'));
      expect(theme.bulletSymbol, contains('•'));
    });

    test('Plain text fallback when ANSI disabled', () {
      const theme = WizardTheme(enableAnsi: false);
      expect(theme.primary('Test'), equals('Test'));
      expect(theme.success('Ok'), equals('Ok'));
      expect(theme.error('Err'), equals('Err'));
      expect(theme.warning('Warn'), equals('Warn'));
      expect(theme.secondary('Sec'), equals('Sec'));
      expect(theme.muted('Dim'), equals('Dim'));
      expect(theme.promptSymbol, equals('?'));
      expect(theme.pointerSymbol, equals('>'));
      expect(theme.successSymbol, equals('[v]'));
      expect(theme.errorSymbol, equals('[x]'));
      expect(theme.bulletSymbol, equals('*'));
    });

    test('Factory fromTerminal', () {
      const mockTerminal = _MockTerminalUtils(supportsAnsi: false);
      final theme = WizardTheme.fromTerminal(mockTerminal);
      expect(theme.enableAnsi, isFalse);
    });
  });

  group('WizardContext Tests', () {
    test('Default values initialization', () {
      final ctx = WizardContext();
      expect(ctx.packageName, isEmpty);
      expect(ctx.projectType, equals('flutter_package'));
      expect(ctx.license, equals('MIT'));
      expect(ctx.platforms,
          containsAll(['android', 'ios', 'web', 'windows', 'macos', 'linux']));
      expect(ctx.testingPreferences, contains('unit'));
    });

    test('toMap and fromMap roundtrip', () {
      final ctx = WizardContext(
        packageName: 'my_plugin',
        projectType: 'plugin',
        description: 'Test plugin',
        orgName: 'io.syntrix',
        author: 'Jane Doe',
        email: 'jane@example.com',
        license: 'BSD-3-Clause',
        repoUrl: 'https://github.com/example/plugin',
        platforms: ['android', 'ios'],
        extraMetadata: {'customKey': 'customVal'},
      );

      final map = ctx.toMap();
      final restored = WizardContext.fromMap(map);

      expect(restored.packageName, equals('my_plugin'));
      expect(restored.projectType, equals('plugin'));
      expect(restored.orgName, equals('io.syntrix'));
      expect(restored.author, equals('Jane Doe'));
      expect(restored.email, equals('jane@example.com'));
      expect(restored.license, equals('BSD-3-Clause'));
      expect(restored.platforms, equals(['android', 'ios']));
      expect(restored.extraMetadata['customKey'], equals('customVal'));
    });

    test('copyWith produces updated instance', () {
      final ctx = WizardContext(packageName: 'old_name');
      final updated =
          ctx.copyWith(packageName: 'new_name', projectType: 'dart_package');
      expect(updated.packageName, equals('new_name'));
      expect(updated.projectType, equals('dart_package'));
      expect(ctx.packageName,
          equals('old_name')); // Immutability of original reference
    });
  });
}

class _MockTerminalUtils implements TerminalUtils {
  @override
  final bool supportsAnsi;

  const _MockTerminalUtils({required this.supportsAnsi});

  @override
  int get height => 24;

  @override
  int get width => 80;
}
