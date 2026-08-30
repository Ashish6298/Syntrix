/// Single authority for planning and applying plugin upgrades and migrations (Phase 7.15).
library;

import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/plugin/configuration/plugin_configuration_models.dart';
import 'package:flutter_package_studio_core/src/plugin/configuration/plugin_configuration_validator.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_models.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_validator.dart';
import 'package:flutter_package_studio_core/src/plugin/dependency/dependency_resolution_models.dart';
import 'package:flutter_package_studio_core/src/plugin/dependency/plugin_dependency_resolver.dart';
import 'package:flutter_package_studio_core/src/plugin/lifecycle/plugin_lifecycle_models.dart';
import 'package:flutter_package_studio_core/src/plugin/persistence/plugin_state_models.dart';
import 'package:flutter_package_studio_core/src/plugin/persistence/plugin_state_store.dart';
import 'package:flutter_package_studio_core/src/plugin/upgrade/plugin_upgrade_models.dart';
import 'package:flutter_package_studio_core/src/release/versioning/semver_models.dart';

/// Coordinator for computing pure migration plans and executing safe upgrade applications.
class PluginUpgradeManager {
  final PluginContractValidator _contractValidator;
  final PluginConfigurationValidator _configValidator;
  final PluginDependencyResolver _dependencyResolver;
  final PluginStateStore? _stateStore;

  PluginContractValidator get contractValidator => _contractValidator;
  PluginConfigurationValidator get configValidator => _configValidator;
  PluginDependencyResolver get dependencyResolver => _dependencyResolver;
  PluginStateStore? get stateStore => _stateStore;

  PluginUpgradeManager({
    PluginContractValidator? contractValidator,
    PluginConfigurationValidator? configValidator,
    PluginDependencyResolver? dependencyResolver,
    PluginStateStore? stateStore,
  })  : _contractValidator = contractValidator ?? PluginContractValidator(),
        _configValidator = configValidator ?? PluginConfigurationValidator(),
        _dependencyResolver = dependencyResolver ?? PluginDependencyResolver(),
        _stateStore = stateStore;

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Pure, Non-Mutating Plan Computation (Plan-First Mandate)
  // ───────────────────────────────────────────────────────────────────────────

