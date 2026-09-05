import 'package:flutter_package_studio_core/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.15: Interaction Laboratory Models', () {
    test('InteractionVector2D and InteractionMonitorState JSON roundtrip', () {
      final state = InteractionMonitorState(
        monitorId: 'mon_test_01',
        pointerPosition: const InteractionVector2D(120.5, 340.2),
        gestureState: InteractionGestureState.dragging,
        scale: 1.5,
        rotationRadians: 0.785398, // 45 deg
        velocity: const InteractionVector2D(15.2, -8.4),
        isInteractionActive: true,
        simulatedInertia: 0.85,
        timestamp: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      expect(state.rotationDegrees, closeTo(45.0, 0.1));

      final json = state.toJson();
      final restored = InteractionMonitorState.fromJson(json);

      expect(restored.monitorId, equals('mon_test_01'));
      expect(restored.pointerPosition.x, equals(120.5));
      expect(restored.pointerPosition.y, equals(340.2));
      expect(restored.gestureState, equals(InteractionGestureState.dragging));
      expect(restored.scale, equals(1.5));
      expect(restored.velocity.x, equals(15.2));
      expect(restored.isInteractionActive, isTrue);
    });
  });

  group('Phase 10.15: Studio Interaction Engine Operations', () {
    test('Handles touch down, drag, scale, and release transitions cleanly', () {
      final controller = StudioV2Controller();
      final interactionEngine = StudioInteractionEngine(controller: controller);

      InteractionMonitorState? notifiedState;
      interactionEngine.addListener((s) {
        notifiedState = s;
      });

      // 1. Touch Down
      interactionEngine.handleTouchDown(100.0, 200.0);
      expect(interactionEngine.state.gestureState, equals(InteractionGestureState.touchDown));
      expect(interactionEngine.state.isInteractionActive, isTrue);
      expect(interactionEngine.state.pointerPosition.x, equals(100.0));
      expect(notifiedState?.gestureState, equals(InteractionGestureState.touchDown));

      // 2. Drag
      interactionEngine.handleDrag(150.0, 260.0, vx: 50.0, vy: 60.0);
      expect(interactionEngine.state.gestureState, equals(InteractionGestureState.dragging));
      expect(interactionEngine.state.velocity.x, equals(50.0));

      // 3. Scale
      interactionEngine.handleScale(2.0, rotation: 1.5708); // 90 deg
      expect(interactionEngine.state.gestureState, equals(InteractionGestureState.scaling));
      expect(interactionEngine.state.scale, equals(2.0));
      expect(interactionEngine.state.rotationDegrees, closeTo(90.0, 0.1));

      // 4. Touch Up
      interactionEngine.handleTouchUp(inertia: 0.9);
      expect(interactionEngine.state.gestureState, equals(InteractionGestureState.touchUp));
      expect(interactionEngine.state.isInteractionActive, isFalse);
      expect(interactionEngine.state.simulatedInertia, equals(0.9));

      // 5. Reset
      interactionEngine.resetInteraction();
      expect(interactionEngine.state.gestureState, equals(InteractionGestureState.idle));
      expect(interactionEngine.state.scale, equals(1.0));
    });
  });

  group('Phase 10.15: Studio Interaction Renderer', () {
    test('Renders ASCII Interaction Monitor, Markdown Telemetry, and JSON state', () {
      final controller = StudioV2Controller();
      final interactionEngine = StudioInteractionEngine(controller: controller);

      interactionEngine.handleDrag(250.0, 180.0, vx: 22.0, vy: -14.0);
      final state = interactionEngine.state;

      // 1. ASCII Monitor Wireframe
      final ascii = StudioInteractionRenderer.renderAsciiMonitor(state);
      expect(ascii, contains('Interaction Monitor'));
      expect(ascii, contains('Pointer Position:'));
      expect(ascii, contains('Gesture State:      DRAGGING'));
      expect(ascii, contains('Scale:'));
      expect(ascii, contains('Active Interaction: YES'));

      // 2. Markdown Telemetry
      final markdown = StudioInteractionRenderer.renderMarkdown(state);
      expect(markdown, contains('# Advanced Interaction Laboratory Telemetry'));
      expect(markdown, contains('## Real-Time Gesture Telemetry'));
      expect(markdown, contains('| **Pointer Position** |'));
      expect(markdown, contains('| **Pointer Velocity** |'));

      // 3. JSON
      final json = StudioInteractionRenderer.renderJson(state);
      expect(json, contains('"monitor_id": "monitor_main"'));
      expect(json, contains('"gesture_state": "dragging"'));
    });
  });
}
