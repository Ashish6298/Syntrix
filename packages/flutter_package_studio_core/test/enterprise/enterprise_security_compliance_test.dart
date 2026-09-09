import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 9.7 — Enterprise Security Policy & Compliance Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_enterprise_sec_test_');
      rootPath = tempDir.path;

      // Scaffold clean workspace
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: compliance_sample_pkg
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');
      final libDir = Directory(p.join(rootPath, 'lib'))
        ..createSync(recursive: true);
      File(p.join(libDir.path, 'main.dart'))
          .writeAsStringSync('void main() {}');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Profile Presets (Standard, Enterprise, Financial, Healthcare, Govt)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Profile Presets: configures industry and enterprise policy presets accurately',
        () {
      final finDoc = EnterpriseSecurityCompliancePolicy.fromProfile(
          EnterpriseComplianceProfile.financial);
      expect(finDoc.profile, equals(EnterpriseComplianceProfile.financial));
      expect(finDoc.requireZeroSecrets, isTrue);
      expect(finDoc.requireEncryptedArtifacts, isTrue);
      expect(finDoc.requireFormalSecurityReview, isTrue);
      expect(finDoc.maxAllowedCriticalFindings, equals(0));
      expect(finDoc.maxAllowedHighFindings, equals(0));

      final healthDoc = EnterpriseSecurityCompliancePolicy.fromProfile(
          EnterpriseComplianceProfile.healthcare);
      expect(healthDoc.requireEncryptedArtifacts, isTrue);

      final stdDoc = EnterpriseSecurityCompliancePolicy.fromProfile(
          EnterpriseComplianceProfile.standard);
      expect(stdDoc.requireEncryptedArtifacts, isFalse);

      // JSON roundtrip
      final json = finDoc.toJson();
      final roundtrip = EnterpriseSecurityCompliancePolicy.fromJson(json);
      expect(roundtrip.profile, equals(finDoc.profile));
      expect(roundtrip.requireEncryptedArtifacts, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Clean Compliance Run on Standard Profile
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Clean Assessment: clean project passes standard and enterprise compliance profiles',
        () async {
      final engine = EnterpriseSecurityComplianceEngine(projectRoot: rootPath);
      final result = await engine.assessCompliance();

      expect(result.isCompliant, isTrue);
      expect(result.isBlocked, isFalse);
      expect(result.criticalViolations, equals(0));
      expect(result.failedGates, isEmpty);
      expect(result.passedGates, contains('secret_detection'));
      expect(result.passedGates, contains('sensitive_file_filter'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Sensitive File Rule Violation
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Sensitive File Control: flags .env or key.properties violation and blocks assessment',
        () async {
      // Create sensitive .env file
      File(p.join(rootPath, '.env'))
          .writeAsStringSync('DATABASE_SECRET=xyz999\n');

      final engine = EnterpriseSecurityComplianceEngine(projectRoot: rootPath);
      final result = await engine.assessCompliance();

      expect(result.isCompliant, isFalse);
      expect(result.isBlocked, isTrue);
      expect(result.failedGates, contains('sensitive_file_filter'));

      final sensitiveFinding = result.controlFindings.firstWhere(
        (f) => f.controlId == 'SEC_CTL_002_SENSITIVE_FILE_BOUNDARY',
      );
      expect(sensitiveFinding.status, equals(ComplianceStatus.failed));
      expect(sensitiveFinding.isBlocking, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Financial Profile Encryption & Formal Review Requirements
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Financial Profile: enforces encryption and formal security auditor sign-off',
        () async {
      final engine = EnterpriseSecurityComplianceEngine(projectRoot: rootPath);

      final finPolicy = EnterpriseSecurityCompliancePolicy.fromProfile(
          EnterpriseComplianceProfile.financial);

      // Without formal security review completed -> FAILS
      final unreviewedResult = await engine.assessCompliance(
        policy: finPolicy,
        operationalEvidence: {
          'formal_security_review_completed': false,
          'encrypted_artifacts_verified': true,
        },
      );

      expect(unreviewedResult.isCompliant, isFalse);
      expect(unreviewedResult.failedGates, contains('formal_security_review'));

      // With formal security review and encrypted artifacts -> PASSES
      final reviewedResult = await engine.assessCompliance(
        policy: finPolicy,
        operationalEvidence: {
          'formal_security_review_completed': true,
          'encrypted_artifacts_verified': true,
        },
      );

      expect(reviewedResult.isCompliant, isTrue);
      expect(reviewedResult.isBlocked, isFalse);
      expect(reviewedResult.failedGates, isEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Vulnerability Threshold Limits
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Vulnerability Thresholds: blocks when critical/high vulnerability limits are exceeded',
        () async {
      final engine = EnterpriseSecurityComplianceEngine(projectRoot: rootPath);

      final result = await engine.assessCompliance(
        operationalEvidence: {
          'critical_vulnerabilities': 2,
        },
      );

      expect(result.isCompliant, isFalse);
      expect(result.isBlocked, isTrue);
      expect(result.failedGates, contains('dependency_security_audit'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Pure Security Compliance Renderer Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Renderer Conformance: generates deterministic JSON and Markdown compliance reports',
        () async {
      final engine = EnterpriseSecurityComplianceEngine(projectRoot: rootPath);
      final result = await engine.assessCompliance();
      const renderer = EnterpriseSecurityComplianceRenderer();

      final json1 = renderer.renderJson(result);
      final json2 = renderer.renderJson(result);
      expect(json1, equals(json2));

      final md = renderer.renderMarkdown(result);
      expect(md, contains('# Enterprise Security Policy & Compliance Report'));
      expect(md, contains('**Compliance Profile**: `Standard Compliance`'));
      expect(md, contains('Compliant: YES'));
    });
  });
}
