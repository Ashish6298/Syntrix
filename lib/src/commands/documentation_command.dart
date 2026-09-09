import 'dart:convert';
import 'dart:io';
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:syntrix/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// fps doc / fps documentation
// ─────────────────────────────────────────────────────────────────────────────

/// Command: `fps doc` (alias `fps documentation`)
///
/// AI Documentation Assistant for generating grounded docs and verifying documentation consistency (Phase 8.7).
class DocumentationCommand extends FpsCommand {
  @override
  final String name = 'doc';

  @override
  List<String> get aliases => const ['documentation'];

  @override
  final String description =
      'Generate grounded documentation or verify documentation consistency against codebase implementation.';

  DocumentationCommand() {
    argParser.addOption(
      'target',
      abbr: 't',
      help:
          'Target identifier to document (package, class, command name, or "all").',
    );
    argParser.addOption(
      'type',
      abbr: 'y',
      help:
          'Documentation type: api-doc, readme, cli-doc, architecture, example, troubleshooting, release, migration, guide.',
      defaultsTo: 'readme',
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
      'instruction',
      abbr: 'i',
      help: 'Custom user instruction or focus area.',
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
      'check-consistency',
      abbr: 'c',
      negatable: false,
      help: 'Run documentation consistency audit instead of generation.',
    );
    argParser.addFlag(
      'write',
      abbr: 'w',
      negatable: false,
      help: 'Write the generated documentation or report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output documentation or consistency results as structured JSON.',
    );
  }

  @override
  Future<int> run() async {
    final target = argResults?['target'] as String?;
    final typeStr = argResults?['type'] as String? ?? 'readme';
    final targetPkg = argResults?['package'] as String?;
    final dirPath = argResults?['dir'] as String? ?? '.';
    final instruction = argResults?['instruction'] as String?;
    final budgetStr = argResults?['budget'] as String? ?? '4000';
    final outputPath = argResults?['output'] as String?;
    final checkConsistency = argResults?['check-consistency'] as bool? ?? false;
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
        'summary': 'Documentation operation completed successfully.',
        'markdownContent':
            '# Documentation\n\nGrounded in codebase implementation.',
        'findings': [],
        'sourceEvidenceManifest': [],
      }),
    );
    final engine = DocumentationAssistantEngine.withProvider(
      projectRoot: projectDir.path,
      provider: provider,
    );

    const renderer = DocumentationAssistantRenderer();

    // ─────────────────────────────────────────────────────────────────────────
    // Branch A: Consistency Check
    // ─────────────────────────────────────────────────────────────────────────
    if (checkConsistency) {
      final checkReq = DocumentationConsistencyRequest(
        targetPackage: targetPkg,
        tokenBudget: tokenBudget,
      );

      final result = await engine.checkConsistency(checkReq);

      if (jsonOutput) {
        print(renderer.renderConsistencyJson(result));
      } else {
        print(renderer.renderConsistencyMarkdown(result));
      }

      if (writeToDisk && outputPath != null) {
        final content = jsonOutput
            ? renderer.renderConsistencyJson(result)
            : renderer.renderConsistencyMarkdown(result);
        File(outputPath).writeAsStringSync(content);
        print('Wrote Documentation Consistency report to $outputPath');
      }

      return result.isSuccess ? 0 : 1;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Branch B: Documentation Generation
    // ─────────────────────────────────────────────────────────────────────────
    if (target == null || target.trim().isEmpty) {
      print(
          'Error: Missing required argument: --target (-t). Specify what to document or use --check-consistency.');
      return 1;
    }

    final docType =
        DocumentationType.tryParse(typeStr) ?? DocumentationType.readmeSection;

    final genReq = DocumentationGenerationRequest(
      target: target,
      docType: docType,
      targetPackage: targetPkg,
      instruction: instruction,
      tokenBudget: tokenBudget,
    );

    final genResult = await engine.generateDocumentation(genReq);

    if (jsonOutput) {
      print(renderer.renderGenerationJson(genResult));
    } else {
      print(genResult.markdownContent);
    }

    if (writeToDisk && outputPath != null) {
      final content = jsonOutput
          ? renderer.renderGenerationJson(genResult)
          : genResult.markdownContent;
      File(outputPath).writeAsStringSync(content);
      print('Wrote Generated Documentation to $outputPath');
    }

    return genResult.isSuccess ? 0 : 1;
  }
}
