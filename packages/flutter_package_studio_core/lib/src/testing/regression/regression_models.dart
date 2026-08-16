/// Status of a regression comparison case.
enum RegressionStatus {
  passed,
  regressed,
  improved,
  unchanged,
  skipped,
  notRun,
  unavailable,
  blocked,
  baselineMissing,
}

/// Severity level of a detected regression.
enum RegressionSeverity {
  low,
  medium,
  high,
  critical,
}

/// A single regression comparison test case.
class RegressionCase {
  final String id;
  final String name;
  final String expected;
  final String actual;
  final RegressionStatus status;
  final RegressionSeverity severity;

  const RegressionCase({
    required this.id,
    required this.name,
    required this.expected,
    required this.actual,
    required this.status,
    required this.severity,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'expected': expected,
        'actual': actual,
        'status': status.name,
        'severity': severity.name,
      };
}

/// Options configuring regression testing analysis.
class RegressionOptions {
  final String packageName;
  final String profile; // 'unit', 'widget', 'integration', 'all'
  final String baselinePath;

  const RegressionOptions({
    required this.packageName,
    this.profile = 'all',
    this.baselinePath = 'test/regression/baseline.json',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'baselinePath': baselinePath,
      };
}

/// Preview plan of regression testing.
class RegressionPlan {
  final String packageName;
  final String profile;
  final String baselinePath;

  const RegressionPlan({
    required this.packageName,
    required this.profile,
    required this.baselinePath,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'baselinePath': baselinePath,
      };
}

/// Evaluated regression check result.
class RegressionResult {
  final String packageName;
  final bool hasRegressions;
  final List<RegressionCase> cases;

  const RegressionResult({
    required this.packageName,
    required this.hasRegressions,
    required this.cases,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Regression Testing Report: $packageName');
    buf.writeln();
    buf.writeln(
        '**Overall Assessment**: ${hasRegressions ? "REGRESSION DETECTED ✗" : "NO REGRESSION ✓"}');
    buf.writeln();
    buf.writeln(
        '| Case ID | Test Target | Expected | Actual | Status | Severity |');
    buf.writeln('|---|---|---|---|---|---|');
    for (final c in cases) {
      buf.writeln(
          '| ${c.id} | ${c.name} | ${c.expected} | ${c.actual} | ${c.status.name.toUpperCase()} | ${c.severity.name.toUpperCase()} |');
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'hasRegressions': hasRegressions,
        'caseCount': cases.length,
        'cases': cases.map((c) => c.toJson()).toList(),
      };
}
