import 'dart:io';
import 'package:flutter_package_studio_core/src/utils/terminal_utils.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_context.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_question.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_step.dart';
import 'package:flutter_package_studio_core/src/wizard/wizard_theme.dart';

/// Function interface for reading text input lines (supports mocking in unit tests).
typedef LineReader = String? Function();

/// Renderer responsible for terminal output formatting, prompt printing, and summary screens.
class WizardRenderer {
  /// Theme styling definitions.
  final WizardTheme theme;

  /// Output sink (defaults to [stdout]).
  final StringSink output;

  /// Line reader function (defaults to standard input reader).
  final LineReader inputReader;

  /// Creates a [WizardRenderer] instance.
  WizardRenderer({
    WizardTheme? theme,
    StringSink? output,
    LineReader? inputReader,
  })  : theme = theme ?? const WizardTheme(),
        output = output ?? stdout,
        inputReader = inputReader ?? stdin.readLineSync;

  /// Creates a [WizardRenderer] configured from [TerminalUtils].
  factory WizardRenderer.fromTerminal(
    TerminalUtils terminal, {
    StringSink? output,
    LineReader? inputReader,
  }) {
    return WizardRenderer(
      theme: WizardTheme.fromTerminal(terminal),
      output: output,
      inputReader: inputReader,
    );
  }

  /// Renders wizard ASCII header.
  void renderHeader() {
    output.writeln();
    output.writeln(
        theme.primary('===================================================='));
    output.writeln(
        theme.primary('       FLUTTER PACKAGE STUDIO — PROJECT WIZARD      '));
    output.writeln(
        theme.primary('===================================================='));
    output.writeln(
        theme.muted('  Enterprise Flutter/Dart package creation workflow '));
    output.writeln();
  }

  /// Renders step header with counter.
  void renderStepHeader(WizardStep step, int stepNumber, int totalSteps) {
    output.writeln();
    output.writeln(
        '${theme.promptSymbol} ${theme.highlight('Step $stepNumber of $totalSteps')}: ${theme.primary(step.title)}');
    output.writeln('  ${theme.muted(step.description)}');
    output.writeln();
  }

  /// Renders error feedback message.
  void renderError(String message) {
    output.writeln('  ${theme.errorSymbol} ${theme.error(message)}');
  }

  /// Renders success confirmation message.
  void renderSuccess(String message) {
    output.writeln('  ${theme.successSymbol} ${theme.success(message)}');
  }

  /// Prompts for input for a given question and returns parsed value or null on back command.
  dynamic renderQuestion(WizardQuestion question, dynamic initialValue) {
    final help = question.helpText != null
        ? ' (${theme.muted(question.helpText!)})'
        : '';
    final defVal = question.defaultValue != null || initialValue != null
        ? ' [default: ${initialValue ?? question.defaultValue}]'
        : '';

    switch (question.type) {
      case WizardQuestionType.confirm:
        return _askConfirm(question, help, initialValue);
      case WizardQuestionType.singleSelect:
        return _askSingleSelect(question, help, initialValue);
      case WizardQuestionType.multiSelect:
        return _askMultiSelect(question, help, initialValue);
      default:
        return _askFreeText(question, help, defVal, initialValue);
    }
  }

  dynamic _askFreeText(WizardQuestion question, String help, String defVal,
      dynamic initialValue) {
    while (true) {
      output.write(
          '  ${theme.pointerSymbol} ${theme.highlight(question.prompt)}$help$defVal: ');
      final rawInput = inputReader();
      if (rawInput == null) return null; // EOF or cancelled

      final trimmed = rawInput.trim();
      if (trimmed == '<' || trimmed == ':b') return ':b'; // Back command

      var val = trimmed;
      if (val.isEmpty) {
        val = (initialValue ?? question.defaultValue)?.toString() ?? '';
      }

      if (question.type == WizardQuestionType.numeric) {
        final parsedNum = num.tryParse(val);
        if (parsedNum == null) {
          renderError('Invalid number format.');
          continue;
        }
        final validation = question.validateInput(parsedNum);
        if (!validation.isValid) {
          validation.errors.forEach(renderError);
          continue;
        }
        return parsedNum;
      }

      final validation = question.validateInput(val);
      if (!validation.isValid) {
        validation.errors.forEach(renderError);
        continue;
      }
      return val;
    }
  }

  dynamic _askConfirm(
      WizardQuestion question, String help, dynamic initialValue) {
    final defBool =
        (initialValue as bool?) ?? (question.defaultValue as bool?) ?? true;
    final hint = defBool ? ' (Y/n)' : ' (y/N)';

    while (true) {
      output.write(
          '  ${theme.pointerSymbol} ${theme.highlight(question.prompt)}$hint: ');
      final rawInput = inputReader();
      if (rawInput == null) return null;

      final trimmed = rawInput.trim().toLowerCase();
      if (trimmed == '<' || trimmed == ':b') return ':b';

      if (trimmed.isEmpty) return defBool;
      if (trimmed == 'y' || trimmed == 'yes') return true;
      if (trimmed == 'n' || trimmed == 'no') return false;

      renderError('Please answer with "y" (yes) or "n" (no).');
    }
  }

