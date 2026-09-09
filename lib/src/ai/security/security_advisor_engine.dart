/// AI Security & Privacy Advisor Engine for Flutter Package Studio (Phase 8.9).
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/ai/context/project_context_engine.dart';
import 'package:syntrix/src/ai/context/project_context_models.dart';
import 'package:syntrix/src/ai/context/sensitive_file_filter.dart';
import 'package:syntrix/src/ai/engine/assistant_engine.dart';
import 'package:syntrix/src/ai/models/assistant_models.dart';
import 'package:syntrix/src/ai/provider/ai_provider.dart';
import 'package:syntrix/src/ai/review/code_review_models.dart';
import 'package:syntrix/src/ai/dependencies/dependency_advisor_engine.dart';
import 'package:syntrix/src/ai/dependencies/dependency_models.dart';
import 'package:syntrix/src/ai/security/secret_redactor.dart';
import 'package:syntrix/src/ai/security/security_models.dart';

/// Central engine for AI Security & Privacy Advisory.
///
/// Core Capabilities:
/// 1. Consumes deterministic security audit outputs, secret scanner findings, and sensitive file exposures.
/// 2. Integrates Phase 8.8 dependency risks (deprecated packages, known CVE patterns) without re-deriving them.
/// 3. Performs deterministic correlation and prioritization into the required 5-tier scale
///    (Critical, High, Medium, Low, Informational).
/// 4. Non-negotiable Redaction Invariant:
///    - ZERO raw secret values sent to AI provider prompts.
///    - ZERO raw secret values emitted in findings, evidence, JSON, or Markdown reports.
///    - Every secret value is replaced with a fixed masked placeholder.
/// 5. AI Reasoning Layer:
///    - Generates plain-language risk explanations, impact narratives, and human verification procedures
///      grounded strictly in redacted evidence.
/// 6. Strict Read-Only Safety Invariant:
///    - NEVER mutates files, credentials, configurations, or packages.
///    - Reports and recommends only.
/// 7. Fail-Closed Error Handling: Structured failure on AI provider unavailability.
class SecurityAdvisorEngine {
  final Logger _logger = Logger('SecurityAdvisorEngine');
  final String _projectRoot;
  final ProjectContextEngine _contextEngine;
  final AssistantEngine _assistantEngine;
  final DependencyAdvisorEngine _dependencyEngine;
  final SensitiveFileFilter _sensitiveFilter;

  String get projectRoot => _projectRoot;

  SecurityAdvisorEngine({
    required String projectRoot,
    required ProjectContextEngine contextEngine,
    required AssistantEngine assistantEngine,
    DependencyAdvisorEngine? dependencyEngine,
    SensitiveFileFilter? sensitiveFilter,
  })  : _projectRoot = p.normalize(projectRoot),
        _contextEngine = contextEngine,
        _assistantEngine = assistantEngine,
        _dependencyEngine = dependencyEngine ??
            DependencyAdvisorEngine(
              projectRoot: projectRoot,
              contextEngine: contextEngine,
              assistantEngine: assistantEngine,
            ),
        _sensitiveFilter =
            sensitiveFilter ?? SensitiveFileFilter.fromProjectRoot(projectRoot);

  /// Convenience factory constructing engine with an [AiProvider].
  factory SecurityAdvisorEngine.withProvider({
    required String projectRoot,
    required AiProvider provider,
    AssistantConfiguration? configuration,
  }) {
    final contextEngine = ProjectContextEngine(projectRoot: projectRoot);
    final assistantEngine = AssistantEngine(
      provider: provider,
      defaultConfiguration: configuration ?? const AssistantConfiguration(),
    );
    final depEngine = DependencyAdvisorEngine(
      projectRoot: projectRoot,
      contextEngine: contextEngine,
      assistantEngine: assistantEngine,
    );
    return SecurityAdvisorEngine(
      projectRoot: projectRoot,
      contextEngine: contextEngine,
      assistantEngine: assistantEngine,
      dependencyEngine: depEngine,
    );
  }

