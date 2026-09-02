/// Domain models for AI Test Generation & Test Intelligence (Phase 8.4).
library;

/// Severity/Priority rating for an identified coverage gap.
enum TestGapSeverity {
  /// Severe gap in core business logic, critical security boundary, or fatal crash pathway.
  critical,

  /// Major untested failure mode, state corruption risk, or missing error handling.
  high,

  /// Missing boundary condition, edge case, or unvalidated optional branch.
  medium,

  /// Minor missing variation, cosmetic format validation, or nice-to-have check.
  low;

  static TestGapSeverity? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in TestGapSeverity.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    return null;
  }
}

/// Category classification of coverage gaps.
enum TestGapCategory {
  /// Untested boundary condition (e.g. empty collection, 0, max integer).
  boundaryCondition,

  /// Untested failure mode (e.g. filesystem exception, timeout, bad JSON).
  failureScenario,

  /// Missing security or sandboxing test (e.g. path traversal, secret leak).
  securityScenario,

  /// Code modified without corresponding test updates.
  regressionRisk,

  /// CLI argument or flag edge cases (e.g. missing required flags, bad combinations).
  cliEdgeCase,

  /// Invalid, malformed, or null input handling.
  invalidInput,

  /// General missing test scenario.
  generalMissingCase;

  static TestGapCategory? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in TestGapCategory.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    return null;
  }
}

/// Individual missing test case within a coverage gap target.
class MissingTestCase implements Comparable<MissingTestCase> {
  /// Unique identifier or slug for the missing test case.
  final String id;

  /// Short descriptive title of the missing test scenario.
  final String title;

  /// Category classification.
  final TestGapCategory category;

  /// Severity/Priority of this gap.
  final TestGapSeverity severity;

  /// Detailed rationale explaining why this test is necessary.
  final String rationale;

  /// Concrete input values, mock state, or trigger conditions.
  final String testConditions;

  /// Expected assertions or outcomes.
  final String expectedOutcome;

  const MissingTestCase({
    required this.id,
    required this.title,
    required this.category,
    required this.severity,
    required this.rationale,
    required this.testConditions,
    required this.expectedOutcome,
  });

