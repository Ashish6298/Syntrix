import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 9.1 — Enterprise Configuration & Policy Engine Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_enterprise_policy_test_');
      rootPath = tempDir.path;

      // Scaffold project workspace
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: enterprise_sample_pkg
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
''');

      final libDir = Directory(p.join(rootPath, 'lib'))..createSync(recursive: true);
      File(p.join(libDir.path, 'main.dart')).writeAsStringSync('''
void main() => print('Enterprise Ready');
''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Model Conformance & Predefined Profile Presets
    // ─────────────────────────────────────────────────────────────────────────

    test('1. Model Conformance: Predefined profiles configure declarative rules accurately', () {
      final strictDoc = EnterprisePolicyDocument.fromProfile(EnterprisePolicyProfile.strict);
      expect(strictDoc.profile, equals(EnterprisePolicyProfile.strict));
      expect(strictDoc.enforcementMode, equals(PolicyEnforcementMode.strict));
      expect(strictDoc.releasePolicy.requireSecurityAudit, isTrue);
      expect(strictDoc.releasePolicy.requirePubDevValidation, isTrue);
      expect(strictDoc.releasePolicy.requireManifest, isTrue);
      expect(strictDoc.releasePolicy.requireReleaseVerification, isTrue);
      expect(strictDoc.releasePolicy.requireChangelog, isTrue);
      expect(strictDoc.releasePolicy.requireGitTag, isTrue);
      expect(strictDoc.aiUsagePolicy.allowExternalAiProvider, isFalse); // strict/gov/fin restricts external AI

      final openSourceDoc = EnterprisePolicyDocument.fromProfile(EnterprisePolicyProfile.openSource);
      expect(openSourceDoc.enforcementMode, equals(PolicyEnforcementMode.permissive));
      expect(openSourceDoc.aiUsagePolicy.allowExternalAiProvider, isTrue);

      // JSON roundtrip
      final json = strictDoc.toJson();
      final roundtrip = EnterprisePolicyDocument.fromJson(json);
      expect(roundtrip.profile, equals(strictDoc.profile));
      expect(roundtrip.releasePolicy.requiredVerificationGates.length,
          equals(strictDoc.releasePolicy.requiredVerificationGates.length));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Hierarchical Policy Composition (Org -> Project -> Package)
    // ─────────────────────────────────────────────────────────────────────────

    test('2. Hierarchical Composition: child policy cleanly overrides and inherits parent rules', () {
      const orgPolicy = EnterprisePolicyDocument(
        organizationId: 'acme_corp',
        organizationName: 'Acme Corporation',
        profile: EnterprisePolicyProfile.strict,
        enforcementMode: PolicyEnforcementMode.strict,
        releasePolicy: ReleasePolicyConfig(requireGitTag: true),
      );

      final projectPolicy = const EnterprisePolicyDocument(
        organizationId: 'acme_corp',
        profile: EnterprisePolicyProfile.financial,
        releasePolicy: ReleasePolicyConfig(requireGitTag: false),
        customMetadata: {'department': 'fintech_mobile'},
      );

      final resolved = orgPolicy.composeWith(projectPolicy);
      expect(resolved.organizationId, equals('acme_corp'));
      expect(resolved.organizationName, equals('Acme Corporation'));
      expect(resolved.profile, equals(EnterprisePolicyProfile.financial));
      expect(resolved.releasePolicy.requireGitTag, isFalse);
      expect(resolved.customMetadata['department'], equals('fintech_mobile'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Policy File Resolution from Workspace
    // ─────────────────────────────────────────────────────────────────────────

    test('3. Policy File Discovery: loads policy from .fps/policy.json or enterprise_policy.json', () {
      final fpsDir = Directory(p.join(rootPath, '.fps'))..createSync(recursive: true);
      File(p.join(fpsDir.path, 'policy.json')).writeAsStringSync(jsonEncode({
        'organization_id': 'globex_corp',
        'profile': 'healthcare',
        'enforcement_mode': 'strict',
        'security_policy': {
          'max_allowed_critical_findings': 0,
        },
      }));

      final engine = EnterprisePolicyEngine(projectRoot: rootPath);
      final policy = engine.resolvePolicy();

      expect(policy.organizationId, equals('globex_corp'));
      expect(policy.profile, equals(EnterprisePolicyProfile.healthcare));
      expect(policy.enforcementMode, equals(PolicyEnforcementMode.strict));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Security Policy Enforcement (Blocked Sensitive Files)
    // ─────────────────────────────────────────────────────────────────────────

    test('4. Security Policy: detects plaintext .env and blocks operation in strict mode', () async {
      // Inject uncommitted .env file
      File(p.join(rootPath, '.env')).writeAsStringSync('API_SECRET=super_confidential_12345\n');

      final engine = EnterprisePolicyEngine(projectRoot: rootPath);
      final result = await engine.evaluatePolicy();

      expect(result.isCompliant, isFalse);
      expect(result.isBlocked, isTrue);
      expect(result.criticalCount, greaterThan(0));
      expect(result.failedGates, contains('security_policy'));
      expect(result.findings.any((f) => f.ruleId == 'SEC_001_BLOCKED_SENSITIVE_FILE'), isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Release Verification Gates Policy
    // ─────────────────────────────────────────────────────────────────────────

    test('5. Release Policy: verifies all mandatory release gates in operation context', () async {
      final engine = EnterprisePolicyEngine(projectRoot: rootPath);

      // 1. All mandatory release gates passed
      final passingContext = {
        'security_audit': true,
        'pub_dev_validation': true,
        'release_verification': true,
        'manifest_generation': true,
      };
      final passResult = await engine.evaluatePolicy(
        operationName: 'release',
        operationContext: passingContext,
      );
      expect(passResult.isCompliant, isTrue);
      expect(passResult.passedGates, contains('release_policy'));

      // 2. Missing release gate -> failed
      final failingContext = {
        'security_audit': true,
        'pub_dev_validation': false, // failed pub.dev validation
        'release_verification': true,
        'manifest_generation': true,
      };
      final failResult = await engine.evaluatePolicy(
        operationName: 'release',
        operationContext: failingContext,
      );
      expect(failResult.isCompliant, isFalse);
      expect(failResult.isBlocked, isTrue);
      expect(failResult.failedGates, contains('release_policy'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: AI Usage Policy Governance
    // ─────────────────────────────────────────────────────────────────────────

    test('6. AI Policy: validates allowed/blocked AI operations and capability boundaries', () async {
      final restrictedDoc = const EnterprisePolicyDocument(
        aiUsagePolicy: AiUsagePolicyConfig(
          allowAiAssistance: true,
          allowedAiCapabilities: ['review', 'analyze', 'security'],
        ),
      );

      final engine = EnterprisePolicyEngine(
        projectRoot: rootPath,
        overridePolicy: restrictedDoc,
      );

      // Allowed capability
      final allowedRes = await engine.evaluatePolicy(operationName: 'ai_review');
      expect(allowedRes.isCompliant, isTrue);

      // Disallowed capability
      final disallowedRes = await engine.evaluatePolicy(operationName: 'ai_modify');
      expect(disallowedRes.isCompliant, isFalse);
      expect(disallowedRes.findings.any((f) => f.ruleId == 'AI_002_CAPABILITY_NOT_PERMITTED'), isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Pure Dual-Format Renderer Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test('7. Renderer Conformance: generates deterministic JSON and Markdown reports', () async {
      final engine = EnterprisePolicyEngine(projectRoot: rootPath);
      final result = await engine.evaluatePolicy(operationName: 'analyze');
      const renderer = EnterprisePolicyRenderer();

      final json1 = renderer.renderJson(result);
      final json2 = renderer.renderJson(result);
      expect(json1, equals(json2));

      final md = renderer.renderMarkdown(result);
      expect(md, contains('# Enterprise Policy Evaluation Report'));
      expect(md, contains('Policy Compliant: YES'));
      expect(md, contains('Operation Blocked: NO'));
    });
  });
}
