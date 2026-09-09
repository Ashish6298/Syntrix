import 'package:flutter_package_studio_core/src/studio_v2/studio_v2.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 10.20: Final Integration & Regression Testing Models', () {
    test(
        'SubsystemStageVerification and StudioFinalIntegrationReport JSON roundtrip',
        () {
      const verification = SubsystemStageVerification(
        stage: StudioSubsystemPipelineStage.coreEngine,
        status: TestExecutionStatus.passed,
        testsExecuted: 42,
        executionTimeMs: 150.0,
        verificationDetails: 'AST parser & state machine active',
      );

      final report = StudioFinalIntegrationReport(
        reportId: 'int_test_01',
        overallSuccess: true,
        totalTestsRun: 42,
        totalTestsPassed: 42,
        totalTestsFailed: 0,
        stageVerifications: [verification],
        testTypeBreakdown: {
          IntegrationTestType.unit: 20,
          IntegrationTestType.widget: 10,
          IntegrationTestType.integration: 12,
        },
        completedAt: DateTime.parse('2026-09-08T12:00:00Z'),
      );

      final json = report.toJson();
      final restored = StudioFinalIntegrationReport.fromJson(json);

      expect(restored.reportId, equals('int_test_01'));
      expect(restored.overallSuccess, isTrue);
      expect(restored.totalTestsRun, equals(42));
      expect(restored.totalTestsPassed, equals(42));
      expect(restored.totalTestsFailed, equals(0));
      expect(restored.stageVerifications.length, equals(1));
      expect(restored.stageVerifications.first.stage,
          equals(StudioSubsystemPipelineStage.coreEngine));
      expect(restored.testTypeBreakdown[IntegrationTestType.unit], equals(20));
    });
  });

  group('Phase 10.20: Studio Final Integration Engine Operations', () {
    test('Runs full multi-subsystem pipeline across all 9 stages cleanly', () {
      final controller = StudioV2Controller();
      final intEngine = StudioFinalIntegrationEngine(controller: controller);

      final report = intEngine.runCompleteIntegrationPipeline();

      expect(report.overallSuccess, isTrue);
      expect(report.stageVerifications.length, equals(9));

      final stages = report.stageVerifications.map((s) => s.stage).toSet();
      expect(stages, contains(StudioSubsystemPipelineStage.coreEngine));
      expect(stages, contains(StudioSubsystemPipelineStage.loaders));
      expect(stages, contains(StudioSubsystemPipelineStage.themes));
      expect(stages, contains(StudioSubsystemPipelineStage.particles));
      expect(stages, contains(StudioSubsystemPipelineStage.physics));
      expect(stages, contains(StudioSubsystemPipelineStage.shaders));
      expect(stages, contains(StudioSubsystemPipelineStage.interactions));
      expect(stages, contains(StudioSubsystemPipelineStage.diagnostics));
      expect(stages, contains(StudioSubsystemPipelineStage.studioV2));

      for (final stage in report.stageVerifications) {
        expect(stage.status, equals(TestExecutionStatus.passed));
        expect(stage.testsExecuted, greaterThan(0));
      }

      expect(report.totalTestsRun, greaterThan(250));
      expect(report.totalTestsPassed, equals(report.totalTestsRun));
      expect(report.totalTestsFailed, equals(0));

      expect(report.testTypeBreakdown.length, equals(9));
      expect(report.testTypeBreakdown.containsKey(IntegrationTestType.unit),
          isTrue);
      expect(report.testTypeBreakdown.containsKey(IntegrationTestType.widget),
          isTrue);
      expect(
          report.testTypeBreakdown.containsKey(IntegrationTestType.integration),
          isTrue);
      expect(
          report.testTypeBreakdown.containsKey(IntegrationTestType.rendering),
          isTrue);
      expect(report.testTypeBreakdown.containsKey(IntegrationTestType.state),
          isTrue);
      expect(report.testTypeBreakdown.containsKey(IntegrationTestType.export),
          isTrue);
      expect(
          report.testTypeBreakdown
              .containsKey(IntegrationTestType.configuration),
          isTrue);
      expect(
          report.testTypeBreakdown.containsKey(IntegrationTestType.performance),
          isTrue);
      expect(
          report.testTypeBreakdown.containsKey(IntegrationTestType.regression),
          isTrue);
    });
  });

  group('Phase 10.20: Studio Final Integration Renderer', () {
    test('Renders ASCII Pipeline Matrix, Markdown report, and JSON schema', () {
      final controller = StudioV2Controller();
      final intEngine = StudioFinalIntegrationEngine(controller: controller);

      final report = intEngine.runCompleteIntegrationPipeline();

      // 1. ASCII Pipeline Matrix
      final ascii =
          StudioFinalIntegrationRenderer.renderAsciiPipelineMatrix(report);
      expect(ascii, contains('Studio v2 Multi-Subsystem Integration Pipeline'));
      expect(ascii, contains('Core Engine'));
      expect(ascii, contains('Loaders'));
      expect(ascii, contains('Themes'));
      expect(ascii, contains('Particles'));
      expect(ascii, contains('Physics'));
      expect(ascii, contains('Shaders'));
      expect(ascii, contains('Interactions'));
      expect(ascii, contains('Diagnostics'));
      expect(ascii, contains('Studio v2'));
      expect(ascii, contains('Pipeline Status: ALL SUBSYSTEMS OPERATIONAL'));

      // 2. Markdown Report
      final markdown = StudioFinalIntegrationRenderer.renderMarkdown(report);
      expect(markdown,
          contains('# Studio v2 Final Integration & Regression Test Report'));
      expect(
          markdown, contains('**Pipeline Status:** `PASSED (100% Verified)`'));
      expect(markdown, contains('## Subsystem Verification Matrix'));
      expect(markdown, contains('## Test Suite Category Breakdown'));
      expect(markdown, contains('| **Unit Tests** |'));

      // 3. JSON
      final json = StudioFinalIntegrationRenderer.renderJson(report);
      expect(json, contains('"report_id"'));
      expect(json, contains('"overall_success": true'));
      expect(json, contains('"stage_verifications"'));
      expect(json, contains('"test_type_breakdown"'));
    });
  });
}
