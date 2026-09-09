/// Domain models and interaction telemetry for Phase 10.15: Advanced Interaction Laboratory.
library;

/// Interactive gesture state enumeration.
enum InteractionGestureState {
  idle,
  touchDown,
  dragging,
  panning,
  scaling,
  rotating,
  touchUp,
  cancelled;

  String get id => name;

  String get label => name.toUpperCase();
}

/// 2D Vector representation for pointer coordinates and velocity.
class InteractionVector2D {
  final double x;
  final double y;

  const InteractionVector2D(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory InteractionVector2D.fromJson(Map<String, dynamic> json) {
    return InteractionVector2D(
      (json['x'] as num?)?.toDouble() ?? 0.0,
      (json['y'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() => '(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

/// Point-in-time telemetry snapshot from the Interaction Monitor.
class InteractionMonitorState {
  final String monitorId;
  final InteractionVector2D pointerPosition;
  final InteractionGestureState gestureState;
  final double scale;
  final double rotationRadians;
  final InteractionVector2D velocity;
  final bool isInteractionActive;
  final double simulatedInertia;
  final DateTime timestamp;

  double get rotationDegrees => rotationRadians * (180.0 / 3.141592653589793);

  const InteractionMonitorState({
    required this.monitorId,
    this.pointerPosition = const InteractionVector2D(0.0, 0.0),
    this.gestureState = InteractionGestureState.idle,
    this.scale = 1.0,
    this.rotationRadians = 0.0,
    this.velocity = const InteractionVector2D(0.0, 0.0),
    this.isInteractionActive = false,
    this.simulatedInertia = 0.0,
    required this.timestamp,
  });

  InteractionMonitorState copyWith({
    String? monitorId,
    InteractionVector2D? pointerPosition,
    InteractionGestureState? gestureState,
    double? scale,
    double? rotationRadians,
    InteractionVector2D? velocity,
    bool? isInteractionActive,
    double? simulatedInertia,
    DateTime? timestamp,
  }) {
    return InteractionMonitorState(
      monitorId: monitorId ?? this.monitorId,
      pointerPosition: pointerPosition ?? this.pointerPosition,
      gestureState: gestureState ?? this.gestureState,
      scale: scale ?? this.scale,
      rotationRadians: rotationRadians ?? this.rotationRadians,
      velocity: velocity ?? this.velocity,
      isInteractionActive: isInteractionActive ?? this.isInteractionActive,
      simulatedInertia: simulatedInertia ?? this.simulatedInertia,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'monitor_id': monitorId,
        'pointer_position': pointerPosition.toJson(),
        'gesture_state': gestureState.id,
        'scale': scale,
        'rotation_radians': rotationRadians,
        'rotation_degrees': rotationDegrees,
        'velocity': velocity.toJson(),
        'is_interaction_active': isInteractionActive,
        'simulated_inertia': simulatedInertia,
        'timestamp': timestamp.toIso8601String(),
      };

  factory InteractionMonitorState.fromJson(Map<String, dynamic> json) {
    return InteractionMonitorState(
      monitorId: json['monitor_id'] as String? ?? 'mon_default',
      pointerPosition: json['pointer_position'] != null
          ? InteractionVector2D.fromJson(
              json['pointer_position'] as Map<String, dynamic>)
          : const InteractionVector2D(0.0, 0.0),
      gestureState: InteractionGestureState.values.firstWhere(
        (g) => g.id == json['gesture_state'] || g.name == json['gesture_state'],
        orElse: () => InteractionGestureState.idle,
      ),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotationRadians: (json['rotation_radians'] as num?)?.toDouble() ?? 0.0,
      velocity: json['velocity'] != null
          ? InteractionVector2D.fromJson(
              json['velocity'] as Map<String, dynamic>)
          : const InteractionVector2D(0.0, 0.0),
      isInteractionActive: json['is_interaction_active'] as bool? ?? false,
      simulatedInertia: (json['simulated_inertia'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
