import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_models.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_validator.dart';
import 'package:flutter_package_studio_core/src/plugin/dependency/dependency_resolution_models.dart';
import 'package:flutter_package_studio_core/src/release/versioning/semver_models.dart';

/// Dependency graph resolver computing ecosystem compatibility and deterministic topological initialization ordering.
class PluginDependencyResolver {
  /// Resolves a collection of discovered plugin manifests and produces a structured [DependencyResolutionResult].
  DependencyResolutionResult resolveDependencies(
      List<PluginManifest> manifests) {
    if (manifests.isEmpty) {
      return DependencyResolutionResult.compatible(const []);
    }

    final findings = <DependencyProblemFinding>[];
    final manifestMap = <String, PluginManifest>{};

    // Index manifests by plugin ID and check API version compatibility
    for (final manifest in manifests) {
      manifestMap[manifest.id.value] = manifest;

      // Check API version reuse from Phase 7.1/7.5
      if (!PluginContractValidator.supportedApiVersions
          .contains(manifest.apiVersion.trim())) {
        findings.add(DependencyProblemFinding(
          type: DependencyProblemType.unsupportedApiVersion,
          sourcePluginId: manifest.id.value,
          message:
              'Plugin "${manifest.id.value}" declares unsupported API version "${manifest.apiVersion}". Supported: ${PluginContractValidator.supportedApiVersions.join(", ")}.',
        ));
      }
    }

    // Build graph edges and validate dependency constraints
    final adjGraph = <String, List<String>>{};
    final inDegree = <String, int>{};

    for (final manifest in manifests) {
      final id = manifest.id.value;
      adjGraph.putIfAbsent(id, () => []);
      inDegree.putIfAbsent(id, () => 0);

      for (final dep in manifest.dependencies) {
        final targetId = dep.name;

        // Check 1: Self-dependency
        if (targetId == id) {
          findings.add(DependencyProblemFinding(
            type: DependencyProblemType.circularDependency,
            sourcePluginId: id,
            targetPluginId: targetId,
            message:
                'Self-referential dependency detected for plugin "$id". Cycle: $id -> $id',
            details: '$id -> $id',
          ));
          continue;
        }

        // Check 2: Missing dependency
        if (!manifestMap.containsKey(targetId)) {
          findings.add(DependencyProblemFinding(
            type: DependencyProblemType.missingDependency,
            sourcePluginId: id,
            targetPluginId: targetId,
            message: 'Plugin "$id" depends on missing plugin "$targetId".',
          ));
          continue;
        }

        final targetManifest = manifestMap[targetId]!;

        // Check 3: Version constraint check
        try {
          if (!_satisfiesConstraint(
              targetManifest.version, dep.versionConstraint)) {
            findings.add(DependencyProblemFinding(
              type: DependencyProblemType.incompatiblePluginVersion,
              sourcePluginId: id,
              targetPluginId: targetId,
              message:
                  'Plugin "$id" requires "$targetId" matching "${dep.versionConstraint}", but actual version is "${targetManifest.version}".',
            ));
          }
        } catch (e) {
          findings.add(DependencyProblemFinding(
            type: DependencyProblemType.versionConflict,
            sourcePluginId: id,
            targetPluginId: targetId,
            message:
                'Malformed version constraint "${dep.versionConstraint}" declared by "$id" for "$targetId": $e',
          ));
        }

        // Dependency edge: targetId must be initialized BEFORE id
        adjGraph.putIfAbsent(targetId, () => []).add(id);
        inDegree[id] = (inDegree[id] ?? 0) + 1;
      }
    }

    // Cycle detection check using DFS to extract exact cycle path strings
    final cycleFinding = _detectCyclesAndPath(manifests, manifestMap);
    if (cycleFinding != null) {
      findings.add(cycleFinding);
    }

    if (findings.isNotEmpty) {
      return DependencyResolutionResult.blocked(findings);
    }

    // Perform deterministic topological sort (Kahn's algorithm with tie-breaker by PluginId)
    final order = <String>[];
    final zeroInDegreeQueue = <String>[];

    inDegree.forEach((node, deg) {
      if (deg == 0) {
        zeroInDegreeQueue.add(node);
      }
    });

    zeroInDegreeQueue.sort(); // Deterministic tie-breaker

    while (zeroInDegreeQueue.isNotEmpty) {
      final current = zeroInDegreeQueue.removeAt(0);
      order.add(current);

      final neighbors = adjGraph[current] ?? const [];
      for (final neighbor in neighbors) {
        inDegree[neighbor] = (inDegree[neighbor] ?? 0) - 1;
        if (inDegree[neighbor] == 0) {
          zeroInDegreeQueue.add(neighbor);
        }
      }
      zeroInDegreeQueue
          .sort(); // Maintain deterministic sort order at every step
    }

    if (order.length != manifests.length) {
      return DependencyResolutionResult.blocked([
        DependencyProblemFinding(
          type: DependencyProblemType.dependencyOrderingImpossible,
          sourcePluginId: 'ECOSYSTEM',
          message:
              'A valid topological initialization order could not be produced for the plugin ecosystem (${order.length}/${manifests.length} ordered).',
        ),
      ]);
    }

    return DependencyResolutionResult.compatible(order);
  }

  DependencyProblemFinding? _detectCyclesAndPath(
      List<PluginManifest> manifests, Map<String, PluginManifest> manifestMap) {
    final visited = <String, int>{}; // 0 = unvisited, 1 = visiting, 2 = visited
    final path = <String>[];

    for (final manifest in manifests) {
      final startNode = manifest.id.value;
      if ((visited[startNode] ?? 0) == 0) {
        final cyclePath = _dfsCycle(startNode, manifestMap, visited, path);
        if (cyclePath != null) {
          final cycleStr = cyclePath.join(' -> ');
          return DependencyProblemFinding(
            type: DependencyProblemType.circularDependency,
            sourcePluginId: cyclePath.first,
            targetPluginId: cyclePath.last,
            message: 'Circular dependency cycle detected: $cycleStr',
            details: cycleStr,
          );
        }
      }
    }
    return null;
  }

  List<String>? _dfsCycle(String u, Map<String, PluginManifest> manifestMap,
      Map<String, int> visited, List<String> path) {
    visited[u] = 1;
    path.add(u);

    final manifest = manifestMap[u];
    if (manifest != null) {
      for (final dep in manifest.dependencies) {
        final v = dep.name;
        if (!manifestMap.containsKey(v)) continue;

        if (visited[v] == 1) {
          final startIndex = path.indexOf(v);
          final cycle = path.sublist(startIndex)..add(v);
          return cycle;
        } else if ((visited[v] ?? 0) == 0) {
          final res = _dfsCycle(v, manifestMap, visited, path);
          if (res != null) return res;
        }
      }
    }

    path.removeLast();
    visited[u] = 2;
    return null;
  }

  bool _satisfiesConstraint(SemVer actualVer, String constraintStr) {
    final clean = constraintStr.trim();
    if (clean == '*' || clean == 'any') return true;

    if (clean.startsWith('^')) {
      final target = SemVer.parse(clean.substring(1));
      return actualVer.major == target.major &&
          actualVer.compareTo(target) >= 0;
    } else if (clean.startsWith('>=')) {
      final target = SemVer.parse(clean.substring(2));
      return actualVer.compareTo(target) >= 0;
    } else if (clean.startsWith('=')) {
      final target = SemVer.parse(clean.substring(1));
      return actualVer == target;
    } else {
      final target = SemVer.parse(clean);
      return actualVer.compareTo(target) >= 0;
    }
  }
}
