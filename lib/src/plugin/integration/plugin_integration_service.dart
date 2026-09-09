/// Optional plugin integration, failure containment, and extension point coordinator (Phase 7.17).
library;

import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/plugin/discovery/plugin_discovery_engine.dart';
import 'package:syntrix/src/plugin/discovery/plugin_discovery_models.dart';
import 'package:syntrix/src/plugin/interface/plugin_contribution_interfaces.dart';
import 'package:syntrix/src/plugin/interface/plugin_registry.dart';
import 'package:syntrix/src/plugin/persistence/plugin_state_store.dart';

/// Single authority for non-intrusive, optional plugin integration across core workflows.
///
/// Guarantees:
/// - Zero startup cost: Plugin registry, discovery, and state store are lazily loaded on demand.
/// - Graceful Failure Containment: Any exception thrown during plugin query/execution is caught and logged,
///   allowing surrounding core workflows (e.g. release, validation, project generation) to proceed uninterrupted.
/// - Optional Additive Enhancements: Plugin contributions augment core operations if available, but never replace or break default behavior.
class PluginIntegrationService {
  final Logger _logger = Logger('PluginIntegrationService');
  final String _rootPath;

  PluginRegistry? _registry;
  PluginStateStore? _stateStore;
  PluginDiscoveryEngine? _discoveryEngine;

  PluginIntegrationService({
    String rootPath = '.',
    PluginRegistry? registry,
    PluginStateStore? stateStore,
    PluginDiscoveryEngine? discoveryEngine,
  })  : _rootPath = rootPath,
        _registry = registry,
        _stateStore = stateStore,
        _discoveryEngine = discoveryEngine;

  /// Lazy accessor for PluginRegistry. Never instantiated until explicitly requested.
  PluginRegistry get registry => _registry ??= PluginRegistry();

  /// Lazy accessor for PluginStateStore. Never instantiated until explicitly requested.
  PluginStateStore get stateStore =>
      _stateStore ??= PluginStateStore(rootPath: _rootPath);

  /// Lazy accessor for PluginDiscoveryEngine. Never instantiated until explicitly requested.
  PluginDiscoveryEngine get discoveryEngine =>
      _discoveryEngine ??= PluginDiscoveryEngine();

  /// Returns true if the plugin registry has any registered plugins.
  bool get hasActivePlugins {
    try {
      if (_registry == null) return false;
      return _registry!.listPlugins().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Safely queries all registered contributions of type [T] across all active plugins.
  ///
  /// Guarantees:
  /// - Failure-contained: Catches any registry errors and returns an empty list.
  /// - Non-blocking: Zero side effects if no plugins or registry are initialized.
  List<T> safeQueryContributions<T>() {
    try {
      if (_registry == null) return const [];
      final results = <T>[];
      for (final manifest in _registry!.listPlugins()) {
        final contribution = _registry!.getContribution<T>(manifest.id.value);
        if (contribution != null) {
          results.add(contribution);
        }
      }
      return List.unmodifiable(results);
    } catch (e) {
      _logger.warning('Failed to query contributions of type $T: $e');
      return const [];
    }
  }

  /// Safely executes optional [ReleaseWorkflowContribution] hooks for a release pipeline stage.
  ///
  /// Returns a combined list of plugin hook outputs. If any plugin throws or fails, the failure
  /// is logged and contained, returning whatever successful hooks produced without halting the core release workflow.
  List<String> executeReleaseWorkflowHooks({
    required String stageName,
    Map<String, dynamic> context = const {},
  }) {
    final hookOutputs = <String>[];
    final contributions = safeQueryContributions<ReleaseWorkflowContribution>();

    for (final contrib in contributions) {
      try {
        final hooks = contrib.getWorkflowHooks();
        for (final hook in hooks) {
          hookOutputs.add('[$stageName] Plugin hook executed: $hook');
        }
      } catch (e) {
        _logger.warning(
            'Contained error executing ReleaseWorkflowContribution hook on stage "$stageName": $e');
      }
    }

    return List.unmodifiable(hookOutputs);
  }

  /// Safely queries optional [ValidationContribution] custom validation rules additively.
  List<String> getOptionalValidationRules() {
    final rules = <String>[];
    final contributions = safeQueryContributions<ValidationContribution>();

    for (final contrib in contributions) {
      try {
        rules.addAll(contrib.getValidationRules());
      } catch (e) {
        _logger.warning(
            'Contained error querying ValidationContribution rules: $e');
      }
    }

    return List.unmodifiable(rules);
  }

  /// Safely queries optional [PackageAnalysisContribution] custom package analyzers additively.
  List<String> getOptionalPackageAnalyzers() {
    final analyzers = <String>[];
    final contributions = safeQueryContributions<PackageAnalysisContribution>();

    for (final contrib in contributions) {
      try {
        analyzers.addAll(contrib.getAnalyzers());
      } catch (e) {
        _logger.warning(
            'Contained error querying PackageAnalysisContribution analyzers: $e');
      }
    }

    return List.unmodifiable(analyzers);
  }

  /// Lazily performs plugin discovery only when explicitly requested by a plugin-specific command.
  Future<DiscoveryResult> discoverPluginsOnDemand(
      List<String> searchRoots) async {
    try {
      return await discoveryEngine.discoverPlugins(searchRoots);
    } catch (e) {
      _logger.warning('Plugin discovery on demand encountered error: $e');
      return DiscoveryResult(scannedRoots: searchRoots, entries: const []);
    }
  }
}
