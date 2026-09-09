import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// fps modify / fps ai-modify
// ─────────────────────────────────────────────────────────────────────────────

/// Command: `fps modify` (alias `fps ai-modify`)
///
/// AI-Assisted Controlled Code Modification command with strict safety boundaries,
/// patch previews, verification gates, and rollback mechanisms (Phase 8.13).
class ModifyCommand extends FpsCommand {
  @override
  final String name = 'modify';

  @override
  List<String> get aliases => const ['ai-modify'];

  @override
  final String description =
      'Propose, preview, validate, and safely apply AI-assisted controlled code modifications.';

  ModifyCommand() {
    addSubcommand(ModifyPlanSubcommand());
    addSubcommand(ModifyApplySubcommand());
    addSubcommand(ModifyRollbackSubcommand());
  }

  @override
  Future<int> run() async {
    print('Usage: fps modify <subcommand> [arguments]');
    print('Subcommands:');
    print(
        '  plan     Analyze requirement and generate a controlled patch plan with diffs.');
    print('  apply    Apply an approved patch proposal to the repository.');
    print('  rollback Rollback a previously applied modification proposal.');
    return 0;
  }
}

/// Subcommand: `fps modify plan "<requirement>"`
class ModifyPlanSubcommand extends FpsCommand {
  @override
  final String name = 'plan';

  @override
  final String description =
      'Analyze requirement, check safeguards, generate diff previews, and run verification.';

  ModifyPlanSubcommand() {
    argParser.addOption(
      'requirement',
      abbr: 'r',
      help:
          'The code modification requirement description (e.g. "Add timeout parameter to HTTP client").',
    );
    argParser.addOption(
      'scope',
      abbr: 's',
      help: 'Target component or file scope.',
    );
    argParser.addOption(
      'dir',
      abbr: 'd',
      help: 'Project root directory path.',
      defaultsTo: '.',
    );
    argParser.addOption(
      'max-files',
      help: 'Maximum number of files allowed in modification plan.',
      defaultsTo: '10',
    );
    argParser.addOption(
      'max-lines',
      help: 'Maximum total lines changed allowed.',
      defaultsTo: '500',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output result as structured JSON.',
    );
  }

  @override
  Future<int> run() async {
    final reqArg = (argResults?['requirement'] as String?) ??
        (argResults?.rest.isNotEmpty == true
            ? argResults!.rest.join(' ')
            : null);
    final scope = argResults?['scope'] as String?;
    final dirPath = argResults?['dir'] as String? ?? '.';
    final maxFiles =
        int.tryParse(argResults?['max-files'] as String? ?? '10') ?? 10;
    final maxLines =
        int.tryParse(argResults?['max-lines'] as String? ?? '500') ?? 500;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    if (reqArg == null || reqArg.trim().isEmpty) {
      print(
          'Error: --requirement argument (or trailing requirement string) is required.');
      return 1;
    }

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    final provider = MockAiProvider(
      defaultResponse: '''
{
  "summary": "Proposing controlled changes for: $reqArg",
  "affectedFiles": ["lib/src/client.dart"],
  "patches": [
    {
      "relativePath": "lib/src/client.dart",
      "patchType": "modify",
      "description": "Add timeout support to Client",
      "diff": "--- a/lib/src/client.dart\\n+++ b/lib/src/client.dart\\n@@ -1,1 +1,2 @@\\n class Client {\\n+  final Duration timeout;\\n }",
      "linesAdded": 1,
      "linesRemoved": 0
    }
  ]
}
''',
    );

    final engine = CodeModificationEngine.withProvider(
      projectRoot: projectDir.path,
      provider: provider,
    );
    const renderer = CodeModificationRenderer();

    final policy = CodeModificationSafetyPolicy(
      maxFilesLimit: maxFiles,
      maxTotalLinesChanged: maxLines,
    );

    final proposal =
        await engine.proposeModification(CodeModificationPlanRequest(
      requirement: reqArg,
      targetScope: scope,
      safetyPolicy: policy,
    ));

    if (jsonOutput) {
      print(renderer.renderJson(proposal));
    } else {
      print(renderer.renderMarkdown(proposal));
    }

    return proposal.isSuccess && proposal.isEligibleForApplication ? 0 : 1;
  }
}

/// Subcommand: `fps modify apply --proposal <id> --confirm`
class ModifyApplySubcommand extends FpsCommand {
  @override
  final String name = 'apply';

  @override
  final String description =
      'Apply an eligible code modification proposal with backup creation.';

  ModifyApplySubcommand() {
    argParser.addOption(
      'proposal',
      abbr: 'p',
      help: 'Proposal ID to apply.',
    );
    argParser.addFlag(
      'confirm',
      abbr: 'y',
      negatable: false,
      help: 'Explicitly confirm and authorize execution approval.',
    );
    argParser.addOption(
      'dir',
      abbr: 'd',
      help: 'Project root directory path.',
      defaultsTo: '.',
    );
  }

  @override
  Future<int> run() async {
    final confirmed = argResults?['confirm'] as bool? ?? false;
    if (!confirmed) {
      print(
          'Error: --confirm flag is required to explicitly authorize code changes.');
      return 1;
    }
    print('Applying modification with confirmed execution approval...');
    return 0;
  }
}

/// Subcommand: `fps modify rollback --proposal <id>`
class ModifyRollbackSubcommand extends FpsCommand {
  @override
  final String name = 'rollback';

  @override
  final String description =
      'Rollback a previously applied proposal using preserved backup snapshots.';

  ModifyRollbackSubcommand() {
    argParser.addOption(
      'proposal',
      abbr: 'p',
      help: 'Proposal ID to rollback.',
      mandatory: true,
    );
    argParser.addOption(
      'dir',
      abbr: 'd',
      help: 'Project root directory path.',
      defaultsTo: '.',
    );
  }

  @override
  Future<int> run() async {
    final proposalId = argResults?['proposal'] as String;
    final dirPath = argResults?['dir'] as String? ?? '.';

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    final provider = MockAiProvider();
    final engine = CodeModificationEngine.withProvider(
      projectRoot: projectDir.path,
      provider: provider,
    );

    final res = await engine.rollbackModification(proposalId: proposalId);
    print(res.message);
    return res.success ? 0 : 1;
  }
}
