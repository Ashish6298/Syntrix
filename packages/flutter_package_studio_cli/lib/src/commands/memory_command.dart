import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// fps memory / fps ai-memory
// ─────────────────────────────────────────────────────────────────────────────

/// Command: `fps memory` (alias `fps ai-memory`)
///
/// AI Engineering Session & Knowledge Memory command for querying, recording, and managing
/// project-level engineering decisions, limitations, and architectural memory (Phase 8.12).
class MemoryCommand extends FpsCommand {
  @override
  final String name = 'memory';

  @override
  List<String> get aliases => const ['ai-memory'];

  @override
  final String description =
      'Query, record, and manage persistent project engineering session and knowledge memory.';

  MemoryCommand() {
    addSubcommand(MemoryQuerySubcommand());
    addSubcommand(MemoryRecordSubcommand());
    addSubcommand(MemorySessionsSubcommand());
    addSubcommand(MemoryPurgeSubcommand());
  }

  @override
  Future<int> run() async {
    print('Usage: fps memory <subcommand> [arguments]');
    print('Subcommands:');
    print(
        '  query    Query documented engineering decisions and project memory.');
    print(
        '  record   Record a new engineering decision, limitation, or report.');
    print('  sessions List all engineering memory sessions in the workspace.');
    print('  purge    Purge expired knowledge memory entries.');
    return 0;
  }
}

/// Subcommand: `fps memory query "<question>"`
class MemoryQuerySubcommand extends FpsCommand {
  @override
  final String name = 'query';

  @override
  final String description =
      'Query project engineering memory for architecture decisions, known limitations, and history.';

  MemoryQuerySubcommand() {
    argParser.addOption(
      'query',
      abbr: 'q',
      help:
          'The natural language question (e.g. "Why did we choose this architecture?").',
    );
    argParser.addOption(
      'type',
      abbr: 't',
      help:
          'Filter by knowledge type (decision, limitation, architecture, bug, releaseHistory, testHistory, implementationReport).',
    );
    argParser.addOption(
      'session',
      abbr: 's',
      help: 'Filter by session ID.',
    );
    argParser.addOption(
      'scope',
      help: 'Filter by component scope (e.g. "core", "cli").',
    );
    argParser.addOption(
      'dir',
      abbr: 'd',
      help: 'Project root directory path.',
      defaultsTo: '.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output result as structured JSON.',
    );
    argParser.addFlag(
      'include-expired',
      negatable: false,
      help: 'Include expired memory entries.',
    );
  }

  @override
  Future<int> run() async {
    final queryArg = (argResults?['query'] as String?) ??
        (argResults?.rest.isNotEmpty == true
            ? argResults!.rest.join(' ')
            : null);
    final typeStr = argResults?['type'] as String?;
    final sessionId = argResults?['session'] as String?;
    final scope = argResults?['scope'] as String?;
    final dirPath = argResults?['dir'] as String? ?? '.';
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final includeExpired = argResults?['include-expired'] as bool? ?? false;

    if (queryArg == null || queryArg.trim().isEmpty) {
      print('Error: --query argument (or trailing query string) is required.');
      return 1;
    }

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    final engine = SessionMemoryEngine(projectRoot: projectDir.path);
    const renderer = SessionMemoryRenderer();

    final req = MemoryQueryRequest(
      query: queryArg,
      type: KnowledgeEntryType.tryParse(typeStr),
      sessionId: sessionId,
      scope: scope,
      includeExpired: includeExpired,
    );

    final result = await engine.query(req);

    if (jsonOutput) {
      print(renderer.renderQueryJson(result));
    } else {
      print(renderer.renderQueryMarkdown(result));
    }

    return result.isSuccess ? 0 : 1;
  }
}

/// Subcommand: `fps memory record --title "..." --content "..."`
class MemoryRecordSubcommand extends FpsCommand {
  @override
  final String name = 'record';

  @override
  final String description =
      'Record a new engineering decision, limitation, architecture note, or resolved defect.';

