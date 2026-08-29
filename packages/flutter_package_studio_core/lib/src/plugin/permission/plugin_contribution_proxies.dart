import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_models.dart';
import 'package:flutter_package_studio_core/src/plugin/interface/plugin_contribution_interfaces.dart';
import 'package:flutter_package_studio_core/src/plugin/permission/plugin_permission_gate.dart';
import 'package:flutter_package_studio_core/src/plugin/permission/plugin_permission_models.dart';

/// Checked permission proxy wrapping [PackageAnalysisContribution].
class CheckedPackageAnalysisContribution
    implements PackageAnalysisContribution {
  final PackageAnalysisContribution _delegate;
  final PluginManifest _manifest;
  final PluginPermissionGate _gate;

  CheckedPackageAnalysisContribution({
    required PackageAnalysisContribution delegate,
    required PluginManifest manifest,
    required PluginPermissionGate gate,
  })  : _delegate = delegate,
        _manifest = manifest,
        _gate = gate;

  @override
  List<String> getAnalyzers() {
    _gate.check(
      manifest: _manifest,
      permission: PluginPermission.packageRead,
      operationAttempted: 'PackageAnalysisContribution.getAnalyzers',
      throwOnDeny: true,
    );
    return _delegate.getAnalyzers();
  }
}

/// Checked permission proxy wrapping [ReleaseWorkflowContribution].
class CheckedReleaseWorkflowContribution
    implements ReleaseWorkflowContribution {
  final ReleaseWorkflowContribution _delegate;
  final PluginManifest _manifest;
  final PluginPermissionGate _gate;

  CheckedReleaseWorkflowContribution({
    required ReleaseWorkflowContribution delegate,
    required PluginManifest manifest,
    required PluginPermissionGate gate,
  })  : _delegate = delegate,
        _manifest = manifest,
        _gate = gate;

  @override
  List<String> getWorkflowHooks() {
    _gate.check(
      manifest: _manifest,
      permission: PluginPermission.gitAccess,
      operationAttempted: 'ReleaseWorkflowContribution.getWorkflowHooks',
      throwOnDeny: true,
    );
    return _delegate.getWorkflowHooks();
  }
}

/// Checked permission proxy wrapping [CommandContribution].
class CheckedCommandContribution implements CommandContribution {
  final CommandContribution _delegate;
  final PluginManifest _manifest;
  final PluginPermissionGate _gate;

  CheckedCommandContribution({
    required CommandContribution delegate,
    required PluginManifest manifest,
    required PluginPermissionGate gate,
  })  : _delegate = delegate,
        _manifest = manifest,
        _gate = gate;

  @override
  List<String> getCommands() {
    _gate.check(
      manifest: _manifest,
      permission: PluginPermission.cliCommandAdd,
      operationAttempted: 'CommandContribution.getCommands',
      throwOnDeny: true,
    );
    return _delegate.getCommands();
  }
}

/// Checked permission proxy wrapping network-reaching operations for plugins.
class CheckedNetworkAccessProxy {
  final PluginManifest _manifest;
  final PluginPermissionGate _gate;

  CheckedNetworkAccessProxy({
    required PluginManifest manifest,
    required PluginPermissionGate gate,
  })  : _manifest = manifest,
        _gate = gate;

  /// Performs a gated network request / external fetch operation.
  Future<T> executeNetworkCall<T>({
    required String uri,
    required Future<T> Function() action,
  }) async {
    _gate.check(
      manifest: _manifest,
      permission: PluginPermission.networkAccess,
      operationAttempted: 'NetworkAccess.executeCall($uri)',
      throwOnDeny: true,
    );
    return action();
  }
}

/// Checked permission proxy wrapping [ServiceContribution].
class CheckedServiceContribution implements ServiceContribution {
  final ServiceContribution _delegate;
  final PluginManifest _manifest;
  final PluginPermissionGate _gate;

  CheckedServiceContribution({
    required ServiceContribution delegate,
    required PluginManifest manifest,
    required PluginPermissionGate gate,
  })  : _delegate = delegate,
        _manifest = manifest,
        _gate = gate;

  @override
  List<String> getServices() {
    _gate.check(
      manifest: _manifest,
      permission: PluginPermission.networkAccess,
      operationAttempted: 'ServiceContribution.getServices',
      throwOnDeny: true,
    );
    return _delegate.getServices();
  }
}
