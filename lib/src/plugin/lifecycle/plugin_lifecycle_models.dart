import 'package:syntrix/src/plugin/contract/plugin_contract_models.dart';
import 'package:syntrix/src/plugin/interface/plugin_contribution_interfaces.dart';

/// Single audit record of a state transition for a plugin instance.
class LifecycleTransitionRecord {
  final String instanceId;
  final PluginLifecycleState fromState;
  final PluginLifecycleState toState;
  final DateTime timestamp;
  final String reason;

  LifecycleTransitionRecord({
    required this.instanceId,
    required this.fromState,
    required this.toState,
    required this.reason,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'instanceId': instanceId,
        'fromState': fromState.name,
        'toState': toState.name,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason,
      };

  @override
  String toString() =>
      '[$instanceId] ${fromState.name} -> ${toState.name} ($reason)';
}

/// Tracked state and history for a specific plugin instance.
class PluginInstanceRecord {
  final String instanceId;
  final PluginManifest manifest;
  final Object? instance;
  PluginLifecycleState state;
  final List<LifecycleTransitionRecord> history;

  PluginInstanceRecord({
    required this.instanceId,
    required this.manifest,
    this.instance,
    this.state = PluginLifecycleState.discovered,
    List<LifecycleTransitionRecord>? history,
  }) : history = history ?? [];

  PluginLifecycleInterface? get lifecycleInterface =>
      instance is PluginLifecycleInterface
          ? instance as PluginLifecycleInterface
          : null;

  Map<String, dynamic> toJson() => {
        'instanceId': instanceId,
        'pluginId': manifest.id.value,
        'version': manifest.version.toString(),
        'state': state.name,
        'history': history.map((h) => h.toJson()).toList(),
      };
}
