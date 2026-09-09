/// Domain models and structured records for Plugin Upgrade & Migration (Phase 7.15).
library;

import 'package:syntrix/src/release/versioning/semver_models.dart';

/// Semantic classification of an upgrade or migration plan.
enum UpgradeCompatibilityType {
  /// Backward-compatible forward upgrade with zero breaking changes or migration hurdles.
  compatible,

  /// API version narrowing or capability removal that breaks consumers or interfaces.
  breakingChange,

  /// Configuration schema differences requiring manual or automated value migration.
  configurationMigrationRequired,

  /// Dependency set additions, removals, or constraint shifts.
  dependencyShift,

  /// Target version is older than installed version. High scrutiny.
  downgrade,

  /// Upgrade cannot proceed due to basic contract failure, corruption, or fatal incompatibility.
  blockedInvalid,
}

/// Structured finding for an individual configuration property difference or incompatibility.
class ConfigurationMigrationFinding {
  final String key;
  final String description;
  final bool isMissingRequired;
  final bool isTypeMismatch;
  final bool isRemovedKey;
  final dynamic oldValue;

  const ConfigurationMigrationFinding({
    required this.key,
    required this.description,
    this.isMissingRequired = false,
    this.isTypeMismatch = false,
    this.isRemovedKey = false,
    this.oldValue,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'description': description,
        'isMissingRequired': isMissingRequired,
        'isTypeMismatch': isTypeMismatch,
        'isRemovedKey': isRemovedKey,
        if (oldValue != null) 'oldValue': oldValue.toString(),
      };

  @override
  String toString() => '[$key] $description';
}

/// Difference in a declared plugin dependency between old and new manifest.
class DependencyChangeFinding {
  final String dependencyName;
  final String? oldConstraint;
  final String? newConstraint;
  final String changeType; // 'added', 'removed', 'modified'

  const DependencyChangeFinding({
    required this.dependencyName,
    this.oldConstraint,
    this.newConstraint,
    required this.changeType,
  });

  Map<String, dynamic> toJson() => {
        'dependencyName': dependencyName,
        if (oldConstraint != null) 'oldConstraint': oldConstraint,
        if (newConstraint != null) 'newConstraint': newConstraint,
        'changeType': changeType,
      };

  @override
  String toString() =>
      '$changeType: $dependencyName ($oldConstraint -> $newConstraint)';
}

/// Actionable migration requirement that must be acknowledged or addressed.
class MigrationRequirement {
  final String title;
  final String description;
  final bool isMandatory;

  const MigrationRequirement({
    required this.title,
    required this.description,
    this.isMandatory = true,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'isMandatory': isMandatory,
      };

  @override
  String toString() =>
      '[${isMandatory ? "MANDATORY" : "OPTIONAL"}] $title: $description';
}

/// Pure, immutable migration plan detailing the computed differences and requirements.
class MigrationPlan {
  final String pluginId;
  final SemVer installedVersion;
  final SemVer? targetVersion;
  final UpgradeCompatibilityType compatibilityType;
  final bool isCompatible;
  final bool isDowngrade;
  final bool isHardBlocked;
  final List<String> breakingChanges;
  final List<String> impactedDependents;
  final List<ConfigurationMigrationFinding> configFindings;
  final List<DependencyChangeFinding> dependencyChanges;
  final List<MigrationRequirement> requirements;
  final String summary;
  final DateTime computedAt;

  MigrationPlan({
    required this.pluginId,
    required this.installedVersion,
    this.targetVersion,
    required this.compatibilityType,
    required this.isCompatible,
    required this.isDowngrade,
    required this.isHardBlocked,
    required List<String> breakingChanges,
    required List<String> impactedDependents,
    required List<ConfigurationMigrationFinding> configFindings,
    required List<DependencyChangeFinding> dependencyChanges,
    required List<MigrationRequirement> requirements,
    required this.summary,
    DateTime? computedAt,
  })  : breakingChanges = List.unmodifiable(breakingChanges),
        impactedDependents = List.unmodifiable(impactedDependents),
        configFindings = List.unmodifiable(configFindings),
        dependencyChanges = List.unmodifiable(dependencyChanges),
        requirements = List.unmodifiable(requirements),
        computedAt = computedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'pluginId': pluginId,
        'installedVersion': installedVersion.toString(),
        if (targetVersion != null) 'targetVersion': targetVersion.toString(),
        'compatibilityType': compatibilityType.name,
        'isCompatible': isCompatible,
        'isDowngrade': isDowngrade,
        'isHardBlocked': isHardBlocked,
        'breakingChanges': breakingChanges,
        'impactedDependents': impactedDependents,
        'configFindings': configFindings.map((c) => c.toJson()).toList(),
        'dependencyChanges': dependencyChanges.map((d) => d.toJson()).toList(),
        'requirements': requirements.map((r) => r.toJson()).toList(),
        'summary': summary,
        'computedAt': computedAt.toIso8601String(),
      };
}
