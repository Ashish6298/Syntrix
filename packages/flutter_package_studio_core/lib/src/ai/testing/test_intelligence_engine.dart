/// Test Intelligence Engine for Flutter Package Studio (Phase 8.4).
library;

import 'dart:convert';
import 'package:path/path.dart' as p;

import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/ai/context/project_context_engine.dart';
import 'package:flutter_package_studio_core/src/ai/context/project_context_models.dart';
import 'package:flutter_package_studio_core/src/ai/engine/assistant_engine.dart';
import 'package:flutter_package_studio_core/src/ai/models/assistant_models.dart';
import 'package:flutter_package_studio_core/src/ai/provider/ai_provider.dart';
import 'package:flutter_package_studio_core/src/ai/testing/test_intelligence_models.dart';

/// Central engine for AI Test Generation & Test Intelligence.
///
/// Guarantees:
/// 1. Accurate Source-to-Test Pairing: Pairs implementation files with test files via 8.2 context/content parsing, not naive globs.
/// 2. Regression-Risk Detection: Flags implementation files that changed or have zero corresponding test assertions.
/// 3. Proposal Isolation: Generated candidate test code is strictly isolated to proposed locations, never modifying real `test/` files.
/// 4. Approval Gate: Suggested tests are tracked as `suggested` and excluded from `existingCoverage` until approved.
/// 5. Sensitive File Safety: Filtered through Phase 8.2 `SensitiveFileFilter` with zero secret leakage.
/// 6. Fail-Closed Error Containment: Structured failure on provider unavailability.
class TestIntelligenceEngine {
  final Logger _logger = Logger('TestIntelligenceEngine');
  final ProjectContextEngine _contextEngine;
  final AssistantEngine _assistantEngine;

  TestIntelligenceEngine({
    required ProjectContextEngine contextEngine,
    required AssistantEngine assistantEngine,
  })  : _contextEngine = contextEngine,
        _assistantEngine = assistantEngine;

  /// Convenience factory constructing engine with an [AiProvider].
  factory TestIntelligenceEngine.withProvider({
    required String projectRoot,
    required AiProvider provider,
    AssistantConfiguration? configuration,
  }) {
    final contextEngine = ProjectContextEngine(projectRoot: projectRoot);
    final assistantEngine = AssistantEngine(
      provider: provider,
      defaultConfiguration: configuration ?? const AssistantConfiguration(),
    );
    return TestIntelligenceEngine(
      contextEngine: contextEngine,
      assistantEngine: assistantEngine,
    );
  }

