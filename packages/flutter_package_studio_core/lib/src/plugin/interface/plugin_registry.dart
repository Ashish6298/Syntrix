import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_models.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_validator.dart';
import 'package:flutter_package_studio_core/src/plugin/interface/plugin_capability_gate.dart';
import 'package:flutter_package_studio_core/src/plugin/interface/plugin_contribution_interfaces.dart';

/// Registered plugin entry tracking manifest and implementation.
class RegisteredPlugin {
  final PluginManifest manifest;
  final Object instance;

  const RegisteredPlugin({
    required this.manifest,
    required this.instance,
  });
}

/// Central authoritative source of truth for all installed/known plugins in Flutter Package Studio.
/// Handles plugin identity, metadata inventory, duplicate-ID detection, capability querying,
/// unregistration, compatibility checking, and explicit activation.
class PluginRegistry {
  final Logger _logger = Logger('PluginRegistry');
  final PluginContractValidator _validator;
  final PluginCapabilityGate _gate;
  final Map<String, RegisteredPlugin> _plugins = {};

  PluginRegistry({
    PluginContractValidator? validator,
    PluginCapabilityGate? gate,
  })  : _validator = validator ?? PluginContractValidator(),
        _gate = gate ?? PluginCapabilityGate();

  /// Registers a validated manifest and plugin instance.
  /// Refuses registration if contract validation fails, capability gating fails, or ID is duplicate.
  /// NOTE: Registration DOES NOT activate the plugin or execute any plugin code.
  void registerPlugin({
    required PluginManifest manifest,
    required Object instance,
  }) {
    _registerInternal(manifest: manifest, instance: instance, isReplace: false);
  }

  /// Explicit replace/update operation for re-registering an already-occupied plugin ID.
  void updatePlugin({
    required PluginManifest manifest,
    required Object instance,
  }) {
    _registerInternal(manifest: manifest, instance: instance, isReplace: true);
  }

  void _registerInternal({
    required PluginManifest manifest,
    required Object instance,
    required bool isReplace,
  }) {
    final pluginId = manifest.id.value;
    _logger.info(
        'Attempting registration for plugin "$pluginId" (replace: $isReplace)');

    // Step 1: Duplicate ID check
    if (_plugins.containsKey(pluginId) && !isReplace) {
      throw PluginRegistrationException(
          'Duplicate Plugin ID: Plugin "$pluginId" is already registered. Use updatePlugin() explicitly to replace.');
    }

    // Step 2: Contract Validation check (Phase 7.1)
    final valResult = _validator.validateRawJson(manifest.toJson());
    if (!valResult.isValid) {
      throw PluginRegistrationException(
          'Registration refused for "$pluginId": Manifest failed contract validation (${valResult.violations.join("; ")}).');
    }

    // Step 3: Capability Gating check (Phase 7.2)
    _gate.authorizePluginCapabilities(manifest, instance);

    // Step 4: Register into inventory (Single source of truth reference)
    _plugins[pluginId] =
        RegisteredPlugin(manifest: manifest, instance: instance);
    _logger.info(
        'Successfully registered plugin "$pluginId" with capabilities: ${manifest.capabilities.map((c) => c.name).join(", ")}');
  }

  /// Unregisters a plugin by ID, removing it and all capability contribution entries cleanly.
  bool unregisterPlugin(String pluginId) {
    if (!_plugins.containsKey(pluginId)) {
      _logger.warning(
          'Unregistration ignored: Plugin "$pluginId" is not currently registered.');
      return false;
    }
    _plugins.remove(pluginId);
    _logger.info('Successfully unregistered plugin "$pluginId".');
    return true;
  }

  /// Checks whether a plugin with the given ID exists in the registry.
  bool exists(String pluginId) => _plugins.containsKey(pluginId);

  /// Finds and returns a registered plugin's metadata manifest by ID, or null if not found.
  PluginManifest? findPlugin(String pluginId) => _plugins[pluginId]?.manifest;

