/// Explicit evaluation status for a compatibility matrix cell.
enum MatrixCellStatus {
  pass,
  fail,
  skipped,
  unsupported,
  notRun,
  unavailable,
  blocked,
}

/// A single cell in the compatibility matrix.
class MatrixCell {
  final String sdkVersion;
  final String platform;
  final String profile;
  final MatrixCellStatus status;
  final String reason;

  const MatrixCell({
    required this.sdkVersion,
    required this.platform,
    required this.profile,
    required this.status,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'sdkVersion': sdkVersion,
        'platform': platform,
        'profile': profile,
        'status': status.name,
        'reason': reason,
      };
}

/// Options configuring compatibility matrix generation.
class CompatibilityOptions {
  final String packageName;
  final String profile; // 'unit', 'widget', 'integration', 'all'
  final String platform; // 'android', 'ios', 'web', 'all'
  final String sdkConstraint;

  const CompatibilityOptions({
    required this.packageName,
    this.profile = 'all',
    this.platform = 'all',
    this.sdkConstraint = '>=3.0.0 <4.0.0',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'platform': platform,
        'sdkConstraint': sdkConstraint,
      };
}

/// Preview plan of compatibility matrix generation.
class CompatibilityPlan {
  final String packageName;
  final String profile;
  final String platform;
  final String sdkConstraint;

  const CompatibilityPlan({
    required this.packageName,
    required this.profile,
    required this.platform,
    required this.sdkConstraint,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile,
        'platform': platform,
        'sdkConstraint': sdkConstraint,
      };
}

/// Evaluated compatibility matrix result.
class TestMatrixResult {
  final String packageName;
  final bool isFullyCompatible;
  final List<MatrixCell> cells;

  const TestMatrixResult({
    required this.packageName,
    required this.isFullyCompatible,
    required this.cells,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Compatibility Test Matrix: $packageName');
    buf.writeln();
    buf.writeln(
        '**Overall Compatibility**: ${isFullyCompatible ? "COMPATIBLE ✓" : "PARTIAL / INCOMPATIBLE ✗"}');
    buf.writeln();
    buf.writeln('| SDK Version | Platform | Profile | Status | Reason |');
    buf.writeln('|---|---|---|---|---|');
    for (final cell in cells) {
      buf.writeln(
          '| ${cell.sdkVersion} | ${cell.platform} | ${cell.profile} | ${cell.status.name.toUpperCase()} | ${cell.reason} |');
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'isFullyCompatible': isFullyCompatible,
        'totalCells': cells.length,
        'cells': cells.map((c) => c.toJson()).toList(),
      };
}
