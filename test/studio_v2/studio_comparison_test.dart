import 'package:syntrix/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.14: Loader Comparison Laboratory Models', () {
    test('LoaderComparisonCandidate and LoaderComparisonSession JSON roundtrip',
        () {
      const candidateA = LoaderComparisonCandidate(
        loaderId: 'galaxy_orbit',
        displayName: 'Galaxy Orbit',
        category: 'Orbital',
        fps: 60.0,
        particleCount: 220,
        hasPhysics: true,
        hasShaders: true,
        renderPassMs: 4.2,
        supportedFeatures: ['Orbital Gravity', 'GPU Fragment Passes'],
      );

      const candidateB = LoaderComparisonCandidate(
        loaderId: 'wormhole_portal',
        displayName: 'Wormhole',
        category: 'Singularity',
        fps: 58.0,
        particleCount: 340,
        hasPhysics: true,
        hasShaders: true,
        renderPassMs: 5.6,
        supportedFeatures: ['Singularity Distortion', 'Event Horizon'],
      );

      final session = LoaderComparisonSession(
        sessionId: 'comp_test_01',
        primary: candidateA,
        secondary: candidateB,
        comparedAt: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      expect(session.fpsDelta, closeTo(-2.0, 0.01));
      expect(session.particleDelta, equals(120));
      expect(session.renderPassDeltaMs, closeTo(1.4, 0.01));

      final json = session.toJson();
      final restored = LoaderComparisonSession.fromJson(json);

      expect(restored.sessionId, equals('comp_test_01'));
      expect(restored.primary.displayName, equals('Galaxy Orbit'));
      expect(restored.secondary.displayName, equals('Wormhole'));
      expect(restored.secondary.particleCount, equals(340));
    });
  });

  group('Phase 10.14: Studio Comparison Engine Operations', () {
    test('Updates comparison candidates and generates session comparison data',
        () {
      final controller = StudioV2Controller();
      final compEngine = StudioComparisonEngine(controller: controller);

      expect(compEngine.primary.loaderId, equals('galaxy_orbit'));
      expect(compEngine.secondary.loaderId, equals('wormhole_portal'));

      // Update candidates
      compEngine.setPrimaryCandidate(const LoaderComparisonCandidate(
        loaderId: 'infinite_universe',
        displayName: 'Infinite Universe',
        fps: 60.0,
        particleCount: 200,
        hasPhysics: true,
        hasShaders: true,
      ));

      compEngine.setSecondaryCandidate(const LoaderComparisonCandidate(
        loaderId: 'pulsar_wave',
        displayName: 'Pulsar Wave',
        fps: 60.0,
        particleCount: 0,
        hasPhysics: false,
        hasShaders: false,
        renderPassMs: 1.5,
      ));

      final session = compEngine.createComparisonSession(
          sessionId: 'session_universe_vs_pulsar');
      expect(session.primary.displayName, equals('Infinite Universe'));
      expect(session.secondary.displayName, equals('Pulsar Wave'));
      expect(session.particleDelta, equals(-200));
    });
  });

  group('Phase 10.14: Studio Comparison Renderer', () {
    test(
        'Renders ASCII Side-by-Side Viewport, Markdown Matrix, and JSON session',
        () {
      final controller = StudioV2Controller();
      final compEngine = StudioComparisonEngine(controller: controller);

      final session = compEngine.createComparisonSession();

      // 1. ASCII Side-by-Side Wireframe
      final ascii = StudioComparisonRenderer.renderAsciiComparison(session);
      expect(ascii, contains('Galaxy Orbit'));
      expect(ascii, contains('Wormhole'));
      expect(ascii, contains('FPS:             60'));
      expect(ascii, contains('Particles:       220'));
      expect(ascii, contains('Particles:       340'));
      expect(ascii, contains('Physics:         Yes'));

      // 2. Markdown Matrix
      final markdown = StudioComparisonRenderer.renderMarkdownMatrix(session);
      expect(markdown, contains('# Loader Comparison Laboratory Report'));
      expect(markdown, contains('| **FPS Performance** |'));
      expect(markdown, contains('| **Active Particles** |'));
      expect(markdown, contains('## Supported Feature Matrix'));

      // 3. JSON
      final json = StudioComparisonRenderer.renderJson(session);
      expect(json, contains('"primary"'));
      expect(json, contains('"secondary"'));
      expect(json, contains('"deltas"'));
    });
  });
}