  /// Lists all registered plugin manifests in the inventory.
  List<PluginManifest> listPlugins() =>
      List.unmodifiable(_plugins.values.map((e) => e.manifest));

  /// Queries all registered plugin manifests that declared and authorized a specific capability.
  List<PluginManifest> queryPluginsByCapability(PluginCapability capability) {
    final matching = <PluginManifest>[];
    for (final entry in _plugins.values) {
      if (entry.manifest.capabilities.contains(capability)) {
        matching.add(entry.manifest);
      }
    }
    return List.unmodifiable(matching);
  }

  /// Checks if a registered plugin's compatibility constraints satisfy a required studio API version.
  bool checkCompatibility(String pluginId, String studioApiVersion) {
    final manifest = findPlugin(pluginId);
    if (manifest == null) return false;

    return manifest.compatibility.minApiVersion == studioApiVersion ||
        (manifest.compatibility.maxApiVersion != null &&
            manifest.compatibility.maxApiVersion == studioApiVersion);
  }

  /// Returns declared-and-implemented capability names for a given plugin ID matching roadmap tree-style structure.
  List<String> getProvidedCapabilities(String pluginId) {
    final entry = _plugins[pluginId];
    if (entry == null) {
      throw PluginRegistrationException(
          'Plugin "$pluginId" is not registered.');
    }
    final caps = entry.manifest.capabilities.map((c) => c.name).toList()
      ..sort();
    return List.unmodifiable(caps);
  }

  /// Retrieves plugin instance as a specific contribution interface type [T] strictly if declared and authorized.
  T? getContribution<T>(String pluginId) {
    final entry = _plugins[pluginId];
    if (entry == null) return null;

    final instance = entry.instance;
    final caps = entry.manifest.capabilities;

    if (T == CommandContribution &&
        caps.contains(PluginCapability.commandContribution) &&
        instance is CommandContribution) {
      return instance as T;
    }
    if (T == ServiceContribution &&
        caps.contains(PluginCapability.serviceContribution) &&
        instance is ServiceContribution) {
      return instance as T;
    }
    if (T == ValidationContribution &&
        caps.contains(PluginCapability.validationContribution) &&
        instance is ValidationContribution) {
      return instance as T;
    }
    if (T == ReleaseWorkflowContribution &&
        caps.contains(PluginCapability.releaseWorkflowContribution) &&
        instance is ReleaseWorkflowContribution) {
      return instance as T;
    }
    if (T == PackageAnalysisContribution &&
        caps.contains(PluginCapability.packageAnalysisContribution) &&
        instance is PackageAnalysisContribution) {
      return instance as T;
    }
    if (T == PluginLifecycleInterface &&
        caps.contains(PluginCapability.lifecycleManagement) &&
        instance is PluginLifecycleInterface) {
      return instance as T;
    }

    return null;
  }

  /// EXPLICIT ACTIVATION: Safely invokes lifecycle `initialize()` only when explicitly requested by caller.
  Future<void> activatePlugin(
      String pluginId, Map<String, dynamic> context) async {
    final lifecycle = getContribution<PluginLifecycleInterface>(pluginId);
    if (lifecycle == null) {
      throw PluginRegistrationException(
          'Cannot activate plugin "$pluginId": Plugin is not registered for lifecycleManagement capability.');
    }
    await lifecycle.initialize(context);
  }

  /// Deprecated alias for activatePlugin for backward compatibility with 7.2 calls.
  Future<void> initializePlugin(
      String pluginId, Map<String, dynamic> context) async {
    return activatePlugin(pluginId, context);
  }

  /// Safely invokes lifecycle `shutdown()` for registered plugins.
  Future<void> shutdownPlugin(String pluginId) async {
    final lifecycle = getContribution<PluginLifecycleInterface>(pluginId);
    if (lifecycle != null) {
      await lifecycle.shutdown();
    }
  }

  /// Returns unmodifiable map of all registered plugins.
  Map<String, RegisteredPlugin> get registeredPlugins =>
      Map.unmodifiable(_plugins);
}
