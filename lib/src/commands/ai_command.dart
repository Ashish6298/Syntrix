import 'dart:io';
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:syntrix/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// fps ai / fps ai-assistant
// ─────────────────────────────────────────────────────────────────────────────

/// Command: `fps ai` (alias `fps ai-assistant`)
///
/// Unified AI Engineering Command Center orchestrator combining all 13 AI capabilities
/// (analyze, review, debug, test, document, security, architecture, dependencies, release, plan, explain, memory, modify)
/// into a single intelligent entry point (Phase 8.14).
class AiCommand extends FpsCommand {
  @override
  final String name = 'ai';

  @override
  List<String> get aliases => const ['ai-assistant'];

  @override
  final String description =
      'Unified AI Engineering Command Center for analyzing, reviewing, debugging, testing, planning, and maintaining packages.';

  AiCommand() {
    addSubcommand(AiSubcommand(CommandCenterCapability.analyze));
    addSubcommand(AiSubcommand(CommandCenterCapability.review));
    addSubcommand(AiSubcommand(CommandCenterCapability.debug));
    addSubcommand(AiSubcommand(CommandCenterCapability.test));
    addSubcommand(AiSubcommand(CommandCenterCapability.document));
    addSubcommand(AiSubcommand(CommandCenterCapability.security));
    addSubcommand(AiSubcommand(CommandCenterCapability.architecture));
    addSubcommand(AiSubcommand(CommandCenterCapability.dependencies));
    addSubcommand(AiSubcommand(CommandCenterCapability.release));
    addSubcommand(AiSubcommand(CommandCenterCapability.plan));
    addSubcommand(AiSubcommand(CommandCenterCapability.explain));
    addSubcommand(AiSubcommand(CommandCenterCapability.memory));
    addSubcommand(AiSubcommand(CommandCenterCapability.modify));
  }
}

/// Generic sub-router for individual `fps ai <capability>` invocations.
class AiSubcommand extends FpsCommand {
  final CommandCenterCapability capability;

  AiSubcommand(this.capability) {
    argParser.addOption(
      'prompt',
      abbr: 'p',
      help: 'Prompt instruction or query.',
    );
    argParser.addOption(
      'target',
      abbr: 't',
      help: 'Target package, template ID, or file path.',
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
      help: 'Token budget limit.',
      defaultsTo: '4000',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output file path when writing report to disk.',
    );
    argParser.addFlag(
      'write',
      abbr: 'w',
      negatable: false,
      help: 'Write the rendered report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output result as structured JSON.',
    );
  }

  @override
  String get name => capability.name;

  @override
  String get description => 'Execute AI ${capability.label}';

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    final promptArg = (argResults?['prompt'] as String?) ??
        (rest.isNotEmpty ? rest.join(' ') : '');
    final targetArg = (argResults?['target'] as String?) ??
        (rest.isNotEmpty ? rest.first : null);
    final dirPath = argResults?['dir'] as String? ?? '.';
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

    final provider = MockAiProvider(
      defaultResponse:
          '{"summary": "Command Center executed ${capability.name} successfully."}',
    );

    final engine = CommandCenterEngine(
      projectRoot: projectDir.path,
      provider: provider,
    );
    const renderer = CommandCenterRenderer();

    final req = CommandCenterRequest(
      capability: capability,
      target: targetArg,
      prompt:
          promptArg.isNotEmpty ? promptArg : (targetArg ?? capability.label),
      tokenBudget: tokenBudget,
    );

    final response = await engine.execute(req);

    if (jsonOutput) {
      final jsonStr = renderer.renderJson(response);
      print(jsonStr);
      if (writeToDisk && outputPath != null) {
        File(outputPath).writeAsStringSync(jsonStr);
        print('Wrote JSON output to $outputPath');
      }
    } else {
      final mdStr = renderer.renderMarkdown(response);
      print(mdStr);
      if (writeToDisk && outputPath != null) {
        File(outputPath).writeAsStringSync(mdStr);
        print('Wrote Markdown report to $outputPath');
      }
    }

    return response.isSuccess ? 0 : 1;
  }
}
