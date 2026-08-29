import 'dart:convert';
import 'dart:io';

import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:flutter_package_studio_cli/src/base_command.dart';

/// Central container and factory for shared plugin subsystem services.
class PluginCliServices {
  final PluginContractValidator validator;
  final PluginDiscoveryEngine discoveryEngine;
  final PluginRegistry registry;
  final PluginLifecycleManager lifecycleManager;
  final PluginPermissionGate permissionGate;
  final PluginExecutionRuntime runtime;

  PluginCliServices({
    PluginContractValidator? validator,
    PluginDiscoveryEngine? discoveryEngine,
    PluginRegistry? registry,
    PluginLifecycleManager? lifecycleManager,
    PluginPermissionGate? permissionGate,
    PluginExecutionRuntime? runtime,
  })  : validator = validator ?? PluginContractValidator(),
        discoveryEngine = discoveryEngine ??
            PluginDiscoveryEngine(
                validator: validator ?? PluginContractValidator()),
        registry = registry ?? PluginRegistry(validator: validator),
        permissionGate = permissionGate ?? PluginPermissionGate(),
        lifecycleManager = lifecycleManager ??
            PluginLifecycleManager(
              validator: validator,
              registry: registry,
              permissionGate: permissionGate,
            ),
        runtime = runtime ??
            PluginExecutionRuntime(
              lifecycleManager: lifecycleManager ??
                  PluginLifecycleManager(
                    validator: validator,
                    registry: registry,
                    permissionGate: permissionGate,
                  ),
              permissionGate: permissionGate ?? PluginPermissionGate(),
              registry: registry ?? PluginRegistry(validator: validator),
            );

  static PluginCliServices? _instance;
  static PluginCliServices get instance =>
      _instance ??= _buildDefaultInstance();

  static void setInstance(PluginCliServices services) {
    _instance = services;
  }

  static void resetInstance() {
    _instance = null;
  }

  static PluginCliServices _buildDefaultInstance() {
    final validator = PluginContractValidator();
    final discoveryEngine = PluginDiscoveryEngine(validator: validator);
    final registry = PluginRegistry(validator: validator);
    final permissionGate = PluginPermissionGate();
    final lifecycleManager = PluginLifecycleManager(
      validator: validator,
      registry: registry,
      permissionGate: permissionGate,
    );
    final runtime = PluginExecutionRuntime(
      lifecycleManager: lifecycleManager,
      permissionGate: permissionGate,
      registry: registry,
    );

    // Register built-in template/ecosystem sample plugin for CLI discovery & lookup
    final sampleManifest = PluginManifest(
      id: PluginId('samplerunner'),
      name: PluginName('SampleRunner'),
      description: PluginDescription('Built-in CLI runner plugin.'),
      version: SemVer.parse('1.0.0'),
      author: const PluginAuthor(name: 'FPS Core Team'),
      apiVersion: '1.0.0',
      capabilities: {
        PluginCapability.commandContribution,
        PluginCapability.packageAnalysisContribution,
      },
      compatibility: PluginCompatibility(minApiVersion: '1.0.0'),
      configSchema: ConfigurationSchema(properties: [
        const ConfigurationProperty(
          key: 'mode',
          type: ConfigPropertyType.string,
          description: 'Execution mode.',
        ),
      ]),
      dependencies: [
        PluginDependency(name: 'core_extension', versionConstraint: '^1.0.0'),
      ],
      securityRequirements: const SecurityRequirements(
        permissions: ['package.read', 'cliCommand.add'],
      ),
    );

    permissionGate.approvePermission(
        'samplerunner', PluginPermission.packageRead);
    permissionGate.approvePermission(
        'samplerunner', PluginPermission.cliCommandAdd);

    try {
      lifecycleManager.trackInstance(
        instanceId: 'samplerunner',
        manifest: sampleManifest,
        instance: _SampleCliPlugin(),
      );
    } catch (_) {}


    return PluginCliServices(
      validator: validator,
      discoveryEngine: discoveryEngine,
      registry: registry,
      lifecycleManager: lifecycleManager,
      permissionGate: permissionGate,
      runtime: runtime,
    );
  }
}

class _SampleCliPlugin
    implements CommandContribution, PackageAnalysisContribution {
  @override
  List<String> getCommands() => ['sample_command_1', 'sample_command_2'];

  @override
  List<String> getAnalyzers() => ['sample_analyzer_alpha'];
}

