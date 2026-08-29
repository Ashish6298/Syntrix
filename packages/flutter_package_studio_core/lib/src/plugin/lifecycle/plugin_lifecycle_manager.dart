import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_models.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_validator.dart';
import 'package:flutter_package_studio_core/src/plugin/interface/plugin_registry.dart';
import 'package:flutter_package_studio_core/src/plugin/lifecycle/plugin_lifecycle_models.dart';

/// Single authority for tracking and transitioning plugin instances through the lifecycle state machine.
class PluginLifecycleManager {
  final Map<String, PluginInstanceRecord> _instances = {};
  final PluginContractValidator _validator;
  final PluginRegistry _registry;

  PluginLifecycleManager({
    PluginContractValidator? validator,
    PluginRegistry? registry,
  })  : _validator = validator ?? PluginContractValidator(),
        _registry = registry ?? PluginRegistry();

  /// Legal transition graph defining valid (fromState -> Set<toState>) pairs.
  static const Map<PluginLifecycleState, Set<PluginLifecycleState>>
      legalTransitions = {
    PluginLifecycleState.discovered: {
      PluginLifecycleState.validated,
      PluginLifecycleState.invalid,
      PluginLifecycleState.disabled,
    },
    PluginLifecycleState.validated: {
      PluginLifecycleState.registered,
      PluginLifecycleState.incompatible,
      PluginLifecycleState.invalid,
      PluginLifecycleState.disabled,
    },
    PluginLifecycleState.registered: {
      PluginLifecycleState.initialized,
      PluginLifecycleState.blocked,
      PluginLifecycleState.disabled,
    },
    PluginLifecycleState.initialized: {
      PluginLifecycleState.active,
      PluginLifecycleState.initializationFailed,
      PluginLifecycleState.disabled,
    },
    PluginLifecycleState.active: {
      PluginLifecycleState.stopping,
      PluginLifecycleState.disabled,
    },
    PluginLifecycleState.stopping: {
      PluginLifecycleState.inactive,
      PluginLifecycleState.shutdownFailed,
      PluginLifecycleState.disabled,
    },
    PluginLifecycleState.inactive: {
      PluginLifecycleState.initialized,
      PluginLifecycleState.disabled,
    },
    // Terminal failure states cannot transition directly to anything without explicit reattempt()
    PluginLifecycleState.invalid: {},
    PluginLifecycleState.incompatible: {},
    PluginLifecycleState.blocked: {},
    PluginLifecycleState.initializationFailed: {},
    PluginLifecycleState.shutdownFailed: {},
    PluginLifecycleState.disabled: {},
  };

  /// Terminal failure states set.
  static const Set<PluginLifecycleState> terminalFailureStates = {
    PluginLifecycleState.invalid,
    PluginLifecycleState.incompatible,
    PluginLifecycleState.blocked,
    PluginLifecycleState.initializationFailed,
    PluginLifecycleState.shutdownFailed,
    PluginLifecycleState.disabled,
  };

  /// Track a new plugin instance in `discovered` state.
  PluginInstanceRecord trackInstance({
    required String instanceId,
    required PluginManifest manifest,
    Object? instance,
  }) {
    if (_instances.containsKey(instanceId)) {
      throw PluginLifecycleException(
          'Plugin instance "$instanceId" is already tracked.');
    }
    final record = PluginInstanceRecord(
      instanceId: instanceId,
      manifest: manifest,
      instance: instance,
      state: PluginLifecycleState.discovered,
    );
    _instances[instanceId] = record;
    return record;
  }

  /// Get record for tracked instance.
  PluginInstanceRecord? getInstance(String instanceId) =>
      _instances[instanceId];

  /// Get complete audit transition history for a tracked instance.
  List<LifecycleTransitionRecord> getAuditHistory(String instanceId) {
    final record = _instances[instanceId];
    if (record == null) {
      throw PluginLifecycleException(
          'Untracked plugin instance "$instanceId".');
    }
    return List.unmodifiable(record.history);
  }

