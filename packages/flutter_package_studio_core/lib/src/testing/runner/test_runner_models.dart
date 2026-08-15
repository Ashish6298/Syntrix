/// Options configuring test execution.
class TestExecutionOptions {
  final String packageName;
  final String profile; // 'unit', 'widget', 'integration', 'all'
  final int timeoutSeconds;

  const TestExecutionOptions({
    required this.packageName,
    this.profile = 'all',
    this.timeoutSeconds = 30,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'timeoutSeconds': timeoutSeconds,
      };
}

/// Discovered test suite ready for execution planning.
class TestSuiteItem {
  final String name;
  final String type; // 'unit', 'widget', 'integration'
  final String path;

  const TestSuiteItem({
    required this.name,
    required this.type,
    required this.path,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'path': path,
      };
}

/// Preview plan of test execution.
class TestExecutionPlan {
  final String packageName;
  final String profile;
  final List<TestSuiteItem> suites;

  const TestExecutionPlan({
    required this.packageName,
    required this.profile,
    required this.suites,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'suiteCount': suites.length,
        'suites': suites.map((s) => s.toJson()).toList(),
      };
}

/// Result of test execution.
class TestExecutionResult {
  final String packageName;
  final bool success;
  final int passedCount;
  final int failedCount;
  final List<String> logs;

  const TestExecutionResult({
    required this.packageName,
    required this.success,
    required this.passedCount,
    required this.failedCount,
    required this.logs,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'success': success,
        'passedCount': passedCount,
        'failedCount': failedCount,
        'logs': logs,
      };
}
