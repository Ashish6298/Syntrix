import 'package:flutter_package_studio_core/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.9: Diagnostics & Performance Center Models', () {
    test(
        'DiagnosticHealthItem, ExceptionEvent, and DashboardSnapshot JSON roundtrip',
        () {
      final snapshot = DiagnosticsDashboardSnapshot(
        dashboardId: 'dash_test_01',
        healthItems: const [
          DiagnosticHealthItem(
            subsystem: 'Rendering',
            status: DiagnosticSubsystemStatus.healthy,
            message: 'All canvas passes clean',
          ),
          DiagnosticHealthItem(
            subsystem: 'Shaders',
            status: DiagnosticSubsystemStatus.disabled,
            message: 'Shaders not active',
          ),
        ],
        liveFps: 60.0,
        liveFrameTimeMs: 16.2,
        activeParticleCount: 320,
        estimatedMemoryMb: 45.2,
        recentExceptions: [
          DiagnosticExceptionEvent(
            eventId: 'exc_01',
            error: 'Simulated Shader Compilation Error',
            context: 'FragmentPass',
            timestamp: DateTime.parse('2026-09-05T12:00:00Z'),
          ),
        ],
        recentLogEntries: ['[INFO] Initialized diagnostics'],
        capturedAt: DateTime.parse('2026-09-05T12:00:00Z'),
      );

      final json = snapshot.toJson();
      final restored = DiagnosticsDashboardSnapshot.fromJson(json);

      expect(restored.dashboardId, equals('dash_test_01'));
      expect(restored.healthItems.length, equals(2));
      expect(restored.healthItems.first.status,
          equals(DiagnosticSubsystemStatus.healthy));
      expect(restored.healthItems.first.status.symbol, equals('✓'));
      expect(restored.liveFps, equals(60.0));
      expect(restored.recentExceptions.length, equals(1));
      expect(restored.recentExceptions.first.context, equals('FragmentPass'));
    });
  });

  group('Phase 10.9: Studio Diagnostics Engine Operations', () {
    test('Runs subsystem health check sweeps and logs runtime events', () {
      final controller = StudioV2Controller();
      final diagEngine = StudioDiagnosticsEngine(controller: controller);

      // Log & exception capture
      diagEngine.appendLog('Diagnostic sweep initiated');
      diagEngine.recordException(Exception('Simulated GPU Buffer OOM'),
          context: 'ParticleEngine');

      // Capture snapshot
      final snapshot = diagEngine.captureDashboardSnapshot(
        liveFps: 59.8,
        liveFrameTimeMs: 16.4,
        activeParticleCount: 350,
      );

      expect(snapshot.healthItems.length, equals(5));
      expect(
          snapshot.healthItems.any((h) => h.subsystem == 'Rendering'), isTrue);
      expect(
          snapshot.healthItems.any((h) => h.subsystem == 'Animation'), isTrue);
      expect(
          snapshot.healthItems.any((h) => h.subsystem == 'Particles'), isTrue);
      expect(snapshot.healthItems.any((h) => h.subsystem == 'Physics'), isTrue);
      expect(snapshot.healthItems.any((h) => h.subsystem == 'Shaders'), isTrue);

      expect(snapshot.recentExceptions.length, equals(1));
      expect(snapshot.recentLogEntries.length, equals(1));
    });
  });

  group('Phase 10.9: Studio Diagnostics Renderer', () {
    test('Renders ASCII Diagnostics Dashboard, Markdown Report, and JSON state',
        () {
      final controller = StudioV2Controller();
      final diagEngine = StudioDiagnosticsEngine(controller: controller);

      final snapshot = diagEngine.captureDashboardSnapshot();

      // 1. ASCII Dashboard
      final ascii = StudioDiagnosticsRenderer.renderAsciiDashboard(snapshot);
      expect(ascii, contains('DIAGNOSTICS & PERFORMANCE CENTER'));
      expect(ascii, contains('Rendering'));
      expect(ascii, contains('Performance Telemetry'));
      expect(ascii, contains('FPS:'));
      expect(ascii, contains('Frame Time:'));
      expect(ascii, contains('Particle Count:'));

      // 2. Markdown Report
      final markdown = StudioDiagnosticsRenderer.renderMarkdown(snapshot);
      expect(markdown, contains('# Diagnostics & Performance Center Report'));
      expect(markdown, contains('## Subsystem Health Checks'));
      expect(markdown, contains('## Telemetry Metrics'));

      // 3. JSON
      final json = StudioDiagnosticsRenderer.renderJson(snapshot);
      expect(json, contains('"dashboard_id"'));
      expect(json, contains('"health_items"'));
    });
  });
}
