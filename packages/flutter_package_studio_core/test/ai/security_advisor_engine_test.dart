import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 8.9 — AI Security & Privacy Advisor Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_security_test_');
      rootPath = tempDir.path;
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    /// Helper to scaffold a monorepo workspace with deliberately injected synthetic secrets.
    void scaffoldSecurityWorkspace() {
      // 1. Root Pubspec
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: security_test_workspace
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      // 2. Deliberate Synthetic Secrets in Sensitive Files
      File(p.join(rootPath, '.env')).writeAsStringSync('''
DATABASE_URL=postgres://user:super_secret_db_password_999@localhost:5432/prod
STRIPE_KEY=sk_live_synthetic_stripe_token_12345
''');

      File(p.join(rootPath, 'credentials.json')).writeAsStringSync('''
{
  "api_token": "ghp_syntheticGitHubPersonalAccessToken12345678",
  "secret_key": "AIzaSySyntheticGoogleApiKey1234567890ABCD"
}
''');

      // 3. Package with hardcoded secret inside source file
      final pkgDir = Directory(p.join(rootPath, 'packages', 'auth_pkg'))
        ..createSync(recursive: true);
      File(p.join(pkgDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: auth_pkg
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
dependencies:
  meta: ^1.11.0
  pedantic: ^1.11.1
''');

      final libDir = Directory(p.join(pkgDir.path, 'lib'))
        ..createSync(recursive: true);
      File(p.join(libDir.path, 'auth_service.dart')).writeAsStringSync('''
class AuthService {
  final String apiKey = "AIzaSySyntheticGoogleApiKey1234567890ABCD";
  final String githubToken = "ghp_syntheticGitHubPersonalAccessToken12345678";
  final String dbPassword = "password: 'super_secret_db_password_999'";
}
''');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Finding Model Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Finding Model Conformance: SecurityFindingItem conforms strictly to CodeReviewFinding schema and serializes 5-tier priority',
        () {
      final item = SecurityFindingItem(
        severity: CodeReviewSeverity.critical,
        category: CodeReviewCategory.unsafePattern,
        file: 'packages/auth_pkg/lib/auth_service.dart',
        location: 'L2',
        problem: 'Hardcoded Google API key detected',
        explanation: 'Source code contains a hardcoded API key.',
        recommendation: 'Move the key to a secure vault.',
        confidence: CodeReviewConfidence.high,
        priority: SecurityPriority.critical,
        securityCategory: SecurityFindingCategory.secretExposure,
        evidence: 'Matched Google API key pattern',
        impact: 'Potential billing quota exhaustion.',
        verificationProcedure: 'Verify API key is revoked.',
      );

      final json = item.toJson();
      expect(json['severity'], equals('critical'));
      expect(json['category'], equals('unsafePattern'));
      expect(json['priority'], equals('critical'));
      expect(json['securityCategory'], equals('secretExposure'));
      expect(json['evidence'], equals('Matched Google API key pattern'));
      expect(json['impact'], equals('Potential billing quota exhaustion.'));
      expect(
          json['verificationProcedure'], equals('Verify API key is revoked.'));

      final restored = SecurityFindingItem.fromJson(json);
      expect(restored.priority, equals(SecurityPriority.critical));
      expect(restored.severity, equals(CodeReviewSeverity.critical));
      expect(restored.securityCategory,
          equals(SecurityFindingCategory.secretExposure));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Five-Tier Priority Classification
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Five-Tier Priority Classification: verifies all 5 tiers map correctly to CodeReviewSeverity',
        () {
      expect(SecurityPriority.critical.toSeverity(),
          equals(CodeReviewSeverity.critical));
      expect(
          SecurityPriority.high.toSeverity(), equals(CodeReviewSeverity.high));
      expect(SecurityPriority.medium.toSeverity(),
          equals(CodeReviewSeverity.medium));
      expect(SecurityPriority.low.toSeverity(), equals(CodeReviewSeverity.low));
      expect(SecurityPriority.informational.toSeverity(),
          equals(CodeReviewSeverity.informational));

      expect(SecurityPriority.fromSeverity(CodeReviewSeverity.critical),
          equals(SecurityPriority.critical));
      expect(SecurityPriority.fromSeverity(CodeReviewSeverity.high),
          equals(SecurityPriority.high));
      expect(SecurityPriority.fromSeverity(CodeReviewSeverity.medium),
          equals(SecurityPriority.medium));
      expect(SecurityPriority.fromSeverity(CodeReviewSeverity.low),
          equals(SecurityPriority.low));
      expect(SecurityPriority.fromSeverity(CodeReviewSeverity.informational),
          equals(SecurityPriority.informational));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Deterministic Prioritization and Audit Ingestion
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Deterministic Prioritization: ingests raw deterministic audit findings and maps priority cleanly',
        () async {
      scaffoldSecurityWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode(
            {'summary': 'Security review completed.', 'findings': []}),
      );

      final engine = SecurityAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final rawFixture = [
        {
          'id': 'SEC_TOKEN_001',
          'severity': 'critical',
          'path': 'packages/auth_pkg/pubspec.yaml',
          'location': 'L5',
          'message': 'Potential secret token in pubspec',
          'remediation': 'Revoke token immediately',
        },
        {
          'id': 'SEC_CONFIG_002',
          'severity': 'warning',
          'path': 'packages/auth_pkg/lib/config.dart',
          'location': 'L10',
          'message': 'Weak cipher configuration',
          'remediation': 'Use AES-256-GCM',
        }
      ];

      final result = await engine.analyze(
        const SecurityAnalysisRequest(
          scope: SecurityAnalysisScope.wholeProject,
        ),
        rawAuditFindingsFixture: rawFixture,
      );

      expect(result.isSuccess, isTrue);
      expect(result.deterministicAuditFindingsCount, equals(2));

      final criticalAudit = result.findings.firstWhere(
        (f) => f.file == 'packages/auth_pkg/pubspec.yaml',
      );
      expect(criticalAudit.priority, equals(SecurityPriority.critical));

      final mediumAudit = result.findings.firstWhere(
        (f) => f.file == 'packages/auth_pkg/lib/config.dart',
      );
      expect(mediumAudit.priority, equals(SecurityPriority.medium));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Dedicated Secret-Redaction Gate (All Layers & Output Surfaces)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Dedicated Secret-Redaction Gate: synthetic secrets are 100% ABSENT across prompts, findings, JSON, and Markdown',
        () async {
      scaffoldSecurityWorkspace();

      const syntheticGithubToken =
          'ghp_syntheticGitHubPersonalAccessToken12345678';
      const syntheticGoogleKey = 'AIzaSySyntheticGoogleApiKey1234567890ABCD';
      const syntheticDbPassword = 'super_secret_db_password_999';
      const syntheticStripeKey = 'sk_live_synthetic_stripe_token_12345';

      final provider = MockAiProvider(
        defaultResponse:
            jsonEncode({'summary': 'AI risk review complete.', 'findings': []}),
      );

      final engine = SecurityAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const SecurityAnalysisRequest(
        scope: SecurityAnalysisScope.wholeProject,
      ));

      expect(result.isSuccess, isTrue);

      // A) Inspect AI Provider Outbound Prompt
      expect(provider.recordedRequests, isNotEmpty);
      final sentPrompt = provider.recordedRequests.first.prompt;
      expect(sentPrompt.contains(syntheticGithubToken), isFalse,
          reason: 'GitHub token leaked to AI prompt');
      expect(sentPrompt.contains(syntheticGoogleKey), isFalse,
          reason: 'Google key leaked to AI prompt');
      expect(sentPrompt.contains(syntheticDbPassword), isFalse,
          reason: 'DB password leaked to AI prompt');
      expect(sentPrompt.contains(syntheticStripeKey), isFalse,
          reason: 'Stripe key leaked to AI prompt');

      // B) Inspect Finding Objects
      for (final finding in result.findings) {
        final findingStr =
            '${finding.problem} ${finding.explanation} ${finding.evidence} ${finding.impact} ${finding.recommendation} ${finding.verificationProcedure}';
        expect(findingStr.contains(syntheticGithubToken), isFalse,
            reason: 'GitHub token present in finding object');
        expect(findingStr.contains(syntheticGoogleKey), isFalse,
            reason: 'Google key present in finding object');
        expect(findingStr.contains(syntheticDbPassword), isFalse,
            reason: 'DB password present in finding object');
        expect(findingStr.contains(syntheticStripeKey), isFalse,
            reason: 'Stripe key present in finding object');
      }

      // C) Inspect Rendered JSON Output
      const renderer = SecurityAdvisorRenderer();
      final renderedJson = renderer.renderJson(result);
      expect(renderedJson.contains(syntheticGithubToken), isFalse,
          reason: 'GitHub token present in JSON output');
      expect(renderedJson.contains(syntheticGoogleKey), isFalse,
          reason: 'Google key present in JSON output');
      expect(renderedJson.contains(syntheticDbPassword), isFalse,
          reason: 'DB password present in JSON output');
      expect(renderedJson.contains(syntheticStripeKey), isFalse,
          reason: 'Stripe key present in JSON output');

      // D) Inspect Rendered Markdown Output
      final renderedMarkdown = renderer.renderMarkdown(result);
      expect(renderedMarkdown.contains(syntheticGithubToken), isFalse,
          reason: 'GitHub token present in Markdown output');
      expect(renderedMarkdown.contains(syntheticGoogleKey), isFalse,
          reason: 'Google key present in Markdown output');
      expect(renderedMarkdown.contains(syntheticDbPassword), isFalse,
          reason: 'DB password present in Markdown output');
      expect(renderedMarkdown.contains(syntheticStripeKey), isFalse,
          reason: 'Stripe key present in Markdown output');

      // E) Assert Redaction Placeholders ARE present
      expect(
        renderedJson.contains('[REDACTED_') ||
            renderedMarkdown.contains('[REDACTED_') ||
            sentPrompt.contains('[REDACTED_'),
        isTrue,
        reason: 'Redaction placeholder missing from outputs',
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Dependency Risk Correlation (Phase 8.8 reuse)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Dependency Risk Correlation: correlates deprecated dependency pedantic from auth_pkg',
        () async {
      scaffoldSecurityWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({'summary': 'Safe scan', 'findings': []}),
      );

      final engine = SecurityAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const SecurityAnalysisRequest(
        scope: SecurityAnalysisScope.wholeProject,
      ));

      expect(result.isSuccess, isTrue);
      final depRisk = result.findings.firstWhere(
        (f) => f.securityCategory == SecurityFindingCategory.dependencyRisk,
      );
      expect(depRisk.problem, contains('pedantic'));
      expect(depRisk.priority, equals(SecurityPriority.medium));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Min-Priority Filtering
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Min-Priority Filtering: filters out lower priority findings when higher threshold is requested',
        () async {
      scaffoldSecurityWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({'summary': 'Safe scan', 'findings': []}),
      );

      final engine = SecurityAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      // Only Critical findings
      final result = await engine.analyze(const SecurityAnalysisRequest(
        scope: SecurityAnalysisScope.wholeProject,
        minPriority: SecurityPriority.critical,
      ));

      expect(result.isSuccess, isTrue);
      for (final f in result.findings) {
        expect(f.priority, equals(SecurityPriority.critical));
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: No-Execution / Zero-Mutation Safety Invariant
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. No-Execution Safety Invariant: security analysis never mutates workspace files',
        () async {
      scaffoldSecurityWorkspace();

      final filesBefore = <String, String>{};
      for (final entity in Directory(rootPath).listSync(recursive: true)) {
        if (entity is File) {
          filesBefore[entity.path] = entity.readAsStringSync();
        }
      }

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({'summary': 'Inspection', 'findings': []}),
      );

      final engine = SecurityAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      await engine.analyze(const SecurityAnalysisRequest(
        scope: SecurityAnalysisScope.wholeProject,
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
    // Test 8: Fail-Closed Provider Failure Handling
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Provider Failure: unavailable provider returns structured failure without throwing',
        () async {
      scaffoldSecurityWorkspace();

      final provider = MockAiProvider(
        injectedException:
            Exception('Security AI provider connection refused 503.'),
      );

      final engine = SecurityAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const SecurityAnalysisRequest(
        scope: SecurityAnalysisScope.wholeProject,
      ));

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage,
          contains('Security AI provider connection refused'));
      expect(result.findings, isEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: Dual-Format Renderer (Valid JSON & Markdown)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9. Dual-Format Renderer: renders schema-valid JSON and structured Markdown reports',
        () {
      final item = SecurityFindingItem(
        severity: CodeReviewSeverity.critical,
        category: CodeReviewCategory.unsafePattern,
        file: '.env',
        location: 'L1',
        problem: 'Sensitive environment file present in project',
        explanation: 'Environment file poses credential leakage risk.',
        recommendation: 'Add .env to .gitignore.',
        confidence: CodeReviewConfidence.high,
        priority: SecurityPriority.critical,
        securityCategory: SecurityFindingCategory.fileExposure,
        evidence: 'Matched sensitive environment file pattern (.env*)',
        impact: 'Exposes cloud secrets and API credentials.',
        verificationProcedure: 'Verify .env is gitignored.',
      );

      final result = SecurityAnalysisResult(
        scope: SecurityAnalysisScope.wholeProject,
        targetScopeId: 'whole_project',
        isSuccess: true,
        summary: 'Security review identified 1 concern.',
        findings: [item],
        scannedPackages: const ['auth_pkg'],
        deterministicAuditFindingsCount: 1,
        durationMs: 42,
        timestamp: DateTime.now(),
      );

      const renderer = SecurityAdvisorRenderer();
      final jsonStr = renderer.renderJson(result);
      final mdStr = renderer.renderMarkdown(result);

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['isSuccess'], isTrue);
      expect(decoded['findingCount'], equals(1));
      expect(decoded['findings'][0]['priority'], equals('critical'));

      expect(
          mdStr,
          contains(
              '# Flutter Package Studio — AI Security & Privacy Advisory Report'));
      expect(mdStr,
          contains('[CRITICAL] Sensitive environment file present in project'));
      expect(mdStr,
          contains('**Evidence**: Matched sensitive environment file pattern'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 10: Regression Check
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '10. Regression check: verifies compatibility with prior AI assistant engine models',
        () {
      expect(SecurityFindingCategory.values.length, greaterThanOrEqualTo(8));
      expect(SecurityPriority.values.length, equals(5));
      expect(SecurityAnalysisScope.values.length, equals(2));
    });
  });
}
