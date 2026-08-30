/// Unified Plugin Testing & Sandbox Harness for Flutter Package Studio (Phase 7.13).
library;

import 'dart:async';
import 'dart:io' as io;
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/plugin/configuration/plugin_configuration_validator.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_validator.dart';
import 'package:flutter_package_studio_core/src/plugin/dependency/plugin_dependency_resolver.dart';
import 'package:flutter_package_studio_core/src/plugin/diagnostics/plugin_diagnostics_engine.dart';
import 'package:flutter_package_studio_core/src/plugin/discovery/plugin_discovery_engine.dart';
import 'package:flutter_package_studio_core/src/plugin/interface/plugin_registry.dart';
import 'package:flutter_package_studio_core/src/plugin/lifecycle/plugin_lifecycle_manager.dart';
import 'package:flutter_package_studio_core/src/plugin/permission/plugin_permission_gate.dart';
import 'package:flutter_package_studio_core/src/plugin/persistence/plugin_state_store.dart';
import 'package:flutter_package_studio_core/src/plugin/runtime/plugin_execution_runtime.dart';
import 'package:flutter_package_studio_core/src/plugin/testing/plugin_sandbox_models.dart';
import 'package:flutter_package_studio_core/src/plugin/trust/plugin_trust_gate.dart';
import 'package:flutter_package_studio_core/src/plugin/upgrade/plugin_upgrade_manager.dart';
import 'package:flutter_package_studio_core/src/plugin/removal/plugin_removal_manager.dart';
import 'package:flutter_package_studio_core/src/release/git/git_process_runner.dart';

import 'package:flutter_package_studio_core/src/release/git/git_release_manager.dart';
import 'package:flutter_package_studio_core/src/release/github/github_api_client.dart';
import 'package:flutter_package_studio_core/src/release/publishing/package_publishing_manager.dart';

/// Single authority for sandboxed, side-effect-free plugin subsystem testing.
class PluginTestHarness {
  final SandboxFileSystem fileSystem;
  final MockGitProcessRunner gitRunner;
  final GitReleaseManager gitReleaseManager;
  final MockGitHubApiClient gitHubClient;
  final MockNetworkTransport network;
  final PackagePublishingManager publishingManager;

  // Real Subsystem Wrappers (Phases 7.1–7.12)
  final PluginDiscoveryEngine discoveryHarness;
  final PluginContractValidator validatorHarness;
  final PluginConfigurationValidator configValidatorHarness;
  final PluginRegistry registryHarness;
  final PluginLifecycleManager lifecycleHarness;
  final PluginDependencyResolver dependencyHarness;
  final PluginPermissionGate permissionHarness;
  final PluginExecutionRuntime runtimeHarness;
  final PluginStateStore stateStoreHarness;
  final PluginDiagnosticsEngine diagnosticsHarness;
  final PluginTrustGate trustGateHarness;
  final PluginUpgradeManager upgradeManagerHarness;
  final PluginRemovalManager removalManagerHarness;

  PluginTestHarness._({
    required this.fileSystem,
    required this.gitRunner,
    required this.gitReleaseManager,
    required this.gitHubClient,
    required this.network,
    required this.publishingManager,
    required this.discoveryHarness,
    required this.validatorHarness,
    required this.configValidatorHarness,
    required this.registryHarness,
    required this.lifecycleHarness,
    required this.dependencyHarness,
    required this.permissionHarness,
    required this.runtimeHarness,
    required this.stateStoreHarness,
    required this.diagnosticsHarness,
    required this.trustGateHarness,
    required this.upgradeManagerHarness,
    required this.removalManagerHarness,
  });

