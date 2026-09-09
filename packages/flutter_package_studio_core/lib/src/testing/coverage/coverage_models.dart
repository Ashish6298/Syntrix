/// Metrics for a single covered source file.
class FileCoverage {
  final String path;
  final int totalLines;
  final int coveredLines;

  const FileCoverage({
    required this.path,
    required this.totalLines,
    required this.coveredLines,
  });

  double get percentage =>
      totalLines == 0 ? 0.0 : (coveredLines / totalLines) * 100.0;

  Map<String, dynamic> toJson() => {
        'path': path,
        'totalLines': totalLines,
        'coveredLines': coveredLines,
        'percentage': double.parse(percentage.toStringAsFixed(2)),
      };
}

/// Threshold requirements for coverage validation.
class CoverageThresholds {
  final double minLineCoverage;

  const CoverageThresholds({
    this.minLineCoverage = 80.0,
  });

  Map<String, dynamic> toJson() => {
        'minLineCoverage': minLineCoverage,
      };
}

/// Options configuring coverage analysis.
class CoverageOptions {
  final String packageName;
  final String profile; // 'unit', 'widget', 'integration', 'all'
  final String inputPath;
  final CoverageThresholds thresholds;

  const CoverageOptions({
    required this.packageName,
    this.profile = 'all',
    this.inputPath = 'coverage/lcov.info',
    this.thresholds = const CoverageThresholds(),
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'inputPath': inputPath,
        'thresholds': thresholds.toJson(),
      };
}

/// Preview plan of coverage analysis.
class CoveragePlan {
  final String packageName;
  final String profile;
  final String inputPath;

  const CoveragePlan({
    required this.packageName,
    required this.profile,
    required this.inputPath,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'inputPath': inputPath,
      };
}

/// Final result of coverage analysis.
class CoverageResult {
  final String packageName;
  final bool isPassed;
  final int totalLines;
  final int coveredLines;
  final List<FileCoverage> files;

  const CoverageResult({
    required this.packageName,
    required this.isPassed,
    required this.totalLines,
    required this.coveredLines,
    required this.files,
  });

  double get overallPercentage =>
      totalLines == 0 ? 0.0 : (coveredLines / totalLines) * 100.0;

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'isPassed': isPassed,
        'totalLines': totalLines,
        'coveredLines': coveredLines,
        'overallPercentage': double.parse(overallPercentage.toStringAsFixed(2)),
        'fileCount': files.length,
        'files': files.map((f) => f.toJson()).toList(),
      };
}