  factory MissingTestCase.fromJson(Map<String, dynamic> json) {
    final catStr = json['category'] as String? ?? 'generalMissingCase';
    final sevStr = json['severity'] as String? ?? 'medium';

    final cat =
        TestGapCategory.tryParse(catStr) ?? TestGapCategory.generalMissingCase;
    final sev = TestGapSeverity.tryParse(sevStr) ?? TestGapSeverity.medium;

    return MissingTestCase(
      id: json['id'] as String? ??
          'gap_${DateTime.now().microsecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Missing Test Case',
      category: cat,
      severity: sev,
      rationale: json['rationale'] as String? ?? '',
      testConditions: json['testConditions'] as String? ?? '',
      expectedOutcome: json['expectedOutcome'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'severity': severity.name,
        'rationale': rationale,
        'testConditions': testConditions,
        'expectedOutcome': expectedOutcome,
      };

  @override
  int compareTo(MissingTestCase other) {
    final sComp = severity.index.compareTo(other.severity.index);
    if (sComp != 0) return sComp;
    return title.compareTo(other.title);
  }
}

/// Structured coverage gap report for a specific class, function, or CLI command.
class TargetCoverageGapReport implements Comparable<TargetCoverageGapReport> {
  /// Target identifier (e.g. "Class: PackageArtifactGenerator" or "Command: fps review").
  final String targetName;

  /// Source implementation file path.
  final String sourceFile;

  /// Associated existing test file path (or null if zero existing tests).
  final String? pairedTestFile;

  /// Whether this target is identified as a regression risk (source changed without test update).
  final bool isRegressionRisk;

  /// List of concrete missing test cases.
  final List<MissingTestCase> missingCases;

  const TargetCoverageGapReport({
    required this.targetName,
    required this.sourceFile,
    this.pairedTestFile,
    this.isRegressionRisk = false,
    this.missingCases = const [],
  });

  factory TargetCoverageGapReport.fromJson(Map<String, dynamic> json) {
    final rawCases = json['missingCases'] as List<dynamic>? ?? const [];
    return TargetCoverageGapReport(
      targetName: json['targetName'] as String? ?? 'Target',
      sourceFile: json['sourceFile'] as String? ?? '',
      pairedTestFile: json['pairedTestFile'] as String?,
      isRegressionRisk: json['isRegressionRisk'] as bool? ?? false,
      missingCases: rawCases
          .whereType<Map<String, dynamic>>()
          .map(MissingTestCase.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'targetName': targetName,
        'sourceFile': sourceFile,
        if (pairedTestFile != null) 'pairedTestFile': pairedTestFile,
        'isRegressionRisk': isRegressionRisk,
        'missingCaseCount': missingCases.length,
        'missingCases': missingCases.map((c) => c.toJson()).toList(),
      };

  @override
  int compareTo(TargetCoverageGapReport other) =>
      targetName.compareTo(other.targetName);
}

/// Lifecycle tracking state for an individual test item.
enum TestTrackingState {
  /// Test already exists in the real test suite.
  existing,

  /// Test is an AI-generated candidate proposal (must NOT count as existing coverage).
  suggested,

  /// Test was executed by a test runner.
  executed,

  /// Test was executed and passed.
  passed,

  /// Test was executed and failed.
  failed;

  static TestTrackingState? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in TestTrackingState.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    return null;
  }
}

/// Immutable test-intelligence record for tracking test status across packages.
class TrackedTestCase {
  /// Unique identifier.
  final String id;

  /// Test name or description.
  final String name;

  /// Implementation file being verified.
  final String targetSourceFile;

  /// Test file location (for existing tests) or proposed file path (for suggested tests).
  final String testFilePath;

  /// Current tracking lifecycle state.
  final TestTrackingState state;

  /// Whether this test has been explicitly approved by a human maintainer.
  final bool isHumanApproved;

  /// Timestamp of creation/discovery.
  final DateTime createdAt;

  const TrackedTestCase({
    required this.id,
    required this.name,
    required this.targetSourceFile,
    required this.testFilePath,
    required this.state,
    this.isHumanApproved = false,
    required this.createdAt,
  });

  /// Factory creating an approved transition to executed/passed/failed.
  /// Enforces state transition invariants: cannot pass or fail unless executed.
  TrackedTestCase transitionTo(TestTrackingState nextState) {
    if ((nextState == TestTrackingState.passed ||
            nextState == TestTrackingState.failed) &&
        state != TestTrackingState.executed &&
        state != TestTrackingState.existing) {
      throw StateError(
          'Cannot transition test "$id" directly from "$state" to "$nextState" without being executed.');
    }

    return TrackedTestCase(
      id: id,
      name: name,
      targetSourceFile: targetSourceFile,
      testFilePath: testFilePath,
      state: nextState,
      isHumanApproved: isHumanApproved,
      createdAt: createdAt,
    );
  }

  /// Explicit human-approval gate: transforms a suggested proposal into an approved candidate.
  TrackedTestCase approve() {
    return TrackedTestCase(
      id: id,
      name: name,
      targetSourceFile: targetSourceFile,
      testFilePath: testFilePath,
      state: TestTrackingState.existing,
      isHumanApproved: true,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetSourceFile': targetSourceFile,
        'testFilePath': testFilePath,
        'state': state.name,
        'isHumanApproved': isHumanApproved,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// A generated candidate test proposal isolated from the real test suite.
class ProposedTestFile {
  /// Suggested relative proposal path (e.g. "report/proposed_tests/my_test.dart.proposed").
  /// Must NEVER point directly to real test/ directory.
  final String proposalFilePath;

  /// Target source implementation file under test.
  final String targetSourceFile;

  /// Generated Dart test source code.
  final String proposedCode;

  /// Rationale and covered gap IDs.
  final List<String> coveredGapIds;

  const ProposedTestFile({
    required this.proposalFilePath,
    required this.targetSourceFile,
    required this.proposedCode,
    this.coveredGapIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'proposalFilePath': proposalFilePath,
        'targetSourceFile': targetSourceFile,
        'coveredGapIds': coveredGapIds,
        'proposedCode': proposedCode,
      };
}

/// Request parameters supplied to the Test Intelligence Engine.
class TestIntelligenceRequest {
  /// Target package ID / name in a monorepo workspace.
  final String? targetPackage;

  /// Optional specific source file to analyze for gaps.
  final String? targetFile;

  /// Whether to generate candidate Dart test proposals (explicit opt-in only).
  final bool generateProposals;

  /// Token budget limit.
  final int tokenBudget;

  const TestIntelligenceRequest({
    this.targetPackage,
    this.targetFile,
    this.generateProposals = false,
    this.tokenBudget = 4000,
  });

  Map<String, dynamic> toJson() => {
        if (targetPackage != null) 'targetPackage': targetPackage,
        if (targetFile != null) 'targetFile': targetFile,
        'generateProposals': generateProposals,
        'tokenBudget': tokenBudget,
      };
}

/// Complete test intelligence result containing gap analysis, tracking snapshot, and proposals.
class TestIntelligenceResult {
  /// Target package or project analyzed.
  final String packageId;

  /// Whether the test intelligence run succeeded.
  final bool isSuccess;

  /// Target-by-target coverage gap reports.
  final List<TargetCoverageGapReport> gapReports;

  /// Queryable tracking state of tests.
  final List<TrackedTestCase> trackedSuite;

  /// Proposed isolated test files (if generation was requested).
  final List<ProposedTestFile> proposals;

  /// High-level summary of test coverage intelligence.
  final String summary;

  /// Duration in milliseconds.
  final int durationMs;

  /// Timestamp.
  final DateTime timestamp;

  /// Error message if execution failed.
  final String? errorMessage;

  const TestIntelligenceResult({
    required this.packageId,
    required this.isSuccess,
    required this.gapReports,
    required this.trackedSuite,
    this.proposals = const [],
    required this.summary,
    required this.durationMs,
    required this.timestamp,
    this.errorMessage,
  });

  factory TestIntelligenceResult.failure({
    required String packageId,
    required String errorMessage,
    int durationMs = 0,
    DateTime? timestamp,
  }) =>
      TestIntelligenceResult(
        packageId: packageId,
        isSuccess: false,
        gapReports: const [],
        trackedSuite: const [],
        proposals: const [],
        summary: 'Test intelligence analysis failed: $errorMessage',
        durationMs: durationMs,
        timestamp: timestamp ?? DateTime.now(),
        errorMessage: errorMessage,
      );

  /// Computes existing verified tests (excluding unapproved suggested proposals).
  List<TrackedTestCase> get existingCoverage => trackedSuite
      .where((t) => t.state != TestTrackingState.suggested)
      .toList();

  /// Computes suggested candidate proposals waiting for human approval.
  List<TrackedTestCase> get suggestedCoverage => trackedSuite
      .where((t) => t.state == TestTrackingState.suggested)
      .toList();

  Map<String, dynamic> toJson() => {
        'packageId': packageId,
        'isSuccess': isSuccess,
        'summary': summary,
        'totalGapsIdentified':
            gapReports.fold<int>(0, (sum, g) => sum + g.missingCases.length),
        'existingTestCount': existingCoverage.length,
        'suggestedTestCount': suggestedCoverage.length,
        'gapReports': gapReports.map((g) => g.toJson()).toList(),
        'trackedSuite': trackedSuite.map((t) => t.toJson()).toList(),
        'proposals': proposals.map((p) => p.toJson()).toList(),
        if (errorMessage != null) 'errorMessage': errorMessage,
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
      };
}
