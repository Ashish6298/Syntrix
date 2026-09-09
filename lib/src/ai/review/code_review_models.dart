/// Domain models for AI Code Analysis & Review Engine (Phase 8.3).
library;

/// Severity classification for code review findings.
enum CodeReviewSeverity {
  /// Severe bugs, security vulnerabilities, or fatal runtime crashes.
  critical,

  /// Major issues, resource leaks, BuildContext async gaps, unhandled exceptions.
  high,

  /// Code smells, performance inefficiencies, improper setState, unawaited futures.
  medium,

  /// Minor maintenance issues, dead code, small conventions.
  low,

  /// Educational insights, style notes, minor suggestions.
  informational;

  static CodeReviewSeverity? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in CodeReviewSeverity.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    return null;
  }
}

/// Category classification of code review findings.
enum CodeReviewCategory {
  /// Potential runtime bugs or logical defects.
  bugRisk,

  /// Code smells, anti-patterns, or readability degradation.
  codeSmell,

  /// High-level design flaws, improper layering, or circular abstractions.
  architecture,

  /// Incorrect usage of Dart/Flutter SDK or third-party APIs.
  apiUsage,

  /// Missing try-catch, ignored errors, or improper exception handling.
  errorHandling,

  /// Hard-to-maintain code, excessive coupling, or high churn risk.
  maintainability,

  /// Redundant or copy-pasted code across files or methods.
  duplication,

  /// High cyclomatic complexity, deeply nested logic, or oversized classes.
  complexity,

  /// Unawaited futures, race conditions, improper Stream/Future lifecycle.
  asyncBehavior,

  /// Type unsafety, risky dynamic invocations, or security anti-patterns.
  unsafePattern,

  /// Widget lifecycle misuse, improper setState, disposal leaks, BuildContext across async gaps.
  flutterLifecycle;

  static CodeReviewCategory? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in CodeReviewCategory.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    return null;
  }
}

/// Confidence rating for code review findings.
enum CodeReviewConfidence {
  /// Finding is backed by direct, unambiguous evidence in the inspected file.
  high,

  /// Finding is inferred from surrounding patterns with high likelihood.
  medium,

  /// Finding is inferred from limited context or ambiguous API conventions.
  low;

  static CodeReviewConfidence? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in CodeReviewConfidence.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    return null;
  }
}

/// Distinct operating modes for AI Code Analysis & Review.
enum CodeReviewMode {
  /// Detailed inspection of a single target file.
  singleFile,

  /// Package-wide review aggregating findings and deduplicating cross-file duplication.
  packageLevel,

  /// Review scoped strictly to changed files / diff hunks.
  changeFocused,

  /// Coarser-grained pass reporting only architectural/API/complexity findings.
  architectureFocused;

  static CodeReviewMode? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in CodeReviewMode.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    return null;
  }
}

/// An individual structured finding emitted by the Code Review Engine.
class CodeReviewFinding implements Comparable<CodeReviewFinding> {
  /// Severity level of the finding.
  final CodeReviewSeverity severity;

  /// Domain category of the finding.
  final CodeReviewCategory category;

  /// Relative file path where the issue was found.
  final String file;

  /// Specific location in the file (e.g. "L42", "L10-L25", or symbol name).
  final String location;

  /// Concise summary of the problem.
  final String problem;

  /// In-depth explanation of why this is an issue.
  final String explanation;

  /// Actionable recommendation and guidance to remediate the issue.
  final String recommendation;

  /// Honest confidence rating based on context availability.
  final CodeReviewConfidence confidence;

  const CodeReviewFinding({
    required this.severity,
    required this.category,
    required this.file,
    required this.location,
    required this.problem,
    required this.explanation,
    required this.recommendation,
    required this.confidence,
  });

