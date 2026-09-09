/// Configuration options for generating an isolated test project.
class TestProjectConfig {
  final String packageName;
  final String sdkConstraint;
  final bool isFlutterTest;

  const TestProjectConfig({
    required this.packageName,
    this.sdkConstraint = '>=3.0.0 <4.0.0',
    this.isFlutterTest = true,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'sdkConstraint': sdkConstraint,
        'isFlutterTest': isFlutterTest,
      };
}

/// Options for configuring Test Project Generation.
class TestProjectOptions {
  final String packageName;
  final String targetDir;
  final TestProjectConfig config;

  const TestProjectOptions({
    required this.packageName,
    this.targetDir = 'test_project',
    this.config = const TestProjectConfig(packageName: ''),
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'targetDir': targetDir,
        'config': config.toJson(),
      };
}

/// Preview plan of test project generation before rendering files.
class TestProjectPlan {
  final String packageName;
  final String targetDir;
  final List<String> relativeFilePaths;

  const TestProjectPlan({
    required this.packageName,
    required this.targetDir,
    required this.relativeFilePaths,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'targetDir': targetDir,
        'fileCount': relativeFilePaths.length,
        'relativeFilePaths': relativeFilePaths,
      };
}

/// Result of test project generation containing file map (`path -> content`).
class TestProjectResult {
  final String packageName;
  final Map<String, String> files;

  const TestProjectResult({
    required this.packageName,
    required this.files,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'fileCount': files.length,
        'paths': files.keys.toList(),
      };
}
