import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ai test / test-intelligence CLI command
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps ai test <package-id>` / `fps project test-intelligence`
///
/// Analyzes test coverage gaps, implementation-to-test pairings, and generates isolated test proposals (Phase 8.4).
class AiTestCommand extends FpsCommand {
  @override
  final String name = 'test';

  @override
  final String description =
      'Analyze test coverage gaps, regression risks, and generate isolated candidate test proposals.';

  AiTestCommand() {
    argParser.addOption(
      'package',
      abbr: 'p',
      help: 'Target package ID/name in workspace.',
    );
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Target source file to analyze for coverage gaps.',
    );
    argParser.addOption(
      'dir',
      abbr: 'd',
      help: 'Project root directory path.',
      defaultsTo: '.',
    );
    argParser.addFlag(
      'proposals',
      abbr: 'g',
      negatable: false,
      help:
          'Generate candidate Dart test proposal snippets in isolated proposal locations.',
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
      defaultsTo: 'test_intelligence_report.md',
    );
    argParser.addFlag(
      'write',
      abbr: 'w',
      negatable: false,
      help: 'Write the rendered test intelligence report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output test intelligence results as structured JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    final targetPkg = (argResults?['package'] as String?) ??
        (rest.isNotEmpty ? rest.first : null);
    final targetFile = argResults?['file'] as String?;
    final dirPath = argResults?['dir'] as String? ?? '.';
    final generateProposals = argResults?['proposals'] as bool? ?? false;
    final budgetStr = argResults?['budget'] as String? ?? '4000';
    final outputPath =
        argResults?['output'] as String? ?? 'test_intelligence_report.md';
    final writeToDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final tokenBudget = int.tryParse(budgetStr) ?? 4000;

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    final provider = MockAiProvider(
      defaultResponse: jsonEncode({
        'summary': 'Test intelligence analysis completed.',
        'gapReports': [],
      }),
    );

    final engine = TestIntelligenceEngine.withProvider(
      projectRoot: projectDir.path,
      provider: provider,
    );

    final request = TestIntelligenceRequest(
      targetPackage: targetPkg,
      targetFile: targetFile,
      generateProposals: generateProposals,
      tokenBudget: tokenBudget,
    );

    final result = await engine.analyze(request);
    const renderer = TestIntelligenceRenderer();

    if (!result.isSuccess) {
      print('Error: Test intelligence analysis failed.');
      if (result.errorMessage != null) {
        print(result.errorMessage!);
      }
      return 1;
    }

    if (jsonOutput) {
      final rendered = renderer.renderJson(result);
      print(rendered);
      if (writeToDisk) {
        final targetOut = File(outputPath);
        targetOut.parent.createSync(recursive: true);
        targetOut.writeAsStringSync(rendered);
        print('Wrote Test Intelligence JSON report to $outputPath');
      }
    } else {
      final rendered = renderer.renderMarkdown(result);
      print(rendered);
      if (writeToDisk) {
        final targetOut = File(outputPath);
        targetOut.parent.createSync(recursive: true);
        targetOut.writeAsStringSync(rendered);
        print('Wrote Test Intelligence Markdown report to $outputPath');
      }
    }

    return 0;
  }
}
