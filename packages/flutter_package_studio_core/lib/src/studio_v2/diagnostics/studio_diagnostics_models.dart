/// Domain models and diagnostics health checks for Phase 10.9: Diagnostics & Performance Center.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/logging/logger.dart';

/// Diagnostics subsystem health status.
enum DiagnosticSubsystemStatus {
  healthy,
  warning,
  error,
  disabled;

  String get id => name;

  String get symbol {
    switch (this) {
      case DiagnosticSubsystemStatus.healthy:
        return '✓';
      case DiagnosticSubsystemStatus.warning:
        return '⚠';
      case DiagnosticSubsystemStatus.error:
        return '✗';
      case DiagnosticSubsystemStatus.disabled:
        return '—';
    }
  }
}

/// An individual subsystem diagnostic verification item.
class DiagnosticHealthItem {
  final String subsystem; // Rendering, Animation, Particles, Physics, Shaders, Memory
  final DiagnosticSubsystemStatus status;
  final String message;
  final Map<String, dynamic> details;

  const DiagnosticHealthItem({
    required this.subsystem,
    required this.status,
    this.message = 'Operational',
    this.details = const {},
  });

  Map<String, dynamic> toJson() => {
        'subsystem': subsystem,
        'status': status.id,
        'message': message,
        'details': details,
      };

  factory DiagnosticHealthItem.fromJson(Map<String, dynamic> json) {
    return DiagnosticHealthItem(
      subsystem: json['subsystem'] as String? ?? 'Unknown',
      status: DiagnosticSubsystemStatus.values.firstWhere(
        (s) => s.id == json['status'] || s.name == json['status'],
        orElse: () => DiagnosticSubsystemStatus.healthy,
      ),
      message: json['message'] as String? ?? 'Operational',
      details: (json['details'] as Map<String, dynamic>?) ?? const {},
    );
  }
}

/// Structured exception event captured by the diagnostics engine.
class DiagnosticExceptionEvent {
  final String eventId;
  final String error;
  final String? stackTrace;
  final String context;
  final DateTime timestamp;

  const DiagnosticExceptionEvent({
    required this.eventId,
    required this.error,
    this.stackTrace,
    required this.context,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'event_id': eventId,
        'error': error,
        'stack_trace': stackTrace,
        'context': context,
        'timestamp': timestamp.toIso8601String(),
      };

  factory DiagnosticExceptionEvent.fromJson(Map<String, dynamic> json) {
    return DiagnosticExceptionEvent(
      eventId: json['event_id'] as String? ?? 'err_unknown',
      error: json['error'] as String? ?? 'Unknown error',
      stackTrace: json['stack_trace'] as String?,
      context: json['context'] as String? ?? 'General',
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Comprehensive Diagnostics & Performance Dashboard Snapshot.
class DiagnosticsDashboardSnapshot {
  final String dashboardId;
  final List<DiagnosticHealthItem> healthItems;
  final double liveFps;
  final double liveFrameTimeMs;
  final int activeParticleCount;
  final double estimatedMemoryMb;
  final List<DiagnosticExceptionEvent> recentExceptions;
  final List<String> recentLogEntries;
  final DateTime capturedAt;

  const DiagnosticsDashboardSnapshot({
    required this.dashboardId,
    required this.healthItems,
    this.liveFps = 60.0,
    this.liveFrameTimeMs = 16.2,
    this.activeParticleCount = 320,
    this.estimatedMemoryMb = 42.5,
    this.recentExceptions = const [],
    this.recentLogEntries = const [],
    required this.capturedAt,
  });

  Map<String, dynamic> toJson() => {
        'dashboard_id': dashboardId,
        'health_items': healthItems.map((h) => h.toJson()).toList(),
        'live_fps': liveFps,
        'live_frame_time_ms': liveFrameTimeMs,
        'active_particle_count': activeParticleCount,
        'estimated_memory_mb': estimatedMemoryMb,
        'recent_exceptions': recentExceptions.map((e) => e.toJson()).toList(),
        'recent_log_entries': recentLogEntries,
        'captured_at': capturedAt.toIso8601String(),
      };

  factory DiagnosticsDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    return DiagnosticsDashboardSnapshot(
      dashboardId: json['dashboard_id'] as String? ?? 'dash_default',
      healthItems: (json['health_items'] as List<dynamic>?)
              ?.map((h) => DiagnosticHealthItem.fromJson(h as Map<String, dynamic>))
              .toList() ??
          const [],
      liveFps: (json['live_fps'] as num?)?.toDouble() ?? 60.0,
      liveFrameTimeMs: (json['live_frame_time_ms'] as num?)?.toDouble() ?? 16.2,
      activeParticleCount: json['active_particle_count'] as int? ?? 320,
      estimatedMemoryMb: (json['estimated_memory_mb'] as num?)?.toDouble() ?? 42.5,
      recentExceptions: (json['recent_exceptions'] as List<dynamic>?)
              ?.map((e) => DiagnosticExceptionEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recentLogEntries: (json['recent_log_entries'] as List<dynamic>?)
              ?.map((l) => l.toString())
              .toList() ??
          const [],
      capturedAt: DateTime.parse(json['captured_at'] as String),
    );
  }
}
