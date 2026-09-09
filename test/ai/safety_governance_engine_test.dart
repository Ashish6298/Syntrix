import 'dart:io';
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 8.15 — AI Safety, Governance & Verification Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('fps_safety_governance_test_');
      rootPath = tempDir.path;

      // Scaffold workspace
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: safety_workspace
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      final libDir = Directory(p.join(rootPath, 'lib'))
        ..createSync(recursive: true);
      File(p.join(libDir.path, 'main.dart')).writeAsStringSync('''
void main() {
  print('Safety Verified Workspace');
}
''');

      // Sensitive files to verify protection
      File(p.join(rootPath, '.env'))
          .writeAsStringSync('API_KEY=ghp_SECRET_TOKEN_99999\n');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Full Safety, Governance & Verification Execution
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Safety Audit: executes all 5 verification pillars and produces PASS decision',
        () async {
      final engine = SafetyGovernanceEngine(projectRoot: rootPath);
      final result = await engine.verifyMilestone8Safety();

      expect(result.allGatesPassed, isTrue);
      expect(result.existingFunctionalityPreserved, isTrue);
      expect(result.securityVerificationPassed, isTrue);
      expect(result.aiSafetyVerificationPassed, isTrue);
      expect(result.unresolvedBlockers, isEmpty);
      expect(result.readyForMilestone9, isTrue);
      expect(result.checks, isNotEmpty);
      expect(result.checks.length, greaterThanOrEqualTo(10));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Pillar 1 (Security) — Secret Leakage & Credential Masking
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Pillar 1 (Security): SecretRedactor and SensitiveFileFilter prevent credential leaks',
        () {
      const prompt =
          'Deploying with aws_secret_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY and ghp_test123456';
      final clean = SecretRedactor.redact(prompt);
      expect(
          clean, isNot(contains('wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY')));
      expect(clean, contains('[REDACTED_AWS_SECRET]'));

      final filter = SensitiveFileFilter.fromProjectRoot(rootPath);
      expect(filter.evaluateFile(relativePath: '.env').isSafe, isFalse);
      expect(filter.evaluateFile(relativePath: 'android/key.properties').isSafe,
          isFalse);
      expect(filter.evaluateFile(relativePath: 'lib/main.dart').isSafe, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Pillar 2 (Reliability) — Provider Outage & Timeout Handling
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Pillar 2 (Reliability): provider failures wrap cleanly in structured response without crash',
        () async {
      final failingProvider = MockAiProvider(
        injectedException: Exception('Remote service 503 unavailable'),
      );
      final engine = CommandCenterEngine(
        projectRoot: rootPath,
        provider: failingProvider,
      );
      final resp = await engine.execute(
        CommandCenterRequest(
          capability: CommandCenterCapability.analyze,
          prompt: 'Analyze template',
        ),
      );

      expect(resp.isSuccess, isFalse);
      expect(resp.errorMessage, isNotNull);
      expect(resp.durationMs, greaterThanOrEqualTo(0));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Pillar 3 (Determinism) — Stable Serialization & Idempotent Reports
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Pillar 3 (Determinism): pure renderers output deterministic, identical JSON and Markdown',
        () async {
      final engine = SafetyGovernanceEngine(projectRoot: rootPath);
      final audit = await engine.verifyMilestone8Safety();
      const renderer = SafetyGovernanceRenderer();

      final json1 = renderer.renderJson(audit);
      final json2 = renderer.renderJson(audit);
      expect(json1, equals(json2));

      final md1 = renderer.renderMarkdown(audit);
      final md2 = renderer.renderMarkdown(audit);
      expect(md1, equals(md2));
      expect(md1, contains('All verification gates passed: YES'));
      expect(md1, contains('Ready for Milestone 9: YES'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Pillar 4 (Safety) — Release Gate Immutability
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Pillar 4 (Safety): AI can never downgrade or override mandatory release failures',
        () async {
      final releaseEngine = ReleaseReadinessAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: MockAiProvider(defaultResponse: '{"status": "ready"}'),
      );

      // Evaluate with mock failed gate
      final assessment = await releaseEngine.assess(
        const ReleaseReadinessRequest(
            scope: ReleaseReadinessScope.wholeProject),
        fixtureVerificationStages: [
          const VerificationStage(
            id: 'security_gate',
            name: 'Security Gate',
            status: VerificationStageStatus.failed,
            details: 'Critical vulnerability detected in dependency',
          ),
        ],
      );

      // Non-negotiable safety invariant: Deterministic lock to notReady
      expect(assessment.status, equals(ReleaseReadinessStatus.notReady));
      expect(assessment.failedMandatoryGates, isNotEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Pillar 4 (Safety) — Controlled Code Modification Approval Gate
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Pillar 4 (Safety): code modification requires explicit approval and rejects invalid patches',
        () async {
      final modEngine = CodeModificationEngine.withProvider(
        projectRoot: rootPath,
        provider: MockAiProvider(),
      );

      final proposal = CodeModificationProposal(
        proposalId: 'prop_test_001',
        requirement: 'Refactor client',
        summary: 'Propose client updates',
        affectedFiles: const ['lib/main.dart'],
        patches: [
          FilePatch(
            relativePath: 'lib/main.dart',
            patchType: FilePatchType.modify,
            description: 'Update main method',
            diff: '@@ -1 +1 @@\n-print(1);\n+print(2);',
          ),
        ],
        safetyPolicy:
            const CodeModificationSafetyPolicy(requireExplicitApproval: true),
        validation: const PatchValidationPipelineResult(
          patchValid: true,
          testsPassed: true,
          analyzerPassed: true,
          formatterPassed: true,
        ),
        totalLinesAdded: 1,
        totalLinesRemoved: 1,
        isEligibleForApplication: true,
        durationMs: 10,
        timestamp: DateTime.now(),
      );

      // 1. Without explicit approval -> rejected
      final resNoApproval = await modEngine.applyModification(
        proposal: proposal,
        explicitApproval: false,
      );
      expect(resNoApproval.success, isFalse);
      expect(resNoApproval.message,
          contains('Explicit execution approval is mandatory'));

      // 2. Ineligible proposal -> rejected
      final ineligibleProposal = CodeModificationProposal(
        proposalId: 'prop_test_002',
        requirement: 'Refactor client',
        summary: 'Propose client updates',
        affectedFiles: const ['lib/main.dart'],
        patches: const [],
        safetyPolicy: const CodeModificationSafetyPolicy(),
        validation: const PatchValidationPipelineResult(
          patchValid: false,
          testsPassed: false,
          analyzerPassed: false,
          formatterPassed: false,
        ),
        totalLinesAdded: 0,
        totalLinesRemoved: 0,
        isEligibleForApplication: false,
        durationMs: 10,
        timestamp: DateTime.now(),
      );
      final resIneligible = await modEngine.applyModification(
        proposal: ineligibleProposal,
        explicitApproval: true,
      );
      expect(resIneligible.success, isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Pillar 5 (Testing) — Dual Model Serialization & Roundtrip
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Model Conformance: SafetyGovernanceResult serializes and deserializes cleanly',
        () {
      final original = SafetyGovernanceResult(
        projectRoot: '/test/workspace',
        allGatesPassed: true,
        existingFunctionalityPreserved: true,
        securityVerificationPassed: true,
        aiSafetyVerificationPassed: true,
        unresolvedBlockers: const [],
        readyForMilestone9: true,
        checks: [
          const SafetyCheckItem(
            id: 'SEC_001',
            title: 'Secret Test',
            category: SafetyVerificationCategory.security,
            status: VerificationGateStatus.passed,
            description: 'No secrets leaked',
          ),
        ],
        summary: 'All clear',
        durationMs: 120,
        timestamp: DateTime.now(),
      );

      final json = original.toJson();
      final roundtrip = SafetyGovernanceResult.fromJson(json);

      expect(roundtrip.allGatesPassed, equals(original.allGatesPassed));
      expect(roundtrip.securityVerificationPassed,
          equals(original.securityVerificationPassed));
      expect(roundtrip.readyForMilestone9, equals(original.readyForMilestone9));
      expect(roundtrip.checks.length, equals(1));
      expect(roundtrip.checks.first.id, equals('SEC_001'));
    });
  });
}
