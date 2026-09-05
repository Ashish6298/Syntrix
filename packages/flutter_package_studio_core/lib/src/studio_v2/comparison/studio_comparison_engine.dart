/// Central Loader Comparison Laboratory Engine for Phase 10.14.
library;

import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_controller.dart';
import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_models.dart';
import 'package:flutter_package_studio_core/src/studio_v2/comparison/studio_comparison_models.dart';

/// Central Comparison Engine allowing developers to benchmark and visually compare loaders side-by-side.
class StudioComparisonEngine {
  final Logger _logger = Logger('StudioComparisonEngine');
  final StudioV2Controller controller;

  LoaderComparisonCandidate _primary;
  LoaderComparisonCandidate _secondary;

  LoaderComparisonCandidate get primary => _primary;
  LoaderComparisonCandidate get secondary => _secondary;

  StudioComparisonEngine({required this.controller})
      : _primary = _createDefaultCandidate('galaxy_orbit', 'Galaxy Orbit', 60.0, 220, true, true, 4.2),
        _secondary = _createDefaultCandidate('wormhole_portal', 'Wormhole', 58.0, 340, true, true, 5.6);

  static LoaderComparisonCandidate _createDefaultCandidate(
    String id,
    String name,
    double fps,
    int particles,
    bool physics,
    bool shaders,
    double renderMs,
  ) {
    return LoaderComparisonCandidate(
      loaderId: id,
      displayName: name,
      fps: fps,
      particleCount: particles,
      hasPhysics: physics,
      hasShaders: shaders,
      isInteractive: true,
      renderPassMs: renderMs,
      supportedFeatures: const ['Continuous Orbit', 'Custom Gravitation', 'Depth Fog', 'GPU Shaders'],
      configuration: StudioConfigurationDescriptor(
        targetLoaderId: id,
        particleCount: particles,
        shadersEnabled: shaders,
      ),
    );
  }

  /// Update primary candidate in comparison laboratory.
  void setPrimaryCandidate(LoaderComparisonCandidate candidate) {
    _primary = candidate;
    _logger.info('Updated primary comparison candidate: ${candidate.displayName}');
  }

  /// Update secondary candidate in comparison laboratory.
  void setSecondaryCandidate(LoaderComparisonCandidate candidate) {
    _secondary = candidate;
    _logger.info('Updated secondary comparison candidate: ${candidate.displayName}');
  }

  /// Create comparison session from current primary and secondary candidates.
  LoaderComparisonSession createComparisonSession({String? sessionId}) {
    final session = LoaderComparisonSession(
      sessionId: sessionId ?? 'comp_${DateTime.now().millisecondsSinceEpoch}',
      primary: _primary,
      secondary: _secondary,
      comparedAt: DateTime.now(),
    );
    _logger.info('Generated loader comparison session: ${session.sessionId}');
    return session;
  }
}
