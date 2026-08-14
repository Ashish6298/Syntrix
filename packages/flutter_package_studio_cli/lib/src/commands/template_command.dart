import 'dart:convert';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

// ─────────────────────────────────────────────────────────────────────────────
// template list
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template list`
///
/// Lists all available templates discovered by [TemplateDiscoveryService].
class TemplateListCommand extends FpsCommand {
  @override
  final String name = 'list';

  @override
  final String description =
      'List all available templates in the discovery catalog.';

  TemplateListCommand() {
    argParser.addOption(
      'project-type',
      abbr: 't',
      help: 'Filter by project type (flutter_package, dart_package, plugin).',
    );
    argParser.addOption(
      'category',
      abbr: 'c',
      help: 'Filter by category (builtin, community, local).',
    );
    argParser.addOption(
      'sort',
      abbr: 's',
      help: 'Sort order: name, version, downloads, rating, recent.',
      defaultsTo: 'name',
    );
    argParser.addOption(
      'limit',
      abbr: 'l',
      help: 'Maximum number of results to display.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output results as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final projectType = argResults?['project-type'] as String?;
    final category = argResults?['category'] as String?;
    final sortStr = argResults?['sort'] as String? ?? 'name';
    final limitStr = argResults?['limit'] as String?;
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final limit = limitStr != null ? int.tryParse(limitStr) : null;

    final service = _buildDiscoveryService();
    final sortOrder = _parseSortOrder(sortStr);

    final q = TemplateCatalogQuery(
      projectType: projectType,
      category: category,
      sortOrder: sortOrder,
      limit: limit,
    );

    final entries = service.query(q);

    if (entries.isEmpty) {
      logger.info('No templates found matching the specified criteria.');
      return 0;
    }

    if (jsonOutput) {
      _printJson(entries);
    } else {
      _printTable(entries);
    }

    return 0;
  }

  void _printTable(List<TemplateCatalogEntry> entries) {
    print(
        '\n  ╔══════════════════════════════════════════════════════════════╗');
    print('  ║       FLUTTER PACKAGE STUDIO — TEMPLATE CATALOG             ║');
    print(
        '  ╚══════════════════════════════════════════════════════════════╝\n');
    print(
        '  ${'ID'.padRight(25)} ${'VERSION'.padRight(8)} ${'TYPE'.padRight(18)} CATEGORY');
    print('  ${'─' * 25} ${'─' * 8} ${'─' * 18} ${'─' * 10}');

    for (final e in entries) {
      final cat = e.category.name;
      final type = e.projectType.padRight(18);
      final ver = e.version.padRight(8);
      final id = e.id.padRight(25);
      print('  $id $ver $type $cat');
    }

    print('\n  ${entries.length} template(s) found.\n');
  }

  void _printJson(List<TemplateCatalogEntry> entries) {
    final lines = entries.map((e) {
      return '  {'
          '"id":"${e.id}",'
          '"version":"${e.version}",'
          '"displayName":"${e.displayName}",'
          '"projectType":"${e.projectType}",'
          '"category":"${e.category.name}",'
          '"maturity":"${e.maturity ?? ""}"}';
    }).join(',\n');
    print('[\n$lines\n]');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template search
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template search <query>`
///
/// Searches the template catalog by free-text query.
class TemplateSearchCommand extends FpsCommand {
  @override
  final String name = 'search';

  @override
  final String description =
      'Search the template catalog by name, description, or tags.';

  TemplateSearchCommand() {
    argParser.addOption(
      'project-type',
      abbr: 't',
      help: 'Narrow search to a specific project type.',
    );
    argParser.addOption(
      'limit',
      abbr: 'l',
      help: 'Maximum number of results.',
      defaultsTo: '10',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output results as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      print('\n  Usage: fps template search <query> [options]\n');
      print('  Example: fps template search "flutter widget"\n');
      return 64; // Usage error
    }

    final query = rest.join(' ');
    final projectType = argResults?['project-type'] as String?;
    final limitStr = argResults?['limit'] as String? ?? '10';
    final limit = int.tryParse(limitStr) ?? 10;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final service = _buildDiscoveryService();

    final q = TemplateCatalogQuery(
      searchText: query,
      projectType: projectType,
      limit: limit,
      sortOrder: TemplateCatalogSortOrder.nameAscending,
    );

    final entries = service.query(q);

    print('\n  Search results for: "$query"\n');

    if (entries.isEmpty) {
      print('  No templates matched your search query.\n');
      return 0;
    }

    if (jsonOutput) {
      _printJson(entries, query);
    } else {
      _printResults(entries, query);
    }

    return 0;
  }

