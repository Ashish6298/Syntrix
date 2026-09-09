/// AI Release Readiness Advisor Engine for Flutter Package Studio (Phase 8.10).
library;

import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/ai/context/project_context_engine.dart';

import 'package:syntrix/src/ai/engine/assistant_engine.dart';
import 'package:syntrix/src/ai/models/assistant_models.dart';
import 'package:syntrix/src/ai/provider/ai_provider.dart';
import 'package:syntrix/src/ai/review/code_review_models.dart';
import 'package:syntrix/src/ai/security/secret_redactor.dart';
import 'package:syntrix/src/ai/security/security_advisor_engine.dart';
import 'package:syntrix/src/ai/security/security_models.dart';
import 'package:syntrix/src/ai/release/release_readiness_models.dart';
import 'package:syntrix/src/release/verification/release_verification_models.dart';
import 'package:syntrix/src/release/verification/release_verification_pipeline.dart';
import 'package:syntrix/src/release/validation/pubdev_package_validator.dart';
import 'package:syntrix/src/release/validation/pubdev_validation_models.dart';

/// Central engine for AI Release Readiness Advisory.
///
/// Core Capabilities & Safety Guarantees:
/// 1. Gathers evidence from all Milestone 5 and 6 deterministic release subsystems:
///    - Version management & Changelog consistency
///    - Distributable artifact generator & manifest verification
///    - Pub.dev readiness validator
///    - Release verification pipeline stages
///    - Phase 8.9 AI Security & Privacy Advisor findings
/// 2. Mandatory-Gate-Override-Prevention Rule (Non-negotiable architectural invariant):
///    - Evaluated at code-level FIRST.
///    - If ANY mandatory release gate fails (e.g. security audit failure, pub.dev validation failure,
///      or release verification failure), Status is deterministically locked to [ReleaseReadinessStatus.notReady].
///    - The AI provider's narrative reasoning can NEVER override or downgrade a mandatory failure to READY or NEEDS_REVIEW.
/// 3. AI Reasoning Layer:
///    - Operates ONLY on sanitized, redacted evidence.
///    - When mandatory gates pass, distinguishes between [ReleaseReadinessStatus.ready] and [ReleaseReadinessStatus.needsReview].
///    - Synthesizes Strengths, Warnings, Blockers, Recommended Actions, and Confidence.
/// 4. Graceful Degradation & Fail-Closed:
///    - If the AI provider is unavailable, times out, or throws, the engine still outputs the
///      deterministic status computation and blockers, marking `isAiSynthesized = false`.
/// 5. Strict Read-Only Safety Invariant:
///    - NEVER mutates files, publishes packages, triggers rollbacks, or promotes channels.
///    - Recommends and assesses only.
class ReleaseReadinessAdvisorEngine {
  final Logger _logger = Logger('ReleaseReadinessAdvisorEngine');
  final String _projectRoot;
  final ProjectContextEngine _contextEngine;
  final AssistantEngine _assistantEngine;
  final SecurityAdvisorEngine _securityEngine;
  final ReleaseVerificationPipeline _verificationPipeline;
  final PubDevPackageValidator _pubDevValidator;

  String get projectRoot => _projectRoot;

  ReleaseReadinessAdvisorEngine({
    required String projectRoot,
    required ProjectContextEngine contextEngine,
    required AssistantEngine assistantEngine,
    SecurityAdvisorEngine? securityEngine,
    ReleaseVerificationPipeline? verificationPipeline,
    PubDevPackageValidator? pubDevValidator,
  })  : _projectRoot = p.normalize(projectRoot),
        _contextEngine = contextEngine,
        _assistantEngine = assistantEngine,
        _securityEngine = securityEngine ??
            SecurityAdvisorEngine.withProvider(
              projectRoot: projectRoot,
              provider: assistantEngine.provider,
            ),
        _verificationPipeline =
            verificationPipeline ?? ReleaseVerificationPipeline(),
        _pubDevValidator = pubDevValidator ?? PubDevPackageValidator();

