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

/// Capability-indexed plugin registry exposing query surfaces and authorized lifecycle execution.
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

  /// Registers a validated manifest and plugin instance after contract and capability authorization.
  void registerPlugin({
    required PluginManifest manifest,
    required Object instance,
  }) {
    _logger.info('Attempting registration for plugin "${manifest.id}"');

    // Step 1: Contract Validation check
    final valResult = _validator.validateRawJson(manifest.toJson());
    if (!valResult.isValid) {
      throw PluginRegistrationException(
          'Registration refused for "${manifest.id}": Manifest failed contract validation (${valResult.violations.join("; ")}).');
    }

    // Step 2: Capability Gating check
    _gate.authorizePluginCapabilities(manifest, instance);

    // Step 3: Register
    _plugins[manifest.id.value] =
        RegisteredPlugin(manifest: manifest, instance: instance);
    _logger.info(
        'Successfully registered plugin "${manifest.id}" with capabilities: ${manifest.capabilities.map((c) => c.name).join(", ")}');
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

  /// Safely invokes lifecycle `initialize()` only for fully validated and registered plugins.
  Future<void> initializePlugin(
      String pluginId, Map<String, dynamic> context) async {
    final lifecycle = getContribution<PluginLifecycleInterface>(pluginId);
    if (lifecycle == null) {
      throw PluginRegistrationException(
          'Cannot initialize plugin "$pluginId": Plugin is not registered for lifecycleManagement capability.');
    }
    await lifecycle.initialize(context);
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