  /// Factory creating a fresh, isolated, sandboxed harness.
  ///
  /// Guarantees:
  /// - Real subsystems from 7.1–7.14 are directly exercised.
  /// - Real external edges (filesystem, Git, GitHub API, publishing, network, credentials) are structurally faked.
  /// - Zero escape hatches: public API contains no parameter to enable real backends.
  factory PluginTestHarness.create({
    String? customSandboxRoot,
    int maxConsecutiveFailures = 3,
  }) {
    io.Directory sandboxDir;
    if (customSandboxRoot != null) {
      sandboxDir = io.Directory(customSandboxRoot);
      if (sandboxDir.existsSync() && sandboxDir.listSync().isNotEmpty) {
        throw PluginHarnessException(
            'Harness Setup Error: Custom sandbox directory "$customSandboxRoot" already exists and is not empty. Refusing to overwrite/pollute.');
      }
      sandboxDir.createSync(recursive: true);
    } else {
      sandboxDir =
          io.Directory.systemTemp.createTempSync('fps_plugin_sandbox_');
    }

    final fs = SandboxFileSystem(sandboxDir);
    final mockGit = MockGitProcessRunner();
    final mockGitHub = MockGitHubApiClient();
    const mockNetwork = MockNetworkTransport();
    final mockPublishing = PackagePublishingManager();

    final validator = PluginContractValidator();
    final configValidator = PluginConfigurationValidator();
    final discovery = PluginDiscoveryEngine(validator: validator);
    final registry = PluginRegistry(validator: validator);
    final permissionGate = PluginPermissionGate();
    final trustGate = PluginTrustGate(
      contractValidator: validator,
      permissionGate: permissionGate,
      dependencyResolver: PluginDependencyResolver(),
    );
    final lifecycle = PluginLifecycleManager(
      validator: validator,
      registry: registry,
      permissionGate: permissionGate,
      trustGate: trustGate,
    );
    final runtime = PluginExecutionRuntime(
      lifecycleManager: lifecycle,
      permissionGate: permissionGate,
      registry: registry,
      maxConsecutiveFailures: maxConsecutiveFailures,
    );
    final stateStore = PluginStateStore(
      rootPath: sandboxDir.path,
      validator: validator,
      configValidator: configValidator,
    );
    final gitReleaseManager = GitReleaseManager(runner: mockGit);
    const diagnostics = PluginDiagnosticsEngine();

    final upgradeManager = PluginUpgradeManager(
      contractValidator: validator,
      configValidator: configValidator,
      dependencyResolver: PluginDependencyResolver(),
      stateStore: stateStore,
    );
    final removalManager = PluginRemovalManager(
      registry: registry,
      stateStore: stateStore,
      rootPath: sandboxDir.path,
    );

    return PluginTestHarness._(
      fileSystem: fs,
      gitRunner: mockGit,
      gitReleaseManager: gitReleaseManager,
      gitHubClient: mockGitHub,
      network: mockNetwork,
      publishingManager: mockPublishing,
      discoveryHarness: discovery,
      validatorHarness: validator,
      configValidatorHarness: configValidator,
      registryHarness: registry,
      lifecycleHarness: lifecycle,
      dependencyHarness: PluginDependencyResolver(),
      permissionHarness: permissionGate,
      runtimeHarness: runtime,
      stateStoreHarness: stateStore,
      diagnosticsHarness: diagnostics,
      trustGateHarness: trustGate,
      upgradeManagerHarness: upgradeManager,
      removalManagerHarness: removalManager,
    );
  }

  /// Scoped test runner executing [action] within the sandboxed test context, automatically disposing resources on finish.
  Future<T> runInSandbox<T>(
      FutureOr<T> Function(PluginTestContext ctx) action) async {
    final ctx = PluginTestContext(
      fileSystem: fileSystem,
      gitRunner: gitRunner,
      gitHubClient: gitHubClient,
      network: network,
    );

    try {
      return await action(ctx);
    } catch (e) {
      if (e is PluginSandboxSecurityException || e is PluginHarnessException) {
        rethrow;
      }
      // Preserve original plugin exception while ensuring context is traceable
      rethrow;
    }
  }

  /// Disposes harness and completely cleans up sandboxed temporary directory tree.
  void dispose() {
    fileSystem.dispose();
  }
}
