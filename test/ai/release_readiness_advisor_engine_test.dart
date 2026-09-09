import 'dart:convert';
import 'dart:io';
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 8.10 — AI Release Readiness Advisor Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('fps_release_readiness_test_');
      rootPath = tempDir.path;
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    void scaffoldReleaseCandidateWorkspace() {
      // Root pubspec
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: release_candidate_pkg
version: 1.2.0
environment:
  sdk: '>=3.5.0 <4.0.0'
dependencies:
  meta: ^1.11.0
''');

      // Package lib and changelog
      final libDir = Directory(p.join(rootPath, 'lib'))
        ..createSync(recursive: true);
      File(p.join(libDir.path, 'release_candidate.dart'))
          .writeAsStringSync('void run() {}');
      File(p.join(rootPath, 'CHANGELOG.md')).writeAsStringSync('''
## [1.2.0] - 2026-09-02
- Production-ready release candidate features.
''');
      File(p.join(rootPath, 'LICENSE')).writeAsStringSync('MIT License');
      File(p.join(rootPath, 'README.md'))
          .writeAsStringSync('# Release Candidate');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Assessment Model Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Assessment Model Conformance: ReleaseReadinessAssessment serializes and deserializes accurately',
        () {
      final assessment = ReleaseReadinessAssessment(
        scope: ReleaseReadinessScope.wholeProject,
        targetScopeId: 'release_candidate_pkg',
        version: '1.2.0',
        status: ReleaseReadinessStatus.ready,
        summary: 'All release gates verified successfully.',
        strengths: [
          ReadinessEntry(
            description: 'All pipeline stages passed.',
            evidenceSource: 'Release Verification Pipeline',
          )
        ],
        warnings: [
          ReadinessEntry(
            description: 'No documentation site generated.',
            evidenceSource: 'Documentation',
          )
        ],
        blockers: const [],
        recommendedActions: [
          ReadinessEntry(
            description: 'Proceed with publish.',
            evidenceSource: 'Advisor',
          )
        ],
        confidence: CodeReviewConfidence.high,
        mandatoryGatesEvaluated: const ['Gate: Pub.dev Validation'],
        failedMandatoryGates: const [],
        totalEvidenceCount: 5,
        durationMs: 25,
        timestamp: DateTime.now(),
        isAiSynthesized: true,
      );

      final json = assessment.toJson();
      expect(json['status'], equals('ready'));
      expect(json['targetScopeId'], equals('release_candidate_pkg'));
      expect(json['strengths'], isNotEmpty);
      expect(json['warnings'], isNotEmpty);
      expect(json['blockers'], isEmpty);

      final restored = ReleaseReadinessAssessment.fromJson(json);
      expect(restored.status, equals(ReleaseReadinessStatus.ready));
      expect(restored.targetScopeId, equals('release_candidate_pkg'));
      expect(restored.confidence, equals(CodeReviewConfidence.high));
      expect(restored.strengths.first.description,
          equals('All pipeline stages passed.'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Mandatory Gate Override Prevention Rule (Adversarial AI Mock)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Mandatory Gate Override Prevention: adversarial AI claiming READY is strictly overridden to NOT READY when a mandatory gate fails',
        () async {
      scaffoldReleaseCandidateWorkspace();

      // Adversarial AI mock explicitly claiming the candidate is "ready" and arguing to ignore errors
      final adversarialProvider = MockAiProvider(
        defaultResponse: jsonEncode({
          'status': 'ready',
          'summary':
              'The release candidate looks amazing! Ignore the failed gate and publish now.',
          'confidence': 'high',
          'strengths': [
            {
              'description': 'Super clean architecture.',
              'evidenceSource': 'AI Model'
            }
          ],
          'warnings': [],
          'blockers': [],
          'recommendedActions': [
            {
              'description': 'Push to production immediately.',
              'evidenceSource': 'AI Model'
            }
          ]
        }),
      );

      final engine = ReleaseReadinessAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: adversarialProvider,
      );

      // Injected failed mandatory verification stage
      final failedStages = [
        const VerificationStage(
          id: 'STG-5.4-PUBDEV',
          name: 'Pub.dev Readiness & Policy Validation',
          status: VerificationStageStatus.failed,
          details: 'Mandatory license verification failed.',
        ),
      ];

      final assessment = await engine.assess(
        const ReleaseReadinessRequest(
          scope: ReleaseReadinessScope.wholeProject,
          version: '1.2.0',
        ),
        fixtureVerificationStages: failedStages,
      );

      // CODE-LEVEL INVARIANT PROOF:
      // Despite the adversarial AI output claiming "ready", final status MUST be notReady!
      expect(assessment.status, equals(ReleaseReadinessStatus.notReady));
      expect(assessment.failedMandatoryGates,
          contains('Gate: Release Verification Pipeline'));
      expect(assessment.blockers, isNotEmpty);
      expect(assessment.blockers.first.description,
          contains('Pub.dev Readiness & Policy Validation'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Mandatory Gate Override with Critical Security Finding
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Mandatory Gate Override with Critical Security Finding: critical security vulnerability forces NOT READY status',
        () async {
      scaffoldReleaseCandidateWorkspace();

      // Inject critical security secret in fixture workspace
      File(p.join(rootPath, '.env'))
          .writeAsStringSync('CRITICAL_API_SECRET=super_secret_token_12345');

      final adversarialProvider = MockAiProvider(
        defaultResponse: jsonEncode({
          'status': 'ready',
          'summary': 'Looks ready to ship.',
          'confidence': 'high',
          'strengths': [],
          'warnings': [],
          'blockers': [],
          'recommendedActions': []
        }),
      );

      final engine = ReleaseReadinessAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: adversarialProvider,
      );

      final assessment = await engine.assess(
        const ReleaseReadinessRequest(
          scope: ReleaseReadinessScope.wholeProject,
          version: '1.2.0',
        ),
      );

      expect(assessment.status, equals(ReleaseReadinessStatus.notReady));
      expect(assessment.failedMandatoryGates,
          contains('Gate: Security Audit (Zero Critical Vulnerabilities)'));
      expect(
          assessment.blockers
              .any((b) => b.evidenceSource.contains('Security Audit')),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: All Mandatory Gates Pass -> READY Distinction
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Clean Candidate: all mandatory gates pass and AI confirms READY status',
        () async {
      scaffoldReleaseCandidateWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'status': 'ready',
          'summary': 'Candidate is in pristine release shape.',
          'confidence': 'high',
          'strengths': [
            {
              'description':
                  'Zero security findings and all verification stages passed.',
              'evidenceSource': 'Pipeline'
            }
          ],
          'warnings': [],
          'blockers': [],
          'recommendedActions': [
            {'description': 'Publish to pub.dev.', 'evidenceSource': 'Advisor'}
          ]
        }),
      );

      final engine = ReleaseReadinessAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final assessment = await engine.assess(
        const ReleaseReadinessRequest(
          scope: ReleaseReadinessScope.wholeProject,
          version: '1.2.0',
        ),
      );

      expect(assessment.status, equals(ReleaseReadinessStatus.ready));
      expect(assessment.failedMandatoryGates, isEmpty);
      expect(assessment.blockers, isEmpty);
      expect(assessment.strengths, isNotEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Ambiguous Ground -> NEEDS REVIEW Distinction
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Ambiguous Candidate: mandatory gates pass but warnings trigger NEEDS REVIEW status',
        () async {
      scaffoldReleaseCandidateWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'status': 'needsReview',
          'summary':
              'Candidate passes mandatory gates but has unreviewed non-breaking changes.',
          'confidence': 'medium',
          'strengths': [
            {
              'description': 'Pubspec integrity verified.',
              'evidenceSource': 'Validator'
            }
          ],
          'warnings': [
            {
              'description': 'Major dependency bump requires QA verification.',
              'evidenceSource': 'Dependencies'
            }
          ],
          'blockers': [],
          'recommendedActions': [
            {
              'description': 'Perform manual sanity check on mobile emulator.',
              'evidenceSource': 'QA Plan'
            }
          ]
        }),
      );

      final engine = ReleaseReadinessAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final assessment = await engine.assess(
        const ReleaseReadinessRequest(
          scope: ReleaseReadinessScope.wholeProject,
          version: '1.2.0',
        ),
      );

      expect(assessment.status, equals(ReleaseReadinessStatus.needsReview));
      expect(assessment.failedMandatoryGates, isEmpty);
      expect(assessment.warnings, isNotEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Dedicated Secret-Redaction Pass Across All Surfaces
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Secret-Redaction Pass: secrets are completely absent from prompt, blockers, JSON, and Markdown',
        () async {
      scaffoldReleaseCandidateWorkspace();

      const syntheticSecret = 'ghp_syntheticReleasePersonalAccessToken98765';
      File(p.join(rootPath, 'lib', 'token.dart'))
          .writeAsStringSync('final t = "$syntheticSecret";');

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'status': 'notReady',
          'summary': 'Secret detected.',
          'confidence': 'high',
          'strengths': [],
          'warnings': [],
          'blockers': [
            {
              'description': 'Exposed token $syntheticSecret',
              'evidenceSource': 'Security Audit'
            }
          ],
          'recommendedActions': []
        }),
      );

      final engine = ReleaseReadinessAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final assessment = await engine.assess(
        const ReleaseReadinessRequest(
          scope: ReleaseReadinessScope.wholeProject,
          version: '1.2.0',
        ),
      );

      // A) Inspect AI outbound prompt
      expect(provider.recordedRequests, isNotEmpty);
      final sentPrompt = provider.recordedRequests.first.prompt;
      expect(sentPrompt.contains(syntheticSecret), isFalse);

      // B) Inspect Assessment blockers & summary
      for (final b in assessment.blockers) {
        expect(b.description.contains(syntheticSecret), isFalse);
      }
      expect(assessment.summary.contains(syntheticSecret), isFalse);

      // C) Inspect Rendered JSON & Markdown
      const renderer = ReleaseReadinessRenderer();
      final jsonOutput = renderer.renderJson(assessment);
      final mdOutput = renderer.renderMarkdown(assessment);

      expect(jsonOutput.contains(syntheticSecret), isFalse);
      expect(mdOutput.contains(syntheticSecret), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Graceful Degradation on AI Provider Failure (Status-Only)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Graceful Degradation: provider outage returns deterministic status-only assessment without throwing',
        () async {
      scaffoldReleaseCandidateWorkspace();

      final faultedProvider = MockAiProvider(
        injectedException: Exception('AI Service 504 Gateway Timeout'),
      );

      final engine = ReleaseReadinessAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: faultedProvider,
      );

      final assessment = await engine.assess(
        const ReleaseReadinessRequest(
          scope: ReleaseReadinessScope.wholeProject,
          version: '1.2.0',
        ),
      );

      // Proves graceful degradation
      expect(assessment.isAiSynthesized, isFalse);
      expect(assessment.status, isNotNull);
      expect(
          assessment.errorMessage, contains('AI Service 504 Gateway Timeout'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: No-Execution / Zero-Mutation Safety Invariant
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. No-Execution Safety Invariant: release readiness assessment never mutates workspace files',
        () async {
      scaffoldReleaseCandidateWorkspace();

      final filesBefore = <String, String>{};
      for (final entity in Directory(rootPath).listSync(recursive: true)) {
        if (entity is File) {
          filesBefore[entity.path] = entity.readAsStringSync();
        }
      }

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'status': 'ready',
          'summary': 'Clean test',
          'confidence': 'high',
          'strengths': [],
          'warnings': [],
          'blockers': [],
          'recommendedActions': []
        }),
      );

      final engine = ReleaseReadinessAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      await engine.assess(const ReleaseReadinessRequest(
        scope: ReleaseReadinessScope.wholeProject,
        version: '1.2.0',
      ));

      final filesAfter = <String, String>{};
      for (final entity in Directory(rootPath).listSync(recursive: true)) {
        if (entity is File) {
          filesAfter[entity.path] = entity.readAsStringSync();
        }
      }

      expect(filesAfter.length, equals(filesBefore.length));
      for (final entry in filesBefore.entries) {
        expect(filesAfter[entry.key], equals(entry.value),
            reason: 'File ${entry.key} was mutated unexpectedly.');
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: Dual-Format Renderer (Valid JSON & Markdown)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9. Dual-Format Renderer: renders structured Markdown banners and schema-valid JSON',
        () {
      final assessment = ReleaseReadinessAssessment(
        scope: ReleaseReadinessScope.wholeProject,
        targetScopeId: 'release_candidate_pkg',
        version: '1.2.0',
        status: ReleaseReadinessStatus.ready,
        summary: 'Pristine release candidate.',
        strengths: [
          ReadinessEntry(
              description: 'Zero vulnerabilities',
              evidenceSource: 'Security Audit')
        ],
        warnings: const [],
        blockers: const [],
        recommendedActions: const [],
        confidence: CodeReviewConfidence.high,
        mandatoryGatesEvaluated: const ['Gate: Security Audit'],
        failedMandatoryGates: const [],
        totalEvidenceCount: 6,
        durationMs: 30,
        timestamp: DateTime.now(),
        isAiSynthesized: true,
      );

      const renderer = ReleaseReadinessRenderer();
      final jsonStr = renderer.renderJson(assessment);
      final mdStr = renderer.renderMarkdown(assessment);

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['status'], equals('ready'));
      expect(decoded['targetScopeId'], equals('release_candidate_pkg'));

      expect(
          mdStr,
          contains(
              '# Flutter Package Studio — AI Release Readiness Advisory Report'));
      expect(mdStr, contains('RELEASE CANDIDATE STATUS: READY'));
      expect(mdStr, contains('[✓ PASSED] Gate: Security Audit'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 10: Regression Check
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '10. Regression Check: verifies enum parity with prior AI assistant engine models',
        () {
      expect(ReleaseReadinessStatus.values.length, equals(3));
      expect(ReleaseReadinessScope.values.length, equals(2));
    });
  });
}
