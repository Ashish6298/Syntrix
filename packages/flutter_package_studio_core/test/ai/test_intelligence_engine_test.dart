import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 8.4 — AI Test Generation & Test Intelligence Tests', () {
    late Directory tempRoot;
    late String rootPath;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('fps_phase_8_4_test_');
      rootPath = tempRoot.path;
    });

    tearDown(() {
      if (tempRoot.existsSync()) {
        try {
          tempRoot.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    /// Helper to scaffold a sample package with realistic Dart source and atypical test structures.
    void scaffoldSamplePackage() {
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: test_intel_sample_pkg
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
dependencies:
  meta: ^1.11.0
''');
      File(p.join(rootPath, '.gitignore')).writeAsStringSync('''
.dart_tool/
build/
.env
*.secret
''');

      Directory(p.join(rootPath, 'lib', 'src')).createSync(recursive: true);
      Directory(p.join(rootPath, 'test', 'custom_suites'))
          .createSync(recursive: true);

      // Implementation 1: Generator with incomplete test coverage
      File(p.join(rootPath, 'lib', 'src', 'artifact_generator.dart'))
          .writeAsStringSync('''
class PackageArtifactGenerator {
  String generateArtifact(String name, {bool isLarge = false, String? outputDir}) {
    if (name.isEmpty) throw ArgumentError('Package name cannot be empty');
    if (outputDir != null && outputDir.contains('..')) throw ArgumentError('Path traversal detected');
    return 'artifact_\$name';
  }
}
''');

      // Test 1: Atypical naming convention (custom_suites/artifact_suite.dart) testing ONLY happy path
      File(p.join(rootPath, 'test', 'custom_suites', 'artifact_suite.dart'))
          .writeAsStringSync('''
import 'package:test/test.dart';
import 'package:test_intel_sample_pkg/src/artifact_generator.dart';

void main() {
  test('generateArtifact happy path', () {
    final gen = PackageArtifactGenerator();
    expect(gen.generateArtifact('my_pkg'), equals('artifact_my_pkg'));
  });
}
''');

      // Implementation 2: CLI Command with no tests (regression risk)
      File(p.join(rootPath, 'lib', 'src', 'deploy_command.dart'))
          .writeAsStringSync('''
// RECENTLY_MODIFIED
class DeployCommand {
  int execute(List<String> args) {
    if (args.isEmpty) return 64;
    return 0;
  }
}
''');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Model Conformance & State Transitions
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Model conformance & state transitions: enforces lifecycle invariants and valid states',
        () {
      final now = DateTime.parse('2026-09-02T12:00:00.000Z');

      // 1a. MissingTestCase schema
      final missing = const MissingTestCase(
        id: 'gap_01',
        title: 'Empty package name rejection',
        category: TestGapCategory.boundaryCondition,
        severity: TestGapSeverity.critical,
        rationale: 'Passing empty name should throw ArgumentError',
        testConditions: 'name = ""',
        expectedOutcome: 'throwsA(isA<ArgumentError>())',
      );
      final missingJson = missing.toJson();
      expect(missingJson['category'], equals('boundaryCondition'));
      expect(missingJson['severity'], equals('critical'));

      final parsedMissing = MissingTestCase.fromJson(missingJson);
      expect(parsedMissing.id, equals('gap_01'));
      expect(parsedMissing.severity, equals(TestGapSeverity.critical));

      // 1b. TrackedTestCase state transition invariants
      final suggested = TrackedTestCase(
        id: 'prop_01',
        name: 'Empty name test',
        targetSourceFile: 'lib/src/artifact_generator.dart',
        testFilePath:
            'report/proposed_tests/artifact_generator_proposed_test.dart.proposed',
        state: TestTrackingState.suggested,
        isHumanApproved: false,
        createdAt: now,
      );

      // Cannot transition suggested test directly to passed/failed without being executed/existing
      expect(
        () => suggested.transitionTo(TestTrackingState.passed),
        throwsA(isA<StateError>()),
      );

      // Human approval transitions state to existing
      final approved = suggested.approve();
      expect(approved.state, equals(TestTrackingState.existing));
      expect(approved.isHumanApproved, isTrue);

      // Approved/existing test can transition to executed and then passed
      final executed = approved.transitionTo(TestTrackingState.executed);
      expect(executed.state, equals(TestTrackingState.executed));
      final passed = executed.transitionTo(TestTrackingState.passed);
      expect(passed.state, equals(TestTrackingState.passed));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Gap Detection (Boundary, Failure, Invalid Inputs)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Gap detection: surfaces concrete boundary, failure, and invalid-input missing cases',
        () async {
      scaffoldSamplePackage();

      final mockResponseJson = jsonEncode({
        'summary':
            'Identified 3 missing boundary and failure cases in PackageArtifactGenerator',
        'gapReports': [
          {
            'targetName': 'Class: PackageArtifactGenerator',
            'sourceFile': 'lib/src/artifact_generator.dart',
            'pairedTestFile': 'test/custom_suites/artifact_suite.dart',
            'isRegressionRisk': false,
            'missingCases': [
              {
                'id': 'gap_empty_name',
                'title': 'Empty package name argument validation',
                'category': 'boundaryCondition',
                'severity': 'critical',
                'rationale':
                    'generateArtifact must reject empty strings with ArgumentError',
                'testConditions': 'generateArtifact("")',
                'expectedOutcome': 'throwsArgumentError'
              },
              {
                'id': 'gap_path_traversal',
                'title': 'Path traversal in outputDir rejection',
                'category': 'securityScenario',
                'severity': 'critical',
                'rationale':
                    'outputDir containing .. must be rejected for sandboxing',
                'testConditions':
                    'generateArtifact("pkg", outputDir: "../outside")',
                'expectedOutcome': 'throwsArgumentError'
              },
              {
                'id': 'gap_large_artifact',
                'title': 'Large artifact generation flag handling',
                'category': 'boundaryCondition',
                'severity': 'medium',
                'rationale':
                    'Verify isLarge=true operates without memory exhaustion',
                'testConditions': 'generateArtifact("pkg", isLarge: true)',
                'expectedOutcome': 'returns valid artifact string'
              }
            ]
          }
        ]
      });

      final provider = MockAiProvider(defaultResponse: mockResponseJson);
      final engine = TestIntelligenceEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const TestIntelligenceRequest(
        targetPackage: 'test_intel_sample_pkg',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.gapReports, isNotEmpty);
      final report = result.gapReports
          .firstWhere((r) => r.sourceFile.contains('artifact_generator.dart'));
      expect(report.missingCases.length, equals(3));
      expect(
          report.missingCases
              .any((c) => c.category == TestGapCategory.securityScenario),
          isTrue);
      expect(report.missingCases.any((c) => c.title.contains('Path traversal')),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Implementation-to-Test Pairing Correctness
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Test-pairing correctness: matches atypical test filenames to source via context content parsing',
        () async {
      scaffoldSamplePackage();

      final provider = MockAiProvider(
          defaultResponse:
              jsonEncode({'summary': 'Pairing analysis', 'gapReports': []}));

      final engine = TestIntelligenceEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const TestIntelligenceRequest(
        targetPackage: 'test_intel_sample_pkg',
      ));

      expect(result.isSuccess, isTrue);
      expect(provider.recordedRequests, isNotEmpty);
      final prompt = provider.recordedRequests.first.prompt;

      // Confirm prompt contains pairing between artifact_generator.dart and artifact_suite.dart
      expect(prompt, contains('artifact_generator.dart'));
      expect(prompt, contains('artifact_suite.dart'));
      expect(prompt, contains('"hasExistingTests":true'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Regression-Risk Detection
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Regression-risk detection: flags implementation file with zero tests as regression risk',
        () async {
      scaffoldSamplePackage();

      final provider = MockAiProvider(
          defaultResponse:
              jsonEncode({'summary': 'Regression check', 'gapReports': []}));

      final engine = TestIntelligenceEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const TestIntelligenceRequest(
        targetPackage: 'test_intel_sample_pkg',
      ));

      expect(result.isSuccess, isTrue);
      final deployReport = result.gapReports
          .firstWhere((r) => r.sourceFile.contains('deploy_command.dart'));
      expect(deployReport.pairedTestFile, isNull);
      expect(deployReport.isRegressionRisk, isTrue);
      expect(
          deployReport.missingCases
              .any((c) => c.category == TestGapCategory.regressionRisk),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: CLI Edge-Case Detection
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. CLI edge-case detection: flags missing tests for invalid CLI flags and arguments',
        () async {
      scaffoldSamplePackage();

      final provider = MockAiProvider(
          defaultResponse:
              jsonEncode({'summary': 'CLI edge case check', 'gapReports': []}));

      final engine = TestIntelligenceEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const TestIntelligenceRequest(
        targetPackage: 'test_intel_sample_pkg',
      ));

      expect(result.isSuccess, isTrue);
      final deployReport = result.gapReports
          .firstWhere((r) => r.sourceFile.contains('deploy_command.dart'));
      expect(
          deployReport.missingCases
              .any((c) => c.category == TestGapCategory.cliEdgeCase),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Proposal-Isolation Safety (Zero Writes to real test/ directory)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Proposal Isolation Safety: test proposals are written to isolated locations, never real test/ dir',
        () async {
      scaffoldSamplePackage();

      // Snapshot real test directory files before run
      final realTestFilesBefore = <String, String>{};
      final testDir = Directory(p.join(rootPath, 'test'));
      for (final entity in testDir.listSync(recursive: true)) {
        if (entity is File) {
          realTestFilesBefore[entity.path] = entity.readAsStringSync();
        }
      }

      final mockResponse = jsonEncode({
        'summary': 'Proposal generation',
        'gapReports': [
          {
            'targetName': 'Class: PackageArtifactGenerator',
            'sourceFile': 'lib/src/artifact_generator.dart',
            'pairedTestFile': 'test/custom_suites/artifact_suite.dart',
            'isRegressionRisk': false,
            'missingCases': [
              {
                'id': 'gap_01',
                'title': 'Empty name test',
                'category': 'boundaryCondition',
                'severity': 'high',
                'rationale': 'Reject empty name',
                'testConditions': 'name=""',
                'expectedOutcome': 'throwsArgumentError'
              }
            ]
          }
        ]
      });

      final provider = MockAiProvider(defaultResponse: mockResponse);
      final engine = TestIntelligenceEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const TestIntelligenceRequest(
        targetPackage: 'test_intel_sample_pkg',
        generateProposals: true,
      ));

      expect(result.isSuccess, isTrue);
      expect(result.proposals, isNotEmpty);
      for (final prop in result.proposals) {
        expect(prop.proposalFilePath, startsWith('report/proposed_tests/'));
        expect(prop.proposalFilePath, endsWith('.proposed'));
        expect(prop.proposalFilePath.startsWith('test/'), isFalse);
      }

      // Assert real test directory is byte-for-byte identical before and after
      final realTestFilesAfter = <String, String>{};
      for (final entity in testDir.listSync(recursive: true)) {
        if (entity is File) {
          realTestFilesAfter[entity.path] = entity.readAsStringSync();
        }
      }

      expect(realTestFilesAfter.length, equals(realTestFilesBefore.length));
      for (final path in realTestFilesBefore.keys) {
        expect(realTestFilesAfter[path], equals(realTestFilesBefore[path]));
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Approval Gate (Suggested != Existing Coverage)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Approval Gate: candidate proposals are tracked as suggested and excluded from existing coverage',
        () async {
      scaffoldSamplePackage();

      final mockResponse = jsonEncode({
        'summary': 'Proposal gate check',
        'gapReports': [
          {
            'targetName': 'Class: PackageArtifactGenerator',
            'sourceFile': 'lib/src/artifact_generator.dart',
            'pairedTestFile': 'test/custom_suites/artifact_suite.dart',
            'isRegressionRisk': false,
            'missingCases': [
              {
                'id': 'gap_suggested_01',
                'title': 'Boundary test',
                'category': 'boundaryCondition',
                'severity': 'high',
                'rationale': 'Coverage gap',
                'testConditions': '',
                'expectedOutcome': ''
              }
            ]
          }
        ]
      });

      final provider = MockAiProvider(defaultResponse: mockResponse);
      final engine = TestIntelligenceEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const TestIntelligenceRequest(
        targetPackage: 'test_intel_sample_pkg',
        generateProposals: true,
      ));

      expect(result.isSuccess, isTrue);
      // Existing coverage must only count real, verified tests from test/
      expect(result.existingCoverage.length, equals(1));
      expect(result.existingCoverage.first.name,
          equals('generateArtifact happy path'));

      // Suggested coverage contains the unapproved candidate test
      expect(result.suggestedCoverage.length, equals(1));
      expect(result.suggestedCoverage.first.name, equals('Boundary test'));
      expect(result.suggestedCoverage.first.isHumanApproved, isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Sensitive-File Exclusion Respected
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Sensitive-File Respect: .env and credentials never leak into prompt or test proposals',
        () async {
      scaffoldSamplePackage();

      File(p.join(rootPath, '.env'))
          .writeAsStringSync('SECRET_STRIPE_KEY=sk_live_1234567890abcdef');
      File(p.join(rootPath, 'credentials.json'))
          .writeAsStringSync('{"db_pass": "super_secret_db"}');

      final provider = MockAiProvider(
          defaultResponse:
              jsonEncode({'summary': 'Safe test analysis', 'gapReports': []}));

      final engine = TestIntelligenceEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const TestIntelligenceRequest(
        targetPackage: 'test_intel_sample_pkg',
        generateProposals: true,
      ));

      expect(result.isSuccess, isTrue);
      expect(provider.recordedRequests, isNotEmpty);
      final prompt = provider.recordedRequests.first.prompt;
      expect(prompt.contains('SECRET_STRIPE_KEY'), isFalse);
      expect(prompt.contains('super_secret_db'), isFalse);
      expect(prompt.contains('.env'), isFalse);
      expect(prompt.contains('credentials.json'), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: AI Provider Failure Handled Safely
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9. Provider Failure: unavailable provider returns structured failure result without crashing',
        () async {
      scaffoldSamplePackage();

      final provider = MockAiProvider(
        injectedException: Exception('Simulated Test Intelligence AI Failure'),
      );
      final engine = TestIntelligenceEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const TestIntelligenceRequest(
        targetPackage: 'test_intel_sample_pkg',
      ));

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage,
          contains('Simulated Test Intelligence AI Failure'));
      expect(result.gapReports, isEmpty);
      expect(result.summary, contains('failed'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 10: Dual-Format Rendering (JSON and Markdown)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '10. Dual-Format Renderer: renders schema-valid JSON and structured Markdown',
        () {
      final now = DateTime.parse('2026-09-02T12:00:00.000Z');
      final result = TestIntelligenceResult(
        packageId: 'test_intel_sample_pkg',
        isSuccess: true,
        gapReports: [
          const TargetCoverageGapReport(
            targetName: 'Class: ArtifactGenerator',
            sourceFile: 'lib/src/artifact_generator.dart',
            pairedTestFile: 'test/custom_suites/artifact_suite.dart',
            isRegressionRisk: false,
            missingCases: [
              MissingTestCase(
                id: 'gap_01',
                title: 'Empty name validation',
                category: TestGapCategory.boundaryCondition,
                severity: TestGapSeverity.critical,
                rationale: 'Must throw ArgumentError',
                testConditions: 'name = ""',
                expectedOutcome: 'throwsArgumentError',
              )
            ],
          )
        ],
        trackedSuite: [
          TrackedTestCase(
            id: 'test_01',
            name: 'happy path',
            targetSourceFile: 'lib/src/artifact_generator.dart',
            testFilePath: 'test/custom_suites/artifact_suite.dart',
            state: TestTrackingState.existing,
            isHumanApproved: true,
            createdAt: now,
          )
        ],
        proposals: const [
          ProposedTestFile(
            proposalFilePath:
                'report/proposed_tests/artifact_generator_proposed_test.dart.proposed',
            targetSourceFile: 'lib/src/artifact_generator.dart',
            proposedCode: 'void main() { test("empty name", () {}); }',
            coveredGapIds: ['gap_01'],
          )
        ],
        summary: 'Analyzed 1 target, found 1 gap.',
        durationMs: 150,
        timestamp: now,
      );

      const renderer = TestIntelligenceRenderer();
      final jsonOutput = renderer.renderJson(result);
      final mdOutput = renderer.renderMarkdown(result);

      // JSON validation
      final decoded = jsonDecode(jsonOutput) as Map<String, dynamic>;
      expect(decoded['isSuccess'], isTrue);
      expect(decoded['totalGapsIdentified'], equals(1));
      expect(decoded['existingTestCount'], equals(1));
      expect(decoded['gapReports'][0]['targetName'],
          equals('Class: ArtifactGenerator'));

      // Markdown validation
      expect(
          mdOutput,
          contains(
              '# Flutter Package Studio — Test Generation & Test Intelligence Report'));
      expect(mdOutput, contains('Class: ArtifactGenerator'));
      expect(mdOutput, contains('Proposed Candidate Test Suites'));
      expect(
          mdOutput,
          contains(
              'report/proposed_tests/artifact_generator_proposed_test.dart.proposed'));
    });
  });
}
