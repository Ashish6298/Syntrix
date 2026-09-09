/// State management, registry, actions, and persistence controller for Studio v2 Architecture.
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_models.dart';

/// Registry maintaining discoverable Studio v2 panels, tools, and actions.
class StudioV2Registry {
  final Map<String, StudioPanelDefinition> _panels = {};
  final Map<String, StudioActionDefinition> _actions = {};
  final Map<String, Function(StudioV2Controller)> _actionHandlers = {};

  List<StudioPanelDefinition> get panels => _panels.values.toList();
  List<StudioActionDefinition> get actions => _actions.values.toList();

  StudioV2Registry() {
    _registerDefaultPanels();
    _registerDefaultActions();
  }

  void _registerDefaultPanels() {
    registerPanel(const StudioPanelDefinition(
      panelId: 'panel_navigation',
      title: 'Navigation Rail',
      area: StudioPanelArea.navigationSidebar,
      defaultWidth: 260.0,
    ));

    registerPanel(const StudioPanelDefinition(
      panelId: 'panel_inspector',
      title: 'Configuration Inspector',
      area: StudioPanelArea.inspectorSidebar,
      defaultWidth: 340.0,
    ));

    registerPanel(const StudioPanelDefinition(
      panelId: 'panel_preview',
      title: 'Interactive Live Viewport',
      area: StudioPanelArea.previewViewport,
      defaultWidth: 800.0,
    ));

    registerPanel(const StudioPanelDefinition(
      panelId: 'panel_console',
      title: 'Diagnostics & Telemetry Console',
      area: StudioPanelArea.bottomConsole,
      defaultHeight: 180.0,
    ));
  }

  void _registerDefaultActions() {
    registerAction(
      const StudioActionDefinition(
        actionId: 'action_reset_config',
        label: 'Reset Configuration',
        shortcut: 'Ctrl+R',
        category: 'Configuration',
      ),
      handler: (controller) => controller.resetConfiguration(),
    );

    registerAction(
      const StudioActionDefinition(
        actionId: 'action_toggle_pause',
        label: 'Toggle Live Preview Pause',
        shortcut: 'Space',
        category: 'Playback',
      ),
      handler: (controller) => controller.toggleLivePreviewPause(),
    );

    registerAction(
      const StudioActionDefinition(
        actionId: 'action_toggle_diagnostics',
        label: 'Toggle Diagnostics Overlay',
        shortcut: 'Ctrl+D',
        category: 'Diagnostics',
      ),
      handler: (controller) => controller.toggleDiagnosticsOverlay(),
    );
  }

  void registerPanel(StudioPanelDefinition panel) {
    _panels[panel.panelId] = panel;
  }

  void registerAction(
    StudioActionDefinition action, {
    Function(StudioV2Controller)? handler,
  }) {
    _actions[action.actionId] = action;
    if (handler != null) {
      _actionHandlers[action.actionId] = handler;
    }
  }

  bool executeAction(String actionId, StudioV2Controller controller) {
    if (_actionHandlers.containsKey(actionId)) {
      _actionHandlers[actionId]!(controller);
      return true;
    }
    return false;
  }
}

/// Abstract storage driver for Studio v2 workspace persistence.
abstract class StudioPersistenceDriver {
  Future<void> save(String key, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> load(String key);
  Future<void> delete(String key);
}

/// Local file-system persistence driver storing workspace states under `.fps/studio_v2/`.
class FileSystemStudioPersistenceDriver implements StudioPersistenceDriver {
  final String _storageDirectory;

  FileSystemStudioPersistenceDriver({required String projectRoot})
      : _storageDirectory =
            p.join(p.normalize(projectRoot), '.fps', 'studio_v2');

  Directory get _dir => Directory(_storageDirectory);

  void _ensureDir() {
    if (!_dir.existsSync()) {
      _dir.createSync(recursive: true);
    }
  }

  File _file(String key) => File(p.join(_storageDirectory, '$key.json'));

  @override
  Future<void> save(String key, Map<String, dynamic> data) async {
    _ensureDir();
    final file = _file(key);
    final tempFile = File('${file.path}.tmp');
    const encoder = JsonEncoder.withIndent('  ');
    await tempFile.writeAsString(encoder.convert(data), flush: true);
    if (file.existsSync()) {
      file.deleteSync();
    }
    await tempFile.rename(file.path);
  }

