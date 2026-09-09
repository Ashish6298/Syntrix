/// Central Advanced Interaction Laboratory Engine for Phase 10.15.
library;

import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/studio_v2/studio_v2_controller.dart';
import 'package:syntrix/src/studio_v2/interaction/studio_interaction_models.dart';

/// Central Interaction Engine managing real-time gesture telemetry, pointer mapping, and physics feedback.
class StudioInteractionEngine {
  final Logger _logger = Logger('StudioInteractionEngine');
  final StudioV2Controller controller;

  InteractionMonitorState _state;
  final List<void Function(InteractionMonitorState)> _listeners = [];

  InteractionMonitorState get state => _state;

  StudioInteractionEngine({required this.controller})
      : _state = InteractionMonitorState(
          monitorId: 'monitor_main',
          timestamp: DateTime.now(),
        );

  void addListener(void Function(InteractionMonitorState) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(InteractionMonitorState) listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final l in _listeners) {
      l(_state);
    }
  }

  /// Simulate or handle Touch Down event.
  void handleTouchDown(double x, double y) {
    _state = _state.copyWith(
      pointerPosition: InteractionVector2D(x, y),
      gestureState: InteractionGestureState.touchDown,
      isInteractionActive: true,
      timestamp: DateTime.now(),
    );
    _logger.info('Touch down at ($x, $y)');
    _notify();
  }

  /// Simulate or handle Drag / Pan movement.
  void handleDrag(double x, double y, {double vx = 0.0, double vy = 0.0}) {
    _state = _state.copyWith(
      pointerPosition: InteractionVector2D(x, y),
      gestureState: InteractionGestureState.dragging,
      velocity: InteractionVector2D(vx, vy),
      isInteractionActive: true,
      timestamp: DateTime.now(),
    );
    _notify();
  }

  /// Simulate or handle Scale / Pinch gesture.
  void handleScale(double scaleMultiplier, {double rotation = 0.0}) {
    _state = _state.copyWith(
      gestureState: InteractionGestureState.scaling,
      scale: scaleMultiplier,
      rotationRadians: rotation,
      isInteractionActive: true,
      timestamp: DateTime.now(),
    );
    _notify();
  }

  /// Simulate or handle Touch Up / Release.
  void handleTouchUp({double inertia = 0.5}) {
    _state = _state.copyWith(
      gestureState: InteractionGestureState.touchUp,
      isInteractionActive: false,
      simulatedInertia: inertia,
      timestamp: DateTime.now(),
    );
    _logger.info('Touch up with inertia $inertia');
    _notify();
  }

  /// Reset interaction monitor back to default idle state.
  void resetInteraction() {
    _state = InteractionMonitorState(
      monitorId: 'monitor_main',
      timestamp: DateTime.now(),
    );
    _logger.info('Reset interaction monitor to idle');
    _notify();
  }
}