  /// Transition a tracked instance to a target state, enforcing the transition graph and invoking real subsystem gates.
  Future<PluginLifecycleState> transitionTo({
    required String instanceId,
    required PluginLifecycleState targetState,
    String reason = 'Normal lifecycle transition',
    Map<String, dynamic> context = const {},
  }) async {
    final record = _instances[instanceId];
    if (record == null) {
      throw PluginLifecycleException(
          'Untracked plugin instance "$instanceId".');
    }

    final currentState = record.state;

    // Check duplicate/redundant transition
    if (currentState == targetState) {
      throw PluginLifecycleException(
          'Redundant transition: Instance "$instanceId" is already in state "${targetState.name}".');
    }

    // Check legal transition graph
    final allowed = legalTransitions[currentState] ?? const {};
    if (!allowed.contains(targetState)) {
      final recordError = LifecycleTransitionRecord(
        instanceId: instanceId,
        fromState: currentState,
        toState: targetState,
        reason:
            'REJECTED: Illegal transition from ${currentState.name} to ${targetState.name}.',
      );
      record.history.add(recordError);
      throw PluginLifecycleException(
          'Illegal state transition for instance "$instanceId": Cannot jump from "${currentState.name}" directly to "${targetState.name}". Allowed target states: ${allowed.map((s) => s.name).join(", ")}.');
    }

    // Check terminal resurrection protection
    if (terminalFailureStates.contains(currentState)) {
      throw PluginLifecycleException(
          'Terminal state protection: Instance "$instanceId" is in terminal state "${currentState.name}" and cannot transition to "${targetState.name}". Call reattempt() first.');
    }

    // Delegate to real subsystem gates based on target state
    try {
      if (targetState == PluginLifecycleState.validated) {
        final valRes = _validator.validateRawJson(record.manifest.toJson());
        if (!valRes.isValid) {
          _applyTransition(record, PluginLifecycleState.invalid,
              'Contract validation failed: ${valRes.violations.join("; ")}');
          return PluginLifecycleState.invalid;
        }
      } else if (targetState == PluginLifecycleState.registered) {
        try {
          _registry.registerPlugin(
              manifest: record.manifest, instance: record.instance ?? Object());
        } catch (e) {
          _applyTransition(record, PluginLifecycleState.blocked,
              'Registry registration refused: $e');
          return PluginLifecycleState.blocked;
        }
      } else if (targetState == PluginLifecycleState.initialized) {
        if (record.lifecycleInterface != null) {
          try {
            await record.lifecycleInterface!.initialize(context);
          } catch (e) {
            _applyTransition(record, PluginLifecycleState.initializationFailed,
                'initialize() hook threw exception: $e');
            return PluginLifecycleState.initializationFailed;
          }
        }
      } else if (targetState == PluginLifecycleState.stopping) {
        if (record.lifecycleInterface != null) {
          try {
            await record.lifecycleInterface!.shutdown();
          } catch (e) {
            _applyTransition(record, PluginLifecycleState.stopping, reason);
            _applyTransition(record, PluginLifecycleState.shutdownFailed,
                'shutdown() hook threw exception: $e');
            return PluginLifecycleState.shutdownFailed;
          }
        }
        _applyTransition(record, PluginLifecycleState.stopping, reason);
        _applyTransition(record, PluginLifecycleState.inactive,
            'Clean shutdown complete: resources released.');
        return PluginLifecycleState.inactive;
      }

      _applyTransition(record, targetState, reason);
      return targetState;
    } catch (e) {
      if (e is PluginLifecycleException) rethrow;
      throw PluginLifecycleException(
          'Transition to "${targetState.name}" failed: $e');
    }
  }

  /// Explicitly re-attempt lifecycle sequence for a failed instance starting from `discovered`.
  Future<PluginLifecycleState> reattempt(String instanceId) async {
    final record = _instances[instanceId];
    if (record == null) {
      throw PluginLifecycleException(
          'Untracked plugin instance "$instanceId".');
    }

    final oldState = record.state;
    record.state = PluginLifecycleState.discovered;
    record.history.add(LifecycleTransitionRecord(
      instanceId: instanceId,
      fromState: oldState,
      toState: PluginLifecycleState.discovered,
      reason: 'Explicit re-attempt initiated from ${oldState.name}.',
    ));
    return PluginLifecycleState.discovered;
  }

  void _applyTransition(PluginInstanceRecord record,
      PluginLifecycleState newState, String reason) {
    final oldState = record.state;
    record.state = newState;
    record.history.add(LifecycleTransitionRecord(
      instanceId: record.instanceId,
      fromState: oldState,
      toState: newState,
      reason: reason,
    ));
  }
}
