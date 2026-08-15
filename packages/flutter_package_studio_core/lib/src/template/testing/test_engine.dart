/// Execution engine for template testing framework.
library;

import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_finding.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_harness.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_registry.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_report.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_request.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_result.dart';
import 'package:flutter_package_studio_core/src/template/testing/test_status.dart';

/// Orchestrates execution of selected template tests.
class TemplateTestEngine {
  final TemplateTestRegistry registry;
  final Logger _logger = Logger('TemplateTestEngine');

  /// Creates a [TemplateTestEngine].
  TemplateTestEngine({
    TemplateTestRegistry? registry,
  }) : registry = registry ?? TemplateTestRegistry();

  /// Executes test suite against [request] using optional [harness].
  Future<TemplateTestReport> execute(
    TemplateTestRequest request, {
    TemplateTestHarness? harness,
  }) async {
    final stopwatch = Stopwatch()..start();
    final effectiveHarness = harness ?? TemplateTestHarness();

    _logger.info(
        'Executing template test framework for template: ${request.templateId} (profile: ${request.profile.name})');

    final tests = registry.listTestsForProfile(request.profile);
    final results = <TemplateTestResult>[];
    final allFindings = <TemplateTestFinding>[];

    var passedCount = 0;
    var failedCount = 0;
    var skippedCount = 0;

    for (final test in tests) {
      try {
        final result =
            await Future.sync(() => test.run(effectiveHarness, request));
        results.add(result);

        if (result.status == TemplateTestStatus.passed) {
          passedCount++;
        } else if (result.status == TemplateTestStatus.skipped) {
          skippedCount++;
        } else {
          failedCount++;
        }

        allFindings.addAll(result.findings);
      } catch (e, st) {
        failedCount++;
        _logger.error('Error executing test "${test.id}": $e', e, st);

        results.add(TemplateTestResult.failed(
          testId: test.id,
          testName: test.name,
          duration: Duration.zero,
          error: e.toString(),
        ));
      }
    }

    // Sort findings deterministically: Severity -> Test ID -> Message
    allFindings.sort((a, b) {
      final sevComp = b.severity.index.compareTo(a.severity.index);
      if (sevComp != 0) return sevComp;
      final testComp = a.testId.compareTo(b.testId);
      if (testComp != 0) return testComp;
      return a.message.compareTo(b.message);
    });

    final overallStatus =
        failedCount > 0 ? TemplateTestStatus.failed : TemplateTestStatus.passed;

    stopwatch.stop();

    return TemplateTestReport(
      templateId: request.templateId,
      version: request.version,
      profile: request.profile,
      status: overallStatus,
      results: results,
      findings: allFindings,
      passedCount: passedCount,
      failedCount: failedCount,
      skippedCount: skippedCount,
      totalDuration: stopwatch.elapsed,
    );
  }
}