  void _printResults(List<TemplateCatalogEntry> entries, String query) {
    for (final e in entries) {
      print('  ● ${e.displayName} (${e.id}@${e.version})');
      print('    Type: ${e.projectType}  Category: ${e.category.name}'
          '${e.maturity != null ? "  Maturity: ${e.maturity}" : ""}');
      if (e.description.isNotEmpty) {
        final desc = e.description.length > 72
            ? '${e.description.substring(0, 72)}…'
            : e.description;
        print('    $desc');
      }
      if (e.allTags.isNotEmpty) {
        print('    Tags: ${e.allTags.take(5).join(", ")}');
      }
      print('');
    }
    print('  ${entries.length} result(s) found.\n');
  }

  void _printJson(List<TemplateCatalogEntry> entries, String query) {
    final lines = entries.map((e) {
      return '  {"id":"${e.id}","version":"${e.version}",'
          '"displayName":"${e.displayName}","description":"${e.description.replaceAll('"', '\\"')}"}';
    }).join(',\n');
    print('[\n$lines\n]');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template info
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template info <id>`
///
/// Shows detailed information about a specific template.
class TemplateInfoCommand extends FpsCommand {
  @override
  final String name = 'info';

  @override
  final String description =
      'Show detailed information about a specific template.';

  TemplateInfoCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Specific version to inspect. Defaults to highest available.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      print('\n  Usage: fps template info <template-id> [--version <ver>]\n');
      print('  Example: fps template info flutter_package\n');
      return 64;
    }

    final id = rest.first;
    final version = argResults?['version'] as String?;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final service = _buildDiscoveryService();
    final entry = service.get(id, version: version);

    if (entry == null) {
      logger.error(
          'Template "$id"${version != null ? "@$version" : ""} not found in catalog.');
      return 1;
    }

    if (jsonOutput) {
      _printJson(entry);
    } else {
      _printDetail(entry);
    }

    return 0;
  }

  void _printDetail(TemplateCatalogEntry e) {
    final m = e.template.manifest;
    print(
        '\n  ╔══════════════════════════════════════════════════════════════╗');
    print('  ║  TEMPLATE DETAILS                                            ║');
    print(
        '  ╚══════════════════════════════════════════════════════════════╝\n');
    print('  ID:            ${e.id}');
    print('  Version:       ${e.version}');
    print('  Display Name:  ${e.displayName}');
    print('  Category:      ${e.category.name}');
    print('  Maturity:      ${e.maturity ?? "unknown"}');
    print('  Project Type:  ${e.projectType}');
    if (e.publisher != null) {
      print('  Publisher:     ${e.publisher}');
    }
    print('  Description:   ${e.description}');
    print('  Dart SDK:      ${m.minimumDartSdk}');
    if (m.minimumFlutterSdk != null) {
      print('  Flutter SDK:   ${m.minimumFlutterSdk}');
    }
    if (m.supportedPlatforms.isNotEmpty) {
      print('  Platforms:     ${m.supportedPlatforms.join(", ")}');
    }
    if (m.capabilities.isNotEmpty) {
      print('  Capabilities:  ${m.capabilities.join(", ")}');
    }
    if (e.allTags.isNotEmpty) {
      print('  Tags:          ${e.allTags.join(", ")}');
    }
    print('  Files:         ${m.files.length} template file(s)');
    if (m.directories.isNotEmpty) {
      print('  Directories:   ${m.directories.join(", ")}');
    }
    if (m.dependencies.isNotEmpty) {
      print(
          '  Dependencies:  ${m.dependencies.map((d) => d.templateId).join(", ")}');
    }
    print('');
  }

  void _printJson(TemplateCatalogEntry e) {
    final m = e.template.manifest;
    print('{'
        '"id":"${e.id}",'
        '"version":"${e.version}",'
        '"displayName":"${e.displayName}",'
        '"description":"${e.description.replaceAll('"', '\\"')}",'
        '"category":"${e.category.name}",'
        '"maturity":"${e.maturity ?? ""}",'
        '"projectType":"${e.projectType}",'
        '"publisher":"${e.publisher ?? ""}",'
        '"minimumDartSdk":"${m.minimumDartSdk}",'
        '"minimumFlutterSdk":"${m.minimumFlutterSdk ?? ""}",'
        '"supportedPlatforms":${_jsonList(m.supportedPlatforms)},'
        '"capabilities":${_jsonList(m.capabilities)},'
        '"tags":${_jsonList(e.allTags)},'
        '"fileCount":${m.files.length}'
        '}');
  }

  String _jsonList(List<String> items) =>
      '[${items.map((s) => '"$s"').join(",")}]';
}

// ─────────────────────────────────────────────────────────────────────────────
// template check <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template check <template-id>`
///
/// Inspects compatibility of a template against the current SDK environment.
class TemplateCheckCommand extends FpsCommand {
  @override
  final String name = 'check';

  @override
  final String description =
      'Inspect compatibility of a template against the SDK environment.';

  TemplateCheckCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Specific version to check. Defaults to highest version.',
    );
    argParser.addOption(
      'dart-version',
      help: 'Mock Dart SDK version to test against.',
      defaultsTo: '3.5.0',
    );
    argParser.addOption(
      'flutter-version',
      help: 'Mock Flutter SDK version to test against.',
      defaultsTo: '3.22.0',
    );
    argParser.addOption(
      'os',
      help: 'Mock operating system (windows, macos, linux, etc.).',
      defaultsTo: 'linux',
    );
    argParser.addOption(
      'policy',
      abbr: 'p',
      help: 'Compatibility policy: permissive, standard, strict, release.',
      defaultsTo: 'standard',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output results as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      printUsage();
      return 64;
    }
    final templateId = rest.first;
    final version = argResults?['version'] as String?;
    final dartVer = argResults?['dart-version'] as String? ?? '3.5.0';
    final flutterVer = argResults?['flutter-version'] as String?;
    final osName = argResults?['os'] as String? ?? 'linux';
    final policyStr = argResults?['policy'] as String? ?? 'standard';
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final service = _buildDiscoveryService();
    final entry = service.get(templateId, version: version);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final env = MockSdkEnvironment(
      dartVersion: dartVer,
      flutterVersion: flutterVer,
      operatingSystem: osName,
    );
    final policy = CompatibilityPolicyX.fromString(policyStr);
    final evaluator = CompatibilityEvaluator(environment: env, policy: policy);

    final result = evaluator.evaluate(entry.template);

    if (jsonOutput) {
      final items = result.issues
          .map((i) => {
                'severity': i.severity.name,
                'axis': i.axis.name,
                'message': i.message,
                'constraint': i.constraint,
                'actual': i.actual,
              })
          .toList();
      print(jsonEncode({
        'templateId': result.templateId,
        'version': result.templateVersion,
        'isCompatible': result.isCompatible,
        'policy': policy.name,
        'environment': result.environmentSummary,
        'issues': items,
      }));
    } else {
      print(
          'Compatibility Report for ${result.templateId}@${result.templateVersion}');
      print('Policy      : ${policy.name}');
      print('Environment : ${result.environmentSummary}');
      print(
          'Status      : ${result.isCompatible ? "COMPATIBLE ✓" : "INCOMPATIBLE ✗"}');
      print('');
      if (result.issues.isEmpty) {
        print('No compatibility issues found.');
      } else {
        for (final issue in result.issues) {
          final prefix = issue.severity == CompatibilityIssueSeverity.error
              ? '✗ [ERROR]'
              : '! [WARN]';
          print('  $prefix (${issue.axis.name}): ${issue.message}');
        }
      }
    }

    return result.isCompatible ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template compose <base-id> [extension-ids...]
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template compose <base-id> [extension-ids...]`
///
/// Previews and inspects template composition of a base template with extensions.
class TemplateComposeCommand extends FpsCommand {
  @override
  final String name = 'compose';

  @override
  final String description =
      'Preview and inspect template composition of a base template with feature extensions.';

  TemplateComposeCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for base template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'conflict-policy',
      abbr: 'c',
      help: 'File conflict policy: fail, override, skip.',
      defaultsTo: 'fail',
    );
    argParser.addOption(
      'compatibility-policy',
      abbr: 'p',
      help: 'Compatibility policy: permissive, standard, strict, release.',
      defaultsTo: 'standard',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output composition plan as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      printUsage();
      return 64;
    }

    final baseId = rest.first;
    final extensionIds = rest.skip(1).toList();
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final conflictStr = argResults?['conflict-policy'] as String? ?? 'fail';
    final compatStr =
        argResults?['compatibility-policy'] as String? ?? 'standard';
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final conflictPolicy = _parseOverrideStrategy(conflictStr);
    final compatPolicy = CompatibilityPolicyX.fromString(compatStr);

    final discoveryService = _buildDiscoveryService();
    final registry = TemplateRegistry();

    // Register all discovered templates into registry
    for (final entry in discoveryService.listAll()) {
      if (!registry.contains(entry.id)) {
        registry.register(entry.template);
      }
    }

    final request = CompositionRequest(
      baseTemplateId: baseId,
      baseVersionConstraint: versionConstraint,
      extensionIds: extensionIds,
      conflictPolicy: conflictPolicy,
      compatibilityPolicy: compatPolicy,
    );

    final resolver = CompatibilityAwareResolver(
      registry: registry,
      environment: MockSdkEnvironment.standard,
      policy: compatPolicy,
    );

    try {
      final plan = resolver.composePlan(request);

      if (jsonOutput) {
        print(jsonEncode(plan.toJson()));
      } else {
        print('Template Composition Plan for "${plan.baseTemplateId}"');
        print('Conflict Policy : ${plan.conflictPolicy.name}');
        print('Total Files     : ${plan.fileCount}');
        print('Overrides       : ${plan.overrideCount}');
        print('Skipped Files   : ${plan.skipCount}');
        print('');
        print('Layers (${plan.layers.length}):');
        for (final l in plan.layers) {
          print(
              '  [#${l.layerIndex}] ${l.templateId}@${l.version} (${l.layerType.name})');
        }
        print('');
        if (plan.conflicts.isNotEmpty) {
          print('Conflicts (${plan.conflicts.length}):');
          for (final c in plan.conflicts) {
            print(
                '  ! ${c.path}: ${c.incomingSourceId}[L#${c.incomingLayerIndex}] -> ${c.existingSourceId}[L#${c.existingLayerIndex}] (${c.resolutionPolicy.name})');
          }
          print('');
        }
        print('File Provenance Preview:');
        for (final p in plan.provenanceRecords.take(10)) {
          print(
              '  ✓ ${p.path} <- ${p.sourceTemplateId}@${p.sourceVersion} [L#${p.layerIndex}, ${p.action}]');
        }
        if (plan.provenanceRecords.length > 10) {
          print(
              '  ... and ${plan.provenanceRecords.length - 10} more asset(s)');
        }
      }
      return 0;
    } on PackageStudioException catch (e) {
      if (jsonOutput) {
        print(jsonEncode({'error': e.message, 'success': false}));
      } else {
        print('Composition Error: ${e.message}');
      }
      return 1;
    }
  }

  OverrideStrategy _parseOverrideStrategy(String val) {
    switch (val.toLowerCase().trim()) {
      case 'override':
        return OverrideStrategy.override;
      case 'skip':
        return OverrideStrategy.skip;
      case 'fail':
      default:
        return OverrideStrategy.fail;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template (parent)
// ─────────────────────────────────────────────────────────────────────────────

/// Command: `fps template`
///
/// Parent command hosting the template catalog subcommands:
/// `list`, `search`, `info`, `check`, `compose`.
class TemplateCatalogCommand extends FpsCommand {
  @override
  final String name = 'template';

  @override
  final String description =
      'Discover, search, inspect, check, and compose templates in the FPS catalog.';

  TemplateCatalogCommand() {
    addSubcommand(TemplateListCommand());
    addSubcommand(TemplateSearchCommand());
    addSubcommand(TemplateInfoCommand());
    addSubcommand(TemplateCheckCommand());
    addSubcommand(TemplateComposeCommand());
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

TemplateDiscoveryService _buildDiscoveryService() {
  final registry = TemplateRegistry();
  BuiltinTemplates.registerDefaultTemplates(registry);

  return TemplateDiscoveryService(
    providers: [
      BuiltinCatalogProvider(registry: registry),
    ],
  );
}

TemplateCatalogSortOrder _parseSortOrder(String value) {
  switch (value.toLowerCase()) {
    case 'version':
      return TemplateCatalogSortOrder.versionNewest;
    case 'downloads':
      return TemplateCatalogSortOrder.mostDownloaded;
    case 'rating':
      return TemplateCatalogSortOrder.topRated;
    case 'recent':
      return TemplateCatalogSortOrder.recentlyAdded;
    case 'name':
    default:
      return TemplateCatalogSortOrder.nameAscending;
  }
}
