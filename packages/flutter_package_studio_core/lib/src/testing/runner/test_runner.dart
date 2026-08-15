import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/testing/runner/test_runner_models.dart';

/// Core service for planning and executing test suites in controlled isolation.
class TestRunner {
  final Logger _logger = Logger('TestRunner');

  /// Plans test execution without process spawning or disk mutations.
  TestExecutionPlan planTestExecution(TestExecutionOptions options) {
    _logger.info(
        'Planning test execution for "${options.packageName}" [profile: ${options.profile}]');

    if (options.packageName.trim().isEmpty) {
      throw TestExecutionException('Package name must not be empty.');
    }

    final cleanPkgName = ReadmeSanitizer.escapeText(options.packageName);
    final suites = <TestSuiteItem>[];

    if (options.profile == 'unit' || options.profile == 'all') {
      suites.add(TestSuiteItem(
        name: '${cleanPkgName}_api_test',
        type: 'unit',
        path: 'test/unit/${cleanPkgName}_api_test.dart',
      ));
    }

    if (options.profile == 'widget' || options.profile == 'all') {
      suites.add(TestSuiteItem(
        name: '${cleanPkgName}_widget_test',
        type: 'widget',
        path: 'test/widget/${cleanPkgName}_widget_test.dart',
      ));
    }

    if (options.profile == 'integration' || options.profile == 'all') {
      suites.add(TestSuiteItem(
        name: '${cleanPkgName}_integration_test',
        type: 'integration',
        path: 'test/integration/${cleanPkgName}_integration_test.dart',
      ));
    }

    return TestExecutionPlan(
      packageName: options.packageName,
      profile: options.profile,
      suites: List.unmodifiable(suites),
    );
  }

  /// Executes test suites defined in [plan] in controlled fake/simulated process environment.
  TestExecutionResult executeTests(
      TestExecutionPlan plan, TestExecutionOptions options) {
    _logger.info('Executing test suites for "${plan.packageName}"');

    final logs = <String>[];
    for (final suite in plan.suites) {
      logs.add('Executed suite ${suite.type}:${suite.name} -> PASSED');
    }

    return TestExecutionResult(
      packageName: plan.packageName,
      success: true,
      passedCount: plan.suites.length,
      failedCount: 0,
      logs: List.unmodifiable(logs),
    );
  }
}
