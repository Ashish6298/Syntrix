import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// architecture / ai architecture CLI command
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps architecture` / `fps ai architecture <template-id>`
///
/// Analyzes whole-monorepo or scoped package architecture, detects circular dependencies, layering violations, and duplicate logic (Phase 8.6).
class ArchitectureCommand extends FpsCommand {
  @override
  final String name = 'architecture';

  @override
  final String description =
      'Analyze monorepo architecture, circular dependencies, layering violations, and structural coupling.';

  ArchitectureCommand() {
    argParser.addOption(
      'package',
      abbr: 'p',
      help: 'Target package ID/name in monorepo to scope scan.',
    );
    argParser.addOption(
      'subsystem',
      abbr: 's',
      help: 'Target subsystem name (e.g. cli, release, wizard) to scope scan.',
    );
    argParser.addOption(
      'dir',
      abbr: 'd',
      help: 'Project root directory path.',
      defaultsTo: '.',
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
      defaultsTo: 'architecture_report.md',
    );
    argParser.addFlag(
      'write',
      abbr: 'w',
      negatable: false,
      help: 'Write the rendered architecture advisory report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output architecture scan results as structured JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    final targetPkg = (argResults?['package'] as String?) ??
        (rest.isNotEmpty ? rest.first : null);
    final targetSubsystem = argResults?['subsystem'] as String?;
    final dirPath = argResults?['dir'] as String? ?? '.';
    final budgetStr = argResults?['budget'] as String? ?? '4000';
    final outputPath =
        argResults?['output'] as String? ?? 'architecture_report.md';
    final writeToDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final tokenBudget = int.tryParse(budgetStr) ?? 4000;

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    final scope = targetPkg != null
        ? ArchitectureScanScope.package
        : (targetSubsystem != null
            ? ArchitectureScanScope.subsystem
            : ArchitectureScanScope.wholeProject);

    final provider = MockAiProvider(
      defaultResponse: jsonEncode({
        'summary': 'Architecture advisory scan completed.',
        'findings': [],
      }),
    );

    final engine = ArchitectureAdvisorEngine.withProvider(
      projectRoot: projectDir.path,
      provider: provider,
    );

    final request = ArchitectureScanRequest(
      scope: scope,
      targetPackage: targetPkg,
      targetSubsystem: targetSubsystem,
      tokenBudget: tokenBudget,
    );

    final result = await engine.scan(request);
    const renderer = ArchitectureAdvisorRenderer();

    if (!result.isSuccess) {
      print('Error: Architecture advisory scan failed.');
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
        print('Wrote Architecture JSON report to $outputPath');
      }
    } else {
      final rendered = renderer.renderMarkdown(result);
      print(rendered);
      if (writeToDisk) {
        final targetOut = File(outputPath);
        targetOut.parent.createSync(recursive: true);
        targetOut.writeAsStringSync(rendered);
        print('Wrote Architecture Markdown report to $outputPath');
      }
    }

    return 0;
  }
}