// ─────────────────────────────────────────────────────────────────────────────
// fps plugin (Root Command Group)
// ─────────────────────────────────────────────────────────────────────────────

/// Dedicated command group: `fps plugin <subcommand>`
class PluginCatalogCommand extends FpsCommand {
  @override
  final String name = 'plugin';

  @override
  final String description =
      'Manage Flutter Package Studio plugins and extensions.';

  PluginCatalogCommand() {
    addSubcommand(PluginListCommand());
    addSubcommand(PluginDiscoverCommand());
    addSubcommand(PluginInfoCommand());
    addSubcommand(PluginValidateCommand());
    addSubcommand(PluginEnableCommand());
    addSubcommand(PluginDisableCommand());
    addSubcommand(PluginInspectCommand());
  }

  @override
  Future<int> run() async {
    print('Flutter Package Studio — Plugin Ecosystem CLI');
    print('Usage: fps plugin <subcommand> [arguments]');
    print('');
    printUsage();
    return 0;
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Subcommand 1: fps plugin list
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps plugin list`
///
/// Lists all registered plugins in the central PluginRegistry inventory.
class PluginListCommand extends FpsCommand {
  @override
  final String name = 'list';

  @override
  final String description =
      'List all registered plugins in the central inventory.';

  PluginListCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output registered plugins list as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final services = PluginCliServices.instance;
    final pluginsMap = <String, PluginManifest>{};
    for (final m in services.registry.listPlugins()) {
      pluginsMap[m.id.value] = m;
    }
    for (final inst in services.lifecycleManager.instances) {
      pluginsMap[inst.manifest.id.value] = inst.manifest;
    }
    final plugins = pluginsMap.values.toList();


    if (jsonOutput) {
      print(jsonEncode(plugins.map((m) => m.toJson()).toList()));
    } else {
      print('Registered Plugins Inventory (${plugins.length}):');
      print('══════════════════════════════════════════════════════════════');
      if (plugins.isEmpty) {
        print('  (No plugins currently registered in inventory)');
      } else {
        for (final m in plugins) {
          print('  • ${m.id} (v${m.version}): ${m.name}');
          print(
              '    Capabilities: ${m.capabilities.map((c) => c.name).join(", ")}');
        }
      }
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subcommand 2: fps plugin discover <dirs...>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps plugin discover <dir1> [dir2...]`
///
/// Scans directory roots for plugin manifests with zero code execution.
class PluginDiscoverCommand extends FpsCommand {
  @override
  final String name = 'discover';

  @override
  final String description =
      'Scan directory roots for plugin manifests with zero code execution.';

  PluginDiscoverCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output discovery report as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      printUsage();
      return 64;
    }

    final jsonOutput = argResults?['json'] as bool? ?? false;
    final services = PluginCliServices.instance;
    final result = await services.discoveryEngine.discoverPlugins(rest);

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else {
      print(result.toFormattedText());
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subcommand 3: fps plugin info <plugin-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps plugin info <plugin-id>`
///
/// Displays detailed metadata, version, author, capabilities, dependencies, and configuration schema for a plugin.
class PluginInfoCommand extends FpsCommand {
  @override
  final String name = 'info';

  @override
  final String description =
      'Display detailed identity, capabilities, dependencies, and schema for a plugin.';

  PluginInfoCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output plugin metadata info as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      printUsage();
      return 64;
    }

    final pluginId = rest.first.trim();
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final services = PluginCliServices.instance;

    final manifest = services.registry.findPlugin(pluginId) ??
        services.lifecycleManager.getInstance(pluginId)?.manifest;

    if (manifest == null) {
      if (jsonOutput) {
        print(jsonEncode({
          'error': 'Plugin "$pluginId" not found in inventory.',
          'pluginId': pluginId,
        }));
      } else {
        print('Error: Plugin "$pluginId" not found in inventory.');
      }
      return 1;
    }

    if (jsonOutput) {
      print(jsonEncode(manifest.toJson()));
    } else {
      print('Plugin Information: "${manifest.id.value}"');
      print('══════════════════════════════════════════════════════════════');
      print('Name         : ${manifest.name.value}');
      print('Description  : ${manifest.description.value}');
      print('Version      : ${manifest.version}');
      print(
          'Author       : ${manifest.author.name}${manifest.author.email != null ? " <${manifest.author.email}>" : ""}');
      print('API Version  : ${manifest.apiVersion}');
      print(
          'Capabilities : ${manifest.capabilities.map((c) => c.name).join(", ")}');
      print(
          'Dependencies : ${manifest.dependencies.isEmpty ? "(none)" : manifest.dependencies.map((d) => "${d.name} (${d.versionConstraint})").join(", ")}');
      print(
          'Config Schema: ${manifest.configSchema.properties.isEmpty ? "(none)" : manifest.configSchema.properties.map((p) => "${p.key}: ${p.type.name}${p.isRequired ? "*" : ""}").join(", ")}');
      print(
          'Permissions  : ${manifest.securityRequirements.permissions.isEmpty ? "(none)" : manifest.securityRequirements.permissions.join(", ")}');
      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subcommand 4: fps plugin validate <manifest-file-or-json>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps plugin validate <manifest-file-or-json>`
///
/// Validates raw plugin manifest JSON or file for contract compliance with zero code execution.
class PluginValidateCommand extends FpsCommand {
  @override
  final String name = 'validate';

  @override
  final String description =
      'Validate raw plugin manifest for contract compliance with zero code execution.';

  PluginValidateCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output validation result as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      printUsage();
      return 64;
    }

    final input = rest.first.trim();
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final services = PluginCliServices.instance;

    Map<String, dynamic> manifestMap;
    try {
      if (input.startsWith('{')) {
        manifestMap = jsonDecode(input) as Map<String, dynamic>;
      } else {
        final file = File(input);
        if (!file.existsSync()) {
          if (jsonOutput) {
            print(jsonEncode(
                {'error': 'File "$input" not found.', 'isValid': false}));
          } else {
            print('Error: File "$input" not found.');
          }
          return 1;
        }
        manifestMap =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
    } catch (e) {
      if (jsonOutput) {
        print(jsonEncode({
          'error': 'Failed to parse JSON manifest input: $e',
          'isValid': false
        }));
      } else {
        print('Error: Failed to parse JSON manifest input: $e');
      }
      return 1;
    }

    final result = services.validator.validateRawJson(manifestMap);

    if (jsonOutput) {
      print(jsonEncode(result.toJson()));
    } else {
      print('Plugin Manifest Contract Validation:');
      print('Status: ${result.isValid ? "VALID ✓" : "INVALID ✗"}');
      if (result.isValid) {
        print(
            'Manifest passed all contract validation rules with zero code execution.');
      } else {
        print('Violations (${result.violations.length}):');
        for (final v in result.violations) {
          print('  - $v');
        }
      }
    }

    return result.isValid ? 0 : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subcommand 5: fps plugin enable <plugin-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps plugin enable <plugin-id>`
///
/// Drives the validated activation lifecycle sequence (discovered -> validated -> registered -> initialized -> active).
class PluginEnableCommand extends FpsCommand {
  @override
  final String name = 'enable';

  @override
  final String description =
      'Perform validated lifecycle activation sequence to enable a plugin.';

  PluginEnableCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output lifecycle activation outcome as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      printUsage();
      return 64;
    }

    final pluginId = rest.first.trim();
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final services = PluginCliServices.instance;

    var record = services.lifecycleManager.getInstance(pluginId);
    if (record == null) {
      // If not yet tracked, look up in registry
      final manifest = services.registry.findPlugin(pluginId);
      if (manifest == null) {
        if (jsonOutput) {
          print(jsonEncode({
            'error':
                'Plugin "$pluginId" not found in registry or lifecycle manager.',
            'pluginId': pluginId,
            'enabled': false,
          }));
        } else {
          print('Error: Plugin "$pluginId" is not tracked or registered.');
        }
        return 1;
      }
      record = services.lifecycleManager.trackInstance(
        instanceId: pluginId,
        manifest: manifest,
      );
    }

    try {
      // If in terminal failure state, re-attempt first
      if (PluginLifecycleManager.terminalFailureStates.contains(record.state)) {
        await services.lifecycleManager.reattempt(pluginId);
      }

      // Progress through lifecycle state machine
      if (record.state == PluginLifecycleState.discovered) {
        await services.lifecycleManager.transitionTo(
          instanceId: pluginId,
          targetState: PluginLifecycleState.validated,
          reason: 'CLI enable: validated',
        );
      }
      if (record.state == PluginLifecycleState.validated) {
        await services.lifecycleManager.transitionTo(
          instanceId: pluginId,
          targetState: PluginLifecycleState.registered,
          reason: 'CLI enable: registered',
        );
      }
      if (record.state == PluginLifecycleState.registered) {
        await services.lifecycleManager.transitionTo(
          instanceId: pluginId,
          targetState: PluginLifecycleState.initialized,
          reason: 'CLI enable: initialized',
        );
      }
      if (record.state == PluginLifecycleState.initialized) {
        await services.lifecycleManager.transitionTo(
          instanceId: pluginId,
          targetState: PluginLifecycleState.active,
          reason: 'CLI enable: active',
        );
      }

      final isSuccess = record.state == PluginLifecycleState.active;

      if (jsonOutput) {
        print(jsonEncode({
          'pluginId': pluginId,
          'enabled': isSuccess,
          'state': record.state.name,
          'history': record.history.map((h) => h.toJson()).toList(),
        }));
      } else {
        print('Plugin Enable Lifecycle Operation for "$pluginId":');
        print('══════════════════════════════════════════════════════════════');
        print(
            'Status : ${isSuccess ? "ENABLED (active) ✓" : "FAILED (${record.state.name}) ✗"}');
        print('State  : ${record.state.name}');
        print('Audit History:');
        for (final h in record.history) {
          print('  - $h');
        }
        print('══════════════════════════════════════════════════════════════');
      }

      return isSuccess ? 0 : 1;
    } catch (e) {
      if (jsonOutput) {
        print(jsonEncode({
          'pluginId': pluginId,
          'enabled': false,
          'state': record.state.name,
          'error': e.toString(),
        }));
      } else {
        print('Error: Failed to enable plugin "$pluginId": $e');
      }
      return 1;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subcommand 6: fps plugin disable <plugin-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps plugin disable <plugin-id>`
///
/// Transitions a plugin instance cleanly to the Disabled lifecycle state.
class PluginDisableCommand extends FpsCommand {
  @override
  final String name = 'disable';

  @override
  final String description =
      'Perform administrative lifecycle transition to disable a plugin.';

  PluginDisableCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output lifecycle disable outcome as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      printUsage();
      return 64;
    }

    final pluginId = rest.first.trim();
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final services = PluginCliServices.instance;

    final record = services.lifecycleManager.getInstance(pluginId);
    if (record == null) {
      if (jsonOutput) {
        print(jsonEncode({
          'error':
              'Plugin instance "$pluginId" is not tracked by lifecycle manager.',
          'pluginId': pluginId,
          'disabled': false,
        }));
      } else {
        print(
            'Error: Plugin instance "$pluginId" is not tracked by lifecycle manager.');
      }
      return 1;
    }

    try {
      if (record.state != PluginLifecycleState.disabled) {
        await services.lifecycleManager.transitionTo(
          instanceId: pluginId,
          targetState: PluginLifecycleState.disabled,
          reason: 'Administrative CLI disable command',
        );
      }

      if (jsonOutput) {
        print(jsonEncode({
          'pluginId': pluginId,
          'disabled': true,
          'state': record.state.name,
          'history': record.history.map((h) => h.toJson()).toList(),
        }));
      } else {
        print('Plugin Disable Lifecycle Operation for "$pluginId":');
        print('══════════════════════════════════════════════════════════════');
        print('Status : DISABLED ✓');
        print('State  : ${record.state.name}');
        print('Reason : Administrative CLI disable command');
        print('══════════════════════════════════════════════════════════════');
      }

      return 0;
    } catch (e) {
      if (jsonOutput) {
        print(jsonEncode({
          'pluginId': pluginId,
          'disabled': false,
          'state': record.state.name,
          'error': e.toString(),
        }));
      } else {
        print('Error: Failed to disable plugin "$pluginId": $e');
      }
      return 1;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subcommand 7: fps plugin inspect <plugin-id>
// ─────────────────────────────────────────────────────────────────────────────

/// Subcommand: `fps plugin inspect <plugin-id>`
///
/// Comprehensive single-plugin deep-dive aggregating data across all Phase 7 subsystems.
class PluginInspectCommand extends FpsCommand {
  @override
  final String name = 'inspect';

  @override
  final String description =
      'Comprehensive deep-dive inspection aggregating manifest, lifecycle, permissions, and audit logs.';

  PluginInspectCommand() {
    argParser.addFlag(
      'json',
      negatable: false,
      help: 'Output comprehensive inspection snapshot as JSON.',
    );
  }

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      printUsage();
      return 64;
    }

    final pluginId = rest.first.trim();
    final jsonOutput = argResults?['json'] as bool? ?? false;
    final services = PluginCliServices.instance;

    final instanceRecord = services.lifecycleManager.getInstance(pluginId);
    final manifest =
        instanceRecord?.manifest ?? services.registry.findPlugin(pluginId);

    if (manifest == null) {
      if (jsonOutput) {
        print(jsonEncode({
          'error':
              'Plugin "$pluginId" not found in lifecycle manager or registry.',
          'pluginId': pluginId,
        }));
      } else {
        print('Error: Plugin "$pluginId" not found.');
      }
      return 1;
    }

    // 1. Manifest & Capabilities (7.1/7.2)
    final isRegistered = services.registry.exists(pluginId);
    final lifecycleState =
        instanceRecord?.state ?? PluginLifecycleState.discovered;
    final transitionHistory = instanceRecord?.history ?? const [];

    // 2. Permission Status (7.8)
    final permissionSummary = services.permissionGate.queryStatus(manifest);

    // 3. Execution Audits (7.9)
    final executionAudits = services.runtime.auditLog
        .where((r) => r.pluginId == pluginId || r.pluginId == manifest.id.value)
        .toList();

    // 4. Dependencies (7.6)
    final depsResolver = PluginDependencyResolver();
    final resolution = depsResolver.resolveDependencies([manifest]);

    final inspectData = {
      'pluginId': manifest.id.value,
      'manifest': manifest.toJson(),
      'isRegistered': isRegistered,
      'lifecycle': {
        'state': lifecycleState.name,
        'transitionCount': transitionHistory.length,
        'history': transitionHistory.map((h) => h.toJson()).toList(),
      },
      'permissions': permissionSummary.toJson(),
      'dependencies': {
        'declared': manifest.dependencies.map((d) => d.toJson()).toList(),
        'isCompatible': resolution.isCompatible,
        'findings': resolution.findings.map((f) => f.toJson()).toList(),
      },
      'configSchema': manifest.configSchema.toJson(),
      'recentExecutionAudits': executionAudits.map((a) => a.toJson()).toList(),
    };

    if (jsonOutput) {
      print(jsonEncode(inspectData));
    } else {
      print('══════════════════════════════════════════════════════════════');
      print('PLUGIN INSPECTION DEEP-DIVE: "${manifest.id.value}"');
      print('══════════════════════════════════════════════════════════════');
      print('1. IDENTITY & METADATA');
      print('   Name         : ${manifest.name.value}');
      print('   Description  : ${manifest.description.value}');
      print('   Version      : v${manifest.version}');
      print('   API Version  : ${manifest.apiVersion}');
      print('   Author       : ${manifest.author.name}');
      print('   Registered   : ${isRegistered ? "YES ✓" : "NO ✗"}');
      print('');
      print('2. LIFECYCLE & STATE MACHINE');
      print('   Current State: ${lifecycleState.name.toUpperCase()}');
      print('   Transitions  : ${transitionHistory.length}');
      for (final h in transitionHistory) {
        print('     - $h');
      }
      print('');
      print('3. DECLARED CAPABILITIES');
      for (final c in manifest.capabilities) {
        print('   • ${c.name}');
      }
      print('');
      print('4. PERMISSION MODEL (✓/✗)');
      for (final item in permissionSummary.items) {
        final symbol = item.isEffective ? "✓" : "✗";
        print(
            '   $symbol ${item.permission.wireName.padRight(22)} (Declared: ${item.isDeclared}, Approved: ${item.isApproved})');
      }
      print('');
      print('5. CONFIGURATION SCHEMA');
      if (manifest.configSchema.properties.isEmpty) {
        print('   (No properties declared)');
      } else {
        for (final p in manifest.configSchema.properties) {
          print(
              '   • ${p.key} [${p.type.name}] ${p.isRequired ? "(Required)" : "(Optional)"} ${p.isSecret ? "[SECRET]" : ""}');
        }
      }
      print('');
      print('6. DEPENDENCIES & ECOSYSTEM');
      if (manifest.dependencies.isEmpty) {
        print('   (No dependencies declared)');
      } else {
        for (final d in manifest.dependencies) {
          print('   • ${d.name} (${d.versionConstraint})');
        }
      }
      print('');
      print('7. RECENT EXECUTION AUDITS (${executionAudits.length})');
      if (executionAudits.isEmpty) {
        print('   (No recent contribution executions recorded)');
      } else {
        for (final a in executionAudits) {
          print(
              '   [${a.status.name}] ${a.operation} (${a.durationMs}ms) - ${a.details ?? "SUCCESS"}');
        }
      }

      print('══════════════════════════════════════════════════════════════');
    }

    return 0;
  }
}