  /// Performs full security and privacy advisory analysis.
  Future<SecurityAnalysisResult> analyze(
    SecurityAnalysisRequest request, {
    DateTime? executionTimestamp,
    List<Map<String, dynamic>>? rawAuditFindingsFixture,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = executionTimestamp ?? DateTime.now();
    final targetScopeId = request.scope == SecurityAnalysisScope.package &&
            request.targetPackage != null
        ? request.targetPackage!
        : 'whole_project';

    _logger.info('Starting AI Security & Privacy Advisory for: $targetScopeId');

    try {
      // 1. Discover Project Context & Packages
      final snapshot = await _contextEngine.discoverProject();
      final relevantPackages = <String, DiscoveredPackage>{};

      if (request.scope == SecurityAnalysisScope.package &&
          request.targetPackage != null) {
        final pkg = snapshot.packages[request.targetPackage!];
        if (pkg != null) {
          relevantPackages[request.targetPackage!] = pkg;
        } else {
          stopwatch.stop();
          return SecurityAnalysisResult.failure(
            scope: request.scope,
            targetScopeId: targetScopeId,
            errorMessage:
                'Target package "${request.targetPackage}" was not found in the workspace.',
            durationMs: stopwatch.elapsedMilliseconds,
            timestamp: now,
          );
        }
      } else {
        relevantPackages.addAll(snapshot.packages);
      }

      // 2. Consume Existing Deterministic Security & Secret Findings
      final deterministicFindings = <SecurityFindingItem>[];

      // A) Ingest raw audit findings if provided or discover from existing files/reports
      final ingestedAuditCount = _ingestDeterministicAuditFindings(
        findings: deterministicFindings,
        fixtureFindings: rawAuditFindingsFixture,
        packages: relevantPackages.values.toList(),
      );

      // B) File Exposure & Credential Leak Scan (Deterministic inspection with instant redaction)
      _scanFileExposures(
        findings: deterministicFindings,
        packages: relevantPackages.values.toList(),
      );

      // C) Dependency Security Correlation (Reuse Phase 8.8 findings)
      await _correlateDependencyRisks(
        findings: deterministicFindings,
        request: request,
      );

      // 3. Filter findings by minimum priority threshold
      final prioritizedFindings = deterministicFindings.where((f) {
        return f.priority.index <= request.minPriority.index;
      }).toList();

      // 4. Assemble Sanitized Prompt Context & Invoke AI Provider for Risk Explanation and Impact
      final sanitizedFacts = <String, dynamic>{
        'scope': request.scope.name,
        'targetScopeId': targetScopeId,
        'findingCount': prioritizedFindings.length,
        'packages': relevantPackages.keys.toList()..sort(),
        'findingsEvidence': prioritizedFindings
            .map((f) => {
                  'id': '${f.file}:${f.location}',
                  'problem': SecretRedactor.redact(f.problem),
                  'priority': f.priority.name,
                  'category': f.securityCategory.name,
                  'evidence': SecretRedactor.redact(f.evidence),
                })
            .toList(),
      };

      final assistantReq = AssistantRequest(
        prompt: _buildSecurityPrompt(
          scope: request.scope,
          targetScopeId: targetScopeId,
          findings: prioritizedFindings,
        ),
        mode: AssistantMode.analysis,
        templateId: targetScopeId,
        context: PromptContext(
          templateId: targetScopeId,
          structuredFacts: sanitizedFacts,
        ),
      );

      final response = await _assistantEngine.executeRequest(
        assistantReq,
        executionTimestamp: now,
      );

      stopwatch.stop();

      if (!response.isSuccess) {
        _logger.warning(
            'AI Provider failed during security analysis: ${response.errorMessage}');
        return SecurityAnalysisResult.failure(
          scope: request.scope,
          targetScopeId: targetScopeId,
          errorMessage: response.errorMessage ??
              'AI provider failed during security analysis.',
          durationMs: stopwatch.elapsedMilliseconds,
          timestamp: now,
        );
      }

      // 5. Parse AI-generated explanations and merge onto findings with mandatory redaction
      final enrichedFindings = _enrichFindingsWithAi(
        deterministicFindings: prioritizedFindings,
        response: response,
      );

      final summary = enrichedFindings.isEmpty
          ? 'Security and privacy advisory completed: No security vulnerabilities or credential exposures detected.'
          : 'Security advisory identified ${enrichedFindings.length} security concern(s) requiring attention.';

      return SecurityAnalysisResult(
        scope: request.scope,
        targetScopeId: targetScopeId,
        isSuccess: true,
        summary: SecretRedactor.redact(summary),
        findings: enrichedFindings,
        scannedPackages: relevantPackages.keys.toList()..sort(),
        deterministicAuditFindingsCount: ingestedAuditCount,
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    } catch (e, st) {
      stopwatch.stop();
      _logger.error('Unhandled exception during security analysis: $e', e, st);
      return SecurityAnalysisResult.failure(
        scope: request.scope,
        targetScopeId: targetScopeId,
        errorMessage:
            'Internal security analysis error: ${SecretRedactor.redact(e.toString())}',
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Deterministic Audit Ingestion & Pre-Flight
  // ───────────────────────────────────────────────────────────────────────────

  int _ingestDeterministicAuditFindings({
    required List<SecurityFindingItem> findings,
    required List<Map<String, dynamic>>? fixtureFindings,
    required List<DiscoveredPackage> packages,
  }) {
    var count = 0;
    if (fixtureFindings != null && fixtureFindings.isNotEmpty) {
      for (final raw in fixtureFindings) {
        count++;
        final sevStr = raw['severity'] as String? ?? 'high';
        final priority = _mapRawSeverityToPriority(sevStr);
        final ruleId =
            raw['id'] as String? ?? raw['ruleId'] as String? ?? 'SEC_AUDIT';
        final rawPath =
            raw['path'] as String? ?? raw['file'] as String? ?? 'pubspec.yaml';
        final rawDesc = raw['description'] as String? ??
            raw['message'] as String? ??
            'Detected security concern';

        // Redact evidence immediately
        final evidence =
            'Audit Rule $ruleId triggered on ${SecretRedactor.redact(rawPath)}';

        findings.add(SecurityFindingItem(
          severity: priority.toSeverity(),
          category: CodeReviewCategory.unsafePattern,
          file: rawPath,
          location: raw['location'] as String? ?? 'L1',
          problem: SecretRedactor.redact(rawDesc),
          explanation:
              'Deterministic security audit flagged this item under rule $ruleId.',
          recommendation: raw['remediation'] as String? ??
              'Remove or secure sensitive item.',
          confidence: CodeReviewConfidence.high,
          priority: priority,
          securityCategory: SecurityFindingCategory.secretExposure,
          evidence: evidence,
          impact:
              'Exposure of credentials may lead to privilege escalation or unauthorized data access.',
          verificationProcedure:
              'Verify secret is removed from $rawPath and revoked at credential provider.',
        ));
      }
    }
    return count;
  }

  void _scanFileExposures({
    required List<SecurityFindingItem> findings,
    required List<DiscoveredPackage> packages,
  }) {
    final rootDir = Directory(_projectRoot);
    if (!rootDir.existsSync()) return;

    try {
      final entities = rootDir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          final relPath =
              p.relative(entity.path, from: _projectRoot).replaceAll('\\', '/');
          final baseName = p.basename(relPath).toLowerCase();

          // Consult SensitiveFileFilter for classification
          final filterDecision = _sensitiveFilter.evaluateFile(
            relativePath: relPath,
          );

          // 1. Sensitive Environment File Exposure (.env, .env.*)
          if (baseName == '.env' ||
              baseName.startsWith('.env.') ||
              filterDecision.reason ==
                  ContextFileExclusionReason.sensitiveEnv) {
            findings.add(SecurityFindingItem(
              severity: CodeReviewSeverity.critical,
              category: CodeReviewCategory.unsafePattern,
              file: relPath,
              location: 'L1',
              problem:
                  'Sensitive environment file "$relPath" is present in project directory',
              explanation:
                  'Environment files often contain live production secrets and should never be bundled.',
              recommendation:
                  'Add "$baseName" to .gitignore and remove it from repository tracking.',
              confidence: CodeReviewConfidence.high,
              priority: SecurityPriority.critical,
              securityCategory: SecurityFindingCategory.fileExposure,
              evidence:
                  'File matched sensitive environment file pattern (.env*)',
              impact:
                  'Full compromise of API keys, database credentials, or third-party service tokens.',
              verificationProcedure:
                  'Ensure file is added to .gitignore and absent from release builds.',
            ));
          }

          // 2. Sensitive Credentials Store (credentials.json, key.properties)
          if (baseName == 'credentials.json' ||
              baseName == 'key.properties' ||
              baseName == 'service_account.json') {
            findings.add(SecurityFindingItem(
              severity: CodeReviewSeverity.critical,
              category: CodeReviewCategory.unsafePattern,
              file: relPath,
              location: 'L1',
              problem: 'Sensitive credential store "$relPath" found in project',
              explanation:
                  'Key stores, service accounts, and credential files pose severe credential leakage risks.',
              recommendation:
                  'Store credentials in secure environment variables or vault instead of workspace files.',
              confidence: CodeReviewConfidence.high,
              priority: SecurityPriority.critical,
              securityCategory: SecurityFindingCategory.credentialHandling,
              evidence:
                  'File matched sensitive credential store pattern ($baseName)',
              impact:
                  'Direct unauthorized access to cloud services or signing keys.',
              verificationProcedure:
                  'Verify file is removed from workspace and replaced with vault references.',
            ));
          }

          // 3. Scan file content for hardcoded secrets (with instant redaction)
          if (entity.lengthSync() < 200000 &&
              !baseName.endsWith('.png') &&
              !baseName.endsWith('.ico')) {
            try {
              final content = entity.readAsStringSync();
              _scanContentForSecrets(relPath, content, findings);
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  }

  void _scanContentForSecrets(
      String relPath, String content, List<SecurityFindingItem> findings) {
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // GitHub Personal Access Token
      if (line.contains(RegExp(r'ghp_[A-Za-z0-9]{20,}'))) {
        findings.add(SecurityFindingItem(
          severity: CodeReviewSeverity.critical,
          category: CodeReviewCategory.unsafePattern,
          file: relPath,
          location: 'L${i + 1}',
          problem: 'Hardcoded GitHub Personal Access Token detected',
          explanation:
              'Source code contains an exposed GitHub Personal Access Token.',
          recommendation:
              'Revoke the GitHub token immediately and load from environment variables.',
          confidence: CodeReviewConfidence.high,
          priority: SecurityPriority.critical,
          securityCategory: SecurityFindingCategory.secretExposure,
          evidence:
              'Matched GitHub token pattern in $relPath:L${i + 1} [REDACTED_GITHUB_TOKEN]',
          impact:
              'Attacker gains authorized access to repository contents, issues, and workflows.',
          verificationProcedure:
              'Verify token is revoked on GitHub settings and deleted from source.',
        ));
      }

      // Google API Key
      if (line.contains(RegExp(r'AIza[0-9A-Za-z\-_]{35}'))) {
        findings.add(SecurityFindingItem(
          severity: CodeReviewSeverity.high,
          category: CodeReviewCategory.unsafePattern,
          file: relPath,
          location: 'L${i + 1}',
          problem: 'Hardcoded Google API key detected',
          explanation:
              'Source code contains a hardcoded Google API key without backend proxying.',
          recommendation:
              'Move the API key to a secure server-side proxy or apply strict HTTP referrer restrictions.',
          confidence: CodeReviewConfidence.high,
          priority: SecurityPriority.high,
          securityCategory: SecurityFindingCategory.secretExposure,
          evidence:
              'Matched Google API key pattern in $relPath:L${i + 1} [REDACTED_GOOGLE_API_KEY]',
          impact:
              'Potential billing exhaustion or unauthorized quota consumption on Google Cloud.',
          verificationProcedure:
              'Verify API key is restricted in Google Cloud Console.',
        ));
      }

      // Password assignment
      if (line.contains(RegExp(
          r'''(?:password|secret|auth_token)\s*[:=]\s*["'][^"']{4,}["']''',
          caseSensitive: false))) {
        findings.add(SecurityFindingItem(
          severity: CodeReviewSeverity.high,
          category: CodeReviewCategory.unsafePattern,
          file: relPath,
          location: 'L${i + 1}',
          problem: 'Hardcoded credential or password assignment detected',
          explanation:
              'Hardcoded credentials in source code bypass access control and cannot be safely rotated.',
          recommendation:
              'Inject credentials at runtime through secure configuration providers.',
          confidence: CodeReviewConfidence.high,
          priority: SecurityPriority.high,
          securityCategory: SecurityFindingCategory.credentialHandling,
          evidence:
              'Matched credential assignment pattern in $relPath:L${i + 1} [REDACTED_SECRET]',
          impact:
              'Exposure of application credentials directly to repository readers.',
          verificationProcedure:
              'Confirm password is replaced with environment lookup.',
        ));
      }
    }
  }

  Future<void> _correlateDependencyRisks({
    required List<SecurityFindingItem> findings,
    required SecurityAnalysisRequest request,
  }) async {
    try {
      final depResult = await _dependencyEngine.analyze(
        DependencyAnalysisRequest(
          scope: request.scope == SecurityAnalysisScope.package
              ? DependencyAnalysisScope.package
              : DependencyAnalysisScope.wholeProject,
          targetPackage: request.targetPackage,
        ),
      );

      for (final depFinding in depResult.findings) {
        if (depFinding.artifactType ==
            DependencyArtifactType.deprecatedPackage) {
          findings.add(SecurityFindingItem(
            severity: CodeReviewSeverity.medium,
            category: CodeReviewCategory.maintainability,
            file: depFinding.file,
            location: depFinding.location,
            problem:
                'Deprecated dependency "${depFinding.dependencyName}" has unmaintained security posture',
            explanation:
                'Discontinued or deprecated dependencies do not receive security patches or vulnerability fixes.',
            recommendation: depFinding.recommendation,
            confidence: CodeReviewConfidence.high,
            priority: SecurityPriority.medium,
            securityCategory: SecurityFindingCategory.dependencyRisk,
            evidence:
                'Dependency analysis flagged ${depFinding.dependencyName} (${depFinding.currentConstraint})',
            impact:
                'Vulnerabilities in unmaintained packages remain unpatched indefinitely.',
            verificationProcedure:
                'Migrate to supported replacement package and run pub upgrade.',
          ));
        }
      }
    } catch (_) {}
  }

  SecurityPriority _mapRawSeverityToPriority(String raw) {
    final clean = raw.trim().toLowerCase();
    switch (clean) {
      case 'critical':
        return SecurityPriority.critical;
      case 'error':
      case 'high':
        return SecurityPriority.high;
      case 'warning':
      case 'medium':
        return SecurityPriority.medium;
      case 'low':
        return SecurityPriority.low;
      default:
        return SecurityPriority.informational;
    }
  }

  String _buildSecurityPrompt({
    required SecurityAnalysisScope scope,
    required String targetScopeId,
    required List<SecurityFindingItem> findings,
  }) {
    final buf = StringBuffer();
    buf.writeln(
        'You are the AI Security & Privacy Advisor for Flutter Package Studio.');
    buf.writeln(
        'Analyze the gathered security findings and provide clear, plain-language risk explanations,');
    buf.writeln('impact assessments, and human verification procedures.');
    buf.writeln('Scope: ${scope.name} ($targetScopeId)');
    buf.writeln();
    buf.writeln('NON-NEGOTIABLE SAFETY RULE:');
    buf.writeln(
        'Under NO circumstances may any secret, password, or token appear in output. Use [REDACTED_SECRET].');
    buf.writeln();
    buf.writeln('GATHERED FINDINGS (REDACTED):');
    for (final f in findings) {
      buf.writeln(
          '- [${f.priority.name.toUpperCase()}] ${f.problem} at ${f.file}:${f.location}');
    }
    buf.writeln();
    buf.writeln('Return ONLY a JSON object matching this schema:');
    buf.writeln('''
{
  "summary": "Executive summary of security posture",
  "findings": [
    {
      "file": "path/to/file",
      "location": "L1",
      "problem": "Concise statement of issue",
      "explanation": "Plain language risk explanation",
      "impact": "Concrete impact if left unaddressed",
      "recommendation": "Recommended mitigation",
      "verificationProcedure": "Step-by-step verification procedure",
      "priority": "critical|high|medium|low|informational",
      "securityCategory": "fileExposure|authenticationHandling|credentialHandling|dangerousConfiguration|dependencyRisk|releaseArtifactRisk|manifestRisk|secretExposure",
      "confidence": "high|medium|low"
    }
  ]
}
''');
    return SecretRedactor.redact(buf.toString());
  }

  List<SecurityFindingItem> _enrichFindingsWithAi({
    required List<SecurityFindingItem> deterministicFindings,
    required AssistantResponse response,
  }) {
    final rawText = response.rawUntrustedCompletion;
    final aiMap = <String, Map<String, dynamic>>{};

    if (rawText != null && rawText.trim().isNotEmpty) {
      try {
        String cleanJson = rawText.trim();
        if (cleanJson.startsWith('```json')) cleanJson = cleanJson.substring(7);
        if (cleanJson.startsWith('```')) cleanJson = cleanJson.substring(3);
        if (cleanJson.endsWith('```'))
          cleanJson = cleanJson.substring(0, cleanJson.length - 3);
        cleanJson = cleanJson.trim();

        final decoded = jsonDecode(cleanJson);
        if (decoded is Map<String, dynamic> && decoded['findings'] is List) {
          for (final item in decoded['findings']) {
            if (item is Map<String, dynamic>) {
              final key = '${item["file"]}_${item["location"]}';
              aiMap[key] = item;
            }
          }
        }
      } catch (e) {
        _logger.warning('Failed to parse AI security enrichment: $e');
      }
    }

    // Merge AI risk explanation, impact, and verificationProcedure onto deterministic findings
    final results = <SecurityFindingItem>[];
    for (final df in deterministicFindings) {
      final key = '${df.file}_${df.location}';
      final aiItem = aiMap[key];

      final explanation = aiItem?['explanation'] as String? ?? df.explanation;
      final impact = aiItem?['impact'] as String? ?? df.impact;
      final verif = aiItem?['verificationProcedure'] as String? ??
          df.verificationProcedure;
      final rec = aiItem?['recommendation'] as String? ?? df.recommendation;

      results.add(SecurityFindingItem(
        severity: df.severity,
        category: df.category,
        file: df.file,
        location: df.location,
        problem: df.problem,
        explanation: SecretRedactor.redact(explanation),
        recommendation: SecretRedactor.redact(rec),
        confidence: df.confidence,
        priority: df.priority,
        securityCategory: df.securityCategory,
        evidence: SecretRedactor.redact(df.evidence),
        impact: SecretRedactor.redact(impact),
        verificationProcedure: SecretRedactor.redact(verif),
      ));
    }

    return results..sort();
  }
}
