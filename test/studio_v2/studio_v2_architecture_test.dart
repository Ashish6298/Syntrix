import 'dart:io';
import 'package:syntrix/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.1: Studio v2 Architecture Foundation Models', () {
    test('StudioPanelDefinition serialization and deserialization', () {
      const panel = StudioPanelDefinition(
        panelId: 'panel_custom_inspector',
        title: 'Custom Inspector',
        area: StudioPanelArea.inspectorSidebar,
        defaultWidth: 350.0,
        defaultHeight: 200.0,
      );

      final json = panel.toJson();
      final restored = StudioPanelDefinition.fromJson(json);

      expect(restored.panelId, equals('panel_custom_inspector'));
      expect(restored.title, equals('Custom Inspector'));
      expect(restored.area, equals(StudioPanelArea.inspectorSidebar));
      expect(restored.defaultWidth, equals(350.0));
      expect(restored.isVisible, isTrue);
    });

    test('StudioConfigurationDescriptor copyWith and JSON roundtrip', () {
      const config = StudioConfigurationDescriptor(
        targetLoaderId: 'cosmic_nebula',
        selectedThemeId: 'solar_flare',
        animationSpeed: 1.5,
        particleCount: 500,
        isInteractive: true,
      );

      final modified = config.copyWith(
        animationSpeed: 2.0,
        scale: 1.25,
      );

      expect(modified.targetLoaderId, equals('cosmic_nebula'));
      expect(modified.animationSpeed, equals(2.0));
      expect(modified.scale, equals(1.25));
      expect(modified.particleCount, equals(500));

      final json = modified.toJson();
      final restored = StudioConfigurationDescriptor.fromJson(json);

      expect(restored.targetLoaderId, equals('cosmic_nebula'));
      expect(restored.selectedThemeId, equals('solar_flare'));
      expect(restored.animationSpeed, equals(2.0));
      expect(restored.particleCount, equals(500));
    });

    test('StudioV2State serialization and deserialization', () {
      final state = StudioV2State(
        workspaceId: 'ws_demo_01',
        workspaceName: 'Demo Workspace',
        currentSection: StudioNavigationSection.themeStudio,
        activeConfiguration: const StudioConfigurationDescriptor(
          targetLoaderId: 'galaxy_orbit',
          selectedThemeId: 'deep_space',
        ),
        favoriteLoaderIds: ['galaxy_orbit', 'cosmic_nebula'],
        isLivePreviewPaused: true,
        isDiagnosticsOverlayVisible: true,
        lastModifiedAt: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      final json = state.toJson();
      final restored = StudioV2State.fromJson(json);

      expect(restored.workspaceId, equals('ws_demo_01'));
      expect(
          restored.currentSection, equals(StudioNavigationSection.themeStudio));
      expect(
          restored.activeConfiguration.targetLoaderId, equals('galaxy_orbit'));
      expect(restored.favoriteLoaderIds.length, equals(2));
      expect(restored.isLivePreviewPaused, isTrue);
      expect(restored.isDiagnosticsOverlayVisible, isTrue);
    });
  });

  group('Phase 10.1: Studio v2 Controller & Registry Operations', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_studio_v2_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('Controller handles section navigation and updates listeners', () {
      final controller = StudioV2Controller();
      StudioV2State? notifiedState;

      controller.addListener((state) {
        notifiedState = state;
      });

      expect(controller.state.currentSection,
          equals(StudioNavigationSection.workspace));

      controller.navigateTo(StudioNavigationSection.explorer);
      expect(controller.state.currentSection,
          equals(StudioNavigationSection.explorer));
      expect(notifiedState, isNotNull);
      expect(notifiedState!.currentSection,
          equals(StudioNavigationSection.explorer));
    });

    test('Controller mutates configuration and triggers registered actions',
        () {
      final registry = StudioV2Registry();
      final controller = StudioV2Controller(registry: registry);

      // Mutate configuration
      controller.updateConfiguration((cfg) => cfg.copyWith(
            animationSpeed: 3.0,
            particleCount: 1000,
          ));

      expect(controller.state.activeConfiguration.animationSpeed, equals(3.0));
      expect(controller.state.activeConfiguration.particleCount, equals(1000));

      // Trigger reset action
      final executed = controller.triggerAction('action_reset_config');
      expect(executed, isTrue);
      expect(controller.state.activeConfiguration.animationSpeed, equals(1.0));
      expect(controller.state.activeConfiguration.particleCount, equals(200));

      // Toggle pause action
      controller.triggerAction('action_toggle_pause');
      expect(controller.state.isLivePreviewPaused, isTrue);

      // Toggle diagnostics action
      controller.triggerAction('action_toggle_diagnostics');
      expect(controller.state.isDiagnosticsOverlayVisible, isTrue);
    });

    test('Controller toggles favorite loaders', () {
      final controller = StudioV2Controller();

      controller.toggleFavoriteLoader('loader_galaxy');
      expect(controller.state.favoriteLoaderIds, contains('loader_galaxy'));

      controller.toggleFavoriteLoader('loader_galaxy');
      expect(
          controller.state.favoriteLoaderIds, isNot(contains('loader_galaxy')));
    });

    test(
        'Controller persists and restores workspace state via FileSystem driver',
        () async {
      final driver =
          FileSystemStudioPersistenceDriver(projectRoot: tempDir.path);
      final controller = StudioV2Controller(
        persistenceDriver: driver,
        initialState: StudioV2State(
          workspaceId: 'saved_ws_01',
          workspaceName: 'Persisted Workspace',
          currentSection: StudioNavigationSection.sceneBuilder,
          activeConfiguration: const StudioConfigurationDescriptor(
            targetLoaderId: 'cosmic_ring',
            animationSpeed: 2.5,
          ),
          lastModifiedAt: DateTime.now(),
        ),
      );

      // Save
      await controller.saveWorkspace();

      // Verify file exists
      final expectedFile =
          File('${tempDir.path}/.fps/studio_v2/saved_ws_01.json');
      expect(expectedFile.existsSync(), isTrue);

      // Create second controller and load
      final secondController = StudioV2Controller(persistenceDriver: driver);
      final loaded = await secondController.loadWorkspace('saved_ws_01');

      expect(loaded, isTrue);
      expect(secondController.state.workspaceId, equals('saved_ws_01'));
      expect(
          secondController.state.workspaceName, equals('Persisted Workspace'));
      expect(secondController.state.currentSection,
          equals(StudioNavigationSection.sceneBuilder));
      expect(secondController.state.activeConfiguration.targetLoaderId,
          equals('cosmic_ring'));
      expect(secondController.state.activeConfiguration.animationSpeed,
          equals(2.5));
    });
  });

  group('Phase 10.1: Studio v2 Multi-Format Renderer', () {
    test('Renders ASCII Shell layout, Markdown summary, and JSON schema', () {
      final state = StudioV2State(
        workspaceId: 'ws_ascii_test',
        workspaceName: 'Syntrix Studio Shell',
        currentSection: StudioNavigationSection.workspace,
        activeConfiguration: const StudioConfigurationDescriptor(
          targetLoaderId: 'infinite_universe',
          selectedThemeId: 'deep_space',
          animationSpeed: 1.2,
          particleCount: 250,
        ),
        registeredPanels: const [
          StudioPanelDefinition(
            panelId: 'panel_preview',
            title: 'Live Viewport',
            area: StudioPanelArea.previewViewport,
          ),
        ],
        lastModifiedAt: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      // 1. ASCII layout
      final ascii = StudioV2Renderer.renderAsciiLayout(state);
      expect(ascii, contains('Syntrix Studio v2 Shell'));
      expect(ascii, contains('Navigation Rail'));
      expect(ascii, contains('Live Viewport Preview'));
      expect(ascii, contains('Configuration Inspector'));
      expect(ascii, contains('infinite_universe'));

      // 2. Markdown
      final markdown = StudioV2Renderer.renderMarkdown(state);
      expect(markdown, contains('# Studio v2 Workspace Status'));
      expect(markdown, contains('**Workspace Name:** `Syntrix Studio Shell`'));
      expect(markdown, contains('`infinite_universe`'));
      expect(markdown, contains('Live Viewport'));

      // 3. JSON
      final json = StudioV2Renderer.renderJson(state);
      expect(json, contains('"workspace_id": "ws_ascii_test"'));
      expect(json, contains('"target_loader_id": "infinite_universe"'));
    });
  });
}