  MemoryRecordSubcommand() {
    argParser.addOption(
      'title',
      abbr: 't',
      help: 'Title of the knowledge record.',
      mandatory: true,
    );
    argParser.addOption(
      'content',
      abbr: 'c',
      help: 'Content / explanation of the decision.',
      mandatory: true,
    );
    argParser.addOption(
      'type',
      abbr: 'k',
      help:
          'Knowledge type (decision, limitation, architecture, bug, releaseHistory, testHistory, implementationReport, repeatedIssue).',
      defaultsTo: 'decision',
    );
    argParser.addOption(
      'session',
      abbr: 's',
      help: 'Session identifier.',
      defaultsTo: 'default',
    );
    argParser.addOption(
      'scope',
      help: 'Target component scope.',
      defaultsTo: 'workspace',
    );
    argParser.addMultiOption(
      'tags',
      help: 'Comma-separated tags for indexing.',
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
    final title = argResults?['title'] as String;
    final content = argResults?['content'] as String;
    final typeStr = argResults?['type'] as String? ?? 'decision';
    final sessionId = argResults?['session'] as String? ?? 'default';
    final scope = argResults?['scope'] as String? ?? 'workspace';
    final tags = (argResults?['tags'] as List<String>?) ?? const [];
    final dirPath = argResults?['dir'] as String? ?? '.';

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    final entryType =
        KnowledgeEntryType.tryParse(typeStr) ?? KnowledgeEntryType.decision;
    final engine = SessionMemoryEngine(projectRoot: projectDir.path);

    final outcome = await engine.recordKnowledge(
      sessionId: sessionId,
      type: entryType,
      title: title,
      content: content,
      scope: scope,
      tags: tags,
    );

    print(
        'Recorded ${entryType.label} "${outcome.entry.title}" (ID: ${outcome.entry.id}) in session "$sessionId".');
    if (outcome.conflicts.isNotEmpty) {
      print(
          '⚠️ Detected ${outcome.conflicts.length} architectural conflict(s):');
      for (final c in outcome.conflicts) {
        print('  - [${c.severity.toUpperCase()}] ${c.reason}');
      }
    }

    return 0;
  }
}

/// Subcommand: `fps memory sessions`
class MemorySessionsSubcommand extends FpsCommand {
  @override
  final String name = 'sessions';

  @override
  final String description =
      'List all recorded engineering memory sessions and summaries.';

  MemorySessionsSubcommand() {
    argParser.addOption(
      'dir',
      abbr: 'd',
      help: 'Project root directory path.',
      defaultsTo: '.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output sessions as structured JSON.',
    );
  }

  @override
  Future<int> run() async {
    final dirPath = argResults?['dir'] as String? ?? '.';
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    final engine = SessionMemoryEngine(projectRoot: projectDir.path);
    const renderer = SessionMemoryRenderer();
    final sessions = await engine.loadAllSessions();

    if (jsonOutput) {
      print(renderer.renderSessionsJson(sessions));
    } else {
      if (sessions.isEmpty) {
        print('No engineering memory sessions found in workspace.');
      } else {
        print(
            '=== Project Engineering Memory Sessions (${sessions.length}) ===');
        for (final s in sessions) {
          print(
              '- [${s.sessionId}] ${s.summary} (${s.entries.length} entries, updated: ${s.lastAccessedAt.toIso8601String().split("T").first})');
        }
      }
    }

    return 0;
  }
}

/// Subcommand: `fps memory purge`
class MemoryPurgeSubcommand extends FpsCommand {
  @override
  final String name = 'purge';

  @override
  final String description =
      'Purge expired knowledge entries across all sessions.';

  MemoryPurgeSubcommand() {
    argParser.addOption(
      'dir',
      abbr: 'd',
      help: 'Project root directory path.',
      defaultsTo: '.',
    );
  }

  @override
  Future<int> run() async {
    final dirPath = argResults?['dir'] as String? ?? '.';

    final projectDir = Directory(dirPath);
    if (!projectDir.existsSync()) {
      print('Error: Target directory "$dirPath" does not exist.');
      return 1;
    }

    final engine = SessionMemoryEngine(projectRoot: projectDir.path);
    final count = await engine.purgeExpired();
    print('Successfully purged $count expired knowledge entries.');
    return 0;
  }
}
