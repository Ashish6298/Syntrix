/// Target Flutter widget class discovered for widget testing.
class WidgetTestTarget {
  final String name;
  final String widgetKind; // 'StatelessWidget', 'StatefulWidget'
  final String filePath;

  const WidgetTestTarget({
    required this.name,
    required this.widgetKind,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'widgetKind': widgetKind,
        'filePath': filePath,
      };
}

/// Individual widget test assertion or pump case.
class WidgetTestCase {
  final String description;
  final String body;
  final bool isTodo;

  const WidgetTestCase({
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

/// Group of related widget test cases for a widget target.
class WidgetTestGroup {
  final String name;
  final List<WidgetTestCase> cases;

  const WidgetTestGroup({
    required this.name,
    required this.cases,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'caseCount': cases.length,
        'cases': cases.map((c) => c.toJson()).toList(),
      };
}

/// Options configuring widget test generation.
class WidgetTestOptions {
  final String packageName;
  final String profile; // 'basic', 'standard', 'strict', 'release'

  const WidgetTestOptions({
    required this.packageName,
    this.profile = 'standard',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
      };
}

/// Preview plan of widget test generation.
class WidgetTestPlan {
  final String packageName;
  final String profile;
  final List<WidgetTestTarget> targets;

  const WidgetTestPlan({
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

/// Final result containing generated widget test file map (`path -> source`).
class WidgetTestResult {
  final String packageName;
  final Map<String, String> files;

  const WidgetTestResult({
    required this.packageName,
    required this.files,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'fileCount': files.length,
        'paths': files.keys.toList(),
      };
}
