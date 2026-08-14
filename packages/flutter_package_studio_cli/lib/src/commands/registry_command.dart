import 'dart:convert';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// registry list
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps registry list`
///
/// Lists all configured remote registries with their current status.
class RegistryListCommand extends FpsCommand {
  @override
  final String name = 'list';

  @override
  final String description = 'List all configured remote template registries.';

  RegistryListCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output results as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final manager = _sharedManager();
    final registries = manager.listAll();

    if (registries.isEmpty) {
      if (jsonOutput) {
        print(jsonEncode({'registries': []}));
      } else {
        print('No remote registries configured. '
            'Use "fps registry add <url>" to add one.');
      }
      return 0;
    }

    final statuses = manager.status();

    if (jsonOutput) {
      final items = statuses
          .map((s) => {
                'id': s.registryId,
                'displayName': s.displayName,
                'health': s.health.name,
                'templateCount': s.templateCount,
                'servingFromCache': s.servingFromCache,
                'message': s.message,
              })
          .toList();
      print(jsonEncode({'registries': items}));
    } else {
      print('Remote Registries:');
      print('');
      for (final s in statuses) {
        final healthStr = _healthIcon(s.health);
        final countStr = s.templateCount != null
            ? '${s.templateCount} templates'
            : 'not refreshed';
        print('  $healthStr  ${s.displayName} (${s.registryId})');
        print('     Status : ${s.health.name}');
        print('     Count  : $countStr');
        if (s.message != null) print('     Note   : ${s.message}');
        print('');
      }
    }
    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// registry add
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps registry add <url>`
///
/// Adds a remote registry by URL.
class RegistryAddCommand extends FpsCommand {
  @override
  final String name = 'add';

  @override
  final String description = 'Add a remote template registry.';

  RegistryAddCommand() {
    argParser.addOption(
      'id',
      abbr: 'i',
      help: 'Registry identifier (must match [a-z][a-z0-9_-]{0,63}). '
          'Derived from URL host if omitted.',
    );
    argParser.addFlag(
      'disable',
      negatable: false,
      help: 'Add in disabled state (do not fetch on startup).',
    );
    argParser.addFlag(
      'dry-run',
      abbr: 'n',
      negatable: false,
      help: 'Show what would be done without making changes.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output result as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      printUsage();
      return 64; // EX_USAGE
    }
    final url = rest.first;
    final idArg = argResults?['id'] as String?;
    final disabled = argResults?['disable'] as bool? ?? false;
    final dryRun = argResults?['dry-run'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    // Derive id from URL host if not provided
    final id = idArg ?? _idFromUrl(url);
    if (id == null) {
      _printError(jsonOutput,
          'Cannot derive registry ID from URL "$url". Use --id to specify one.');
      return 1;
    }

    RemoteRegistryOptions opts;
    try {
      opts = RemoteRegistryOptions(
        id: id,
        baseUrl: url,
        enabled: !disabled,
      );
    } on RegistryConfigurationException catch (e) {
      _printError(jsonOutput, e.message);
      return 1;
    }

    final manager = _sharedManager();
    try {
      final plan = manager.add(opts, dryRun: dryRun);
      if (jsonOutput) {
        print(jsonEncode({
          'plan': plan.description,
          'dryRun': dryRun,
          'success': true,
        }));
      } else {
        print(plan.toString());
        if (!dryRun) {
          print('Registry "${opts.id}" added successfully.');
          print('Run "fps registry refresh ${opts.id}" to fetch its catalog.');
        }
      }
    } on RegistryConfigurationException catch (e) {
      _printError(jsonOutput, e.message);
      return 1;
    }
    return 0;
  }

  String? _idFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host =
          uri.host.replaceAll('.', '_').replaceAll('-', '_').toLowerCase();
      if (host.isEmpty) return null;
      // Must start with letter
      if (!RegExp(r'^[a-z]').hasMatch(host)) return 'reg_$host';
      return host.length > 63 ? host.substring(0, 63) : host;
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// registry remove
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps registry remove <id>`
class RegistryRemoveCommand extends FpsCommand {
  @override
  final String name = 'remove';

  @override
  final String description = 'Remove a configured remote registry.';

  RegistryRemoveCommand() {
    argParser.addFlag(
      'dry-run',
      abbr: 'n',
      negatable: false,
      help: 'Show what would be done without making changes.',
    );
    argParser.addFlag('json', negatable: false, help: 'Output as JSON.');
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      printUsage();
      return 64;
    }
    final id = rest.first;
    final dryRun = argResults?['dry-run'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final manager = _sharedManager();
    try {
      final plan = manager.remove(id, dryRun: dryRun);
      if (jsonOutput) {
        print(jsonEncode(
            {'plan': plan.description, 'dryRun': dryRun, 'success': true}));
      } else {
        print(plan.toString());
      }
    } on RegistryConfigurationException catch (e) {
      _printError(jsonOutput, e.message);
      return 1;
    }
    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// registry enable / disable
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps registry enable <id>`
class RegistryEnableCommand extends FpsCommand {
  @override
  final String name = 'enable';

  @override
  final String description = 'Enable a configured remote registry.';

  RegistryEnableCommand() {
    argParser.addFlag('dry-run', abbr: 'n', negatable: false);
    argParser.addFlag('json', negatable: false);
  }

  @override
  Future<int> run() async => _toggle(true);

  Future<int> _toggle(bool enable) async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      printUsage();
      return 64;
    }
    final id = rest.first;
    final dryRun = argResults?['dry-run'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final manager = _sharedManager();
    try {
      final plan = enable
          ? manager.enable(id, dryRun: dryRun)
          : manager.disable(id, dryRun: dryRun);
      if (jsonOutput) {
        print(jsonEncode(
            {'plan': plan.description, 'dryRun': dryRun, 'success': true}));
      } else {
        print(plan.toString());
      }
    } on RegistryConfigurationException catch (e) {
      _printError(jsonOutput, e.message);
      return 1;
    }
    return 0;
  }
}

/// Subcommand: `fps registry disable <id>`
class RegistryDisableCommand extends FpsCommand {
  @override
  final String name = 'disable';