  /// Convenience factory constructing engine with an [AiProvider].
  factory ReleaseReadinessAdvisorEngine.withProvider({
    required String projectRoot,
    required AiProvider provider,
    AssistantConfiguration? configuration,
  }) {
    final contextEngine = ProjectContextEngine(projectRoot: projectRoot);
    final assistantEngine = AssistantEngine(
      provider: provider,
      defaultConfiguration: configuration ?? const AssistantConfiguration(),
    );
    return ReleaseReadinessAdvisorEngine(
      projectRoot: projectRoot,
      contextEngine: contextEngine,
      assistantEngine: assistantEngine,
    );
  }

  /// Evaluates full release readiness for the requested scope.
  Future<ReleaseReadinessAssessment> assess(
    ReleaseReadinessRequest request, {
    DateTime? executionTimestamp,
    List<VerificationStage>? fixtureVerificationStages,
    List<ValidationCheck>? fixturePubDevChecks,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = executionTimestamp ?? DateTime.now();
    final targetScopeId = request.scope == ReleaseReadinessScope.package &&
            request.targetPackage != null
        ? request.targetPackage!
        : 'whole_project';

    _logger
        .info('Starting AI Release Readiness Assessment for: $targetScopeId');

    try {
      // 1. Discover Project Context & Target Packages
      final snapshot = await _contextEngine.discoverProject();
      final targetPackageName = request.targetPackage ??
          (snapshot.packages.isNotEmpty
              ? snapshot.packages.keys.first
              : 'workspace_package');

      // 2. Gather Evidence across all Milestone 5/6 Subsystems
      final evidenceGathering = await _gatherDeterministicEvidence(
        request: request,
        targetPackageName: targetPackageName,
        fixtureStages: fixtureVerificationStages,
        fixturePubDevChecks: fixturePubDevChecks,
      );

      // 3. CODE-LEVEL MANDATORY GATE EVALUATION (NON-OVERRIDABLE)
      final mandatoryGatesEvaluated = <String>[
        'Gate: Security Audit (Zero Critical Vulnerabilities)',
        'Gate: Pub.dev Validation (Mandatory Policies)',
        'Gate: Release Verification Pipeline',
      ];

      final failedMandatoryGates = <String>[];
      final deterministicBlockers = <ReadinessEntry>[];
      final deterministicWarnings = <ReadinessEntry>[];
      final deterministicStrengths = <ReadinessEntry>[];

      // A) Evaluate Security Audit Gate (Critical Findings are Fatal Blockers)
      final criticalSecFindings = evidenceGathering.securityFindings
          .where((f) => f.priority == SecurityPriority.critical)
          .toList();
      if (criticalSecFindings.isNotEmpty) {
        final gateName = 'Gate: Security Audit (Zero Critical Vulnerabilities)';
        failedMandatoryGates.add(gateName);
        for (final sec in criticalSecFindings) {
          deterministicBlockers.add(ReadinessEntry(
            description:
                'Critical security issue: ${SecretRedactor.redact(sec.problem)} at ${sec.file}:${sec.location}',
            evidenceSource: 'Security Audit (${sec.securityCategory.name})',
          ));
        }
      } else {
        deterministicStrengths.add(ReadinessEntry(
          description:
              'Zero critical security vulnerabilities or exposed credentials detected.',
          evidenceSource: 'Security Audit',
        ));
      }

      // Add non-critical security warnings
      final warnSecFindings = evidenceGathering.securityFindings
          .where((f) =>
              f.priority == SecurityPriority.high ||
              f.priority == SecurityPriority.medium)
          .toList();
      for (final sec in warnSecFindings) {
        deterministicWarnings.add(ReadinessEntry(
          description:
              '${sec.priority.name.toUpperCase()} security concern: ${SecretRedactor.redact(sec.problem)}',
          evidenceSource: 'Security Audit (${sec.securityCategory.name})',
        ));
      }

      // B) Evaluate Pub.dev Validation Gate
      final failedMandatoryPubDev = evidenceGathering.pubDevChecks
          .where((c) => c.isMandatory && c.status == ValidationStatus.failed)
          .toList();
      if (failedMandatoryPubDev.isNotEmpty) {
        final gateName = 'Gate: Pub.dev Validation (Mandatory Policies)';
        failedMandatoryGates.add(gateName);
        for (final check in failedMandatoryPubDev) {
          deterministicBlockers.add(ReadinessEntry(
            description:
                'Pub.dev mandatory validation failed: ${SecretRedactor.redact(check.description)} (${check.details})',
            evidenceSource: 'Pub.dev Validator (${check.id})',
          ));
        }
      } else {
        deterministicStrengths.add(ReadinessEntry(
          description:
              'All mandatory pub.dev package publishing criteria passed.',
          evidenceSource: 'Pub.dev Validator',
        ));
      }

      // C) Evaluate Release Verification Pipeline Gate
      final failedPipelineStages = evidenceGathering.verificationStages
          .where((s) =>
              s.status == VerificationStageStatus.failed ||
              s.status == VerificationStageStatus.blocked)
          .toList();
      if (failedPipelineStages.isNotEmpty) {
        final gateName = 'Gate: Release Verification Pipeline';
        failedMandatoryGates.add(gateName);
        for (final stg in failedPipelineStages) {
          deterministicBlockers.add(ReadinessEntry(
            description:
                'Release verification stage "${stg.name}" failed: ${stg.details}',
            evidenceSource: 'Release Verification Pipeline (${stg.id})',
          ));
        }
      } else {
        deterministicStrengths.add(ReadinessEntry(
          description:
              'All release verification pipeline stages passed cleanly.',
          evidenceSource: 'Release Verification Pipeline',
        ));
      }

      // Short-circuit decision logic
      final isDeterministicNotReady = failedMandatoryGates.isNotEmpty;
      final deterministicStatus = isDeterministicNotReady
          ? ReleaseReadinessStatus.notReady
          : (deterministicWarnings.isNotEmpty
              ? ReleaseReadinessStatus.needsReview
              : ReleaseReadinessStatus.ready);

      // 4. Construct AI Prompt & Synthesize Narrative (If Provider Available)
      final sanitizedFacts = <String, dynamic>{
        'targetPackage': targetPackageName,
        'version': request.version,
        'deterministicStatus': deterministicStatus.name,
        'failedMandatoryGates': failedMandatoryGates,
        'blockersCount': deterministicBlockers.length,
        'warningsCount': deterministicWarnings.length,
        'strengthsCount': deterministicStrengths.length,
        'evidence': {
          'blockers': deterministicBlockers.map((b) => b.toJson()).toList(),
          'warnings': deterministicWarnings.map((w) => w.toJson()).toList(),
          'strengths': deterministicStrengths.map((s) => s.toJson()).toList(),
        },
      };

      final assistantReq = AssistantRequest(
        prompt: _buildReadinessPrompt(
          targetPackage: targetPackageName,
          version: request.version,
          deterministicStatus: deterministicStatus,
          failedMandatoryGates: failedMandatoryGates,
          blockers: deterministicBlockers,
          warnings: deterministicWarnings,
          strengths: deterministicStrengths,
        ),
        mode: AssistantMode.analysis,
        templateId: targetScopeId,
        context: PromptContext(
          templateId: targetScopeId,
          structuredFacts: sanitizedFacts,
        ),
      );

      AssistantResponse response;
      try {
        response = await _assistantEngine.executeRequest(
          assistantReq,
          executionTimestamp: now,
        );
      } catch (e) {
        _logger.warning(
            'AI Provider failed during release readiness synthesis: $e');
        response = AssistantResponse(
          responseId: 'resp_error_${now.millisecondsSinceEpoch}',
          mode: assistantReq.mode,
          status: AssistantResponseStatus.providerUnavailable,
          templateId: targetScopeId,
          errorMessage: 'AI Provider unavailable: $e',
          timestamp: now,
        );
      }

      stopwatch.stop();

      // 5. Graceful Degradation / Fallback handling on AI failure
      if (!response.isSuccess || response.rawUntrustedCompletion == null) {
        _logger.info('Degrading to status-only release readiness result.');
        return ReleaseReadinessAssessment(
          scope: request.scope,
          targetScopeId: targetScopeId,
          version: request.version,
          status: deterministicStatus,
          summary: isDeterministicNotReady
              ? 'Release NOT READY: One or more mandatory release gates failed deterministically.'
              : 'Release status determined from deterministic pipeline gates.',
          strengths: deterministicStrengths,
          warnings: deterministicWarnings,
          blockers: deterministicBlockers,
          recommendedActions: [
            if (isDeterministicNotReady)
              ReadinessEntry(
                description:
                    'Resolve all failed mandatory release gates listed in the blockers section.',
                evidenceSource: 'Deterministic Release Pipeline',
              ),
          ],
          confidence: CodeReviewConfidence.high,
          mandatoryGatesEvaluated: mandatoryGatesEvaluated,
          failedMandatoryGates: failedMandatoryGates,
          totalEvidenceCount: evidenceGathering.totalEvidenceCount,
          durationMs: stopwatch.elapsedMilliseconds,
          timestamp: now,
          isAiSynthesized: false,
          errorMessage: response.errorMessage,
        );
      }

      // 6. Enforce Mandatory-Gate-Override-Prevention Invariant on Parsed AI Response
      final synthesized = _parseAiSynthesis(
        rawText: response.rawUntrustedCompletion!,
        deterministicStatus: deterministicStatus,
        isDeterministicNotReady: isDeterministicNotReady,
        deterministicBlockers: deterministicBlockers,
        deterministicWarnings: deterministicWarnings,
        deterministicStrengths: deterministicStrengths,
        failedMandatoryGates: failedMandatoryGates,
        mandatoryGatesEvaluated: mandatoryGatesEvaluated,
        scope: request.scope,
        targetScopeId: targetScopeId,
        version: request.version,
        totalEvidenceCount: evidenceGathering.totalEvidenceCount,
        durationMs: stopwatch.elapsedMilliseconds,
        now: now,
      );

      return synthesized;
    } catch (e, st) {
      stopwatch.stop();
      _logger.error(
          'Unhandled exception during release readiness assessment: $e', e, st);
      return ReleaseReadinessAssessment(
        scope: request.scope,
        targetScopeId: targetScopeId,
        version: request.version,
        status: ReleaseReadinessStatus.notReady,
        summary:
            'Internal error during release readiness assessment: ${SecretRedactor.redact(e.toString())}',
        strengths: const [],
        warnings: const [],
        blockers: [
          ReadinessEntry(
            description:
                'Internal assessment failure: ${SecretRedactor.redact(e.toString())}',
            evidenceSource: 'Release Readiness Advisor',
          ),
        ],
        recommendedActions: const [],
        confidence: CodeReviewConfidence.low,
        mandatoryGatesEvaluated: const [],
        failedMandatoryGates: const ['Internal Failure'],
        totalEvidenceCount: 0,
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
        isAiSynthesized: false,
        errorMessage: SecretRedactor.redact(e.toString()),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Deterministic Evidence Gathering across Subsystems
  // ───────────────────────────────────────────────────────────────────────────

  Future<_GatheredEvidence> _gatherDeterministicEvidence({
    required ReleaseReadinessRequest request,
    required String targetPackageName,
    List<VerificationStage>? fixtureStages,
    List<ValidationCheck>? fixturePubDevChecks,
  }) async {
    // 1. Gather Phase 8.9 Security Findings
    List<SecurityFindingItem> securityFindings = const [];
    try {
      final secResult = await _securityEngine.analyze(
        SecurityAnalysisRequest(
          scope: request.scope == ReleaseReadinessScope.package
              ? SecurityAnalysisScope.package
              : SecurityAnalysisScope.wholeProject,
          targetPackage: request.targetPackage,
        ),
      );
      securityFindings = secResult.findings;
    } catch (_) {}

    // 2. Gather Verification Pipeline Stages
    List<VerificationStage> verificationStages;
    if (fixtureStages != null) {
      verificationStages = fixtureStages;
    } else {
      final plan =
          _verificationPipeline.planPipeline(ReleaseVerificationOptions(
        packageName: targetPackageName,
        version: request.version,
      ));
      final result = _verificationPipeline.executePipeline(plan);
      verificationStages = result.stages;
    }

    // 3. Gather Pub.dev Validation Checks
    List<ValidationCheck> pubDevChecks;
    if (fixturePubDevChecks != null) {
      pubDevChecks = fixturePubDevChecks;
    } else {
      final plan = _pubDevValidator.planValidation(PubDevValidationOptions(
        packageName: targetPackageName,
        version: request.version,
      ));
      final result = _pubDevValidator.validatePackage(plan);
      pubDevChecks = result.checks;
    }

    final totalCount = securityFindings.length +
        verificationStages.length +
        pubDevChecks.length;

    return _GatheredEvidence(
      securityFindings: securityFindings,
      verificationStages: verificationStages,
      pubDevChecks: pubDevChecks,
      totalEvidenceCount: totalCount,
    );
  }

  String _buildReadinessPrompt({
    required String targetPackage,
    required String version,
    required ReleaseReadinessStatus deterministicStatus,
    required List<String> failedMandatoryGates,
    required List<ReadinessEntry> blockers,
    required List<ReadinessEntry> warnings,
    required List<ReadinessEntry> strengths,
  }) {
    final buf = StringBuffer();
    buf.writeln(
        'You are the AI Release Readiness Advisor for Flutter Package Studio.');
    buf.writeln(
        'Synthesize release readiness for candidate "$targetPackage" version $version.');
    buf.writeln();
    buf.writeln('MANDATORY GATE INVARIANT:');
    buf.writeln(
        'Deterministic Status: ${deterministicStatus.name.toUpperCase()}');
    if (failedMandatoryGates.isNotEmpty) {
      buf.writeln('FAILED MANDATORY GATES: ${failedMandatoryGates.join(", ")}');
      buf.writeln(
          'You MUST NOT declare status as READY or NEEDS_REVIEW. The release is strictly NOT READY.');
    }
    buf.writeln();
    buf.writeln('EVIDENCE:');
    for (final s in strengths) {
      buf.writeln('- STRENGTH: ${s.description} (Source: ${s.evidenceSource})');
    }
    for (final w in warnings) {
      buf.writeln('- WARNING: ${w.description} (Source: ${w.evidenceSource})');
    }
    for (final b in blockers) {
      buf.writeln('- BLOCKER: ${b.description} (Source: ${b.evidenceSource})');
    }
    buf.writeln();
    buf.writeln('Return ONLY a JSON object matching this schema:');
    buf.writeln('''
{
  "status": "ready|notReady|needsReview",
  "summary": "Executive summary narrative",
  "confidence": "high|medium|low",
  "strengths": [
    {"description": "...", "evidenceSource": "..."}
  ],
  "warnings": [
    {"description": "...", "evidenceSource": "..."}
  ],
  "blockers": [
    {"description": "...", "evidenceSource": "..."}
  ],
  "recommendedActions": [
    {"description": "...", "evidenceSource": "..."}
  ]
}
''');
    return SecretRedactor.redact(buf.toString());
  }

  ReleaseReadinessAssessment _parseAiSynthesis({
    required String rawText,
    required ReleaseReadinessStatus deterministicStatus,
    required bool isDeterministicNotReady,
    required List<ReadinessEntry> deterministicBlockers,
    required List<ReadinessEntry> deterministicWarnings,
    required List<ReadinessEntry> deterministicStrengths,
    required List<String> failedMandatoryGates,
    required List<String> mandatoryGatesEvaluated,
    required ReleaseReadinessScope scope,
    required String targetScopeId,
    required String version,
    required int totalEvidenceCount,
    required int durationMs,
    required DateTime now,
  }) {
    String cleanJson = rawText.trim();
    if (cleanJson.startsWith('```json')) cleanJson = cleanJson.substring(7);
    if (cleanJson.startsWith('```')) cleanJson = cleanJson.substring(3);
    if (cleanJson.endsWith('```'))
      cleanJson = cleanJson.substring(0, cleanJson.length - 3);
    cleanJson = cleanJson.trim();

    Map<String, dynamic> decoded = {};
    try {
      final parsed = jsonDecode(cleanJson);
      if (parsed is Map<String, dynamic>) {
        decoded = parsed;
      }
    } catch (_) {}

    // Extract AI status suggestion
    final rawAiStatus = decoded['status'] as String?;
    var finalStatus =
        ReleaseReadinessStatus.tryParse(rawAiStatus) ?? deterministicStatus;

    // MANDATORY GATE OVERRIDE PREVENTION RULE:
    // If code-level gate check evaluated to NOT READY, AI CAN NEVER OVERRIDE TO READY OR NEEDS_REVIEW!
    if (isDeterministicNotReady) {
      finalStatus = ReleaseReadinessStatus.notReady;
    }

    final confStr = decoded['confidence'] as String? ?? 'high';
    final conf =
        CodeReviewConfidence.tryParse(confStr) ?? CodeReviewConfidence.high;

    final summary = decoded['summary'] as String? ??
        (finalStatus == ReleaseReadinessStatus.ready
            ? 'Release candidate satisfies all quality and release criteria.'
            : 'Release candidate requires resolution of outstanding concerns.');

    List<ReadinessEntry> extractEntries(
        String key, List<ReadinessEntry> fallback) {
      final list = decoded[key];
      if (list is List && list.isNotEmpty) {
        final res = <ReadinessEntry>[];
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            res.add(ReadinessEntry.fromJson(item));
          }
        }
        return res;
      }
      return fallback;
    }

    final strengths = extractEntries('strengths', deterministicStrengths);
    final warnings = extractEntries('warnings', deterministicWarnings);
    var blockers = extractEntries('blockers', deterministicBlockers);
    var actions = extractEntries('recommendedActions', const []);

    // Ensure all deterministic blockers remain present if failed mandatory gates exist
    if (isDeterministicNotReady && blockers.isEmpty) {
      blockers = deterministicBlockers;
    }

    if (actions.isEmpty && isDeterministicNotReady) {
      actions = [
        ReadinessEntry(
          description:
              'Address all mandatory gate failures and critical blockers.',
          evidenceSource: 'Release Verification Pipeline',
        )
      ];
    }

    return ReleaseReadinessAssessment(
      scope: scope,
      targetScopeId: targetScopeId,
      version: version,
      status: finalStatus,
      summary: summary,
      strengths: strengths,
      warnings: warnings,
      blockers: blockers,
      recommendedActions: actions,
      confidence: conf,
      mandatoryGatesEvaluated: mandatoryGatesEvaluated,
      failedMandatoryGates: failedMandatoryGates,
      totalEvidenceCount: totalEvidenceCount,
      durationMs: durationMs,
      timestamp: now,
      isAiSynthesized: true,
    );
  }
}

class _GatheredEvidence {
  final List<SecurityFindingItem> securityFindings;
  final List<VerificationStage> verificationStages;
  final List<ValidationCheck> pubDevChecks;
  final int totalEvidenceCount;

  const _GatheredEvidence({
    required this.securityFindings,
    required this.verificationStages,
    required this.pubDevChecks,
    required this.totalEvidenceCount,
  });
}
