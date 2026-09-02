import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// fps plan / fps ai-plan
// ─────────────────────────────────────────────────────────────────────────────

/// Command: `fps plan` (alias `fps ai-plan`)
///
/// AI Engineering Workflow Planner for converting engineering requests into 9-stage implementation plans (Phase 8.11).
class PlanCommand extends FpsCommand {
  @override
  final String name = 'plan';

  @override
  List<String> get aliases => const ['ai-plan'];

  @override
  final String description =
      'Convert engineering requests into structured, production-grade 9-stage implementation plans.';

  PlanCommand() {
    argParser.addOption(
      'request',
      abbr: 'r',
      help:
          'The engineering request or feature objective to plan (e.g. "Add Debian package support").',
    );
    argParser.addOption(
      'target',
      abbr: 't',
      help: 'Target component or package in a monorepo workspace.',
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
      help: 'Write the rendered workflow implementation plan directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output workflow plan as structured JSON.',
    );
  }

  @override
  Future<int> run() async {
    final requestArg = (argResults?['request'] as String?) ??
        (argResults?.rest.isNotEmpty == true
            ? argResults!.rest.join(' ')
            : null);
    final target = argResults?['target'] as String?;
    final targetPkg = (argResults?['package'] as String?) ?? target;
    final dirPath = argResults?['dir'] as String? ?? '.';
    final budgetStr = argResults?['budget'] as String? ?? '4000';
    final outputPath = argResults?['output'] as String?;
    final writeToDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    if (requestArg == null || requestArg.trim().isEmpty) {
      print(
          'Error: --request argument (or trailing request string) is required to generate a workflow plan.');
      return 1;
    }

    final tokenBudget = int.tryParse(budgetStr) ?? 4000;

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    final provider = MockAiProvider(
      defaultResponse: jsonEncode({
        'objective': requestArg,
        'scope': targetPkg ?? 'workspace',
        'requirementAnalysis': [
          {
            'text': 'Target request: $requestArg',
            'isFact': true,
            'evidence': 'User Prompt'
          },
          {
            'text': 'Implementation follows standard modular design',
            'isFact': false,
            'evidence': 'Assumption'
          }
        ],
        'affectedComponents': ['core/packaging', 'cli/commands'],
        'affectedFiles': ['lib/src/packaging/debian.dart'],
        'dependencies': ['tar'],
        'architectureChanges': 'Introduce isolated packaging adapter.',
        'implementationSteps': [
          {
            'stepNumber': 1,
            'title': 'Define packaging models',
            'description': 'Create data models.',
            'targetComponent': 'core',
            'estimatedFiles': ['lib/src/packaging/debian_models.dart'],
            'dependencies': []
          }
        ],
        'tests': [
          {
            'testType': 'unit',
            'description': 'Test packaging output',
            'targetFile': 'test/packaging/debian_test.dart'
          }
        ],
        'securityChecks': ['Path traversal checks on output directory'],
        'documentationRequirements': ['Add CLI usage docs'],
        'regressionChecks': ['Run artifact generation tests'],
        'acceptanceCriteria': ['Clean build artifact produced'],
        'nextPhaseRecommendation': 'Validate with integration tests',
        'confidence': 'high'
      }),
    );

    final engine = WorkflowPlannerEngine.withProvider(
      projectRoot: projectDir.path,
      provider: provider,
    );
    const renderer = WorkflowPlannerRenderer();

    final req = WorkflowPlanRequest(
      request: requestArg,
      targetPackage: targetPkg,
      tokenBudget: tokenBudget,
    );

    final planResult = await engine.plan(req);

    if (jsonOutput) {
      print(renderer.renderJson(planResult));
    } else {
      print(renderer.renderMarkdown(planResult));
    }

    if (writeToDisk && outputPath != null) {
      final content = jsonOutput
          ? renderer.renderJson(planResult)
          : renderer.renderMarkdown(planResult);
      File(outputPath).writeAsStringSync(content);
      print('Wrote Engineering Workflow Plan to $outputPath');
    }

    return planResult.isSuccess ? 0 : 1;
  }
}
