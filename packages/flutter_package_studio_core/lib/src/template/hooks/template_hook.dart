/// Core TemplateHook abstract class and functional implementations.
library;

import 'dart:async';
import 'package:flutter_package_studio_core/src/template/hooks/hook_context.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_phase.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_policy.dart';
import 'package:flutter_package_studio_core/src/template/hooks/hook_result.dart';

/// Abstract base class representing a lifecycle hook for template generation.
abstract class TemplateHook {
  /// Unique identifier for this hook.
  String get id;

  /// Human-readable display name.
  String get name;

  /// List of lifecycle phases during which this hook can execute.
  List<TemplateHookPhase> get supportedPhases;

  /// Priority of hook execution (higher values execute first). Default is 0.
  int get priority => 0;

  /// Whether this hook is currently enabled.
  bool get enabled => true;

  /// Provenance identifier (e.g. source template or extension ID).
  String get provenance;

  /// List of hook IDs that must be executed prior to this hook.
  List<String> get dependencies => const [];

  /// Failure handling policy for this hook.
  TemplateHookPolicy get failurePolicy => TemplateHookPolicy.failFast;

  /// Executes hook logic within [context] and returns [TemplateHookResult].
  FutureOr<TemplateHookResult> execute(TemplateHookContext context);
}

/// Typed callback signature for functional hooks.
typedef HookHandler = FutureOr<TemplateHookResult> Function(
    TemplateHookContext context);

/// Functional implementation of [TemplateHook] taking a handler callback.
class FunctionalTemplateHook extends TemplateHook {
  @override
  final String id;

  @override
  final String name;

  @override
  final List<TemplateHookPhase> supportedPhases;

  @override
  final int priority;

  @override
  final bool enabled;

  @override
  final String provenance;

  @override
  final List<String> dependencies;

  @override
  final TemplateHookPolicy failurePolicy;

  final HookHandler _handler;

  /// Creates a [FunctionalTemplateHook].
  FunctionalTemplateHook({
    required this.id,
    required this.name,
    required this.supportedPhases,
    required this.provenance,
    required HookHandler handler,
    this.priority = 0,
    this.enabled = true,
    this.dependencies = const [],
    this.failurePolicy = TemplateHookPolicy.failFast,
  }) : _handler = handler;

  @override
  FutureOr<TemplateHookResult> execute(TemplateHookContext context) {
    return _handler(context);
  }
}