  factory CodeReviewFinding.fromJson(Map<String, dynamic> json) {
    final sevStr = json['severity'] as String? ?? 'medium';
    final catStr = json['category'] as String? ?? 'codeSmell';
    final confStr = json['confidence'] as String? ?? 'medium';

    final sev =
        CodeReviewSeverity.tryParse(sevStr) ?? CodeReviewSeverity.medium;
    final cat =
        CodeReviewCategory.tryParse(catStr) ?? CodeReviewCategory.codeSmell;
    final conf =
        CodeReviewConfidence.tryParse(confStr) ?? CodeReviewConfidence.medium;

    return CodeReviewFinding(
      severity: sev,
      category: cat,
      file: json['file'] as String? ?? '',
      location: json['location'] as String? ?? '',
      problem: json['problem'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      recommendation: json['recommendation'] as String? ?? '',
      confidence: conf,
    );
  }

  Map<String, dynamic> toJson() => {
        'severity': severity.name,
        'category': category.name,
        'file': file,
        'location': location,
        'problem': problem,
        'explanation': explanation,
        'recommendation': recommendation,
        'confidence': confidence.name,
      };

  @override
  int compareTo(CodeReviewFinding other) {
    // 1. Severity (critical first, informational last)
    final sComp = severity.index.compareTo(other.severity.index);
    if (sComp != 0) return sComp;

    // 2. File path
    final fComp = file.compareTo(other.file);
    if (fComp != 0) return fComp;

    // 3. Location
    final lComp = location.compareTo(other.location);
    if (lComp != 0) return lComp;

    // 4. Problem
    return problem.compareTo(other.problem);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeReviewFinding &&
          runtimeType == other.runtimeType &&
          severity == other.severity &&
          category == other.category &&
          file == other.file &&
          location == other.location &&
          problem == other.problem;

  @override
  int get hashCode => Object.hash(severity, category, file, location, problem);
}

/// Request parameters supplied to the Code Review Engine.
class CodeReviewRequest {
  /// Target review mode.
  final CodeReviewMode mode;

  /// Target file path (for [CodeReviewMode.singleFile]).
  final String? targetFile;

  /// Target package ID / name (for [CodeReviewMode.packageLevel]).
  final String? targetPackage;

  /// Set of modified file paths (for [CodeReviewMode.changeFocused]).
  final Set<String>? changedFiles;

  /// Custom review instruction or focus area.
  final String? customInstruction;

  /// Maximum total token budget.
  final int tokenBudget;

  const CodeReviewRequest({
    required this.mode,
    this.targetFile,
    this.targetPackage,
    this.changedFiles,
    this.customInstruction,
    this.tokenBudget = 4000,
  });

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        if (targetFile != null) 'targetFile': targetFile,
        if (targetPackage != null) 'targetPackage': targetPackage,
        if (changedFiles != null)
          'changedFiles': changedFiles!.toList()..sort(),
        if (customInstruction != null) 'customInstruction': customInstruction,
        'tokenBudget': tokenBudget,
      };
}

/// Result payload produced by the Code Review Engine.
class CodeReviewResult {
  /// Target mode executed.
  final CodeReviewMode mode;

  /// Whether the review completed successfully.
  final bool isSuccess;

  /// All structured findings detected.
  final List<CodeReviewFinding> findings;

  /// High-level summary of the review.
  final String summary;

  /// Files inspected during this review run.
  final List<String> inspectedFiles;

  /// Error message if review execution failed.
  final String? errorMessage;

  /// Duration in milliseconds.
  final int durationMs;

  /// Timestamp of review.
  final DateTime timestamp;

  const CodeReviewResult({
    required this.mode,
    required this.isSuccess,
    required this.findings,
    required this.summary,
    required this.inspectedFiles,
    this.errorMessage,
    required this.durationMs,
    required this.timestamp,
  });

  factory CodeReviewResult.failure({
    required CodeReviewMode mode,
    required String errorMessage,
    List<String> inspectedFiles = const [],
    int durationMs = 0,
    DateTime? timestamp,
  }) =>
      CodeReviewResult(
        mode: mode,
        isSuccess: false,
        findings: const [],
        summary: 'Code review failed: $errorMessage',
        inspectedFiles: inspectedFiles,
        errorMessage: errorMessage,
        durationMs: durationMs,
        timestamp: timestamp ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() {
    final sortedFindings = List<CodeReviewFinding>.from(findings)..sort();
    final sortedFiles = List<String>.from(inspectedFiles)..sort();

    return {
      'mode': mode.name,
      'isSuccess': isSuccess,
      'summary': summary,
      'findingCount': findings.length,
      'severityCounts': {
        'critical': findings
            .where((f) => f.severity == CodeReviewSeverity.critical)
            .length,
        'high':
            findings.where((f) => f.severity == CodeReviewSeverity.high).length,
        'medium': findings
            .where((f) => f.severity == CodeReviewSeverity.medium)
            .length,
        'low':
            findings.where((f) => f.severity == CodeReviewSeverity.low).length,
        'informational': findings
            .where((f) => f.severity == CodeReviewSeverity.informational)
            .length,
      },
      'findings': sortedFindings.map((f) => f.toJson()).toList(),
      'inspectedFiles': sortedFiles,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'durationMs': durationMs,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
