import 'dart:convert';
import 'dart:io';
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:syntrix/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// fps security / fps ai security
// ─────────────────────────────────────────────────────────────────────────────

/// Command: `fps security` (alias `fps ai-security`)
///
/// AI Security & Privacy Advisor for analyzing audit findings, secret exposures, and credential risks (Phase 8.9).
class SecurityCommand extends FpsCommand {
  @override
  final String name = 'security';

  @override
  List<String> get aliases => const ['ai-security'];

  @override
  final String description =
      'Analyze security audit findings, secret exposures, credential handling, and privacy risks.';

  SecurityCommand() {
    argParser.addOption(
      'target',
      abbr: 't',
      help: 'Target package or component identifier.',
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
      help: 'Target package name in a monorepo workspace.',
    );
    argParser.addOption(
      'dir',
      abbr: 'd',
      help: 'Project root directory path.',
      defaultsTo: '.',
    );
    argParser.addOption(
      'min-priority',
      help:
          'Minimum priority filter: critical, high, medium, low, informational.',
      defaultsTo: 'informational',
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
      'write',
      abbr: 'w',
      negatable: false,
      help: 'Write the rendered security report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output security advisory findings as structured JSON.',
    );
  }

  @override
  Future<int> run() async {
    final target = argResults?['target'] as String?;
    final scopeStr = argResults?['scope'] as String? ?? 'whole-project';
    final targetPkg = (argResults?['package'] as String?) ?? target;
    final dirPath = argResults?['dir'] as String? ?? '.';
    final minPrioStr =
        argResults?['min-priority'] as String? ?? 'informational';
    final budgetStr = argResults?['budget'] as String? ?? '4000';
    final outputPath = argResults?['output'] as String?;
    final writeToDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final tokenBudget = int.tryParse(budgetStr) ?? 4000;

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    final scope = SecurityAnalysisScope.tryParse(scopeStr) ??
        SecurityAnalysisScope.wholeProject;
    if (scope == SecurityAnalysisScope.package &&
        (targetPkg == null || targetPkg.trim().isEmpty)) {
      print(
          'Error: --package argument is required when running with package scope.');
      return 1;
    }

    final minPriority =
        SecurityPriority.tryParse(minPrioStr) ?? SecurityPriority.informational;

    final provider = MockAiProvider(
      defaultResponse: jsonEncode({
        'summary': 'Security and privacy analysis completed.',
        'findings': [],
      }),
    );

    final engine = SecurityAdvisorEngine.withProvider(
      projectRoot: projectDir.path,
      provider: provider,
    );
    const renderer = SecurityAdvisorRenderer();

    final req = SecurityAnalysisRequest(
      scope: scope,
      targetPackage: targetPkg,
      minPriority: minPriority,
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
      print('Wrote Security Advisory report to $outputPath');
    }

    return result.isSuccess ? 0 : 1;
  }
}
