import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 8.5 — AI Debugging & Failure Diagnosis Tests', () {
    late Directory tempRoot;
    late String rootPath;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('fps_phase_8_5_test_');
      rootPath = tempRoot.path;
    });

    tearDown(() {
      if (tempRoot.existsSync()) {
        try {
          tempRoot.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    /// Helper to scaffold a monorepo containing multiple packages, reports, and source files.
    void scaffoldMonorepo() {
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: syntrix_monorepo
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');
      File(p.join(rootPath, '.gitignore')).writeAsStringSync('''
.dart_tool/
build/
.env
*.secret
''');

      // 1. Prior phase verification reports in root /report
      Directory(p.join(rootPath, 'report')).createSync(recursive: true);
      File(p.join(rootPath, 'report', 'phase_8_4_verification_report.txt'))
          .writeAsStringSync('''
================================================================================
PHASE 8.4 — AI TEST GENERATION & TEST INTELLIGENCE — VERIFICATION REPORT
================================================================================
Known limitations / deferred items:
- Null pointer handling on uninitialized buffer in PackageArtifactGenerator is a known limitation.
''');

      // 2. Package A: pkg_core
      final pkgCore = p.join(rootPath, 'packages', 'pkg_core');
      Directory(p.join(pkgCore, 'lib', 'src')).createSync(recursive: true);
      Directory(p.join(pkgCore, 'test')).createSync(recursive: true);
      File(p.join(pkgCore, 'pubspec.yaml')).writeAsStringSync('''
name: pkg_core
version: 1.0.0
dependencies:
  meta: ^1.11.0
''');
      File(p.join(pkgCore, 'lib', 'src', 'data_handler.dart'))
          .writeAsStringSync('''
class DataHandler {
  void processData(String? raw) {
    // Line 3: Defect location
    final length = raw!.length;
    print("Processed: \$length");
  }
}
''');
      File(p.join(pkgCore, 'test', 'data_handler_test.dart'))
          .writeAsStringSync('''
import 'package:test/test.dart';
import 'package:pkg_core/src/data_handler.dart';

void main() {
  test('processData failure on null', () {
    final handler = DataHandler();
    handler.processData(null);
  });
}
''');

      // 3. Package B: pkg_cli
      final pkgCli = p.join(rootPath, 'packages', 'pkg_cli');
      Directory(p.join(pkgCli, 'lib')).createSync(recursive: true);
      File(p.join(pkgCli, 'pubspec.yaml')).writeAsStringSync('''
name: pkg_cli
version: 1.0.0
dependencies:
  args: ^2.5.0
''');
      File(p.join(pkgCli, 'lib', 'runner.dart'))
          .writeAsStringSync('void runCli() {}');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Diagnosis Model Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Diagnosis model conformance: all 7 required fields present, correctly typed, and certainty is constrained enum',
        () {
      final diag = const FailureDiagnosis(
        problem:
            'Null check operator used on a null value in DataHandler.processData',
        likelyCauses: [
          DiagnosedCause(
            description:
                'Parameter `raw` is null when `raw!.length` is evaluated at data_handler.dart:L3',
            certainty: CauseCertainty.confirmed,
            rationale:
                'Directly verified from line 3 stack trace and null parameter invocation in test.',
          )
        ],
        citedEvidence: [
          'test/data_handler_test.dart:L8',
          'packages/pkg_core/lib/src/data_handler.dart:L3'
        ],
        affectedComponents: ['packages/pkg_core/lib/src/data_handler.dart'],
        recommendedFix:
            'Guard `raw` with an explicit null-check or make `raw` a non-nullable required parameter.',
        risk: CodeReviewSeverity.low,
        verificationSteps: [
          VerificationStep(
            stepNumber: 1,
            action: 'dart test packages/pkg_core/test/data_handler_test.dart',
            expectedOutcome: 'Test passes without NullThrownError.',
          )
        ],
      );

      final jsonMap = diag.toJson();
      expect(jsonMap['problem'], contains('Null check operator'));
      expect(jsonMap['likelyCauses'][0]['certainty'], equals('confirmed'));
      expect(jsonMap['citedEvidence'].length, equals(2));
      expect(
          jsonMap['affectedComponents'].first, contains('data_handler.dart'));
      expect(jsonMap['recommendedFix'], contains('Guard `raw`'));
      expect(jsonMap['risk'], equals('low'));
      expect(jsonMap['verificationSteps'][0]['action'], contains('dart test'));

      final parsed = FailureDiagnosis.fromJson(jsonMap);
      expect(parsed.likelyCauses.first.certainty,
          equals(CauseCertainty.confirmed));
      expect(parsed.risk, equals(CodeReviewSeverity.low));
      expect(parsed.verificationSteps.first.stepNumber, equals(1));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Certainty-Tiering Correctness (Confirmed vs. Possible)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Certainty-tiering correctness: tags unambiguous stack trace as confirmed and circumstantial evidence as possible',
        () async {
      scaffoldMonorepo();

      // 2a. Unambiguous direct stack trace -> confirmed
      final confirmedMockJson = jsonEncode({
        'summary': 'Confirmed NullCheckError in DataHandler',
        'problem': 'NullCheckError in DataHandler',
        'likelyCauses': [
          {
            'description': 'Direct null dereference on raw!.length at line 3',
            'certainty': 'confirmed',
            'rationale': 'Stack trace points directly to line 3'
          }
        ],
        'citedEvidence': ['data_handler.dart:L3'],
        'affectedComponents': ['packages/pkg_core/lib/src/data_handler.dart'],
        'recommendedFix': 'Add if (raw == null) check',
        'risk': 'low',
        'verificationSteps': [
          {'stepNumber': 1, 'action': 'dart test', 'expectedOutcome': 'pass'}
        ]
      });

      final providerA = MockAiProvider(defaultResponse: confirmedMockJson);
      final engineA = FailureDiagnosisEngine.withProvider(
        projectRoot: rootPath,
        provider: providerA,
      );

      final resConfirmed = await engineA.diagnose(DiagnosisRequest(
        evidence: FailureEvidenceBundle(
          primaryError: 'Null check operator used on null value',
          items: const [
            DiagnosisEvidenceItem(
              id: 'ev_trace',
              type: EvidenceType.stackTrace,
              source: 'packages/pkg_core/lib/src/data_handler.dart:3:19',
              content:
                  '#0 DataHandler.processData (package:pkg_core/src/data_handler.dart:3:19)',
            )
          ],
          targetPackage: 'pkg_core',
        ),
      ));

      expect(resConfirmed.isSuccess, isTrue);
      expect(resConfirmed.diagnosis!.likelyCauses.first.certainty,
          equals(CauseCertainty.confirmed));

      // 2b. Circumstantial partial evidence -> possible
      final possibleMockJson = jsonEncode({
        'summary': 'Possible intermittent network timeout',
        'problem': 'Intermittent network timeout',
        'likelyCauses': [
          {
            'description': 'Flaky DNS resolution or slow proxy latency',
            'certainty': 'possible',
            'rationale': 'Circumstantial log message without stack trace'
          }
        ],
        'citedEvidence': ['generalLog'],
        'affectedComponents': ['packages/pkg_core/lib/src/data_handler.dart'],
        'recommendedFix': 'Increase timeout threshold',
        'risk': 'low',
        'verificationSteps': [
          {'stepNumber': 1, 'action': 'dart test', 'expectedOutcome': 'pass'}
        ]
      });

      final providerB = MockAiProvider(defaultResponse: possibleMockJson);
      final engineB = FailureDiagnosisEngine.withProvider(
        projectRoot: rootPath,
        provider: providerB,
      );

      final resPossible = await engineB.diagnose(DiagnosisRequest(
        evidence: FailureEvidenceBundle(
          primaryError: 'SocketException: Connection timed out',
          items: const [
            DiagnosisEvidenceItem(
              id: 'ev_log',
              type: EvidenceType.generalLog,
              source: 'network',
              content: 'Failed after 30000ms',
            )
          ],
          targetPackage: 'pkg_core',
        ),
      ));

      expect(resPossible.isSuccess, isTrue);
      expect(resPossible.diagnosis!.likelyCauses.first.certainty,
          equals(CauseCertainty.possible));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Evidence Pipeline (Stack Trace, Test Failure, Analyzer, CLI Error)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Evidence pipeline: ingests and cites stack trace, test failure, analyzer output, and CLI error',
        () async {
      scaffoldMonorepo();

      final provider = MockAiProvider(
          defaultResponse: jsonEncode({
        'summary': 'Multiple failure symptoms ingested',
        'problem': 'Multiple failure symptoms ingested',
        'likelyCauses': [
          {
            'description': 'Compilation and assertion failure',
            'certainty': 'probable',
            'rationale': 'Multiple evidence streams point to data_handler.dart'
          }
        ],
        'citedEvidence': [
          'Stack Trace: DataHandler.processData',
          'Test Failure: processData failure on null',
          'Analyzer Output: unused_local_variable',
          'CLI Error: exit code 64'
        ],
        'affectedComponents': ['packages/pkg_core/lib/src/data_handler.dart'],
        'recommendedFix': 'Refactor data_handler.dart',
        'risk': 'medium',
        'verificationSteps': [
          {'stepNumber': 1, 'action': 'dart test', 'expectedOutcome': 'pass'}
        ]
      }));

      final engine = FailureDiagnosisEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final trackedTest = TrackedTestCase(
        id: 'test_failed_01',
        name: 'processData failure on null',
        targetSourceFile: 'packages/pkg_core/lib/src/data_handler.dart',
        testFilePath: 'packages/pkg_core/test/data_handler_test.dart',
        state: TestTrackingState.failed,
        isHumanApproved: true,
        createdAt: DateTime.now(),
      );

      final evidence = FailureEvidenceBundle(
        primaryError: 'Multiple failure signals detected',
        targetPackage: 'pkg_core',
        failedTestRecord: trackedTest,
        items: const [
          DiagnosisEvidenceItem(
            id: 'ev_trace',
            type: EvidenceType.stackTrace,
            source: 'data_handler.dart:L3',
            content: '#0 DataHandler.processData (data_handler.dart:3)',
          ),
          DiagnosisEvidenceItem(
            id: 'ev_analyzer',
            type: EvidenceType.analyzerOutput,
            source: 'dart analyze',
            content: 'warning - unused_local_variable length at L3',
          ),
          DiagnosisEvidenceItem(
            id: 'ev_cli',
            type: EvidenceType.cliError,
            source: 'fps run',
            content: 'Command exited with code 64: missing arguments',
          ),
        ],
      );

      final result =
          await engine.diagnose(DiagnosisRequest(evidence: evidence));

      expect(result.isSuccess, isTrue);
      expect(result.diagnosis!.citedEvidence.length, equals(4));
      expect(
          result.diagnosis!.citedEvidence
              .any((e) => e.contains('Analyzer Output')),
          isTrue);
      expect(
          result.diagnosis!.citedEvidence.any((e) => e.contains('CLI Error')),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Historical-Report Integration
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Historical-report integration: locates and cites prior phase verification reports',
        () async {
      scaffoldMonorepo();

      final provider = MockAiProvider(
          defaultResponse: jsonEncode({
        'summary': 'Null pointer on uninitialized buffer',
        'problem': 'Null pointer on uninitialized buffer',
        'likelyCauses': [
          {
            'description': 'Buffer uninitialized',
            'certainty': 'confirmed',
            'rationale':
                'Matches limitation in phase_8_4_verification_report.txt'
          }
        ],
        'citedEvidence': ['report/phase_8_4_verification_report.txt'],
        'affectedComponents': ['packages/pkg_core/lib/src/data_handler.dart'],
        'recommendedFix': 'Initialize buffer eagerly',
        'risk': 'low',
        'verificationSteps': [
          {'stepNumber': 1, 'action': 'dart test', 'expectedOutcome': 'pass'}
        ]
      }));

      final engine = FailureDiagnosisEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.diagnose(DiagnosisRequest(
        evidence: const FailureEvidenceBundle(
          primaryError: 'Null pointer handling on uninitialized buffer',
          targetPackage: 'pkg_core',
        ),
      ));

      expect(result.isSuccess, isTrue);
      expect(result.historicalCitations, isNotEmpty);
      expect(
          result.historicalCitations
              .any((c) => c.contains('phase_8_4_verification_report.txt')),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Affected-Component Identification
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Affected-component identification: correctly narrows to failing package/file via 8.2 context',
        () async {
      scaffoldMonorepo();

      final provider = MockAiProvider(
          defaultResponse: jsonEncode({
        'summary': 'DataHandler failure',
        'problem': 'DataHandler failure',
        'likelyCauses': [
          {
            'description': 'Null dereference in data_handler.dart',
            'certainty': 'confirmed',
            'rationale': 'Localized strictly to pkg_core'
          }
        ],
        'citedEvidence': ['data_handler.dart'],
        'affectedComponents': ['packages/pkg_core/lib/src/data_handler.dart'],
        'recommendedFix': 'Fix null-safety',
        'risk': 'low',
        'verificationSteps': [
          {'stepNumber': 1, 'action': 'dart test', 'expectedOutcome': 'pass'}
        ]
      }));

      final engine = FailureDiagnosisEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.diagnose(DiagnosisRequest(
        evidence: const FailureEvidenceBundle(
          primaryError: 'DataHandler exception',
          targetPackage: 'pkg_core',
          targetFile: 'packages/pkg_core/lib/src/data_handler.dart',
        ),
      ));

      expect(result.isSuccess, isTrue);
      expect(result.diagnosis!.affectedComponents,
          contains('packages/pkg_core/lib/src/data_handler.dart'));
      // Does not pollute with unrelated pkg_cli
      expect(
          result.diagnosis!.affectedComponents
              .any((c) => c.contains('pkg_cli')),
          isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: No-Execution Safety (Zero Subprocesses, Zero File Writes)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. No-Execution Safety Invariant: diagnosis execution is strictly read-only with byte-identical workspace',
        () async {
      scaffoldMonorepo();

      // Snapshot workspace before diagnosis
      final filesBefore = <String, String>{};
      for (final entity in tempRoot.listSync(recursive: true)) {
        if (entity is File) {
          filesBefore[entity.path] = entity.readAsStringSync();
        }
      }

      final provider = MockAiProvider(
          defaultResponse: jsonEncode({
        'summary': 'Read-only safety check',
        'problem': 'Read-only safety check',
        'likelyCauses': [
          {
            'description': 'Safe check',
            'certainty': 'confirmed',
            'rationale': 'No side-effects'
          }
        ],
        'citedEvidence': [],
        'affectedComponents': ['packages/pkg_core/lib/src/data_handler.dart'],
        'recommendedFix': 'No-op',
        'risk': 'low',
        'verificationSteps': []
      }));

      final engine = FailureDiagnosisEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.diagnose(DiagnosisRequest(
        evidence: const FailureEvidenceBundle(
          primaryError: 'Safety verification error',
          targetPackage: 'pkg_core',
        ),
      ));

      expect(result.isSuccess, isTrue);

      // Verify all files are byte-for-byte identical after run
      final filesAfter = <String, String>{};
      for (final entity in tempRoot.listSync(recursive: true)) {
        if (entity is File) {
          filesAfter[entity.path] = entity.readAsStringSync();
        }
      }

      expect(filesAfter.length, equals(filesBefore.length));
      for (final path in filesBefore.keys) {
        expect(filesAfter[path], equals(filesBefore[path]));
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Sensitive-File Exclusion Respected
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Sensitive-File Respect: .env and credentials are completely excluded from AI provider prompt',
        () async {
      scaffoldMonorepo();

      File(p.join(rootPath, '.env'))
          .writeAsStringSync('PROD_AUTH_TOKEN=secret_token_123456789');
      File(p.join(rootPath, 'credentials.json'))
          .writeAsStringSync('{"apiKey": "my_super_secret_api_key"}');

      final provider = MockAiProvider(
          defaultResponse: jsonEncode({
        'summary': 'Safe diagnosis',
        'problem': 'Safe diagnosis',
        'likelyCauses': [
          {
            'description': 'Safe diagnosis',
            'certainty': 'confirmed',
            'rationale': 'No secrets passed'
          }
        ],
        'citedEvidence': [],
        'affectedComponents': ['packages/pkg_core/lib/src/data_handler.dart'],
        'recommendedFix': 'Fix logic',
        'risk': 'low',
        'verificationSteps': []
      }));

      final engine = FailureDiagnosisEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.diagnose(DiagnosisRequest(
        evidence: const FailureEvidenceBundle(
          primaryError: 'Secret safety check',
          targetPackage: 'pkg_core',
        ),
      ));

      expect(result.isSuccess, isTrue);
      expect(provider.recordedRequests, isNotEmpty);
      final sentPrompt = provider.recordedRequests.first.prompt;
      expect(sentPrompt.contains('PROD_AUTH_TOKEN'), isFalse);
      expect(sentPrompt.contains('secret_token_123456789'), isFalse);
      expect(sentPrompt.contains('my_super_secret_api_key'), isFalse);
      expect(sentPrompt.contains('.env'), isFalse);
      expect(sentPrompt.contains('credentials.json'), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Remediation & Verification Plan Quality
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Remediation & Verification Plan Quality: produces concrete actionable fix and human-executable verification steps',
        () async {
      scaffoldMonorepo();

      final provider = MockAiProvider(
          defaultResponse: jsonEncode({
        'summary': 'Null check operator used on a null value',
        'problem': 'Null check operator used on a null value',
        'likelyCauses': [
          {
            'description': 'Dereferencing raw!.length when raw is null',
            'certainty': 'confirmed',
            'rationale': 'Line 3 in data_handler.dart'
          }
        ],
        'citedEvidence': ['data_handler.dart:L3'],
        'affectedComponents': ['packages/pkg_core/lib/src/data_handler.dart'],
        'recommendedFix':
            'Replace `final length = raw!.length;` with `if (raw == null) return; final length = raw.length;`.',
        'risk': 'low',
        'verificationSteps': [
          {
            'stepNumber': 1,
            'action': 'dart test packages/pkg_core/test/data_handler_test.dart',
            'expectedOutcome': 'Test suite passes with 0 failures.'
          },
          {
            'stepNumber': 2,
            'action': 'dart analyze packages/pkg_core',
            'expectedOutcome': 'Zero static analysis issues found.'
          }
        ]
      }));

      final engine = FailureDiagnosisEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.diagnose(DiagnosisRequest(
        evidence: const FailureEvidenceBundle(
          primaryError: 'Null check operator used on a null value',
          targetPackage: 'pkg_core',
        ),
      ));

      expect(result.isSuccess, isTrue);
      final diag = result.diagnosis!;
      expect(diag.recommendedFix, contains('if (raw == null) return;'));
      expect(diag.verificationSteps.length, equals(2));
      expect(diag.verificationSteps[0].action, contains('dart test'));
      expect(diag.verificationSteps[1].action, contains('dart analyze'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: AI Provider Failure Handled Safely
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9. Provider Failure: unavailable provider returns structured failure result without crashing',
        () async {
      scaffoldMonorepo();

      final provider = MockAiProvider(
        injectedException: Exception('Simulated Diagnosis AI Provider Failure'),
      );
      final engine = FailureDiagnosisEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.diagnose(DiagnosisRequest(
        evidence: const FailureEvidenceBundle(
          primaryError: 'Fault tolerance check',
          targetPackage: 'pkg_core',
        ),
      ));

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage,
          contains('Simulated Diagnosis AI Provider Failure'));
      expect(result.diagnosis, isNull);
      expect(result.summary, contains('Diagnosis failed'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 10: Dual-Format Rendering (JSON and Markdown)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '10. Dual-Format Renderer: renders schema-valid JSON and structured Markdown',
        () {
      final now = DateTime.parse('2026-09-02T12:00:00.000Z');
      final result = DiagnosisResult(
        packageId: 'pkg_core',
        isSuccess: true,
        diagnosis: const FailureDiagnosis(
          problem: 'Null check failure',
          likelyCauses: [
            DiagnosedCause(
              description: 'Null dereference at line 3',
              certainty: CauseCertainty.confirmed,
              rationale: 'Direct reproduction from stack trace',
            )
          ],
          citedEvidence: ['data_handler.dart:L3'],
          affectedComponents: ['packages/pkg_core/lib/src/data_handler.dart'],
          recommendedFix: 'Add null check guard',
          risk: CodeReviewSeverity.low,
          verificationSteps: [
            VerificationStep(
              stepNumber: 1,
              action: 'dart test',
              expectedOutcome: 'pass',
            )
          ],
        ),
        summary: 'Diagnosed failure in pkg_core with 1 cause tier(s).',
        historicalCitations: ['report/phase_8_4_verification_report.txt'],
        durationMs: 95,
        timestamp: now,
      );

      const renderer = FailureDiagnosisRenderer();
      final jsonOutput = renderer.renderJson(result);
      final mdOutput = renderer.renderMarkdown(result);

      // JSON validation
      final decoded = jsonDecode(jsonOutput) as Map<String, dynamic>;
      expect(decoded['isSuccess'], isTrue);
      expect(decoded['diagnosis']['likelyCauses'][0]['certainty'],
          equals('confirmed'));
      expect(decoded['historicalCitations'].length, equals(1));

      // Markdown validation
      expect(mdOutput,
          contains('# Flutter Package Studio — AI Failure Diagnosis Report'));
      expect(mdOutput, contains('🟢 `[CONFIRMED CAUSE]`'));
      expect(mdOutput, contains('## 🛠️ Recommended Remediation Fix'));
      expect(mdOutput,
          contains('## 📋 Verification Plan (Human Action Required)'));
      expect(mdOutput, contains('report/phase_8_4_verification_report.txt'));
    });
  });
}
