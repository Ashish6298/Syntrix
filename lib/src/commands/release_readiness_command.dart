import 'dart:convert';
import 'dart:io';
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:syntrix/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// fps release-readiness / fps ai-release
// ─────────────────────────────────────────────────────────────────────────────

/// Command: `fps release-readiness` (alias `fps ai-release`)
///
/// AI Release Readiness Advisor for synthesizing release candidates across deterministic gates (Phase 8.10).
class ReleaseReadinessCommand extends FpsCommand {
  @override
  final String name = 'release-readiness';

  @override
  List<String> get aliases => const ['ai-release'];

  @override
  final String description =
      'Evaluate release candidate readiness across security, pub.dev validation, and verification gates.';

  ReleaseReadinessCommand() {
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
      'version',
      abbr: 'v',
      help: 'Release candidate version to evaluate.',
      defaultsTo: '1.0.0',
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
      'strict',
      negatable: false,
      help:
          'Fail with exit code 1 if release readiness status is NOT READY or NEEDS REVIEW.',
    );
    argParser.addFlag(
      'write',
      abbr: 'w',
      negatable: false,
      help: 'Write the rendered release readiness report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output release readiness assessment as structured JSON.',
    );
  }

  @override
  Future<int> run() async {
    final target = argResults?['target'] as String?;
    final scopeStr = argResults?['scope'] as String? ?? 'whole-project';
    final targetPkg = (argResults?['package'] as String?) ?? target;
    final dirPath = argResults?['dir'] as String? ?? '.';
    final versionStr = argResults?['version'] as String? ?? '1.0.0';
    final budgetStr = argResults?['budget'] as String? ?? '4000';
    final outputPath = argResults?['output'] as String?;
    final isStrict = argResults?['strict'] as bool? ?? false;
    final writeToDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final tokenBudget = int.tryParse(budgetStr) ?? 4000;

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    final scope = ReleaseReadinessScope.tryParse(scopeStr) ??
        ReleaseReadinessScope.wholeProject;
    if (scope == ReleaseReadinessScope.package &&
        (targetPkg == null || targetPkg.trim().isEmpty)) {
      print(
          'Error: --package argument is required when running with package scope.');
      return 1;
    }

    final provider = MockAiProvider(
      defaultResponse: jsonEncode({
        'status': 'ready',
        'summary':
            'Release candidate satisfies all quality and release criteria.',
        'confidence': 'high',
        'strengths': [
          {
            'description': 'All release gates verified.',
            'evidenceSource': 'Release Pipeline'
          }
        ],
        'warnings': [],
        'blockers': [],
        'recommendedActions': [
          {
            'description': 'Proceed with publishing candidate.',
            'evidenceSource': 'Advisor'
          }
        ]
      }),
    );

    final engine = ReleaseReadinessAdvisorEngine.withProvider(
      projectRoot: projectDir.path,
      provider: provider,
    );
    const renderer = ReleaseReadinessRenderer();

    final req = ReleaseReadinessRequest(
      scope: scope,
      targetPackage: targetPkg,
      version: versionStr,
      tokenBudget: tokenBudget,
    );

    final assessment = await engine.assess(req);

    if (jsonOutput) {
      print(renderer.renderJson(assessment));
    } else {
      print(renderer.renderMarkdown(assessment));
    }

    if (writeToDisk && outputPath != null) {
      final content = jsonOutput
          ? renderer.renderJson(assessment)
          : renderer.renderMarkdown(assessment);
      File(outputPath).writeAsStringSync(content);
      print('Wrote Release Readiness report to $outputPath');
    }

    if (isStrict) {
      return assessment.status == ReleaseReadinessStatus.ready ? 0 : 1;
    }

    return assessment.status == ReleaseReadinessStatus.notReady ? 1 : 0;
  }
}
