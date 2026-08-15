/// Central registry for registering and resolving template hooks.
library;

import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_phase.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_registration.dart';
import 'package:flutter_package_studio_core/src/template/hooks/template_hook.dart';

/// Registry holding registered hooks and providing deterministic resolution by phase.
class TemplateHookRegistry {
  final Map<String, TemplateHookRegistration> _registrations = {};
  int _counter = 0;

  /// Registers a new [TemplateHook].
  ///
  /// Throws [TemplateHookValidationException] if the hook ID is duplicate or invalid.
  void register(TemplateHook hook) {
    if (hook.id.trim().isEmpty) {
      throw TemplateHookValidationException(
          'Hook registration failed: Hook ID cannot be empty.');
    }
    if (_registrations.containsKey(hook.id)) {
      throw TemplateHookValidationException(
          'Hook registration failed: Duplicate hook ID "${hook.id}".');
    }
    if (hook.supportedPhases.isEmpty) {
      throw TemplateHookValidationException(
          'Hook registration failed: Hook "${hook.id}" must declare at least one supported lifecycle phase.');
    }

    _counter++;
    _registrations[hook.id] = TemplateHookRegistration(
      hook: hook,
      registrationIndex: _counter,
    );
  }

  /// Checks if a hook with [id] is registered.
  bool contains(String id) => _registrations.containsKey(id);

  /// Returns registration for [id] or `null`.
  TemplateHookRegistration? get(String id) => _registrations[id];

  /// Unregisters hook with [id].
  bool unregister(String id) => _registrations.remove(id) != null;

  /// Clears all registered hooks.
  void clear() {
    _registrations.clear();
    _counter = 0;
  }

  /// Returns list of all registered hooks.
  List<TemplateHookRegistration> listAll() {
    final list = _registrations.values.toList();
    list.sort((a, b) => a.registrationIndex.compareTo(b.registrationIndex));
    return List.unmodifiable(list);
  }

  /// Returns list of registered hooks for a specific [provenance] (template ID or extension ID).
  List<TemplateHookRegistration> listByProvenance(String provenance) {
    final list =
        _registrations.values.where((r) => r.provenance == provenance).toList();
    list.sort((a, b) => a.registrationIndex.compareTo(b.registrationIndex));
    return List.unmodifiable(list);
  }

  /// Resolves hooks for [phase] in deterministic execution order.
  ///
  /// Ordering rules:
  /// 1. Topological ordering based on [TemplateHook.dependencies].
  /// 2. Priority descending (higher priority runs first).
  /// 3. Registration index ascending (stable tie-breaker).
  ///
  /// Throws [TemplateHookDependencyException] if circular dependency is detected.
  List<TemplateHook> resolveHooksForPhase(TemplateHookPhase phase) {
    final eligible = _registrations.values
        .where((r) => r.hook.enabled && r.hook.supportedPhases.contains(phase))
        .toList();

    if (eligible.isEmpty) return const [];

    // Map for fast lookup of eligible registrations by ID
    final eligibleMap = <String, TemplateHookRegistration>{
      for (final reg in eligible) reg.id: reg
    };

    // Detect circular dependencies and compute graph dependencies
    final graph = <String, List<String>>{};
    for (final reg in eligible) {
      final deps = <String>[];
      for (final depId in reg.hook.dependencies) {
        if (eligibleMap.containsKey(depId)) {
          deps.add(depId);
        }
      }
      graph[reg.id] = deps;
    }

    _detectCircularDependencies(graph);

    // Sort deterministically:
    // Topological sort respecting priority & registration order as secondary sort criteria.
    final result = <TemplateHookRegistration>[];
    final visited = <String>{};

    // Sort candidates initially by priority DESC, then registration index ASC
    eligible.sort((a, b) {
      final pComp = b.hook.priority.compareTo(a.hook.priority);
      if (pComp != 0) return pComp;
      return a.registrationIndex.compareTo(b.registrationIndex);
    });

    void visit(TemplateHookRegistration reg) {
      if (visited.contains(reg.id)) return;

      for (final depId in graph[reg.id] ?? const []) {
        final depReg = eligibleMap[depId];
        if (depReg != null) {
          visit(depReg);
        }
      }

      visited.add(reg.id);
      result.add(reg);
    }

    for (final reg in eligible) {
      visit(reg);
    }

    return result.map((r) => r.hook).toList();
  }

  void _detectCircularDependencies(Map<String, List<String>> graph) {
    final visited = <String, int>{}; // 0 = unvisited, 1 = visiting, 2 = visited

    void dfs(String node, List<String> path) {
      visited[node] = 1;
      path.add(node);

      for (final neighbor in graph[node] ?? const []) {
        final state = visited[neighbor] ?? 0;
        if (state == 1) {
          final cyclePath = [...path, neighbor].join(' -> ');
          throw TemplateHookDependencyException(
            'Circular hook dependency detected: $cyclePath',
          );
        } else if (state == 0) {
          dfs(neighbor, path);
        }
      }

      visited[node] = 2;
      path.removeLast();
    }

    for (final node in graph.keys) {
      if ((visited[node] ?? 0) == 0) {
        dfs(node, []);
      }
    }
  }
}