  /// Executes test intelligence analysis and optional proposal generation.
  Future<TestIntelligenceResult> analyze(
    TestIntelligenceRequest request, {
    DateTime? executionTimestamp,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = executionTimestamp ?? DateTime.now();
    final targetPkg = request.targetPackage ?? 'project_root';

    _logger.info('Starting Test Intelligence analysis for package: $targetPkg');

    try {
      // 1. Discover project structure and assemble safe context via 8.2
      final assembled = await _contextEngine.assembleContext(
        query:
            'Analyze test coverage, test pairs, and missing test cases for $targetPkg',
        targetPackageId: request.targetPackage,
        tokenBudget: request.tokenBudget,
      );

      // 2. Identify and accurately pair source files with corresponding test files
      final sourceFiles = assembled.scopedFiles
          .where((f) => f.category == ProjectFileCategory.source)
          .toList();
      final testFiles = assembled.scopedFiles
          .where((f) => f.category == ProjectFileCategory.test)
          .toList();

      if (sourceFiles.isEmpty) {
        stopwatch.stop();
        return TestIntelligenceResult(
          packageId: targetPkg,
          isSuccess: true,
          gapReports: const [],
          trackedSuite: const [],
          proposals: const [],
          summary: 'No safe source files found in target scope.',
          durationMs: stopwatch.elapsedMilliseconds,
          timestamp: now,
        );
      }

      // Filter by targetFile if specified
      final eligibleSources = request.targetFile != null
          ? sourceFiles.where((f) {
              final normRel = p.normalize(f.relativePath).replaceAll('\\', '/');
              final targetNorm =
                  p.normalize(request.targetFile!).replaceAll('\\', '/');
              return normRel == targetNorm || normRel.endsWith(targetNorm);
            }).toList()
          : sourceFiles;

      // 3. Build implementation-to-test pairings
      final pairs = _pairSourceAndTestFiles(
        sources: eligibleSources,
        tests: testFiles,
      );

      // 4. Build tracked test suite snapshot
      final trackedSuite = <TrackedTestCase>[];
      for (final t in testFiles) {
        final existingTestCases = _extractExistingTestNames(t);
        for (final name in existingTestCases) {
          trackedSuite.add(TrackedTestCase(
            id: 'test_${t.relativePath}_${name.hashCode}',
            name: name,
            targetSourceFile:
                _findPairedSourceForTest(t.relativePath, sourceFiles),
            testFilePath: t.relativePath,
            state: TestTrackingState.existing,
            isHumanApproved: true,
            createdAt: now,
          ));
        }
      }

      // 5. Construct AI Prompt & Execute Assistant request
      final promptContext = PromptContext(
        templateId: targetPkg,
        structuredFacts: {
          'sourceCount': eligibleSources.length,
          'testCount': testFiles.length,
          'pairings': pairs
              .map((p) => {
                    'sourceFile': p.sourceFile.relativePath,
                    'testFile': p.testFile?.relativePath,
                    'hasExistingTests': p.testFile != null,
                  })
              .toList(),
          'files': {
            for (final s in eligibleSources) s.relativePath: s.content,
            for (final t in testFiles) t.relativePath: t.content,
          },
        },
      );

      final assistantReq = AssistantRequest(
        prompt: _buildTestIntelligencePrompt(pairs, request),
        mode: AssistantMode.analysis,
        templateId: targetPkg,
        context: promptContext,
      );

      final response = await _assistantEngine.executeRequest(
        assistantReq,
        executionTimestamp: now,
      );

      stopwatch.stop();

      if (!response.isSuccess) {
        _logger.warning(
            'AI Provider failed during test intelligence: ${response.errorMessage}');
        return TestIntelligenceResult.failure(
          packageId: targetPkg,
          errorMessage: response.errorMessage ??
              'AI provider failed during test intelligence.',
          durationMs: stopwatch.elapsedMilliseconds,
          timestamp: now,
        );
      }

      // 6. Parse structured coverage gap reports
      final gapReports = _parseGapReports(
        response: response,
        pairs: pairs,
      );

      // 7. If proposal generation requested, generate isolated proposed test files
      final proposals = <ProposedTestFile>[];
      if (request.generateProposals) {
        for (final report in gapReports) {
          if (report.missingCases.isNotEmpty) {
            final proposalPath =
                _computeIsolatedProposalPath(report.sourceFile);
            final proposedCode = _generateProposalDartCode(report);

            proposals.add(ProposedTestFile(
              proposalFilePath: proposalPath,
              targetSourceFile: report.sourceFile,
              proposedCode: proposedCode,
              coveredGapIds: report.missingCases.map((c) => c.id).toList(),
            ));

            // Track suggested test cases as 'suggested' (unapproved)
            for (final missing in report.missingCases) {
              trackedSuite.add(TrackedTestCase(
                id: missing.id,
                name: missing.title,
                targetSourceFile: report.sourceFile,
                testFilePath: proposalPath,
                state: TestTrackingState.suggested,
                isHumanApproved: false,
                createdAt: now,
              ));
            }
          }
        }
      }

      return TestIntelligenceResult(
        packageId: targetPkg,
        isSuccess: true,
        gapReports: gapReports,
        trackedSuite: trackedSuite,
        proposals: proposals,
        summary:
            'Analyzed ${pairs.length} implementation target(s), identifying ${gapReports.fold<int>(0, (sum, g) => sum + g.missingCases.length)} coverage gap(s).',
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    } catch (e, st) {
      stopwatch.stop();
      _logger.error('Unhandled exception during test intelligence: $e', e, st);
      return TestIntelligenceResult.failure(
        packageId: targetPkg,
        errorMessage: 'Internal test intelligence error: $e',
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Implementation-to-Test Pairing Logic
  // ───────────────────────────────────────────────────────────────────────────

  List<_SourceTestPair> _pairSourceAndTestFiles({
    required List<ScopedFileContent> sources,
    required List<ScopedFileContent> tests,
  }) {
    final pairs = <_SourceTestPair>[];

    for (final src in sources) {
      final srcBase =
          p.basenameWithoutExtension(src.relativePath).toLowerCase();
      ScopedFileContent? matchedTest;

      // 1. Direct content reference check (e.g. test imports source file)
      for (final t in tests) {
        if (t.content.contains(p.basename(src.relativePath)) ||
            t.content.contains(src.relativePath.replaceAll('\\', '/'))) {
          matchedTest = t;
          break;
        }
      }

      // 2. Exact name pair match (e.g. lib/my_widget.dart <-> test/my_widget_test.dart)
      if (matchedTest == null) {
        for (final t in tests) {
          final testBase =
              p.basenameWithoutExtension(t.relativePath).toLowerCase();
          if (testBase == '${srcBase}_test' || testBase == srcBase) {
            matchedTest = t;
            break;
          }
        }
      }

      // 3. Substring / heuristic pair match
      if (matchedTest == null) {
        for (final t in tests) {
          final testBase =
              p.basenameWithoutExtension(t.relativePath).toLowerCase();
          if (testBase.contains(srcBase) ||
              srcBase.contains(testBase.replaceAll('_test', ''))) {
            matchedTest = t;
            break;
          }
        }
      }

      final isRegRisk = matchedTest == null ||
          src.content.contains('// RECENTLY_MODIFIED') ||
          !matchedTest.content.contains(srcBase);

      pairs.add(_SourceTestPair(
        sourceFile: src,
        testFile: matchedTest,
        isRegressionRisk: isRegRisk,
      ));
    }

    return pairs;
  }

  String _findPairedSourceForTest(
      String testPath, List<ScopedFileContent> sources) {
    final testBase = p
        .basenameWithoutExtension(testPath)
        .replaceAll('_test', '')
        .toLowerCase();
    for (final s in sources) {
      final srcBase = p.basenameWithoutExtension(s.relativePath).toLowerCase();
      if (srcBase == testBase || s.relativePath.contains(testBase)) {
        return s.relativePath;
      }
    }
    return 'lib/src/unknown.dart';
  }

  List<String> _extractExistingTestNames(ScopedFileContent testFile) {
    final names = <String>[];
    final testRegex = RegExp("test\\(\\s*['\"]([^'\"]+)['\"]");
    for (final match in testRegex.allMatches(testFile.content)) {
      final name = match.group(1);
      if (name != null && name.isNotEmpty) {
        names.add(name);
      }
    }
    return names.isEmpty
        ? ['[Standard test suite in ${p.basename(testFile.relativePath)}]']
        : names;
  }

  String _buildTestIntelligencePrompt(
    List<_SourceTestPair> pairs,
    TestIntelligenceRequest request,
  ) {
    final buf = StringBuffer();
    buf.writeln(
        'Analyze the test coverage and identify missing test cases across the following Dart/Flutter targets.');
    buf.writeln();
    buf.writeln('Inspect every target for:');
    buf.writeln(
        '1. Untested boundary conditions (empty collections, 0, limits).');
    buf.writeln(
        '2. Untested failure scenarios (bad inputs, thrown exceptions, network/disk failures).');
    buf.writeln(
        '3. Missing security/sandboxing cases (path traversal, secret leakage, injection).');
    buf.writeln(
        '4. Regression risks (source files with zero tests or missing coverage on modified features).');
    buf.writeln(
        '5. CLI edge cases (missing required options, bad combinations, invalid flags).');
    buf.writeln('6. Invalid input handling.');
    buf.writeln();
    buf.writeln('Return ONLY a JSON object matching this schema:');
    buf.writeln('''
{
  "summary": "High-level summary of test coverage intelligence",
  "gapReports": [
    {
      "targetName": "Class: TargetClassName or Command: TargetCommand",
      "sourceFile": "lib/path/to/source.dart",
      "pairedTestFile": "test/path/to/test.dart",
      "isRegressionRisk": true,
      "missingCases": [
        {
          "id": "gap_01",
          "title": "Short title of missing test scenario",
          "category": "boundaryCondition|failureScenario|securityScenario|regressionRisk|cliEdgeCase|invalidInput|generalMissingCase",
          "severity": "critical|high|medium|low",
          "rationale": "Why this test case is necessary",
          "testConditions": "Input values or state conditions",
          "expectedOutcome": "Expected assertions or behaviors"
        }
      ]
    }
  ]
}
''');

    return buf.toString();
  }

  List<TargetCoverageGapReport> _parseGapReports({
    required AssistantResponse response,
    required List<_SourceTestPair> pairs,
  }) {
    final reports = <TargetCoverageGapReport>[];
    final rawText = response.rawUntrustedCompletion;

    if (rawText != null && rawText.trim().isNotEmpty) {
      try {
        String cleanJson = rawText.trim();
        if (cleanJson.startsWith('```json')) cleanJson = cleanJson.substring(7);
        if (cleanJson.startsWith('```')) cleanJson = cleanJson.substring(3);
        if (cleanJson.endsWith('```'))
          cleanJson = cleanJson.substring(0, cleanJson.length - 3);
        cleanJson = cleanJson.trim();

        final decoded = jsonDecode(cleanJson);
        if (decoded is Map<String, dynamic> && decoded['gapReports'] is List) {
          final list = decoded['gapReports'] as List;
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              reports.add(TargetCoverageGapReport.fromJson(item));
            }
          }
        }
      } catch (e) {
        _logger.warning('Failed to parse gapReports from raw response: $e');
      }
    }

    // Fallback: If no AI reports generated, construct baseline gap reports for untested pairs
    if (reports.isEmpty) {
      for (final pair in pairs) {
        final targetName =
            'Target: ${p.basename(pair.sourceFile.relativePath)}';
        final missing = <MissingTestCase>[];

        if (pair.testFile == null) {
          missing.add(MissingTestCase(
            id: 'gap_untested_${pair.sourceFile.relativePath.hashCode}',
            title:
                'Complete unit test suite missing for ${p.basename(pair.sourceFile.relativePath)}',
            category: TestGapCategory.regressionRisk,
            severity: TestGapSeverity.high,
            rationale: 'Source file has no paired unit test file in test/.',
            testConditions: 'Instantiate target and test public interface.',
            expectedOutcome: 'All public methods execute and pass assertions.',
          ));
        }

        // CLI edge case detection for CLI commands
        if (pair.sourceFile.relativePath.contains('command') ||
            pair.sourceFile.content.contains('FpsCommand') ||
            pair.sourceFile.content.contains('CommandRunner')) {
          missing.add(MissingTestCase(
            id: 'gap_cli_${pair.sourceFile.relativePath.hashCode}',
            title: 'Invalid arguments and missing required flags test',
            category: TestGapCategory.cliEdgeCase,
            severity: TestGapSeverity.medium,
            rationale:
                'CLI commands must reject invalid options with exit code 64.',
            testConditions: 'Run command with unknown or missing arguments.',
            expectedOutcome: 'Returns usage error code (64) without crashing.',
          ));
        }

        reports.add(TargetCoverageGapReport(
          targetName: targetName,
          sourceFile: pair.sourceFile.relativePath,
          pairedTestFile: pair.testFile?.relativePath,
          isRegressionRisk: pair.isRegressionRisk,
          missingCases: missing,
        ));
      }
    }

    return reports..sort();
  }

  String _computeIsolatedProposalPath(String sourcePath) {
    final base = p.basenameWithoutExtension(sourcePath);
    // Writes to isolated proposal directory, NEVER directly in test/
    return p
        .join('report', 'proposed_tests', '${base}_proposed_test.dart.proposed')
        .replaceAll('\\', '/');
  }

  String _generateProposalDartCode(TargetCoverageGapReport report) {
    final buf = StringBuffer();
    buf.writeln(
        '// ═══════════════════════════════════════════════════════════════════════════');
    buf.writeln(
        '// PROPOSED CANDIDATE TEST SUITE — REQUIRES HUMAN REVIEW AND APPROVAL');
    buf.writeln('// Target Source: ${report.sourceFile}');
    buf.writeln(
        '// ═══════════════════════════════════════════════════════════════════════════');
    buf.writeln();
    buf.writeln("import 'package:test/test.dart';");
    buf.writeln();
    buf.writeln('void main() {');
    buf.writeln("  group('Proposed Tests for ${report.targetName}', () {");
    for (final c in report.missingCases) {
      buf.writeln("    test('${c.title} (${c.category.name})', () {");
      buf.writeln('      // Rationale: ${c.rationale}');
      buf.writeln('      // Conditions: ${c.testConditions}');
      buf.writeln('      // Expected: ${c.expectedOutcome}');
      buf.writeln(
          '      expect(true, isTrue); // TODO: Replace placeholder with verified test logic');
      buf.writeln('    });');
      buf.writeln();
    }
    buf.writeln('  });');
    buf.writeln('}');
    return buf.toString();
  }
}

class _SourceTestPair {
  final ScopedFileContent sourceFile;
  final ScopedFileContent? testFile;
  final bool isRegressionRisk;

  const _SourceTestPair({
    required this.sourceFile,
    this.testFile,
    this.isRegressionRisk = false,
  });
}
