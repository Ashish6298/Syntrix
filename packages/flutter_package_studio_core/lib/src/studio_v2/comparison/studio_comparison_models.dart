/// Domain models and comparison matrices for Phase 10.14: Loader Comparison Laboratory.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_models.dart';

/// Single candidate profile inside the comparison laboratory.
class LoaderComparisonCandidate {
  final String loaderId;
  final String displayName;
  final String category;
  final double fps;
  final int particleCount;
  final bool hasPhysics;
  final bool hasShaders;
  final bool isInteractive;
  final double renderPassMs;
  final List<String> supportedFeatures;
  final StudioConfigurationDescriptor configuration;

  const LoaderComparisonCandidate({
    required this.loaderId,
    required this.displayName,
    this.category = 'Celestial',
    this.fps = 60.0,
    this.particleCount = 200,
    this.hasPhysics = true,
    this.hasShaders = true,
    this.isInteractive = true,
    this.renderPassMs = 4.5,
    this.supportedFeatures = const [],
    this.configuration = const StudioConfigurationDescriptor(),
  });

  Map<String, dynamic> toJson() => {
        'loader_id': loaderId,
        'display_name': displayName,
        'category': category,
        'fps': fps,
        'particle_count': particleCount,
        'has_physics': hasPhysics,
        'has_shaders': hasShaders,
        'is_interactive': isInteractive,
        'render_pass_ms': renderPassMs,
        'supported_features': supportedFeatures,
        'configuration': configuration.toJson(),
      };

  factory LoaderComparisonCandidate.fromJson(Map<String, dynamic> json) {
    return LoaderComparisonCandidate(
      loaderId: json['loader_id'] as String? ?? 'infinite_universe',
      displayName: json['display_name'] as String? ?? 'Infinite Universe',
      category: json['category'] as String? ?? 'Celestial',
      fps: (json['fps'] as num?)?.toDouble() ?? 60.0,
      particleCount: json['particle_count'] as int? ?? 200,
      hasPhysics: json['has_physics'] as bool? ?? true,
      hasShaders: json['has_shaders'] as bool? ?? true,
      isInteractive: json['is_interactive'] as bool? ?? true,
      renderPassMs: (json['render_pass_ms'] as num?)?.toDouble() ?? 4.5,
      supportedFeatures: (json['supported_features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      configuration: json['configuration'] != null
          ? StudioConfigurationDescriptor.fromJson(json['configuration'] as Map<String, dynamic>)
          : const StudioConfigurationDescriptor(),
    );
  }
}

/// Dual or multi-way side-by-side comparison session.
class LoaderComparisonSession {
  final String sessionId;
  final LoaderComparisonCandidate primary;
  final LoaderComparisonCandidate secondary;
  final DateTime comparedAt;

  double get fpsDelta => secondary.fps - primary.fps;
  int get particleDelta => secondary.particleCount - primary.particleCount;
  double get renderPassDeltaMs => secondary.renderPassMs - primary.renderPassMs;

  const LoaderComparisonSession({
    required this.sessionId,
    required this.primary,
    required this.secondary,
    required this.comparedAt,
  });

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'primary': primary.toJson(),
        'secondary': secondary.toJson(),
        'deltas': {
          'fps_delta': fpsDelta,
          'particle_delta': particleDelta,
          'render_pass_delta_ms': renderPassDeltaMs,
        },
        'compared_at': comparedAt.toIso8601String(),
      };

  factory LoaderComparisonSession.fromJson(Map<String, dynamic> json) {
    return LoaderComparisonSession(
      sessionId: json['session_id'] as String? ?? 'comp_default',
      primary: json['primary'] != null
          ? LoaderComparisonCandidate.fromJson(json['primary'] as Map<String, dynamic>)
          : const LoaderComparisonCandidate(loaderId: 'a', displayName: 'Loader A'),
      secondary: json['secondary'] != null
          ? LoaderComparisonCandidate.fromJson(json['secondary'] as Map<String, dynamic>)
          : const LoaderComparisonCandidate(loaderId: 'b', displayName: 'Loader B'),
      comparedAt: DateTime.parse(json['compared_at'] as String),
    );
  }
}