  @override
  final String description = 'Disable a configured remote registry.';

  RegistryDisableCommand() {
    argParser.addFlag('dry-run', abbr: 'n', negatable: false);
    argParser.addFlag('json', negatable: false);
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      printUsage();
      return 64;
    }
    final id = rest.first;
    final dryRun = argResults?['dry-run'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final manager = _sharedManager();
    try {
      final plan = manager.disable(id, dryRun: dryRun);
      if (jsonOutput) {
        print(jsonEncode(
            {'plan': plan.description, 'dryRun': dryRun, 'success': true}));
      } else {
        print(plan.toString());
      }
    } on RegistryConfigurationException catch (e) {
      _printError(jsonOutput, e.message);
      return 1;
    }
    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// registry refresh
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps registry refresh [id]`
///
/// Refreshes cached metadata for all registries (or a specific one).
class RegistryRefreshCommand extends FpsCommand {
  @override
  final String name = 'refresh';

  @override
  final String description = 'Refresh cached metadata from remote registries.';

  RegistryRefreshCommand() {
    argParser.addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Force refresh even if cache is fresh.',
    );
    argParser.addFlag('json', negatable: false, help: 'Output as JSON.');
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    final specificId = rest.isNotEmpty ? rest.first : null;
    final force = argResults?['force'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final manager = _sharedManager();
    final results = await manager.refresh(registryId: specificId, force: force);

    if (results.isEmpty) {
      if (jsonOutput) {
        print(jsonEncode({'results': []}));
      } else {
        print('No registries to refresh.');
      }
      return 0;
    }

    if (jsonOutput) {
      final items = results
          .map((r) => {
                'registry': r.registryId,
                'succeeded': r.succeeded,
                'accepted': r.recordsAccepted,
                'rejected': r.recordsRejected,
                'error': r.errorMessage,
              })
          .toList();
      print(jsonEncode({'results': items}));
    } else {
      for (final r in results) {
        if (r.succeeded) {
          print('✓ ${r.registryId}: ${r.recordsAccepted} templates accepted, '
              '${r.recordsRejected} rejected.');
        } else {
          print('✗ ${r.registryId}: failed — ${r.errorMessage}');
        }
      }
    }

    final allOk = results.every((r) => r.succeeded);
    return allOk ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// registry status
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps registry status [id]`
///
/// Reports the health and cache state of registries.
class RegistryStatusCommand extends FpsCommand {
  @override
  final String name = 'status';

  @override
  final String description = 'Show health status of configured registries.';

  RegistryStatusCommand() {
    argParser.addFlag('json', negatable: false, help: 'Output as JSON.');
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    final specificId = rest.isNotEmpty ? rest.first : null;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final manager = _sharedManager();
    final statuses = manager.status(registryId: specificId);

    if (statuses.isEmpty) {
      if (jsonOutput) {
        print(jsonEncode({'statuses': []}));
      } else {
        print('No registries configured.');
      }
      return 0;
    }

    if (jsonOutput) {
      final items = statuses
          .map((s) => {
                'id': s.registryId,
                'displayName': s.displayName,
                'health': s.health.name,
                'templateCount': s.templateCount,
                'lastFetchedAt': s.lastFetchedAt?.toIso8601String(),
                'servingFromCache': s.servingFromCache,
                'message': s.message,
              })
          .toList();
      print(jsonEncode({'statuses': items}));
    } else {
      for (final s in statuses) {
        print('${_healthIcon(s.health)} ${s.displayName} (${s.registryId}): '
            '${s.health.name.toUpperCase()}');
        if (s.templateCount != null) {
          print('   Templates : ${s.templateCount}');
        }
        if (s.lastFetchedAt != null) {
          print('   Last fetch: ${s.lastFetchedAt!.toIso8601String()}');
        }
        if (s.servingFromCache) {
          print('   [Serving stale cached data]');
        }
        if (s.message != null) {
          print('   Note      : ${s.message}');
        }
        print('');
      }
    }
    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// registry (parent)
// ─────────────────────────────────────────────────────────────────────────────

/// Command: `fps registry`
///
/// Parent command for remote registry management subcommands:
/// `list`, `add`, `remove`, `enable`, `disable`, `refresh`, `status`.
class RegistryCommand extends FpsCommand {
  @override
  final String name = 'registry';

  @override
  final String description =
      'Manage remote template registries for the FPS Template Marketplace.';

  RegistryCommand() {
    addSubcommand(RegistryListCommand());
    addSubcommand(RegistryAddCommand());
    addSubcommand(RegistryRemoveCommand());
    addSubcommand(RegistryEnableCommand());
    addSubcommand(RegistryDisableCommand());
    addSubcommand(RegistryRefreshCommand());
    addSubcommand(RegistryStatusCommand());
  }

  @override
  Future<int> run() async {
    printUsage();
    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Builds a fresh [RegistryManager] with a no-op transport.
///
/// In a real deployment, inject a production HTTP transport via DI.
RegistryManager _sharedManager() {
  // Default: no-op transport (no network calls without explicit configuration)
  final transport = MockRegistryTransport(const {});
  return RegistryManager.withClient(
    client: RemoteRegistryClient(transport: transport),
  );
}

String _healthIcon(RegistryHealthState health) {
  return switch (health) {
    RegistryHealthState.online => '✓',
    RegistryHealthState.stale => '~',
    RegistryHealthState.offline => '✗',
    RegistryHealthState.disabled => '○',
    RegistryHealthState.invalid => '!',
    RegistryHealthState.unknown => '?',
  };
}

void _printError(bool jsonOutput, String message) {
  if (jsonOutput) {
    print(jsonEncode({'error': message, 'success': false}));
  } else {
    print('Error: $message');
  }
}
