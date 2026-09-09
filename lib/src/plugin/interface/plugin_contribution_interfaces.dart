/// Base lifecycle interface for Flutter Package Studio plugins.
abstract class PluginLifecycleInterface {
  /// Initializes the plugin with environment/core metadata. Must be idempotent-safe.
  Future<void> initialize(Map<String, dynamic> context);

  /// Shuts down the plugin cleanly. Safe to invoke even if initialize failed or partially completed.
  Future<void> shutdown();
}

/// Contribution point for plugins adding CLI commands.
abstract class CommandContribution {
  List<String> getCommands();
}

/// Contribution point for plugins providing reusable services.
abstract class ServiceContribution {
  List<String> getServices();
}

/// Contribution point for plugins adding validation rules.
abstract class ValidationContribution {
  List<String> getValidationRules();
}

/// Contribution point for plugins hooking into release pipeline workflows.
abstract class ReleaseWorkflowContribution {
  List<String> getWorkflowHooks();
}

/// Contribution point for plugins analyzing package contents.
abstract class PackageAnalysisContribution {
  List<String> getAnalyzers();
}
