import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// fps deps / fps dependencies
// ─────────────────────────────────────────────────────────────────────────────

/// Command: `fps deps` (alias `fps dependencies`)
///
/// AI Dependency & Compatibility Advisor for analyzing constraints, conflicts, and upgrade risks (Phase 8.8).
class DependencyCommand extends FpsCommand {
  @override
  final String name = 'deps';

  @override
  List<String> get aliases => const ['dependencies'];

  @override
  final String description =
      'Analyze Dart/Flutter package dependencies, SDK constraints, version conflicts, and upgrade risks.';

  DependencyCommand() {
    argParser.addOption(
      'target',
      abbr: 't',
      help: 'Specific target dependency to focus on (e.g. "meta", "provider").',
    );
    argParser.addOption(
      'scope',
      abbr: 's',
      help: 'Analysis scope: whole-project or package.',
      defaultsTo: 'whole-project',
    );
    argParser.addOption(
      'package',
      abbr: 'p',
      help: 'Target package in a monorepo workspace.',
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
      help: 'Context token budget limit.',
      defaultsTo: '4000',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output file path when --write is specified.',
    );
    argParser.addFlag(
      'check-duplicates',
      defaultsTo: true,
      help: 'Audit duplicate dependencies across monorepo packages.',
    );
    argParser.addFlag(
      'write',
      abbr: 'w',
      negatable: false,
      help: 'Write the rendered dependency report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output dependency analysis findings as structured JSON.',
    );
  }

  @override
  Future<int> run() async {
    final targetDep = argResults?['target'] as String?;
    final scopeStr = argResults?['scope'] as String? ?? 'whole-project';
    final targetPkg = argResults?['package'] as String?;
    final dirPath = argResults?['dir'] as String? ?? '.';
    final budgetStr = argResults?['budget'] as String? ?? '4000';
    final outputPath = argResults?['output'] as String?;
    final checkDuplicates = argResults?['check-duplicates'] as bool? ?? true;
    final writeToDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final tokenBudget = int.tryParse(budgetStr) ?? 4000;

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    final scope = DependencyAnalysisScope.tryParse(scopeStr) ??
        DependencyAnalysisScope.wholeProject;
    if (scope == DependencyAnalysisScope.package &&
        (targetPkg == null || targetPkg.trim().isEmpty)) {
      print(
          'Error: --package argument is required when running with package scope.');
      return 1;
    }

    final provider = MockAiProvider(
      defaultResponse: jsonEncode({
        'summary': 'Dependency and compatibility analysis completed.',
        'findings': [],
      }),
    );

    final engine = DependencyAdvisorEngine.withProvider(
      projectRoot: projectDir.path,
      provider: provider,
    );
    const renderer = DependencyAdvisorRenderer();

    final req = DependencyAnalysisRequest(
      scope: scope,
      targetPackage: targetPkg,
      targetDependency: targetDep,
      checkDuplicates: checkDuplicates,
      tokenBudget: tokenBudget,
    );

    final result = await engine.analyze(req);

    if (jsonOutput) {
      print(renderer.renderJson(result));
    } else {
      print(renderer.renderMarkdown(result));
    }

    if (writeToDisk && outputPath != null) {
      final content = jsonOutput
          ? renderer.renderJson(result)
          : renderer.renderMarkdown(result);
      File(outputPath).writeAsStringSync(content);
      print('Wrote Dependency Advisory report to $outputPath');
    }

    return result.isSuccess ? 0 : 1;
  }
}