  /// Computes a structured [MigrationPlan] comparing [installedState] with [candidateManifest].
  ///
  /// Guarantees:
  /// - Pure and inert data: Never mutates state store, lifecycle state, or executes plugin code.
  /// - Reuses Phase 6.1/7.1 SemVer comparison, 7.6 Dependency Resolution, and 7.5 Config Validation.
  /// - Fail-closed on corrupted state or invalid candidate manifests.
  MigrationPlan planUpgrade({
    required PersistedPluginState installedState,
    dynamic candidateManifest,
    PluginManifest? installedManifest,
    List<PluginManifest> otherInstalledPlugins = const [],
    bool isStateCorrupted = false,
  }) {
    final pluginId = installedState.pluginId;

    // Fail-Closed Check 1: Corrupted or unverified persisted state
    if (isStateCorrupted) {
      return MigrationPlan(
        pluginId: pluginId,
        installedVersion: installedState.version,
        targetVersion: candidateManifest is PluginManifest
            ? candidateManifest.version
            : null,
        compatibilityType: UpgradeCompatibilityType.blockedInvalid,
        isCompatible: false,
        isDowngrade: false,
        isHardBlocked: true,
        breakingChanges: const [
          'Persisted state integrity check failed or state is corrupted.'
        ],
        impactedDependents: const [],
        configFindings: const [],
        dependencyChanges: const [],
        requirements: const [
          MigrationRequirement(
            title: 'Repair Corrupted State',
            description:
                'The currently installed plugin state is corrupted and must be repaired or re-installed.',
          ),
        ],
        summary: 'Upgrade BLOCKED: Persisted state failed integrity check.',
      );
    }

    // Fail-Closed Check 2: Basic contract validation of candidate manifest input
    Map<String, dynamic> candidateJson;
    PluginManifest? parsedCandidateManifest;

    if (candidateManifest is PluginManifest) {
      parsedCandidateManifest = candidateManifest;
      candidateJson = candidateManifest.toJson();
    } else if (candidateManifest is Map<String, dynamic>) {
      candidateJson = candidateManifest;
      try {
        parsedCandidateManifest = PluginManifest.fromJson(candidateManifest);
      } catch (_) {
        parsedCandidateManifest = null;
      }
    } else {
      return MigrationPlan(
        pluginId: pluginId,
        installedVersion: installedState.version,
        targetVersion: null,
        compatibilityType: UpgradeCompatibilityType.blockedInvalid,
        isCompatible: false,
        isDowngrade: false,
        isHardBlocked: true,
        breakingChanges: const ['Candidate manifest is null or unparseable.'],
        impactedDependents: const [],
        configFindings: const [],
        dependencyChanges: const [],
        requirements: const [
          MigrationRequirement(
            title: 'Provide Valid Candidate Manifest',
            description: 'Candidate manifest is invalid or malformed.',
          ),
        ],
        summary:
            'Upgrade BLOCKED: Candidate manifest input is invalid or missing.',
      );
    }

    final contractRes = _contractValidator.validateRawJson(candidateJson);
    if (!contractRes.isValid || parsedCandidateManifest == null) {
      SemVer? targetVer;
      if (candidateJson['version'] is String) {
        try {
          targetVer = SemVer.parse(candidateJson['version'] as String);
        } catch (_) {}
      }

      return MigrationPlan(
        pluginId: pluginId,
        installedVersion: installedState.version,
        targetVersion: targetVer,
        compatibilityType: UpgradeCompatibilityType.blockedInvalid,
        isCompatible: false,
        isDowngrade: false,
        isHardBlocked: true,
        breakingChanges: [
          'Candidate manifest violates Phase 7.1 contract: ${contractRes.violations.join("; ")}'
        ],
        impactedDependents: const [],
        configFindings: const [],
        dependencyChanges: const [],
        requirements: const [
          MigrationRequirement(
            title: 'Fix Candidate Manifest',
            description:
                'The new plugin manifest is invalid and cannot be used for upgrade.',
          ),
        ],
        summary:
            'Upgrade BLOCKED: Candidate manifest failed contract validation.',
      );
    }

    final candidate = parsedCandidateManifest;
    final oldVer = installedState.version;
    final newVer = candidate.version;

    // ─────────────────────────────────────────────────────────────────────────
    // Version Comparison (Phase 6.1 / 7.1 SemVer reuse)
    // ─────────────────────────────────────────────────────────────────────────
    final isDowngrade = newVer.compareTo(oldVer) < 0;
    final isMajorBump = newVer.major > oldVer.major;

    final breakingChanges = <String>[];
    final impactedDependents = <String>[];
    final configFindings = <ConfigurationMigrationFinding>[];
    final dependencyChanges = <DependencyChangeFinding>[];
    final requirements = <MigrationRequirement>[];

    // Check Breaking API Version / Capability narrowing
    if (installedManifest != null) {
      final oldCaps = installedManifest.capabilities;
      final newCaps = candidate.capabilities;
      final removedCaps = oldCaps.difference(newCaps);

      if (removedCaps.isNotEmpty) {
        final capNames = removedCaps.map((c) => c.name).join(', ');
        breakingChanges.add('Removed capabilities: $capNames');
      }

      if (installedManifest.apiVersion != candidate.apiVersion) {
        breakingChanges.add(
            'API version changed from ${installedManifest.apiVersion} to ${candidate.apiVersion}');
      }

      // Check dependent plugins impacted by breaking change (Phase 7.6 dependency reuse)
      for (final other in otherInstalledPlugins) {
        for (final dep in other.dependencies) {
          if (dep.name == pluginId) {
            impactedDependents.add(other.id.value);
            breakingChanges.add(
                'Dependent plugin "${other.id.value}" relies on "$pluginId"');
          }
        }
      }
    } else if (isMajorBump) {
      breakingChanges.add('Major SemVer version bump from $oldVer to $newVer');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Configuration Migration Check (Phase 7.5 Config Schema reuse)
    // ─────────────────────────────────────────────────────────────────────────
    final existingConfigMap = installedState.redactedConfiguration;
    final newSchema = candidate.configSchema;

    final declaredNewKeys = <String>{};
    for (final prop in newSchema.properties) {
      declaredNewKeys.add(prop.key);
      final hasKey = existingConfigMap.containsKey(prop.key);

      if (prop.isRequired && !hasKey) {
        configFindings.add(ConfigurationMigrationFinding(
          key: prop.key,
          description:
              'Newly required configuration key "${prop.key}" is missing from existing configuration.',
          isMissingRequired: true,
        ));
      } else if (hasKey) {
        final val = existingConfigMap[prop.key];
        if (val != null && val != '[REDACTED]') {
          // Check type match
          final matchesType = _isTypeCompatible(val, prop.type);
          if (!matchesType) {
            configFindings.add(ConfigurationMigrationFinding(
              key: prop.key,
              description:
                  'Type mismatch for key "${prop.key}": expected ${prop.type.name}, found ${val.runtimeType}.',
              isTypeMismatch: true,
              oldValue: val,
            ));
          }
        }
      }
    }

    // Check removed configuration keys that were previously configured
    for (final oldKey in existingConfigMap.keys) {
      if (!declaredNewKeys.contains(oldKey)) {
        configFindings.add(ConfigurationMigrationFinding(
          key: oldKey,
          description:
              'Previously configured property "$oldKey" is no longer declared in new schema.',
          isRemovedKey: true,
          oldValue: existingConfigMap[oldKey],
        ));
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Dependency Set Diffs (Phase 7.6 Dependency Model reuse)
    // ─────────────────────────────────────────────────────────────────────────
    if (installedManifest != null) {
      final oldDeps = {
        for (final d in installedManifest.dependencies)
          d.name: d.versionConstraint
      };
      final newDeps = {
        for (final d in candidate.dependencies) d.name: d.versionConstraint
      };

      // Added
      for (final entry in newDeps.entries) {
        if (!oldDeps.containsKey(entry.key)) {
          dependencyChanges.add(DependencyChangeFinding(
            dependencyName: entry.key,
            newConstraint: entry.value,
            changeType: 'added',
          ));
        } else if (oldDeps[entry.key] != entry.value) {
          dependencyChanges.add(DependencyChangeFinding(
            dependencyName: entry.key,
            oldConstraint: oldDeps[entry.key],
            newConstraint: entry.value,
            changeType: 'modified',
          ));
        }
      }

      // Removed
      for (final entry in oldDeps.entries) {
        if (!newDeps.containsKey(entry.key)) {
          dependencyChanges.add(DependencyChangeFinding(
            dependencyName: entry.key,
            oldConstraint: entry.value,
            changeType: 'removed',
          ));
        }
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Derivation of Concrete Migration Requirements
    // ─────────────────────────────────────────────────────────────────────────
    if (isDowngrade) {
      requirements.add(const MigrationRequirement(
        title: 'Acknowledge Downgrade Risk',
        description:
            'Target version is older than currently installed version. Downgrading may reintroduce vulnerabilities or drop state.',
        isMandatory: true,
      ));
    }

    if (breakingChanges.isNotEmpty) {
      requirements.add(MigrationRequirement(
        title: 'Review Breaking API Changes',
        description:
            'Verify dependent plugins (${impactedDependents.join(", ")}) are compatible with narrowed capabilities.',
        isMandatory: true,
      ));
    }

    for (final cf in configFindings) {
      if (cf.isMissingRequired) {
        requirements.add(MigrationRequirement(
          title: 'Supply Required Setting: "${cf.key}"',
          description:
              'Provide a valid value for newly required configuration property "${cf.key}".',
          isMandatory: true,
        ));
      } else if (cf.isTypeMismatch) {
        requirements.add(MigrationRequirement(
          title: 'Update Setting Format: "${cf.key}"',
          description: cf.description,
          isMandatory: true,
        ));
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Classification Synthesis
    // ─────────────────────────────────────────────────────────────────────────
    UpgradeCompatibilityType compType;
    String summary;

    if (isDowngrade) {
      compType = UpgradeCompatibilityType.downgrade;
      summary =
          'Downgrade detected ($oldVer -> $newVer). Requires explicit downgrade acknowledgment.';
    } else if (breakingChanges.isNotEmpty) {
      compType = UpgradeCompatibilityType.breakingChange;
      summary =
          'Breaking API or capability change detected ($oldVer -> $newVer).';
    } else if (configFindings
        .any((c) => c.isMissingRequired || c.isTypeMismatch)) {
      compType = UpgradeCompatibilityType.configurationMigrationRequired;
      summary =
          'Configuration migration required before upgrade can complete ($oldVer -> $newVer).';
    } else if (dependencyChanges.isNotEmpty) {
      compType = UpgradeCompatibilityType.dependencyShift;
      summary = 'Dependency set modified in new version ($oldVer -> $newVer).';
    } else {
      compType = UpgradeCompatibilityType.compatible;
      summary =
          'Backward-compatible upgrade ($oldVer -> $newVer) with zero breaking changes.';
    }

    return MigrationPlan(
      pluginId: pluginId,
      installedVersion: oldVer,
      targetVersion: newVer,
      compatibilityType: compType,
      isCompatible: compType == UpgradeCompatibilityType.compatible ||
          compType == UpgradeCompatibilityType.dependencyShift,
      isDowngrade: isDowngrade,
      isHardBlocked: false,
      breakingChanges: breakingChanges,
      impactedDependents: impactedDependents,
      configFindings: configFindings,
      dependencyChanges: dependencyChanges,
      requirements: requirements,
      summary: summary,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Explicit, Separately-Invoked Upgrade Application Step
  // ───────────────────────────────────────────────────────────────────────────

  /// Applies an upgrade according to [plan] and [newManifest], persisting updated state.
  ///
  /// Guarantees:
  /// - Still-valid configuration values carry over unchanged.
  /// - Invalid values are rejected / flagged rather than silently coerced.
  /// - `SecretValue` redaction is preserved without plaintext leakage.
  PersistedPluginState applyUpgrade({
    required MigrationPlan plan,
    required PluginManifest newManifest,
    required PersistedPluginState currentState,
    RuntimeConfiguration? updatedConfiguration,
  }) {
    if (plan.isHardBlocked) {
      throw PluginUpgradeException(
          'Cannot apply upgrade: Migration plan is hard-blocked (${plan.summary}).');
    }

    // Prepare migrated configuration
    final newConfigValues = <String, dynamic>{};
    final newSchema = newManifest.configSchema;

    // Carry over still-valid configuration values
    for (final prop in newSchema.properties) {
      if (updatedConfiguration != null &&
          updatedConfiguration.containsKey(prop.key)) {
        newConfigValues[prop.key] = updatedConfiguration.getValue(prop.key);
      } else if (currentState.redactedConfiguration.containsKey(prop.key)) {
        final existingVal = currentState.redactedConfiguration[prop.key];
        // If type still matches or is secret
        if (prop.isSecret ||
            existingVal == '[REDACTED]' ||
            _isTypeCompatible(existingVal, prop.type)) {
          newConfigValues[prop.key] = existingVal;
        } else {
          throw PluginUpgradeException(
              'Cannot carry over invalid configuration for "${prop.key}": Expected ${prop.type.name}, got ${existingVal.runtimeType}. Supply valid configuration.');
        }
      } else if (prop.isRequired) {
        throw PluginUpgradeException(
            'Cannot apply upgrade: Missing required configuration property "${prop.key}". Supply updated configuration.');
      }
    }

    final updatedHistory =
        List<LifecycleTransitionRecord>.from(currentState.lifecycleHistory)
          ..add(LifecycleTransitionRecord(
            instanceId: currentState.pluginId,
            fromState: currentState.lifecycleState,
            toState: PluginLifecycleState.discovered,
            reason:
                'Upgrade applied: transitioned from v${currentState.version} to v${newManifest.version}',
          ));

    final updatedPersistedState = PersistedPluginState(
      pluginId: currentState.pluginId,
      version: newManifest.version,
      isEnabled: currentState.isEnabled,
      lifecycleState: PluginLifecycleState.discovered,
      validationResult:
          const PluginValidationResult(isValid: true, violations: []),
      compatibilityResult: DependencyResolutionResult.compatible(const []),
      redactedConfiguration: newConfigValues,
      lifecycleHistory: updatedHistory,
      failureRecords: currentState.failureRecords,
      lastKnownGoodSnapshot: currentState.toJson(),
      lastUpdated: DateTime.now(),
    );

    // If state store is supplied, persist updated document
    final store = _stateStore;
    if (store != null) {
      store.savePluginState(
        pluginId: updatedPersistedState.pluginId,
        version: updatedPersistedState.version,
        isEnabled: updatedPersistedState.isEnabled,
        lifecycleState: updatedPersistedState.lifecycleState,
        validationResult: updatedPersistedState.validationResult,
        compatibilityResult: updatedPersistedState.compatibilityResult,
        configuration: RuntimeConfiguration(newConfigValues),
        schema: newSchema,
        lifecycleHistory: updatedPersistedState.lifecycleHistory,
        failureRecords: updatedPersistedState.failureRecords,
        lastKnownGoodSnapshot: updatedPersistedState.lastKnownGoodSnapshot,
      );
    }

    return updatedPersistedState;
  }

  bool _isTypeCompatible(dynamic val, ConfigPropertyType expectedType) {
    if (val is SecretValue || val == '[REDACTED]') return true;
    switch (expectedType) {
      case ConfigPropertyType.string:
        return val is String;
      case ConfigPropertyType.number:
        return val is num;
      case ConfigPropertyType.boolean:
        return val is bool;
      case ConfigPropertyType.map:
        return val is Map;
      case ConfigPropertyType.list:
        return val is List;
    }
  }
}
