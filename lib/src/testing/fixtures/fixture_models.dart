/// Target data model discovered for test fixture generation.
class FixtureTarget {
  final String name;
  final String category; // 'model', 'config', 'widget'
  final String filePath;

  const FixtureTarget({
    required this.name,
    required this.category,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'filePath': filePath,
      };
}

/// Target service/dependency discovered for mock/stub generation.
class MockTarget {
  final String name;
  final String serviceKind; // 'service', 'client', 'repository'
  final String filePath;

  const MockTarget({
    required this.name,
    required this.serviceKind,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'serviceKind': serviceKind,
        'filePath': filePath,
      };
}

/// Options configuring test fixture and mock generation.
class FixtureOptions {
  final String packageName;
  final String profile; // 'basic', 'standard', 'strict', 'release'

  const FixtureOptions({
    required this.packageName,
    this.profile = 'standard',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
      };
}

/// Preview plan of test fixture generation.
class FixturePlan {
  final String packageName;
  final String profile;
  final List<FixtureTarget> fixtureTargets;
  final List<MockTarget> mockTargets;

  const FixturePlan({
    required this.packageName,
    required this.profile,
    required this.fixtureTargets,
    required this.mockTargets,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'fixtureCount': fixtureTargets.length,
        'mockCount': mockTargets.length,
        'fixtureTargets': fixtureTargets.map((f) => f.toJson()).toList(),
        'mockTargets': mockTargets.map((m) => m.toJson()).toList(),
      };
}

/// Final result containing generated fixture and mock file map (`path -> source`).
class FixtureResult {
  final String packageName;
  final Map<String, String> files;

  const FixtureResult({
    required this.packageName,
    required this.files,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'fileCount': files.length,
        'paths': files.keys.toList(),
      };
}
