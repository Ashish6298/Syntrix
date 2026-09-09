/// Public API symbol target discovered for unit testing.
class UnitTestTarget {
  final String name;
  final String kind; // 'function', 'class', 'constructor', 'method'
  final String filePath;

  const UnitTestTarget({
    required this.name,
    required this.kind,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind,
        'filePath': filePath,
      };
}

/// Individual unit test assertion or placeholder case.
class TestCase {
  final String description;
  final String body;
  final bool isTodo;

  const TestCase({
    required this.description,
    required this.body,
    this.isTodo = false,
  });

  Map<String, dynamic> toJson() => {
        'description': description,
        'body': body,
        'isTodo': isTodo,
      };
}

/// Group of related unit test cases for a target.
class TestGroup {
  final String name;
  final List<TestCase> cases;

  const TestGroup({
    required this.name,
    required this.cases,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'caseCount': cases.length,
        'cases': cases.map((c) => c.toJson()).toList(),
      };
}

/// Options configuring unit test generation.
class UnitTestOptions {
  final String packageName;
  final String profile; // 'basic', 'standard', 'strict', 'release'

  const UnitTestOptions({
    required this.packageName,
    this.profile = 'standard',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
      };
}

/// Preview plan of unit test generation.
class UnitTestPlan {
  final String packageName;
  final String profile;
  final List<UnitTestTarget> targets;

  const UnitTestPlan({
    required this.packageName,
    required this.profile,
    required this.targets,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'targetCount': targets.length,
        'targets': targets.map((t) => t.toJson()).toList(),
      };
}

/// Final result containing generated unit test file map (`path -> source`).
class UnitTestResult {
  final String packageName;
  final Map<String, String> files;

  const UnitTestResult({
    required this.packageName,
    required this.files,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'fileCount': files.length,
        'paths': files.keys.toList(),
      };
}
