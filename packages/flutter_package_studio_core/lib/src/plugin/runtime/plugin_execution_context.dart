import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_models.dart';
import 'package:flutter_package_studio_core/src/plugin/interface/plugin_contribution_interfaces.dart';
import 'package:flutter_package_studio_core/src/plugin/permission/plugin_contribution_proxies.dart';
import 'package:flutter_package_studio_core/src/plugin/permission/plugin_permission_gate.dart';

/// Context passed strictly per invocation to a plugin contribution method.
/// Scoped to the executing plugin with zero unrestricted backdoors to the core.
class PluginExecutionContext {
  final String pluginId;
  final PluginManifest manifest;
  final Map<String, dynamic> metadata;
  final PluginPermissionGate _permissionGate;
  final Object? _rawPluginInstance;

  PluginExecutionContext({
    required this.pluginId,
    required this.manifest,
    required PluginPermissionGate permissionGate,
    Map<String, dynamic>? metadata,
    Object? rawPluginInstance,
  })  : _permissionGate = permissionGate,
        _rawPluginInstance = rawPluginInstance,
        metadata = Map.unmodifiable(metadata ?? const {});

  /// Provides a checked proxy for [PackageAnalysisContribution].
  CheckedPackageAnalysisContribution? get analysisContribution {
    final inst = _rawPluginInstance;
    if (inst is PackageAnalysisContribution) {
      return CheckedPackageAnalysisContribution(
        delegate: inst,
        manifest: manifest,
        gate: _permissionGate,
      );
    }
    return null;
  }

  /// Provides a checked proxy for [ReleaseWorkflowContribution].
  CheckedReleaseWorkflowContribution? get releaseWorkflowContribution {
    final inst = _rawPluginInstance;
    if (inst is ReleaseWorkflowContribution) {
      return CheckedReleaseWorkflowContribution(
        delegate: inst,
        manifest: manifest,
        gate: _permissionGate,
      );
    }
    return null;
  }

  /// Provides a checked proxy for [CommandContribution].
  CheckedCommandContribution? get commandContribution {
    final inst = _rawPluginInstance;
    if (inst is CommandContribution) {
      return CheckedCommandContribution(
        delegate: inst,
        manifest: manifest,
        gate: _permissionGate,
      );
    }
    return null;
  }

  /// Provides a checked proxy for network operations.
  CheckedNetworkAccessProxy get networkProxy => CheckedNetworkAccessProxy(
        manifest: manifest,
        gate: _permissionGate,
      );

  /// Provides a checked proxy for [ServiceContribution].
  CheckedServiceContribution? get serviceContribution {
    final inst = _rawPluginInstance;
    if (inst is ServiceContribution) {
      return CheckedServiceContribution(
        delegate: inst,
        manifest: manifest,
        gate: _permissionGate,
      );
    }
    return null;
  }
}
