import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_models.dart';
import 'package:flutter_package_studio_core/src/plugin/interface/plugin_contribution_interfaces.dart';

/// Authorization gate enforcing that plugin instances only access interface contribution points matching manifest capabilities.
class PluginCapabilityGate {
  /// Verifies exact bi-directional contract match between declared manifest capabilities and implemented interfaces.
  void authorizePluginCapabilities(
      PluginManifest manifest, Object pluginInstance) {
    final declaredCaps = manifest.capabilities;

    // Check 1: Implemented interfaces must be declared in manifest
    if (pluginInstance is CommandContribution &&
        !declaredCaps.contains(PluginCapability.commandContribution)) {
      throw PluginCapabilityException(
          'Capability Mismatch: Plugin "${manifest.id}" implements CommandContribution but did not declare "commandContribution" in manifest.');
    }
    if (pluginInstance is ServiceContribution &&
        !declaredCaps.contains(PluginCapability.serviceContribution)) {
      throw PluginCapabilityException(
          'Capability Mismatch: Plugin "${manifest.id}" implements ServiceContribution but did not declare "serviceContribution" in manifest.');
    }
    if (pluginInstance is ValidationContribution &&
        !declaredCaps.contains(PluginCapability.validationContribution)) {
      throw PluginCapabilityException(
          'Capability Mismatch: Plugin "${manifest.id}" implements ValidationContribution but did not declare "validationContribution" in manifest.');
    }
    if (pluginInstance is ReleaseWorkflowContribution &&
        !declaredCaps.contains(PluginCapability.releaseWorkflowContribution)) {
      throw PluginCapabilityException(
          'Capability Mismatch: Plugin "${manifest.id}" implements ReleaseWorkflowContribution but did not declare "releaseWorkflowContribution" in manifest.');
    }
    if (pluginInstance is PackageAnalysisContribution &&
        !declaredCaps.contains(PluginCapability.packageAnalysisContribution)) {
      throw PluginCapabilityException(
          'Capability Mismatch: Plugin "${manifest.id}" implements PackageAnalysisContribution but did not declare "packageAnalysisContribution" in manifest.');
    }
    if (pluginInstance is PluginLifecycleInterface &&
        !declaredCaps.contains(PluginCapability.lifecycleManagement)) {
      throw PluginCapabilityException(
          'Capability Mismatch: Plugin "${manifest.id}" implements PluginLifecycleInterface but did not declare "lifecycleManagement" in manifest.');
    }

    // Check 2: Declared capabilities must be implemented by plugin instance
    if (declaredCaps.contains(PluginCapability.commandContribution) &&
        pluginInstance is! CommandContribution) {
      throw PluginCapabilityException(
          'Contract Violation: Plugin "${manifest.id}" declared "commandContribution" in manifest but does not implement CommandContribution interface.');
    }
    if (declaredCaps.contains(PluginCapability.serviceContribution) &&
        pluginInstance is! ServiceContribution) {
      throw PluginCapabilityException(
          'Contract Violation: Plugin "${manifest.id}" declared "serviceContribution" in manifest but does not implement ServiceContribution interface.');
    }
    if (declaredCaps.contains(PluginCapability.validationContribution) &&
        pluginInstance is! ValidationContribution) {
      throw PluginCapabilityException(
          'Contract Violation: Plugin "${manifest.id}" declared "validationContribution" in manifest but does not implement ValidationContribution interface.');
    }
    if (declaredCaps.contains(PluginCapability.releaseWorkflowContribution) &&
        pluginInstance is! ReleaseWorkflowContribution) {
      throw PluginCapabilityException(
          'Contract Violation: Plugin "${manifest.id}" declared "releaseWorkflowContribution" in manifest but does not implement ReleaseWorkflowContribution interface.');
    }
    if (declaredCaps.contains(PluginCapability.packageAnalysisContribution) &&
        pluginInstance is! PackageAnalysisContribution) {
      throw PluginCapabilityException(
          'Contract Violation: Plugin "${manifest.id}" declared "packageAnalysisContribution" in manifest but does not implement PackageAnalysisContribution interface.');
    }
    if (declaredCaps.contains(PluginCapability.lifecycleManagement) &&
        pluginInstance is! PluginLifecycleInterface) {
      throw PluginCapabilityException(
          'Contract Violation: Plugin "${manifest.id}" declared "lifecycleManagement" in manifest but does not implement PluginLifecycleInterface interface.');
    }
  }
}