  @override
  Future<Map<String, dynamic>?> load(String key) async {
    final file = _file(key);
    if (!file.existsSync()) return null;
    try {
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> delete(String key) async {
    final file = _file(key);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }
}

/// Central Controller coordinating Studio v2 navigation, state mutation, and persistence.
class StudioV2Controller {
  final Logger _logger = Logger('StudioV2Controller');
  final StudioV2Registry registry;
  final StudioPersistenceDriver persistenceDriver;

  StudioV2State _state;
  final List<void Function(StudioV2State)> _listeners = [];

  StudioV2State get state => _state;

  StudioV2Controller({
    StudioV2Registry? registry,
    StudioPersistenceDriver? persistenceDriver,
    StudioV2State? initialState,
  })  : registry = registry ?? StudioV2Registry(),
        persistenceDriver = persistenceDriver ??
            FileSystemStudioPersistenceDriver(
                projectRoot: Directory.current.path),
        _state = initialState ??
            StudioV2State(
              workspaceId: 'default_workspace',
              workspaceName: 'Syntrix Studio v2',
              lastModifiedAt: DateTime.now(),
            ) {
    // Populate default panels & actions from registry into state if empty
    if (_state.registeredPanels.isEmpty) {
      _state = _state.copyWith(
        registeredPanels: this.registry.panels,
        registeredActions: this.registry.actions,
      );
    }
  }

  void addListener(void Function(StudioV2State) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(StudioV2State) listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in _listeners) {
      listener(_state);
    }
  }

  /// Switch the active navigation section.
  void navigateTo(StudioNavigationSection section) {
    _state = _state.copyWith(
      currentSection: section,
      lastModifiedAt: DateTime.now(),
    );
    _logger.info('Navigated to section: ${section.label}');
    _notify();
  }

  /// Update loader / component preview configuration.
  void updateConfiguration(
      StudioConfigurationDescriptor Function(StudioConfigurationDescriptor)
          updater) {
    _state = _state.copyWith(
      activeConfiguration: updater(_state.activeConfiguration),
      lastModifiedAt: DateTime.now(),
    );
    _notify();
  }

  /// Reset configuration to initial defaults.
  void resetConfiguration() {
    _state = _state.copyWith(
      activeConfiguration: const StudioConfigurationDescriptor(),
      lastModifiedAt: DateTime.now(),
    );
    _logger.info('Configuration reset to defaults.');
    _notify();
  }

  /// Toggle pause/resume state of the live preview engine.
  void toggleLivePreviewPause() {
    _state = _state.copyWith(
      isLivePreviewPaused: !_state.isLivePreviewPaused,
      lastModifiedAt: DateTime.now(),
    );
    _notify();
  }

  /// Toggle visibility of the diagnostics overlay.
  void toggleDiagnosticsOverlay() {
    _state = _state.copyWith(
      isDiagnosticsOverlayVisible: !_state.isDiagnosticsOverlayVisible,
      lastModifiedAt: DateTime.now(),
    );
    _notify();
  }

  /// Toggle favorite status of a loader.
  void toggleFavoriteLoader(String loaderId) {
    final list = List<String>.from(_state.favoriteLoaderIds);
    if (list.contains(loaderId)) {
      list.remove(loaderId);
    } else {
      list.add(loaderId);
    }
    _state = _state.copyWith(
      favoriteLoaderIds: list,
      lastModifiedAt: DateTime.now(),
    );
    _notify();
  }

  /// Execute a registered Studio action.
  bool triggerAction(String actionId) {
    return registry.executeAction(actionId, this);
  }

  /// Persist current workspace state via storage driver.
  Future<void> saveWorkspace() async {
    await persistenceDriver.save(_state.workspaceId, _state.toJson());
    _logger.info('Saved workspace: ${_state.workspaceId}');
  }

  /// Restore workspace state from storage driver.
  Future<bool> loadWorkspace(String workspaceId) async {
    final data = await persistenceDriver.load(workspaceId);
    if (data != null) {
      _state = StudioV2State.fromJson(data);
      _notify();
      _logger.info('Loaded workspace: $workspaceId');
      return true;
    }
    return false;
  }
}
