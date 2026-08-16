import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('UnifiedTestingWorkflow Unit Tests', () {
    late UnifiedTestingWorkflow workflow;

    setUp(() {
      workflow = UnifiedTestingWorkflow();
    });

    test('Plans workflow execution and validates output directory safety', () {
      const options = WorkflowOptions(
          packageName: 'awesome_pkg', outputDir: 'doc/testing_workflow');
      final plan = workflow.planWorkflow(options);

      expect(plan.packageName, equals('awesome_pkg'));
      expect(plan.outputDir, equals('doc/testing_workflow'));
      expect(plan.stages.length, equals(11));
    });

    test('Executes workflow stages and produces passed report', () {
      const options = WorkflowOptions(packageName: 'awesome_pkg');
      final plan = workflow.planWorkflow(options);
      final result = workflow.executeWorkflow(plan);

      expect(result.packageName, equals('awesome_pkg'));
      expect(result.isSuccess, isTrue);
      expect(result.stages.length, equals(11));

      final md = result.toMarkdown();
      expect(md, contains('# Unified Testing Workflow Report: awesome_pkg'));
      expect(md, contains('PASSED ✓'));
    });

    test('Rejects absolute output directory paths', () {
      const options =
          WorkflowOptions(packageName: 'pkg', outputDir: '/etc/workflow');
      expect(() => workflow.planWorkflow(options),
          throwsA(isA<UnifiedTestingWorkflowException>()));
    });

    test('Rejects path traversal ".." in output directory', () {
      const options =
          WorkflowOptions(packageName: 'pkg', outputDir: '../workflow');
      expect(() => workflow.planWorkflow(options),
          throwsA(isA<UnifiedTestingWorkflowException>()));
    });
  });
}
