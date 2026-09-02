import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// review
// ─────────────────────────────────────────────────────────────────────────────

/// Command: `fps review`
///
/// Runs the AI Code Analysis & Review Engine across Dart/Flutter packages and files (Phase 8.3).
class ReviewCommand extends FpsCommand {
  @override
  final String name = 'review';

  @override
  final String description =
      'Inspect Dart/Flutter source files and generate structured AI code review findings.';

  ReviewCommand() {
    argParser.addOption(
      'mode',
      abbr: 'm',
      help: 'Review mode: single-file, package, change-focused, architecture.',
      defaultsTo: 'package',
    );
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Target file path when running in single-file mode.',
    );
    argParser.addOption(
      'package',
      abbr: 'p',
      help: 'Target package name in a monorepo workspace.',
    );
    argParser.addOption(
      'dir',
      abbr: 'd',
      help: 'Project root directory path.',
      defaultsTo: '.',
    );
    argParser.addOption(
      'changed-files',
      abbr: 'c',
      help:
          'Comma-separated list of modified file paths for change-focused mode.',
    );
    argParser.addOption(
      'instruction',
      abbr: 'i',
      help: 'Custom review instruction or focus area.',
    );
    argParser.addOption(
      'budget',
      abbr: 'b',
      help: 'Maximum context token budget limit.',
      defaultsTo: '4000',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output file path when --write is specified.',
      defaultsTo: 'code_review_report.md',
    );
    argParser.addFlag(
      'write',
      abbr: 'w',
      negatable: false,
      help: 'Write the rendered review report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output review findings as structured JSON.',
    );
  }

  @override
  Future<int> run() async {
    final modeStr = argResults?['mode'] as String? ?? 'package';
    final targetFilePath = argResults?['file'] as String?;
    final targetPkg = argResults?['package'] as String?;
    final dirPath = argResults?['dir'] as String? ?? '.';
    final changedFilesStr = argResults?['changed-files'] as String?;
    final customInstruction = argResults?['instruction'] as String?;
    final budgetStr = argResults?['budget'] as String? ?? '4000';
    final outputPath =
        argResults?['output'] as String? ?? 'code_review_report.md';
    final writeToDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final tokenBudget = int.tryParse(budgetStr) ?? 4000;

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    CodeReviewMode reviewMode;
    switch (modeStr.toLowerCase()) {
      case 'single-file':
      case 'singlefile':
      case 'file':
        reviewMode = CodeReviewMode.singleFile;
        if (targetFilePath == null || targetFilePath.trim().isEmpty) {
          print(
              'Error: --file is required when running in single-file review mode.');
          return 64;
        }
        break;
      case 'package':
      case 'package-level':
      case 'packagelevel':
        reviewMode = CodeReviewMode.packageLevel;
        break;
      case 'change':
      case 'change-focused':
      case 'changefocused':
      case 'diff':
        reviewMode = CodeReviewMode.changeFocused;
        break;
      case 'architecture':
      case 'architecture-focused':
      case 'arch':
        reviewMode = CodeReviewMode.architectureFocused;
        break;
      default:
        print(
            'Error: Unrecognized review mode "$modeStr". Supported modes: single-file, package, change-focused, architecture.');
        return 64;
    }

    Set<String>? changedSet;
    if (changedFilesStr != null && changedFilesStr.trim().isNotEmpty) {
      changedSet = changedFilesStr
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
    }

    final provider = MockAiProvider(
      defaultResponse:
          '{"summary": "Code review analysis complete.", "findings": []}',
    );
    final engine = CodeReviewEngine.withProvider(
      projectRoot: projectDir.path,
      provider: provider,
    );

    final request = CodeReviewRequest(
      mode: reviewMode,
      targetFile: targetFilePath,
      targetPackage: targetPkg,
      changedFiles: changedSet,
      customInstruction: customInstruction,
      tokenBudget: tokenBudget,
    );

    final result = await engine.review(request);
    const renderer = CodeReviewRenderer();

    if (!result.isSuccess) {
      print('Error: Code review failed.');
      if (result.errorMessage != null) {
        print(result.errorMessage!);
      }
      return 1;
    }

    if (jsonOutput) {
      final rendered = renderer.renderJson(result);
      print(rendered);
      if (writeToDisk) {
        final targetFile = File(outputPath);
        targetFile.parent.createSync(recursive: true);
        targetFile.writeAsStringSync(rendered);
        print('Wrote Code Review JSON report to $outputPath');
      }
    } else {
      final rendered = renderer.renderMarkdown(result);
      print(rendered);
      if (writeToDisk) {
        final targetFile = File(outputPath);
        targetFile.parent.createSync(recursive: true);
        targetFile.writeAsStringSync(rendered);
        print('Wrote Code Review Markdown report to $outputPath');
      }
    }

    return 0;
  }
}
