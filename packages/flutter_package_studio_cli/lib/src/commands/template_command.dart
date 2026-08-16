import 'dart:convert';
import 'dart:io';
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
// template customize <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template customize <template-id>`
///
/// Previews and inspects template customization variables, presets, file rules, and path overrides.
class TemplateCustomizeCommand extends FpsCommand {
  @override
  final String name = 'customize';

  @override
  final String description =
      'Preview and inspect template customization parameters, presets, and conditional file rules.';

  TemplateCustomizeCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'preset',
      abbr: 'p',
      help:
          'Customization preset profile (e.g., minimal, standard, production).',
    );
    argParser.addMultiOption(
      'var',
      help:
          'Customization variable in key=value format (e.g., --var enable_auth=true).',
    );
    argParser.addOption(
      'compatibility-policy',
      help: 'Compatibility policy: permissive, standard, strict, release.',
      defaultsTo: 'standard',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output customization plan as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final presetName = argResults?['preset'] as String?;
    final rawVars = argResults?['var'] as List<String>? ?? [];
    final compatStr =
        argResults?['compatibility-policy'] as String? ?? 'standard';
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final userValues = <String, dynamic>{};
    for (final raw in rawVars) {
      final parts = raw.split('=');
      if (parts.length >= 2) {
        final k = parts[0].trim();
        final v = parts.sublist(1).join('=').trim();
        userValues[k] = v;
      }
    }

    final compatPolicy = CompatibilityPolicyX.fromString(compatStr);
    final discoveryService = _buildDiscoveryService();
    final registry = TemplateRegistry();

    for (final entry in discoveryService.listAll()) {
      if (!registry.contains(entry.id)) {
        registry.register(entry.template);
      }
    }

    final orchestrator = CustomizationAwareOrchestrator(
      registry: registry,
      environment: MockSdkEnvironment.standard,
    );

    try {
      final plan = orchestrator.buildCustomizationPlan(
        templateId: templateId,
        versionConstraint: versionConstraint,
        compatibilityPolicy: compatPolicy,
        presetName: presetName,
        userValues: userValues,
      );

      if (jsonOutput) {
        print(jsonEncode(plan.toJson()));
      } else {
        print('Template Customization Plan for "${plan.templateId}"');
        print('Active Preset   : ${plan.activePreset ?? "none"}');
        print('Included Files  : ${plan.fileCount}');
        print('Excluded Files  : ${plan.excludedCount}');
        print('');
        print(
            'Resolved Customization Variables (${plan.context.toMap().length}):');
        plan.context.toMap().forEach((k, v) {
          print('  • $k = $v');
        });
        print('');
        if (plan.excludedFiles.isNotEmpty) {
          print('Excluded Files (${plan.excludedFiles.length}):');
          for (final f in plan.excludedFiles) {
            print('  - $f (condition unmet)');
          }
          print('');
        }
        if (plan.activePathOverrides.isNotEmpty) {
          print('Path Overrides (${plan.activePathOverrides.length}):');
          plan.activePathOverrides.forEach((src, dst) {
            print('  → $src -> $dst');
          });
          print('');
        }
        print('Included Files Preview:');
        for (final f in plan.includedFiles.take(10)) {
          print('  ✓ $f');
        }
        if (plan.includedFiles.length > 10) {
          print('  ... and ${plan.includedFiles.length - 10} more asset(s)');
        }
      }
      return 0;
    } on PackageStudioException catch (e) {
      if (jsonOutput) {
        print(jsonEncode({'error': e.message, 'success': false}));
      } else {
        print('Customization Error: ${e.message}');
      }
      return 1;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template validate <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template validate <template-id>`
///
/// Executes quality assurance checks on a template and produces a quality report.
class TemplateValidateCommand extends FpsCommand {
  @override
  final String name = 'validate';

  @override
  final String description =
      'Execute quality assurance and validation checks on a template.';

  TemplateValidateCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Quality enforcement profile: basic, standard, strict, release.',
      defaultsTo: 'standard',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output quality report as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final profileStr = argResults?['profile'] as String? ?? 'standard';
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final profile = TemplateQualityProfileX.fromString(profileStr);
    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final qualityEngine = TemplateQualityEngine();
    final report =
        qualityEngine.evaluateTemplate(entry.template, profile: profile);

    if (jsonOutput) {
      print(jsonEncode(report.toJson()));
    } else {
      print(
          'Template Quality Assurance Report for "${report.templateId}@${report.version}"');
      print('Profile  : ${report.profile.name}');
      print('Status   : ${report.isPassed ? "PASSED ✓" : "FAILED ✗"}');
      print('Errors   : ${report.errorCount}');
      print('Warnings : ${report.warningCount}');
      print('');

      if (report.findings.isEmpty) {
        print('No quality issues detected.');
      } else {
        for (final f in report.findings) {
          final prefix = f.severity == TemplateQualitySeverity.error
              ? '✗ [ERROR]'
              : (f.severity == TemplateQualitySeverity.warning
                  ? '! [WARN]'
                  : 'i [INFO]');
          print('  $prefix (${f.category.name}): ${f.message}');
        }
      }
    }

    return report.isPassed ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template hooks <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template hooks <template-id>`
///
/// Inspects registered lifecycle hooks and previews execution for a template.
class TemplateHooksCommand extends FpsCommand {
  @override
  final String name = 'hooks';

  @override
  final String description =
      'Inspect registered lifecycle hooks and preview execution for a template.';

  TemplateHooksCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'phase',
      abbr: 'p',
      help:
          'Lifecycle phase filter (preResolution, postResolution, preComposition, postComposition, preCustomization, postCustomization, preGeneration, postGeneration, validation, completion, failure).',
    );
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Preview execution of lifecycle hooks in dry-run mode.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final phaseStr = argResults?['phase'] as String?;
    final isDryRun = argResults?['dry-run'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final registry = TemplateHookRegistry();

    final sampleHook = FunctionalTemplateHook(
      id: '${templateId}_default_validation_hook',
      name: 'Default Validation Hook',
      supportedPhases: [
        TemplateHookPhase.validation,
        TemplateHookPhase.preGeneration
      ],
      provenance: templateId,
      priority: 10,
      handler: (ctx) {
        return TemplateHookResult.success(
          hookId: '${templateId}_default_validation_hook',
          phase: ctx.activePhase,
          duration: const Duration(milliseconds: 2),
          diagnostics: [
            TemplateHookDiagnostic(
              level: TemplateHookDiagnosticLevel.info,
              message: 'Verified manifest integrity for $templateId',
              hookId: '${templateId}_default_validation_hook',
              phase: ctx.activePhase,
            )
          ],
        );
      },
    );
    registry.register(sampleHook);

    TemplateHookPhase? targetPhase;
    if (phaseStr != null) {
      targetPhase = TemplateHookPhase.values.firstWhere(
        (p) =>
            p.name.toLowerCase() == phaseStr.toLowerCase().trim() ||
            p.displayName.toLowerCase() == phaseStr.toLowerCase().trim(),
        orElse: () => TemplateHookPhase.validation,
      );
    }

    if (isDryRun || targetPhase != null) {
      final phaseToRun = targetPhase ?? TemplateHookPhase.validation;
      final engine = TemplateHookEngine(registry: registry);
      final ctx = TemplateHookContext(
        targetDirectory: '/virtual/$templateId',
        activePhase: phaseToRun,
        metadata: {'templateId': templateId, 'version': entry.version},
        dryRun: true,
      );

      final report = await engine.executePhase(phase: phaseToRun, context: ctx);

      if (jsonOutput) {
        print(jsonEncode(report.toJson()));
      } else {
        print(
            'Template Hook Preview Report for "${entry.id}@${entry.version}"');
        print('Phase        : ${phaseToRun.displayName}');
        print('Dry Run      : ${report.isDryRun}');
        print('Status       : ${report.isSuccess ? "SUCCESS ✓" : "FAILED ✗"}');
        print('Executed     : ${report.results.length} hook(s)');
        print('Actions      : ${report.aggregatedActions.length} action(s)');
        print('');
        for (final r in report.results) {
          print(
              '  ● Hook: ${r.hookId} [${r.status.name}] (${r.duration.inMilliseconds}ms)');
          for (final d in r.diagnostics) {
            print('    [${d.level.name.toUpperCase()}] ${d.message}');
          }
        }
      }
      return report.isSuccess ? 0 : 1;
    }

    final hooks = registry.listByProvenance(templateId).isNotEmpty
        ? registry.listByProvenance(templateId)
        : registry.listAll();

    if (jsonOutput) {
      print(jsonEncode({
        'templateId': templateId,
        'version': entry.version,
        'hooks': hooks.map((h) => h.toJson()).toList(),
      }));
    } else {
      print('Registered Lifecycle Hooks for "${entry.id}@${entry.version}"');
      print('Total Hooks  : ${hooks.length}');
      print('');
      for (final reg in hooks) {
        final h = reg.hook;
        final phases = h.supportedPhases.map((p) => p.name).join(', ');
        print('  ● ${h.name} (${h.id})');
        print(
            '    Provenance: ${h.provenance}  Priority: ${h.priority}  Enabled: ${h.enabled}');
        print('    Phases    : $phases');
        print('    Policy    : ${h.failurePolicy.name}');
        if (h.dependencies.isNotEmpty) {
          print('    Depends On: ${h.dependencies.join(", ")}');
        }
        print('');
      }
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template certify <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template certify <template-id>`
///
/// Executes template certification checks and produces a formal certification report.
class TemplateCertifyCommand extends FpsCommand {
  @override
  final String name = 'certify';

  @override
  final String description =
      'Execute template certification checks and produce a formal certification report.';

  TemplateCertifyCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Certification profile: basic, standard, strict, release.',
      defaultsTo: 'standard',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output certification report as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final profileStr = argResults?['profile'] as String? ?? 'standard';
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final profile = TemplateCertificationProfile.fromString(profileStr);
    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final service = TemplateCertificationService();
    final report = service.certifyTemplate(entry.template, profile: profile);

    if (jsonOutput) {
      print(jsonEncode(report.toJson()));
    } else {
      print(
          'Template Certification Report for "${report.templateId}@${report.version}"');
      print('Profile     : ${report.profile.name}');
      print('Tier Level  : ${report.level.name}');
      print('Status      : ${report.status.name.toUpperCase()}');
      print(
          'Eligibility : ${report.isGenerationEligible ? "ELIGIBLE FOR GENERATION ✓" : "INELIGIBLE ✗"}');
      print('Passed      : ${report.passedCheckCount}');
      print('Failed      : ${report.failedCheckCount}');
      print('Errors      : ${report.errorCount}');
      print('Warnings    : ${report.warningCount}');
      print('');

      if (report.findings.isEmpty) {
        print('No certification findings detected.');
      } else {
        for (final f in report.findings) {
          final prefix = f.severity == TemplateCertificationSeverity.error
              ? '✗ [ERROR]'
              : (f.severity == TemplateCertificationSeverity.warning
                  ? '! [WARN]'
                  : 'i [INFO]');
          print('  $prefix (${f.category.name}): ${f.message}');
        }
      }
    }

    return report.isPassed ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template test <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template test <template-id>`
///
/// Runs the automated template testing framework on a template.
class TemplateTestCommand extends FpsCommand {
  @override
  final String name = 'test';

  @override
  final String description =
      'Run automated template testing framework on a template.';

  TemplateTestCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Test enforcement profile: basic, standard, strict, release.',
      defaultsTo: 'standard',
    );
    argParser.addFlag(
      'dry-run',
      negatable: false,
      help: 'Preview test execution in non-mutating dry-run mode.',
      defaultsTo: true,
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output test report as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final profileStr = argResults?['profile'] as String? ?? 'standard';
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final profile = TemplateTestProfile.fromString(profileStr);
    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final service = TemplateTestingService();
    final report = await service.testTemplate(entry.template, profile: profile);

    if (jsonOutput) {
      print(jsonEncode(report.toJson()));
    } else {
      print(
          'Template Testing Report for "${report.templateId}@${report.version}"');
      print('Profile     : ${report.profile.name}');
      print('Status      : ${report.status.name.toUpperCase()}');
      print(
          'Eligibility : ${report.isEligibleForCertification ? "CERTIFICATION ELIGIBLE ✓" : "INELIGIBLE ✗"}');
      print('Passed Tests: ${report.passedCount}');
      print('Failed Tests: ${report.failedCount}');
      print('Skipped     : ${report.skippedCount}');
      print('Errors      : ${report.errorCount}');
      print('Warnings    : ${report.warningCount}');
      print('');

      if (report.findings.isEmpty) {
        print('All template test suites passed cleanly.');
      } else {
        for (final f in report.findings) {
          final prefix = f.severity == TemplateTestSeverity.error
              ? '✗ [ERROR]'
              : (f.severity == TemplateTestSeverity.warning
                  ? '! [WARN]'
                  : 'i [INFO]');
          print('  $prefix (${f.category.name}): ${f.message}');
        }
      }
    }

    return report.isPassed ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template migrate <target>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template migrate <target>`
///
/// Plans or executes a template upgrade & migration for an existing project.
class TemplateMigrateCommand extends FpsCommand {
  @override
  final String name = 'migrate';

  @override
  final String description =
      'Plan or execute a template upgrade and migration for an existing project.';

  TemplateMigrateCommand() {
    argParser.addOption(
      'from',
      help: 'Source template version (detected automatically if omitted).',
    );
    argParser.addOption(
      'to',
      help: 'Target template version.',
      defaultsTo: '1.1.0',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Migration profile: basic, standard, strict, release.',
      defaultsTo: 'standard',
    );
    argParser.addOption(
      'conflict-policy',
      help: 'Conflict policy: fail, preserve, overwrite, skip.',
      defaultsTo: 'preserve',
    );
    argParser.addFlag(
      'dry-run',
      help: 'Preview migration plan without modifying disk.',
      defaultsTo: true,
    );
    argParser.addFlag(
      'execute',
      negatable: false,
      help: 'Execute migration plan against project files.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output migration plan or result as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      printUsage();
      return 64;
    }

    final targetPath = rest.first;
    final fromVersion = argResults?['from'] as String?;
    final toVersion = argResults?['to'] as String? ?? '1.1.0';
    final profileStr = argResults?['profile'] as String? ?? 'standard';
    final conflictStr = argResults?['conflict-policy'] as String? ?? 'preserve';
    final executeMode = argResults?['execute'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final profile = TemplateMigrationProfileX.fromString(profileStr);
    final conflictPolicy = TemplateMigrationConflictPolicy.values.firstWhere(
      (c) => c.name == conflictStr.toLowerCase(),
      orElse: () => TemplateMigrationConflictPolicy.preserve,
    );

    final registry = TemplateMigrationRegistry();
    registry.register(SimpleTemplateMigration(
      id: 'v1_0_0_to_v1_1_0',
      templateId: 'flutter_package',
      sourceVersion: '1.0.0',
      targetVersion: '1.1.0',
      description: 'Standard package upgrade to v1.1.0',
      actions: [
        const TemplateMigrationAction(
          type: TemplateMigrationActionType.updateMetadata,
          path: 'pubspec.yaml',
          reason: 'Upgrade template metadata to v1.1.0',
        ),
      ],
    ));

    final engine = TemplateMigrationEngine(registry: registry);

    try {
      final request = TemplateMigrationRequest(
        projectPath: targetPath,
        sourceTemplateId: 'flutter_package',
        sourceVersion: fromVersion,
        targetTemplateId: 'flutter_package',
        targetVersion: toVersion,
        profile: profile,
        conflictPolicy: conflictPolicy,
      );

      final plan = engine.planMigration(request);

      if (!executeMode) {
        if (jsonOutput) {
          print(jsonEncode(plan.toJson()));
        } else {
          print('Template Migration Preview Plan for "$targetPath"');
          print('Source   : ${plan.sourceTemplateId}@${plan.sourceVersion}');
          print('Target   : ${plan.targetTemplateId}@${plan.targetVersion}');
          print('Profile  : ${plan.profile.name}');
          print('Steps    : ${plan.steps.length}');
          print('Actions  : ${plan.totalActions}');
          print('');

          for (final s in plan.steps) {
            print(
                'Step: ${s.description} (${s.sourceVersion} -> ${s.targetVersion})');
            for (final a in s.actions) {
              print('  • [${a.type.name}] ${a.path} - ${a.reason}');
            }
          }
        }
        return plan.hasErrors ? 1 : 0;
      }

      final result = engine.executeMigration(plan, projectPath: targetPath);
      if (jsonOutput) {
        print(jsonEncode(result.toJson()));
      } else {
        print('Template Migration Result for "$targetPath"');
        print('Status   : ${result.isSuccess ? "SUCCESS ✓" : "FAILED ✗"}');
        print('Actions  : ${result.actionsExecuted}');
      }
      return result.isSuccess ? 0 : 1;
    } catch (e) {
      if (jsonOutput) {
        print(jsonEncode({'error': e.toString(), 'success': false}));
      } else {
        print('Migration Error: $e');
      }
      return 1;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template readme <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template readme <template-id>`
///
/// Previews or writes generated README documentation for a template.
class TemplateReadmeCommand extends FpsCommand {
  @override
  final String name = 'readme';

  @override
  final String description =
      'Preview or generate professional README documentation for a template.';

  TemplateReadmeCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output file path when writing to disk.',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated README directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output README generation result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final outputPath = argResults?['output'] as String?;
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final options = ReadmeGenerationOptions(
      packageName: tmpl.manifest.name,
      description: tmpl.manifest.description.isEmpty
          ? 'Production-ready package generated with Flutter Package Studio.'
          : tmpl.manifest.description,
      version: tmpl.version,
    );

    final generator = ReadmeGenerator();
    final plan = generator.planReadme(options);
    final result = generator.generateReadme(plan);

    if (writeDisk) {
      final targetFile = outputPath ?? 'README.md';
      final file = File(targetFile);
      await file.writeAsString(result.markdown);
      if (!jsonOutput) {
        print('Successfully wrote README to "$targetFile".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print('Generated README.md Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print(result.markdown);
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template api-docs <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template api-docs <template-id>`
///
/// Previews or writes generated API reference documentation for a template.
class TemplateApiDocsCommand extends FpsCommand {
  @override
  final String name = 'api-docs';

  @override
  final String description =
      'Preview or generate professional API reference documentation for a template.';

  TemplateApiDocsCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output file path when writing to disk.',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated API documentation directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output API documentation result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final outputPath = argResults?['output'] as String?;
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final generator = ApiDocGenerator();
    final plan = generator.planFromTemplate(tmpl);
    final result = generator.generateApiDoc(plan);

    if (writeDisk) {
      final targetFile = outputPath ?? 'API.md';
      final file = File(targetFile);
      await file.writeAsString(result.markdown);
      if (!jsonOutput) {
        print('Successfully wrote API documentation to "$targetFile".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print('Generated API Reference Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print(result.markdown);
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template architecture
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template architecture`
///
/// Previews or writes generated system architecture documentation and Mermaid diagrams.
class TemplateArchitectureCommand extends FpsCommand {
  @override
  final String name = 'architecture';

  @override
  final String description =
      'Preview or generate system architecture documentation and Mermaid diagrams.';

  TemplateArchitectureCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output file path when writing to disk.',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated architecture documentation directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output architecture documentation result as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final outputPath = argResults?['output'] as String?;
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final generator = ArchitectureDocGenerator();
    final plan = generator.planArchitectureDoc(const ArchDocOptions());
    final result = generator.generateArchitectureDoc(plan);

    if (writeDisk) {
      final targetFile = outputPath ?? 'ARCHITECTURE.md';
      final file = File(targetFile);
      await file.writeAsString(result.markdown);
      if (!jsonOutput) {
        print(
            'Successfully wrote architecture documentation to "$targetFile".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print('Generated Architecture Documentation Preview:');
      print('══════════════════════════════════════════════════════════════');
      print(result.markdown);
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template mermaid
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template mermaid`
///
/// Previews or writes generated Mermaid diagram `.mmd` string source.
class TemplateMermaidCommand extends FpsCommand {
  @override
  final String name = 'mermaid';

  @override
  final String description =
      'Preview or generate standalone Mermaid diagram (.mmd) string source.';

  TemplateMermaidCommand() {
    argParser.addOption(
      'type',
      abbr: 't',
      help: 'Mermaid diagram type (flowchart, sequence).',
      defaultsTo: 'flowchart',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output file path when writing to disk.',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated Mermaid diagram directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output Mermaid diagram result as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final typeStr = argResults?['type'] as String? ?? 'flowchart';
    final outputPath = argResults?['output'] as String?;
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final type = typeStr.toLowerCase() == 'sequence'
        ? MermaidType.sequenceDiagram
        : MermaidType.flowchartTD;

    final generator = MermaidDiagramGenerator();
    final options = MermaidDiagramOptions(
      title: 'FPS Pipeline Diagram',
      type: type,
      nodes: const [
        MermaidNode(id: 'Discovery', label: 'Template Catalog'),
        MermaidNode(id: 'Resolver', label: 'Template Resolver'),
        MermaidNode(id: 'Generator', label: 'Project Generator'),
      ],
      edges: const [
        MermaidEdge(fromId: 'Discovery', toId: 'Resolver'),
        MermaidEdge(fromId: 'Resolver', toId: 'Generator'),
      ],
    );

    final plan = generator.planDiagram(options);
    final result = generator.generateDiagram(plan);

    if (writeDisk) {
      final targetFile = outputPath ?? 'diagram.mmd';
      final file = File(targetFile);
      await file.writeAsString(result.source);
      if (!jsonOutput) {
        print('Successfully wrote Mermaid diagram to "$targetFile".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print('Generated Mermaid Diagram Preview:');
      print('══════════════════════════════════════════════════════════════');
      print(result.source);
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template examples <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template examples <template-id>`
///
/// Previews or writes generated Dart code examples for a template.
class TemplateExamplesCommand extends FpsCommand {
  @override
  final String name = 'examples';

  @override
  final String description =
      'Preview or generate Dart/Flutter code examples for a template.';

  TemplateExamplesCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'type',
      abbr: 't',
      help: 'Code example type (basic, init, config, full).',
      defaultsTo: 'basic',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output file path when writing to disk.',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated code example directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output code example result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final typeStr = argResults?['type'] as String? ?? 'basic';
    final outputPath = argResults?['output'] as String?;
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    CodeExampleType type;
    switch (typeStr.toLowerCase()) {
      case 'init':
        type = CodeExampleType.initialization;
        break;
      case 'config':
        type = CodeExampleType.configuration;
        break;
      case 'full':
        type = CodeExampleType.fullExample;
        break;
      case 'basic':
      default:
        type = CodeExampleType.basicUsage;
        break;
    }

    final tmpl = entry.template;
    final generator = CodeExampleGenerator();
    final options = CodeExampleOptions(
      packageName: tmpl.manifest.name,
      exampleType: type,
    );

    final plan = generator.planExample(options);
    final result = generator.generateExample(plan);

    if (writeDisk) {
      final targetFile = outputPath ?? 'example/main.dart';
      final file = File(targetFile);
      await file.parent.create(recursive: true);
      await file.writeAsString(result.code);
      if (!jsonOutput) {
        print('Successfully wrote code example to "$targetFile".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print('Generated Code Example Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print(result.code);
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template screenshots <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template screenshots <template-id>`
///
/// Previews or writes generated screenshot gallery documentation for a template.
class TemplateScreenshotsCommand extends FpsCommand {
  @override
  final String name = 'screenshots';

  @override
  final String description =
      'Preview or generate screenshot gallery documentation for a template.';

  TemplateScreenshotsCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'category',
      abbr: 'c',
      help:
          'Filter category (overview, feature, usage, workflow, platform, custom).',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output file path when writing to disk.',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated screenshot gallery directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output screenshot management result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final categoryStr = argResults?['category'] as String?;
    final outputPath = argResults?['output'] as String?;
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    ScreenshotCategory? category;
    if (categoryStr != null) {
      switch (categoryStr.toLowerCase()) {
        case 'feature':
          category = ScreenshotCategory.feature;
          break;
        case 'usage':
          category = ScreenshotCategory.usage;
          break;
        case 'workflow':
          category = ScreenshotCategory.workflow;
          break;
        case 'platform':
          category = ScreenshotCategory.platform;
          break;
        case 'custom':
          category = ScreenshotCategory.custom;
          break;
        case 'overview':
        default:
          category = ScreenshotCategory.overview;
          break;
      }
    }

    final tmpl = entry.template;
    final manager = ScreenshotManager();
    final options = ScreenshotOptions(
      packageName: tmpl.manifest.name,
      filterCategory: category,
    );

    final plan = manager.planScreenshots(options);
    final result = manager.manageScreenshots(plan);

    if (writeDisk) {
      final targetFile = outputPath ?? 'SCREENSHOTS.md';
      final file = File(targetFile);
      await file.writeAsString(result.markdownManifest);
      if (!jsonOutput) {
        print('Successfully wrote screenshot gallery to "$targetFile".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print(
          'Generated Screenshot Gallery Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print(result.markdownManifest);
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template gifs <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template gifs <template-id>`
///
/// Previews or writes generated GIF animation gallery documentation for a template.
class TemplateGifsCommand extends FpsCommand {
  @override
  final String name = 'gifs';

  @override
  final String description =
      'Preview or generate GIF animation gallery documentation for a template.';

  TemplateGifsCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'category',
      abbr: 'c',
      help: 'Filter category (demo, feature, workflow, onboarding, custom).',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output file path when writing to disk.',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated GIF gallery directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output GIF pipeline result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final categoryStr = argResults?['category'] as String?;
    final outputPath = argResults?['output'] as String?;
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    GifCategory? category;
    if (categoryStr != null) {
      switch (categoryStr.toLowerCase()) {
        case 'feature':
          category = GifCategory.feature;
          break;
        case 'workflow':
          category = GifCategory.workflow;
          break;
        case 'onboarding':
          category = GifCategory.onboarding;
          break;
        case 'custom':
          category = GifCategory.custom;
          break;
        case 'demo':
        default:
          category = GifCategory.demo;
          break;
      }
    }

    final tmpl = entry.template;
    final manager = GifManager();
    final options = GifOptions(
      packageName: tmpl.manifest.name,
      filterCategory: category,
    );

    final plan = manager.planGifs(options);
    final result = manager.manageGifs(plan);

    if (writeDisk) {
      final targetFile = outputPath ?? 'DEMOS.md';
      final file = File(targetFile);
      await file.writeAsString(result.markdownManifest);
      if (!jsonOutput) {
        print('Successfully wrote GIF gallery to "$targetFile".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print('Generated GIF Gallery Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print(result.markdownManifest);
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template website <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template website <template-id>`
///
/// Previews or writes generated static documentation website for a template.
class TemplateWebsiteCommand extends FpsCommand {
  @override
  final String name = 'website';

  @override
  final String description =
      'Preview or generate a complete static documentation website for a template.';

  TemplateWebsiteCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing site to disk.',
      defaultsTo: 'doc/site',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated static website files directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output static website result map as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final outputDir = argResults?['output'] as String? ?? 'doc/site';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final generator = StaticWebsiteGenerator();
    final options = WebsiteOptions(packageName: tmpl.manifest.name);

    final plan = generator.planWebsite(options);
    final result = generator.generateWebsite(plan);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);

      for (final entry in result.files.entries) {
        final file = File('${baseDir.path}/${entry.key}');
        await file.parent.create(recursive: true);
        await file.writeAsString(entry.value);
      }

      if (!jsonOutput) {
        print(
            'Successfully wrote static website (${result.files.length} files) to "$outputDir".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print(
          'Generated Static Website Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Total Pages : ${plan.pages.length}');
      print('Routes      : ${plan.pages.map((p) => p.route).join(', ')}');
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template test-project <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template test-project <template-id>`
///
/// Previews or writes generated isolated test project files for a template.
class TemplateTestProjectCommand extends FpsCommand {
  @override
  final String name = 'test-project';

  @override
  final String description =
      'Preview or generate an isolated test project structure for a template.';

  TemplateTestProjectCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing project to disk.',
      defaultsTo: 'test_project',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated test project files directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output test project result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final outputDir = argResults?['output'] as String? ?? 'test_project';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final generator = TestProjectGenerator();
    final options = TestProjectOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      targetDir: outputDir,
    );

    final plan = generator.planTestProject(options);
    final result = generator.generateTestProject(plan, options);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);

      for (final entry in result.files.entries) {
        final file = File('${baseDir.path}/${entry.key}');
        await file.parent.create(recursive: true);
        await file.writeAsString(entry.value);
      }

      if (!jsonOutput) {
        print(
            'Successfully wrote test project (${result.files.length} files) to "$outputDir".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print('Generated Test Project Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Target Directory : ${plan.targetDir}');
      print('Total Files      : ${plan.relativeFilePaths.length}');
      print('File Paths       : ${plan.relativeFilePaths.join(', ')}');
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template unit-tests <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template unit-tests <template-id>`
///
/// Previews or writes generated unit test source files for a template.
class TemplateUnitTestsCommand extends FpsCommand {
  @override
  final String name = 'unit-tests';

  @override
  final String description =
      'Preview or generate unit test suites for a template.';

  TemplateUnitTestsCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing unit tests to disk.',
      defaultsTo: 'test/unit',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Generation profile (basic, standard, strict, release).',
      defaultsTo: 'standard',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated unit test files directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output unit test generation result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final outputDir = argResults?['output'] as String? ?? 'test/unit';
    final profile = argResults?['profile'] as String? ?? 'standard';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final generator = UnitTestGenerator();
    final options = UnitTestOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      profile: profile,
    );

    final plan = generator.planUnitTests(options);
    final result = generator.generateUnitTests(plan, options);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);

      for (final entry in result.files.entries) {
        final file =
            File('${baseDir.path}/${entry.key.replaceFirst('test/unit/', '')}');
        await file.parent.create(recursive: true);
        await file.writeAsString(entry.value);
      }

      if (!jsonOutput) {
        print(
            'Successfully wrote unit tests (${result.files.length} files) to "$outputDir".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print('Generated Unit Test Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Profile     : ${plan.profile}');
      print('API Targets : ${plan.targets.length}');
      print(
          'Targets     : ${plan.targets.map((t) => '${t.kind}:${t.name}').join(', ')}');
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template widget-tests <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template widget-tests <template-id>`
///
/// Previews or writes generated widget test source files for a template.
class TemplateWidgetTestsCommand extends FpsCommand {
  @override
  final String name = 'widget-tests';

  @override
  final String description =
      'Preview or generate widget test suites for a template.';

  TemplateWidgetTestsCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing widget tests to disk.',
      defaultsTo: 'test/widget',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Generation profile (basic, standard, strict, release).',
      defaultsTo: 'standard',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated widget test files directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output widget test generation result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final outputDir = argResults?['output'] as String? ?? 'test/widget';
    final profile = argResults?['profile'] as String? ?? 'standard';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final generator = WidgetTestGenerator();
    final options = WidgetTestOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      profile: profile,
    );

    final plan = generator.planWidgetTests(options);
    final result = generator.generateWidgetTests(plan, options);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);

      for (final entry in result.files.entries) {
        final file = File(
            '${baseDir.path}/${entry.key.replaceFirst('test/widget/', '')}');
        await file.parent.create(recursive: true);
        await file.writeAsString(entry.value);
      }

      if (!jsonOutput) {
        print(
            'Successfully wrote widget tests (${result.files.length} files) to "$outputDir".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print('Generated Widget Test Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Profile        : ${plan.profile}');
      print('Widget Targets : ${plan.targets.length}');
      print(
          'Targets        : ${plan.targets.map((t) => '${t.widgetKind}:${t.name}').join(', ')}');
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template integration-tests <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template integration-tests <template-id>`
///
/// Previews or writes generated integration test source files for a template.
class TemplateIntegrationTestsCommand extends FpsCommand {
  @override
  final String name = 'integration-tests';

  @override
  final String description =
      'Preview or generate integration test suites for a template.';

  TemplateIntegrationTestsCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing integration tests to disk.',
      defaultsTo: 'test/integration',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Generation profile (basic, standard, strict, release).',
      defaultsTo: 'standard',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated integration test files directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output integration test generation result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final outputDir = argResults?['output'] as String? ?? 'test/integration';
    final profile = argResults?['profile'] as String? ?? 'standard';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final generator = IntegrationTestGenerator();
    final options = IntegrationTestOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      profile: profile,
    );

    final plan = generator.planIntegrationTests(options);
    final result = generator.generateIntegrationTests(plan, options);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);

      for (final entry in result.files.entries) {
        final file = File(
            '${baseDir.path}/${entry.key.replaceFirst('test/integration/', '')}');
        await file.parent.create(recursive: true);
        await file.writeAsString(entry.value);
      }

      if (!jsonOutput) {
        print(
            'Successfully wrote integration tests (${result.files.length} files) to "$outputDir".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print(
          'Generated Integration Test Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Profile             : ${plan.profile}');
      print('Integration Targets : ${plan.targets.length}');
      print(
          'Targets             : ${plan.targets.map((t) => t.name).join(', ')}');
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template fixtures <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template fixtures <template-id>`
///
/// Previews or writes generated test fixtures and mocks for a template.
class TemplateFixturesCommand extends FpsCommand {
  @override
  final String name = 'fixtures';

  @override
  final String description =
      'Preview or generate test fixtures and mock doubles for a template.';

  TemplateFixturesCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing fixtures to disk.',
      defaultsTo: 'test',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Generation profile (basic, standard, strict, release).',
      defaultsTo: 'standard',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated test fixture/mock files directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output test fixture generation result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final outputDir = argResults?['output'] as String? ?? 'test';
    final profile = argResults?['profile'] as String? ?? 'standard';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final generator = TestFixtureGenerator();
    final options = FixtureOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      profile: profile,
    );

    final plan = generator.planFixtures(options);
    final result = generator.generateFixtures(plan, options);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);

      for (final entry in result.files.entries) {
        final file =
            File('${baseDir.path}/${entry.key.replaceFirst('test/', '')}');
        await file.parent.create(recursive: true);
        await file.writeAsString(entry.value);
      }

      if (!jsonOutput) {
        print(
            'Successfully wrote test fixtures & mocks (${result.files.length} files) to "$outputDir".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print(
          'Generated Test Fixture & Mock Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Profile          : ${plan.profile}');
      print('Fixture Targets  : ${plan.fixtureTargets.length}');
      print('Mock Targets     : ${plan.mockTargets.length}');
      print(
          'Fixtures         : ${plan.fixtureTargets.map((f) => f.name).join(', ')}');
      print(
          'Mocks            : ${plan.mockTargets.map((m) => m.name).join(', ')}');
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template test-runner <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template test-runner <template-id>`
///
/// Previews or executes test suites (unit, widget, integration) for a template.
class TemplateTestRunnerCommand extends FpsCommand {
  @override
  final String name = 'test-runner';

  @override
  final String description =
      'Preview or execute test suites (unit, widget, integration) for a template.';

  TemplateTestRunnerCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Test profile to execute (unit, widget, integration, all).',
      defaultsTo: 'all',
    );
    argParser.addOption(
      'timeout',
      abbr: 't',
      help: 'Timeout in seconds for test suite execution.',
      defaultsTo: '30',
    );
    argParser.addFlag(
      'execute',
      negatable: false,
      help: 'Execute planned test suites.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output test execution result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final profile = argResults?['profile'] as String? ?? 'all';
    final timeoutStr = argResults?['timeout'] as String? ?? '30';
    final timeoutSeconds = int.tryParse(timeoutStr) ?? 30;
    final executeFlag = argResults?['execute'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final runner = TestRunner();
    final options = TestExecutionOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      profile: profile,
      timeoutSeconds: timeoutSeconds,
    );

    final plan = runner.planTestExecution(options);

    if (executeFlag) {
      final result = runner.executeTests(plan, options);

      if (jsonOutput) {
        print(jsonEncode(result.toJson()));
      } else {
        print('Executed Test Suite Results for "${result.packageName}":');
        print('══════════════════════════════════════════════════════════════');
        print('Success      : ${result.success}');
        print('Passed Suites: ${result.passedCount}');
        print('Failed Suites: ${result.failedCount}');
        print('Logs         : ${result.logs.join('\n')}');
        print('══════════════════════════════════════════════════════════════');
      }
      return result.success ? 0 : 1;
    }

    if (jsonOutput) {
      print(jsonEncode(plan.toJson()));
    } else {
      print('Generated Test Execution Plan Preview for "${plan.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Profile     : ${plan.profile}');
      print('Test Suites : ${plan.suites.length}');
      print(
          'Suites      : ${plan.suites.map((s) => '${s.type}:${s.name}').join(', ')}');
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template coverage <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template coverage <template-id>`
///
/// Previews or writes code coverage analysis for a template.
class TemplateCoverageCommand extends FpsCommand {
  @override
  final String name = 'coverage';

  @override
  final String description =
      'Preview or calculate code coverage metrics for a template.';

  TemplateCoverageCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Coverage profile (unit, widget, integration, all).',
      defaultsTo: 'all',
    );
    argParser.addOption(
      'input',
      abbr: 'i',
      help: 'Path to LCOV coverage file.',
      defaultsTo: 'coverage/lcov.info',
    );
    argParser.addOption(
      'threshold',
      abbr: 't',
      help: 'Minimum required line coverage percentage.',
      defaultsTo: '80.0',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing report to disk.',
      defaultsTo: 'coverage',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated coverage report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output coverage analysis result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final profile = argResults?['profile'] as String? ?? 'all';
    final inputPath = argResults?['input'] as String? ?? 'coverage/lcov.info';
    final thresholdStr = argResults?['threshold'] as String? ?? '80.0';
    final minThreshold = double.tryParse(thresholdStr) ?? 80.0;
    final outputDir = argResults?['output'] as String? ?? 'coverage';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final analyzer = CoverageAnalyzer();
    final options = CoverageOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      profile: profile,
      inputPath: inputPath,
      thresholds: CoverageThresholds(minLineCoverage: minThreshold),
    );

    final plan = analyzer.planCoverageAnalysis(options);

    String lcovContent = '';
    final inputFile = File(inputPath);
    if (await inputFile.exists()) {
      lcovContent = await inputFile.readAsString();
    }

    final result = analyzer.analyzeCoverage(plan, lcovContent,
        thresholds: options.thresholds);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);
      final reportFile = File('${baseDir.path}/coverage_report.json');
      await reportFile.writeAsString(jsonEncode(result.toJson()));

      if (!jsonOutput) {
        print('Successfully wrote coverage report to "${reportFile.path}".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print(
          'Generated Code Coverage Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Profile        : ${plan.profile}');
      print('Input File     : ${plan.inputPath}');
      print('Overall Line % : ${result.overallPercentage.toStringAsFixed(1)}%');
      print('Status         : ${result.isPassed ? "PASSED ✓" : "FAILED ✗"}');
      print('══════════════════════════════════════════════════════════════');
    }

    return result.isPassed ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template test-report <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template test-report <template-id>`
///
/// Previews or writes aggregated test & coverage reports for a template.
class TemplateTestReportCommand extends FpsCommand {
  @override
  final String name = 'test-report';

  @override
  final String description =
      'Preview or generate aggregated test execution & coverage report for a template.';

  TemplateTestReportCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Report profile (unit, widget, integration, all).',
      defaultsTo: 'all',
    );
    argParser.addOption(
      'execution-report',
      help: 'Path to optional execution result JSON file.',
    );
    argParser.addOption(
      'coverage-report',
      help: 'Path to optional coverage result JSON file.',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing report to disk.',
      defaultsTo: 'doc/reports',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated test report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output test report result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final profile = argResults?['profile'] as String? ?? 'all';
    final outputDir = argResults?['output'] as String? ?? 'doc/reports';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final generator = TestReportGenerator();
    final options = ReportOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      profile: profile,
      outputFormat: jsonOutput ? 'json' : 'markdown',
    );

    final plan = generator.planTestReport(options);
    final report = generator.generateReport(plan);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);
      final file =
          File('${baseDir.path}/test_report.${jsonOutput ? 'json' : 'md'}');
      await file.writeAsString(
          jsonOutput ? jsonEncode(report.toJson()) : report.toMarkdown());

      if (!jsonOutput) {
        print('Successfully wrote aggregate test report to "${file.path}".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(report.toJson()));
    } else if (!writeDisk) {
      print('Generated Test Report Plan Preview for "${report.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Profile  : ${plan.profile}');
      print('Status   : ${report.overallSuccess ? "PASSED ✓" : "FAILED ✗"}');
      print('Format   : ${plan.outputFormat}');
      print('══════════════════════════════════════════════════════════════');
    }

    return report.overallSuccess ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template compatibility <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template compatibility <template-id>`
///
/// Previews or writes compatibility test matrix reports for a template.
class TemplateCompatibilityCommand extends FpsCommand {
  @override
  final String name = 'compatibility';

  @override
  final String description =
      'Preview or evaluate compatibility test matrix for a template.';

  TemplateCompatibilityCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Test profile to filter (unit, widget, integration, all).',
      defaultsTo: 'all',
    );
    argParser.addOption(
      'platform',
      help: 'Platform target to filter (android, ios, web, all).',
      defaultsTo: 'all',
    );
    argParser.addOption(
      'sdk',
      help: 'SDK constraint to evaluate.',
      defaultsTo: '>=3.0.0 <4.0.0',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing matrix to disk.',
      defaultsTo: 'doc/matrix',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated compatibility matrix directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output compatibility matrix result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final profile = argResults?['profile'] as String? ?? 'all';
    final platform = argResults?['platform'] as String? ?? 'all';
    final sdkConstraint = argResults?['sdk'] as String? ?? '>=3.0.0 <4.0.0';
    final outputDir = argResults?['output'] as String? ?? 'doc/matrix';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final service = CompatibilityMatrixService();
    final options = CompatibilityOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      profile: profile,
      platform: platform,
      sdkConstraint: sdkConstraint,
    );

    final plan = service.planCompatibilityMatrix(options);
    final result = service.evaluateMatrix(plan);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);
      final file = File(
          '${baseDir.path}/compatibility_matrix.${jsonOutput ? 'json' : 'md'}');
      await file.writeAsString(
          jsonOutput ? jsonEncode(result.toJson()) : result.toMarkdown());

      if (!jsonOutput) {
        print('Successfully wrote compatibility matrix to "${file.path}".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print(
          'Generated Compatibility Matrix Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Profile     : ${plan.profile}');
      print('Platform    : ${plan.platform}');
      print('SDK Range   : ${plan.sdkConstraint}');
      print('Total Cells : ${result.cells.length}');
      print(
          'Status      : ${result.isFullyCompatible ? "COMPATIBLE ✓" : "INCOMPATIBLE ✗"}');
      print('══════════════════════════════════════════════════════════════');
    }

    return result.isFullyCompatible ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template regression <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template regression <template-id>`
///
/// Previews or executes regression testing checks against baselines for a template.
class TemplateRegressionCommand extends FpsCommand {
  @override
  final String name = 'regression';

  @override
  final String description =
      'Preview or evaluate regression testing checks against baseline for a template.';

  TemplateRegressionCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Regression test profile (unit, widget, integration, all).',
      defaultsTo: 'all',
    );
    argParser.addOption(
      'baseline',
      abbr: 'b',
      help: 'Path to baseline evidence JSON file.',
      defaultsTo: 'test/regression/baseline.json',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing report to disk.',
      defaultsTo: 'doc/regression',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated regression report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output regression check result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final profile = argResults?['profile'] as String? ?? 'all';
    final baselinePath =
        argResults?['baseline'] as String? ?? 'test/regression/baseline.json';
    final outputDir = argResults?['output'] as String? ?? 'doc/regression';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final engine = RegressionTestingEngine();
    final options = RegressionOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      profile: profile,
      baselinePath: baselinePath,
    );

    final plan = engine.planRegressionTesting(options);
    final result = engine.runRegressionCheck(plan);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);
      final file = File(
          '${baseDir.path}/regression_report.${jsonOutput ? 'json' : 'md'}');
      await file.writeAsString(
          jsonOutput ? jsonEncode(result.toJson()) : result.toMarkdown());

      if (!jsonOutput) {
        print('Successfully wrote regression report to "${file.path}".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print(
          'Generated Regression Testing Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Profile        : ${plan.profile}');
      print('Baseline File  : ${plan.baselinePath}');
      print('Total Cases    : ${result.cases.length}');
      print(
          'Status         : ${result.hasRegressions ? "REGRESSION DETECTED ✗" : "NO REGRESSION ✓"}');
      print('══════════════════════════════════════════════════════════════');
    }

    return result.hasRegressions ? 1 : 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template test-certify <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template test-certify <template-id>`
///
/// Previews or evaluates test quality & certification gate reports for a template.
class TemplateTestCertifyCommand extends FpsCommand {
  @override
  final String name = 'test-certify';

  @override
  final String description =
      'Preview or evaluate test quality certification gate requirements for a template.';

  TemplateTestCertifyCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Quality certification profile (standard, strict, custom).',
      defaultsTo: 'standard',
    );
    argParser.addOption(
      'config',
      abbr: 'c',
      help: 'Path to certification gate configuration file.',
      defaultsTo: 'test/certification_config.json',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing report to disk.',
      defaultsTo: 'doc/certification',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated test certification report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output test certification result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final profile = argResults?['profile'] as String? ?? 'standard';
    final configPath =
        argResults?['config'] as String? ?? 'test/certification_config.json';
    final outputDir = argResults?['output'] as String? ?? 'doc/certification';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final gate = TestCertificationGate();
    final options = TestCertificationOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      profile: profile,
      configPath: configPath,
    );

    final plan = gate.planCertification(options);
    final result = gate.certifyPackage(plan);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);
      final file = File(
          '${baseDir.path}/test_certification.${jsonOutput ? 'json' : 'md'}');
      await file.writeAsString(
          jsonOutput ? jsonEncode(result.toJson()) : result.toMarkdown());

      if (!jsonOutput) {
        print(
            'Successfully wrote test certification report to "${file.path}".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print(
          'Generated Test Quality Certification Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Profile     : ${plan.profile}');
      print('Config File : ${plan.configPath}');
      print('Total Gates : ${result.gates.length}');
      print(
          'Decision    : ${result.isCertified ? "CERTIFIED ✓" : "NOT CERTIFIED ✗"}');
      print('══════════════════════════════════════════════════════════════');
    }

    return result.isCertified ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template test-workflow <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template test-workflow <template-id>`
///
/// Previews or executes the unified testing workflow lifecycle for a template.
class TemplateTestWorkflowCommand extends FpsCommand {
  @override
  final String name = 'test-workflow';

  @override
  final String description =
      'Preview or execute the unified testing workflow lifecycle for a template.';

  TemplateTestWorkflowCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint for template.',
      defaultsTo: '*',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Workflow profile (plan, test, full, regression, certify, all).',
      defaultsTo: 'all',
    );
    argParser.addFlag(
      'execute',
      negatable: false,
      help: 'Opt-in to process execution through controlled runner.',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing workflow report to disk.',
      defaultsTo: 'doc/testing_workflow',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated unified testing workflow report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output unified testing workflow result as JSON.',
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
    final versionConstraint = argResults?['version'] as String? ?? '*';
    final profileName = argResults?['profile'] as String? ?? 'all';
    final executeOpt = argResults?['execute'] as bool? ?? false;
    final outputDir =
        argResults?['output'] as String? ?? 'doc/testing_workflow';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId,
        version: versionConstraint == '*' ? null : versionConstraint);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final workflow = UnifiedTestingWorkflow();
    final profile = WorkflowProfile.values.firstWhere(
      (p) => p.name.toLowerCase() == profileName.toLowerCase(),
      orElse: () => WorkflowProfile.all,
    );

    final options = WorkflowOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      profile: profile,
      execute: executeOpt,
      outputDir: outputDir,
    );

    final plan = workflow.planWorkflow(options);
    final result = workflow.executeWorkflow(plan);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);
      final file = File(
          '${baseDir.path}/unified_testing_workflow.${jsonOutput ? 'json' : 'md'}');
      await file.writeAsString(
          jsonOutput ? jsonEncode(result.toJson()) : result.toMarkdown());

      if (!jsonOutput) {
        print(
            'Successfully wrote unified testing workflow report to "${file.path}".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print(
          'Generated Unified Testing Workflow Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Profile      : ${plan.profile.name}');
      print(
          'Execution    : ${options.execute ? "EXPLICIT EXECUTION" : "PREVIEW-ONLY"}');
      print('Total Stages : ${result.stages.length}');
      print(
          'Status       : ${result.isSuccess ? "WORKFLOW COMPLETED ✓" : "WORKFLOW FAILED ✗"}');
      print('══════════════════════════════════════════════════════════════');
    }

    return result.isSuccess ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template release-plan <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template release-plan <template-id>`
///
/// Previews or evaluates release readiness plans for a template.
class TemplateReleasePlanCommand extends FpsCommand {
  @override
  final String name = 'release-plan';

  @override
  final String description =
      'Preview or evaluate release readiness criteria for a template.';

  TemplateReleasePlanCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Target release version.',
      defaultsTo: '1.0.0',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Release planning profile (standard, strict, custom).',
      defaultsTo: 'standard',
    );
    argParser.addOption(
      'config',
      abbr: 'c',
      help: 'Path to release planning configuration file.',
      defaultsTo: 'release_config.json',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing release plan report to disk.',
      defaultsTo: 'doc/release',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated release readiness report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output release readiness plan result as JSON.',
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
    final targetVersion = argResults?['version'] as String? ?? '1.0.0';
    final profile = argResults?['profile'] as String? ?? 'standard';
    final configPath =
        argResults?['config'] as String? ?? 'release_config.json';
    final outputDir = argResults?['output'] as String? ?? 'doc/release';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final planner = ReleasePlanner();
    final options = ReleasePlanningOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      profile: profile,
      targetVersion: targetVersion,
      configPath: configPath,
    );

    final plan = planner.createReleasePlan(options);
    final result = planner.evaluateReadiness(plan);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);
      final file = File(
          '${baseDir.path}/release_readiness.${jsonOutput ? 'json' : 'md'}');
      await file.writeAsString(
          jsonOutput ? jsonEncode(result.toJson()) : result.toMarkdown());

      if (!jsonOutput) {
        print('Successfully wrote release readiness report to "${file.path}".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print(
          'Generated Release Readiness Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Target Version : ${plan.targetVersion}');
      print('Profile        : ${plan.profile}');
      print('Total Checks   : ${result.checks.length}');
      print(
          'Decision       : ${result.isReady ? "RELEASE READY ✓" : "NOT READY ✗"}');
      print('══════════════════════════════════════════════════════════════');
    }

    return result.isReady ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template version <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template version <template-id>`
///
/// Previews or applies version bumps and changelog release notes for a template.
class TemplateVersionCommand extends FpsCommand {
  @override
  final String name = 'version';

  @override
  final String description =
      'Preview or apply semantic version bumps and changelog updates for a template.';

  TemplateVersionCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Explicit target version.',
    );
    argParser.addOption(
      'type',
      abbr: 't',
      help: 'Version bump type (patch, minor, major, explicit).',
      defaultsTo: 'patch',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing version report to disk.',
      defaultsTo: 'doc/release',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help:
          'Apply generated version bump and changelog update directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output version bump result as JSON.',
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
    final explicitVer = argResults?['version'] as String?;
    final typeName = argResults?['type'] as String? ?? 'patch';
    final outputDir = argResults?['output'] as String? ?? 'doc/release';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final manager = VersionChangelogManager();
    final type = VersionChangeType.values.firstWhere(
      (t) => t.name.toLowerCase() == typeName.toLowerCase(),
      orElse: () => VersionChangeType.patch,
    );

    final options = VersionOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      currentVersion: tmpl.manifest.version,
      type: explicitVer != null ? VersionChangeType.explicit : type,
      explicitVersion: explicitVer,
    );

    final plan = manager.planVersionBump(options);
    final result = manager.applyVersionBump(plan, writeDisk: writeDisk);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);
      final file =
          File('${baseDir.path}/version_bump.${jsonOutput ? 'json' : 'md'}');
      await file.writeAsString(
          jsonOutput ? jsonEncode(result.toJson()) : result.toMarkdown());

      if (!jsonOutput) {
        print('Successfully wrote version report to "${file.path}".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print(
          'Generated Version & Changelog Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Previous Version : ${result.previousVersion}');
      print('New Version      : ${result.newVersion}');
      print('Change Type      : ${plan.type.name}');
      print(
          'Status           : ${result.isApplied ? "APPLIED ✓" : "PREVIEW-ONLY"}');
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template build <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template build <template-id>`
///
/// Previews or generates package build artifacts for a template.
class TemplateBuildCommand extends FpsCommand {
  @override
  final String name = 'build';

  @override
  final String description =
      'Preview or generate distributable package build artifacts for a template.';

  TemplateBuildCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint/target for template package artifact.',
      defaultsTo: '1.0.0',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing artifacts to disk.',
      defaultsTo: 'build/artifacts',
    );
    argParser.addFlag(
      'execute',
      negatable: false,
      help: 'Execute controlled build commands.',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated build artifact report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output build artifact result as JSON.',
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
    final targetVersion = argResults?['version'] as String? ?? '1.0.0';
    final outputDir = argResults?['output'] as String? ?? 'build/artifacts';
    final executeOpt = argResults?['execute'] as bool? ?? false;
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final generator = PackageArtifactGenerator();
    final options = ArtifactOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      version: targetVersion,
      outputDir: outputDir,
      execute: executeOpt,
    );

    final plan = generator.planArtifactGeneration(options);
    final result = generator.generateArtifacts(plan);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);
      final file = File(
          '${baseDir.path}/build_artifact_report.${jsonOutput ? 'json' : 'md'}');
      await file.writeAsString(
          jsonOutput ? jsonEncode(result.toJson()) : result.toMarkdown());

      if (!jsonOutput) {
        print('Successfully wrote build artifact report to "${file.path}".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print(
          'Generated Package Build & Artifact Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Package Version  : ${plan.version}');
      print('Output Directory : ${plan.outputDir}');
      print('Total Targets    : ${result.generatedArtifacts.length}');
      print(
          'Status           : ${result.isSuccess ? "BUILD PLAN SUCCESS ✓" : "BUILD PLAN FAILED ✗"}');
      print('══════════════════════════════════════════════════════════════');
    }

    return result.isSuccess ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template pubdev-validate <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template pubdev-validate <template-id>`
///
/// Previews or evaluates pub.dev package readiness validation for a template.
class TemplatePubDevValidateCommand extends FpsCommand {
  @override
  final String name = 'pubdev-validate';

  @override
  final String description =
      'Preview or evaluate pub.dev package readiness criteria for a template.';

  TemplatePubDevValidateCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint/target for template package.',
      defaultsTo: '1.0.0',
    );
    argParser.addOption(
      'profile',
      abbr: 'p',
      help: 'Validation profile (standard, strict, offline).',
      defaultsTo: 'standard',
    );
    argParser.addOption(
      'artifact',
      abbr: 'a',
      help: 'Path to Phase 5.3 package artifact tarball.',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing validation report to disk.',
      defaultsTo: 'doc/release',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated pub.dev validation report directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output pub.dev validation result as JSON.',
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
    final targetVersion = argResults?['version'] as String? ?? '1.0.0';
    final profile = argResults?['profile'] as String? ?? 'standard';
    final artifactPath = argResults?['artifact'] as String?;
    final outputDir = argResults?['output'] as String? ?? 'doc/release';
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final validator = PubDevPackageValidator();
    final options = PubDevValidationOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      version: targetVersion,
      profile: profile,
      artifactPath: artifactPath,
    );

    final plan = validator.planValidation(options);
    final result = validator.validatePackage(plan);

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);
      final file = File(
          '${baseDir.path}/pubdev_validation_report.${jsonOutput ? 'json' : 'md'}');
      await file.writeAsString(
          jsonOutput ? jsonEncode(result.toJson()) : result.toMarkdown());

      if (!jsonOutput) {
        print(
            'Successfully wrote pub.dev validation report to "${file.path}".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print(
          'Generated Pub.dev Package Validation Plan Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Package Version : ${plan.version}');
      print('Profile         : ${plan.profile}');
      print('Total Checks    : ${result.checks.length}');
      print(
          'Status          : ${result.isPublishable ? "PUBLISHABLE TO PUB.DEV ✓" : "NOT PUBLISHABLE ✗"}');
      print('══════════════════════════════════════════════════════════════');
    }

    return result.isPublishable ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template manifest <template-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps template manifest <template-id>`
///
/// Previews or generates a release artifact manifest for a template.
class TemplateManifestCommand extends FpsCommand {
  @override
  final String name = 'manifest';

  @override
  final String description =
      'Preview or generate canonical release artifact manifest for a template.';

  TemplateManifestCommand() {
    argParser.addOption(
      'version',
      abbr: 'v',
      help: 'Version constraint/target for template package manifest.',
      defaultsTo: '1.0.0',
    );
    argParser.addOption(
      'artifact-dir',
      abbr: 'a',
      help: 'Target directory containing generated artifacts.',
      defaultsTo: 'build/artifacts',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Target output directory when writing manifest to disk.',
      defaultsTo: 'doc/release',
    );
    argParser.addFlag(
      'verify',
      negatable: false,
      help: 'Verify existing release artifact manifest integrity.',
    );
    argParser.addFlag(
      'write',
      negatable: false,
      help: 'Write generated release artifact manifest directly to disk.',
    );
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output release artifact manifest as JSON.',
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
    final targetVersion = argResults?['version'] as String? ?? '1.0.0';
    final artifactDir =
        argResults?['artifact-dir'] as String? ?? 'build/artifacts';
    final outputDir = argResults?['output'] as String? ?? 'doc/release';
    final verifyOpt = argResults?['verify'] as bool? ?? false;
    final writeDisk = argResults?['write'] as bool? ?? false;
    final jsonOutput = argResults?['json'] as bool? ?? false;

    final discoveryService = _buildDiscoveryService();
    final entry = discoveryService.get(templateId);

    if (entry == null) {
      if (jsonOutput) {
        print(jsonEncode(
            {'error': 'Template "$templateId" not found.', 'success': false}));
      } else {
        print('Error: Template "$templateId" not found in catalog.');
      }
      return 1;
    }

    final tmpl = entry.template;
    final generator = ReleaseArtifactManifestGenerator();
    final options = ManifestOptions(
      packageName: tmpl.manifest.name.toLowerCase().replaceAll(' ', '_'),
      version: targetVersion,
      artifactDir: artifactDir,
      outputDir: outputDir,
    );

    final plan = generator.planManifest(options);
    final result = generator.generateManifest(plan);

    if (verifyOpt) {
      final isVerified = generator.verifyManifest(result);
      if (!isVerified) {
        if (jsonOutput) {
          print(jsonEncode(
              {'error': 'Manifest verification failed.', 'success': false}));
        } else {
          print('Error: Release artifact manifest verification failed.');
        }
        return 1;
      }
    }

    if (writeDisk) {
      final baseDir = Directory(outputDir);
      await baseDir.create(recursive: true);
      final file = File(
          '${baseDir.path}/release_artifact_manifest.${jsonOutput ? 'json' : 'md'}');
      await file.writeAsString(
          jsonOutput ? jsonEncode(result.toJson()) : result.toMarkdown());

      if (!jsonOutput) {
        print(
            'Successfully wrote release artifact manifest to "${file.path}".');
      }
    }

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else if (!writeDisk) {
      print(
          'Generated Release Artifact Manifest Preview for "${result.packageName}":');
      print('══════════════════════════════════════════════════════════════');
      print('Package Version : ${plan.version}');
      print('Schema Version  : ${plan.schemaVersion}');
      print('Total Entries   : ${result.entries.length}');
      print(
          'Integrity Status: ${result.isVerified ? "VERIFIED ✓" : "UNVERIFIED ✗"}');
      print('══════════════════════════════════════════════════════════════');
    }

    return result.isVerified ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// template (parent)
// ─────────────────────────────────────────────────────────────────────────────

/// Command: `fps template`
///
/// Parent command hosting the template catalog subcommands:
/// `list`, `search`, `info`, `check`, `compose`, `customize`, `validate`, `hooks`, `certify`, `test`, `migrate`, `readme`, `api-docs`, `architecture`, `mermaid`, `examples`, `screenshots`, `gifs`, `website`, `test-project`, `unit-tests`, `widget-tests`, `integration-tests`, `fixtures`, `coverage`, `test-runner`, `test-report`, `compatibility`, `regression`, `test-certify`, `test-workflow`, `release-plan`, `version`, `build`, `pubdev-validate`, `manifest`.
class TemplateCatalogCommand extends FpsCommand {
  @override
  final String name = 'template';

  @override
  final String description =
      'Ecosystem CLI for template discovery, inspection, composition, customization, quality, testing, certification, migration, release, build, validation, manifest, and documentation.';

  TemplateCatalogCommand() {
    addSubcommand(TemplateListCommand());
    addSubcommand(TemplateSearchCommand());
    addSubcommand(TemplateInfoCommand());
    addSubcommand(TemplateCheckCommand());
    addSubcommand(TemplateComposeCommand());
    addSubcommand(TemplateCustomizeCommand());
    addSubcommand(TemplateValidateCommand());
    addSubcommand(TemplateHooksCommand());
    addSubcommand(TemplateCertifyCommand());
    addSubcommand(TemplateTestCommand());
    addSubcommand(TemplateMigrateCommand());
    addSubcommand(TemplateReadmeCommand());
    addSubcommand(TemplateApiDocsCommand());
    addSubcommand(TemplateArchitectureCommand());
    addSubcommand(TemplateMermaidCommand());
    addSubcommand(TemplateExamplesCommand());
    addSubcommand(TemplateScreenshotsCommand());
    addSubcommand(TemplateGifsCommand());
    addSubcommand(TemplateWebsiteCommand());
    addSubcommand(TemplateTestProjectCommand());
    addSubcommand(TemplateUnitTestsCommand());
    addSubcommand(TemplateWidgetTestsCommand());
    addSubcommand(TemplateIntegrationTestsCommand());
    addSubcommand(TemplateFixturesCommand());
    addSubcommand(TemplateTestRunnerCommand());
    addSubcommand(TemplateCoverageCommand());
    addSubcommand(TemplateTestReportCommand());
    addSubcommand(TemplateCompatibilityCommand());
    addSubcommand(TemplateRegressionCommand());
    addSubcommand(TemplateTestCertifyCommand());
    addSubcommand(TemplateTestWorkflowCommand());
    addSubcommand(TemplateReleasePlanCommand());
    addSubcommand(TemplateVersionCommand());
    addSubcommand(TemplateBuildCommand());
    addSubcommand(TemplatePubDevValidateCommand());
    addSubcommand(TemplateManifestCommand());
  }

  @override
  Future<int> run() async {
    print('Flutter Package Studio — Template Ecosystem CLI');
    print(
        'Recommended Workflow: discovery → info → check → compose → customize → validate → test → certify → readme → api-docs → architecture → mermaid → examples → screenshots → gifs → website → test-project → unit-tests → widget-tests → integration-tests → fixtures → coverage → test-runner → test-report → compatibility → regression → test-certify → test-workflow → release-plan → version → build → pubdev-validate → manifest → migrate');
    print('');
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