  dynamic _askSingleSelect(
      WizardQuestion question, String help, dynamic initialValue) {
    final options = question.options;
    output.writeln(
        '  ${theme.pointerSymbol} ${theme.highlight(question.prompt)}$help:');
    for (int i = 0; i < options.length; i++) {
      final opt = options[i];
      final isDef = (initialValue ?? question.defaultValue) == opt.value;
      final marker = isDef ? ' ${theme.success('*')}' : '';
      final desc =
          opt.description != null ? ' - ${theme.muted(opt.description!)}' : '';
      output.writeln(
          '    ${theme.primary('${i + 1}.')} ${opt.label}$desc$marker');
    }

    while (true) {
      output.write('  Enter selection number (1-${options.length}) or value: ');
      final rawInput = inputReader();
      if (rawInput == null) return null;

      final trimmed = rawInput.trim();
      if (trimmed == '<' || trimmed == ':b') return ':b';

      if (trimmed.isEmpty) {
        final defaultVal = initialValue ?? question.defaultValue;
        if (defaultVal != null) return defaultVal;
      }

      final index = int.tryParse(trimmed);
      if (index != null && index >= 1 && index <= options.length) {
        return options[index - 1].value;
      }

      // Check if user entered option value directly
      final matchedOpt =
          options.where((o) => o.value.toString() == trimmed).firstOrNull;
      if (matchedOpt != null) return matchedOpt.value;

      renderError(
          'Invalid selection. Enter a number between 1 and ${options.length}.');
    }
  }

  dynamic _askMultiSelect(
      WizardQuestion question, String help, dynamic initialValue) {
    final options = question.options;
    final initialList = (initialValue as List?)
            ?.map((e) => e.toString())
            .toList() ??
        (question.defaultValue as List?)?.map((e) => e.toString()).toList() ??
        <String>[];

    output.writeln(
        '  ${theme.pointerSymbol} ${theme.highlight(question.prompt)}$help:');
    output.writeln(
        '    ${theme.muted('(Enter comma-separated numbers, e.g. "1, 2, 4")')}');
    for (int i = 0; i < options.length; i++) {
      final opt = options[i];
      final isSelected = initialList.contains(opt.value.toString());
      final box = isSelected ? theme.success('[X]') : theme.muted('[ ]');
      output.writeln('    ${theme.primary('${i + 1}.')} $box ${opt.label}');
    }

    while (true) {
      output.write('  Select options: ');
      final rawInput = inputReader();
      if (rawInput == null) return null;

      final trimmed = rawInput.trim();
      if (trimmed == '<' || trimmed == ':b') return ':b';

      if (trimmed.isEmpty) return initialList;

      final parts = trimmed
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final selectedValues = <String>[];
      bool valid = true;

      for (final part in parts) {
        final idx = int.tryParse(part);
        if (idx != null && idx >= 1 && idx <= options.length) {
          selectedValues.add(options[idx - 1].value.toString());
        } else if (options.any((o) => o.value.toString() == part)) {
          selectedValues.add(part);
        } else {
          renderError('Invalid choice "$part".');
          valid = false;
          break;
        }
      }

      if (valid) return selectedValues;
    }
  }

  /// Renders final project summary and confirmation page. Returns true if user confirms generation.
  bool renderSummaryAndConfirm(WizardContext context) {
    output.writeln();
    output.writeln(
        theme.primary('===================================================='));
    output.writeln(
        theme.primary('           PROJECT GENERATION SUMMARY               '));
    output.writeln(
        theme.primary('===================================================='));
    output.writeln(
        '  ${theme.highlight('Package Name:')}        ${context.packageName}');
    output.writeln(
        '  ${theme.highlight('Project Type:')}        ${context.projectType}');
    output.writeln(
        '  ${theme.highlight('Description:')}         ${context.description}');
    output.writeln(
        '  ${theme.highlight('Organization:')}        ${context.orgName}');
    output.writeln(
        '  ${theme.highlight('Author:')}              ${context.author} <${context.email}>');
    output.writeln(
        '  ${theme.highlight('License:')}             ${context.license}');
    output.writeln(
        '  ${theme.highlight('Dart SDK:')}            ${context.dartSdkConstraint}');
    if (context.projectType != 'dart_package') {
      output.writeln(
          '  ${theme.highlight('Flutter SDK:')}         ${context.flutterSdkConstraint}');
      output.writeln(
          '  ${theme.highlight('Platforms:')}           ${context.platforms.join(', ')}');
    }
    output.writeln(
        '  ${theme.highlight('Architecture:')}        ${context.preferredArchitecture}');
    output.writeln(
        '  ${theme.highlight('Testing Suite:')}       ${context.testingPreferences.join(', ')}');
    output.writeln(
        '  ${theme.highlight('CI/CD Setup:')}          ${context.ciCdPreferences}');
    output.writeln(
        '  ${theme.highlight('Output Directory:')}    ${context.outputDirectory}');
    output.writeln(
        theme.primary('===================================================='));
    output.writeln();

    output.write(
        '  ${theme.pointerSymbol} Proceed with project creation? (Y/n): ');
    final rawInput = inputReader();
    if (rawInput == null) return false;
    final trimmed = rawInput.trim().toLowerCase();
    return trimmed.isEmpty || trimmed == 'y' || trimmed == 'yes';
  }
}
