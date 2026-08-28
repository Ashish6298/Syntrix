/// Specific categories of plugin dependency and compatibility issues.
enum DependencyProblemType {
  missingDependency,
  versionConflict,
  circularDependency,
  unsupportedApiVersion,
  incompatiblePluginVersion,
  dependencyOrderingImpossible,
}

/// Single attributed dependency or compatibility finding.
class DependencyProblemFinding {
  final DependencyProblemType type;
  final String sourcePluginId;
  final String? targetPluginId;
  final String message;
  final String? details;

  const DependencyProblemFinding({
    required this.type,
    required this.sourcePluginId,
    this.targetPluginId,
    required this.message,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'sourcePluginId': sourcePluginId,
        if (targetPluginId != null) 'targetPluginId': targetPluginId,
        'message': message,
        if (details != null) 'details': details,
      };

  @override
  String toString() =>
      '[$type] ($sourcePluginId -> ${targetPluginId ?? "N/A"}): $message';
}

/// Aggregated result of dependency graph resolution and compatibility analysis.
class DependencyResolutionResult {
  final bool isCompatible;
  final List<String>? initializationOrder;
  final List<DependencyProblemFinding> findings;

  DependencyResolutionResult._({
    required this.isCompatible,
    this.initializationOrder,
    required this.findings,
  }) {
    // Fail-safe constraint: Blocked result MUST NEVER carry a partial initialization order.
    if (!isCompatible && initializationOrder != null) {
      throw ArgumentError(
          'Blocked DependencyResolutionResult must not contain a partial initialization order.');
    }
  }

  factory DependencyResolutionResult.compatible(List<String> order) {
    return DependencyResolutionResult._(
      isCompatible: true,
      initializationOrder: List.unmodifiable(order),
      findings: const [],
    );
  }

  factory DependencyResolutionResult.blocked(
      List<DependencyProblemFinding> findings) {
    return DependencyResolutionResult._(
      isCompatible: false,
      initializationOrder: null,
      findings: List.unmodifiable(findings),
    );
  }

  Map<String, dynamic> toJson() => {
        'isCompatible': isCompatible,
        if (initializationOrder != null)
          'initializationOrder': initializationOrder,
        'findings': findings.map((f) => f.toJson()).toList(),
      };
}
