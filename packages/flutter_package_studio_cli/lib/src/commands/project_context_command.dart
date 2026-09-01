import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// project context
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps project context`
///
/// Discovers project structure, resolves package boundaries, filters sensitive files,
/// and previews or outputs assembled codebase intelligence context (Phase 8.2).
class ProjectContextCommand extends FpsCommand {
  @override
  final String name = 'context';

  @override
  final String description =
      'Discover project structure, resolve packages, filter sensitive files, and preview AI context.';

  ProjectContextCommand() {
    argParser.addOption(
      'query',
      abbr: 'q',
      help:
          'Natural language query or problem description (e.g. "Why is package X failing?").',
      defaultsTo: 'General project context discovery',
    );
    argParser.addOption(
      'package',
      abbr: 'p',
      help: 'Explicit package name to target in a monorepo.',
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
      defaultsTo: 'project_context_report.md',
    );
    argParser.addFlag(
      'write',
      abbr: 'w',
      negatable: false,
      help: 'Write the rendered project context report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output assembled project context as structured JSON.',
    );
    argParser.addFlag(
      'inventory-only',
      negatable: false,
      help:
          'Output discovered project package snapshot without assembling full file context.',
    );
  }

  @override
  Future<int> run() async {
    final query =
        argResults?['query'] as String? ?? 'General project context discovery';
    final targetPkg = argResults?['package'] as String?;
    final dirPath = argResults?['dir'] as String? ?? '.';
    final budgetStr = argResults?['budget'] as String? ?? '4000';
    final outputPath =
        argResults?['output'] as String? ?? 'project_context_report.md';
    final writeToDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final inventoryOnly = argResults?['inventory-only'] as bool? ?? false;

    final tokenBudget = int.tryParse(budgetStr) ?? 4000;

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    final engine = ProjectContextEngine(projectRoot: projectDir.path);
    const renderer = ProjectContextRenderer();

    if (inventoryOnly) {
      final snapshot = await engine.discoverProject();
      if (jsonOutput) {
        final rendered = renderer.renderSnapshotJson(snapshot);
        print(rendered);
        if (writeToDisk) {
          final targetFile = File(outputPath);
          targetFile.parent.createSync(recursive: true);
          targetFile.writeAsStringSync(rendered);
          print('Wrote snapshot JSON to $outputPath');
        }
      } else {
        print('Discovered Project Snapshot for "${snapshot.rootPath}":');
        print('Monorepo      : ${snapshot.isMonorepo}');
        print('Package Count : ${snapshot.packages.length}');
        print('Packages      : ${snapshot.packages.keys.join(", ")}');
        print('Total Files   : ${snapshot.projectFiles.length}');
      }
      return 0;
    }

    final assembled = await engine.assembleContext(
      query: query,
      targetPackageId: targetPkg,
      tokenBudget: tokenBudget,
    );

    if (jsonOutput) {
      final rendered = renderer.renderJson(assembled);
      print(rendered);
      if (writeToDisk) {
        final targetFile = File(outputPath);
        targetFile.parent.createSync(recursive: true);
        targetFile.writeAsStringSync(rendered);
        print('Wrote Project Context JSON report to $outputPath');
      }
    } else {
      final rendered = renderer.renderMarkdown(assembled);
      print(rendered);
      if (writeToDisk) {
        final targetFile = File(outputPath);
        targetFile.parent.createSync(recursive: true);
        targetFile.writeAsStringSync(rendered);
        print('Wrote Project Context Markdown report to $outputPath');
      }
    }

    return 0;
  }
}
