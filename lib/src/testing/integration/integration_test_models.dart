/// Integration test target representing a multi-component interaction.
class IntegrationTestTarget {
  final String name;
  final List<String> components;
  final String filePath;

  const IntegrationTestTarget({
    required this.name,
    required this.components,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'components': components,
        'filePath': filePath,
      };
}

/// Individual integration test scenario step or assertion.
class IntegrationScenario {
  final String title;
  final String body;
  final bool isTodo;

  const IntegrationScenario({
    required this.title,
    required this.body,
    this.isTodo = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'isTodo': isTodo,
      };
}

/// Options configuring integration test generation.
class IntegrationTestOptions {
  final String packageName;
  final String profile; // 'basic', 'standard', 'strict', 'release'

  const IntegrationTestOptions({
    required this.packageName,
    this.profile = 'standard',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
      };
}

/// Preview plan of integration test generation.
class IntegrationTestPlan {
  final String packageName;
  final String profile;
  final List<IntegrationTestTarget> targets;

  const IntegrationTestPlan({
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

/// Final result containing generated integration test file map (`path -> source`).
class IntegrationTestResult {
  final String packageName;
  final Map<String, String> files;

  const IntegrationTestResult({
    required this.packageName,
    required this.files,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'fileCount': files.length,
        'paths': files.keys.toList(),
      };
}
