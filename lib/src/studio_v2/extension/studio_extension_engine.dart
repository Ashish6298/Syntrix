/// Central Studio Extension Architecture Registry & Engine for Phase 10.18.
library;

import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/studio_v2/studio_v2_controller.dart';
import 'package:syntrix/src/studio_v2/extension/studio_extension_models.dart';
import 'package:syntrix/src/studio_v2/extension/studio_prebuilt_extensions.dart';

/// Central Extension Engine managing registration, discovery, initialization, and execution of extensions.
class StudioExtensionEngine {
  final Logger _logger = Logger('StudioExtensionEngine');
  final StudioV2Controller controller;

  final Map<String, StudioExtension> _registeredExtensions = {};
  final List<void Function(StudioExtension)> _onExtensionRegisteredListeners =
      [];

  Map<String, StudioExtension> get registeredExtensions =>
      Map.unmodifiable(_registeredExtensions);

  StudioExtensionEngine(
      {required this.controller, bool registerDefaults = true}) {
    if (registerDefaults) {
      registerDefaultExtensions();
    }
  }

  /// Register built-in default extensions (Shader Studio, AI Assistant, Timelines, Advanced Profiler).
  void registerDefaultExtensions() {
    registerExtension(ShaderStudioExtension());
    registerExtension(AIAssistantExtension());
    registerExtension(AnimationTimelineExtension());
    registerExtension(SceneTimelineExtension());
    registerExtension(AdvancedProfilerExtension());
  }

  /// Register a new Studio extension dynamically.
  Future<void> registerExtension(StudioExtension extension) async {
    _registeredExtensions[extension.extensionId] = extension;
    await extension.onInitialize(controller);
    _logger.info(
        'Registered Studio extension: "${extension.name}" (${extension.extensionId}) v${extension.version}');

    for (final l in _onExtensionRegisteredListeners) {
      l(extension);
    }
  }

  /// Unregister an existing extension.
  Future<void> unregisterExtension(String extensionId) async {
    final ext = _registeredExtensions.remove(extensionId);
    if (ext != null) {
      await ext.onDispose(controller);
      _logger.info('Unregistered Studio extension: "${ext.name}"');
    }
  }

  /// Query all available custom tools across active extensions.
  List<StudioTool> getAllTools() {
    return _registeredExtensions.values.expand((e) => e.tools).toList();
  }

  /// Query all available custom actions across active extensions.
  List<StudioAction> getAllActions() {
    return _registeredExtensions.values.expand((e) => e.actions).toList();
  }

  /// Query all available custom validators across active extensions.
  List<StudioValidatorExtension> getAllValidators() {
    return _registeredExtensions.values.expand((e) => e.validators).toList();
  }

  /// Query all available custom exporters across active extensions.
  List<StudioExporterExtension> getAllExporters() {
    return _registeredExtensions.values.expand((e) => e.exporters).toList();
  }

  /// Query all available custom inspectors across active extensions.
  List<StudioInspectorExtension> getAllInspectors() {
    return _registeredExtensions.values.expand((e) => e.inspectors).toList();
  }

  /// Execute an action by actionId.
  Future<bool> triggerAction(String actionId) async {
    for (final ext in _registeredExtensions.values) {
      for (final act in ext.actions) {
        if (act.actionId == actionId) {
          _logger.info('Triggering action: ${act.label} ($actionId)');
          await act.trigger(controller);
          return true;
        }
      }
    }
    _logger.warning('Action not found: $actionId');
    return false;
  }
}
