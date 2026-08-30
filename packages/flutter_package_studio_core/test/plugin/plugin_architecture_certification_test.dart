import 'dart:io' as io;
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 7.18: Plugin Architecture Hardening & Certification Tests', () {
    late io.Directory tempDir;
    late PluginArchitectureCertifier certifier;

    setUp(() {
      tempDir = io.Directory.systemTemp.createTempSync('fps_cert_test_');
      certifier = PluginArchitectureCertifier();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Complete Continuous Functional E2E Lifecycle Pass (CERT-FUNC-01)
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '1. Functional E2E: single continuous flow through discovery, validation, registration, dependencies, activation, execution, diagnostics, upgrade, and removal (CERT-FUNC-01)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final e2eItem = result.items.firstWhere((i) => i.id == 'CERT-FUNC-01');

      if (!e2eItem.isPassed) {
        print('CERT-FUNC-01 failure evidence: ${e2eItem.evidence}');
      }
      expect(e2eItem.status, equals(PluginCertificationStatus.passed));
      expect(e2eItem.evidence, contains('Successfully traversed'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Individually Named Adversarial Security Scenarios (CERT-SEC-01 to 07)
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '2a. Adversarial Security: undeclared permission exceedance attempt is actively caught and denied (CERT-SEC-01)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-SEC-01');
      expect(item.status, equals(PluginCertificationStatus.passed));
      expect(item.isAdversarial, isTrue);
    });

    test(
        '2b. Adversarial Security: borderline invalid manifest rejection fails closed (CERT-SEC-02)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-SEC-02');
      expect(item.status, equals(PluginCertificationStatus.passed));
      expect(item.isAdversarial, isTrue);
    });

    test(
        '2c. Adversarial Security: malicious configuration payload (SQL injection style) is safely sanitized as literal (CERT-SEC-03)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-SEC-03');
      expect(item.status, equals(PluginCertificationStatus.passed));
      expect(item.isAdversarial, isTrue);
    });

    test(
        '2d. Adversarial Security: active path traversal attack outside sandbox root is blocked (CERT-SEC-04)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-SEC-04');
      expect(item.status, equals(PluginCertificationStatus.passed));
      expect(item.isAdversarial, isTrue);
    });

    test(
        '2e. Adversarial Security: unauthorized process execution attempt without permission is denied (CERT-SEC-05)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-SEC-05');
      expect(item.status, equals(PluginCertificationStatus.passed));
      expect(item.isAdversarial, isTrue);
    });

    test(
        '2f. Adversarial Security: unauthorized credential/environment access attempt without permission is blocked (CERT-SEC-06)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-SEC-06');
      expect(item.status, equals(PluginCertificationStatus.passed));
      expect(item.isAdversarial, isTrue);
    });

    test(
        '2g. Adversarial Security: unauthorized network socket connection attempt without permission is denied (CERT-SEC-07)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-SEC-07');
      expect(item.status, equals(PluginCertificationStatus.passed));
      expect(item.isAdversarial, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Injected Failure & Reliability Scenarios (CERT-REL-01 to 05)
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '3a. Injected Failure: mid-execution internal plugin crash is isolated without unwinding host (CERT-REL-01)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-REL-01');
      expect(item.status, equals(PluginCertificationStatus.passed));
    });

    test(
        '3b. Injected Failure: consecutive crash circuit-breaker quarantines failing plugin instance (CERT-REL-02)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-REL-02');
      expect(item.status, equals(PluginCertificationStatus.passed));
    });

    test(
        '3c. Injected Failure: corrupted persisted state document on disk is safely absorbed without crash (CERT-REL-03)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-REL-03');
      expect(item.status, equals(PluginCertificationStatus.passed));
    });

    test(
        '3d. Injected Failure: missing or broken dependency graph evaluates fail-closed gracefully (CERT-REL-04)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-REL-04');
      expect(item.status, equals(PluginCertificationStatus.passed));
    });

    test(
        '3e. Injected Failure: lifecycle initialization crash properly transitions to initializationFailed state (7.7) (CERT-REL-05)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-REL-05');
      expect(item.status, equals(PluginCertificationStatus.passed));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Compound Hostile Re-Audit of Previously-Fixed Gaps (CERT-HOSTILE-01 to 05)
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '4a. Compound Hostile: baseline overlap with borderline trust, excess perms, dependencies, and concurrent upgrade (CERT-HOSTILE-01)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-HOSTILE-01');
      expect(item.status, equals(PluginCertificationStatus.passed));
      expect(item.isAdversarial, isTrue);
      expect(item.evidence, contains('TRUSTED tier'));
    });

    test(
        '4b. Compound Hostile: abandoned future absorption under concurrent hostile load (7.9) (CERT-HOSTILE-02)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-HOSTILE-02');
      expect(item.status, equals(PluginCertificationStatus.passed));
      expect(item.isAdversarial, isTrue);
      expect(item.evidence, contains('safely contained'));
    });

    test(
        '4c. Compound Hostile: state-store atomic write and temporary file cleanup under compound stress (7.11) (CERT-HOSTILE-03)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-HOSTILE-03');
      expect(item.status, equals(PluginCertificationStatus.passed));
      expect(item.isAdversarial, isTrue);
      expect(item.evidence, contains('atomic write/rename boundary'));
    });

    test(
        '4d. Compound Hostile: sandbox path traversal rejection under concurrent hostile load (7.13) (CERT-HOSTILE-04)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-HOSTILE-04');
      expect(item.status, equals(PluginCertificationStatus.passed));
      expect(item.isAdversarial, isTrue);
      expect(item.evidence, contains('SandboxFileSystem strictly intercepted'));
    });

    test(
        '4e. Compound Hostile: core file and blocking dependent protection during removal under load (7.16) (CERT-HOSTILE-05)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-HOSTILE-05');
      expect(item.status, equals(PluginCertificationStatus.passed));
      expect(item.isAdversarial, isTrue);
      expect(item.evidence, contains('blocking and strictly excluded'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Determinism Verification Across All 6 Required Artifact Types (CERT-DET-01 to 06)
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '5a. Determinism: JSON diagnostic serialization byte-identical equality (CERT-DET-01)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-DET-01');
      expect(item.status, equals(PluginCertificationStatus.passed));
    });

    test(
        '5b. Determinism: Markdown diagnostic report rendering byte-identical equality (CERT-DET-02)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-DET-02');
      expect(item.status, equals(PluginCertificationStatus.passed));
    });

    test(
        '5c. Determinism: structured validation results for contract (7.1) and config (7.5) byte-identical equality (CERT-DET-03)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-DET-03');
      expect(item.status, equals(PluginCertificationStatus.passed));
    });

    test(
        '5d. Determinism: upgrade migration plan computation byte-identical equality (7.15) (CERT-DET-04)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-DET-04');
      expect(item.status, equals(PluginCertificationStatus.passed));
    });

    test(
        '5e. Determinism: removal plan computation byte-identical equality (7.16) (CERT-DET-05)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-DET-05');
      expect(item.status, equals(PluginCertificationStatus.passed));
    });

    test(
        '5f. Determinism: registry state & capability query representation byte-identical equality (7.3) (CERT-DET-06)',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);
      final item = result.items.firstWhere((i) => i.id == 'CERT-DET-06');
      expect(item.status, equals(PluginCertificationStatus.passed));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Overall Verdict Generation & Certification Guarantee
    // ─────────────────────────────────────────────────────────────────────────
    test(
        '6. Certification Verdict: overall verdict is CERTIFIED when all 24 gate checks pass',
        () async {
      final result =
          await certifier.runCertificationPass(sandboxRootPath: tempDir.path);

      expect(result.totalScenarios, equals(24));
      expect(result.passedScenarios, equals(24));
      expect(result.failedScenarios, equals(0));
      expect(result.isCertified, isTrue);
      expect(result.verdict, equals(Milestone7CertificationVerdict.certified));
      expect(result.findings, isEmpty);

      final markdown = result.toMarkdownReport();
      expect(markdown, contains('**Verdict:** `CERTIFIED`'));
      expect(markdown, contains('## Category Breakdown'));
    });
  });
}
