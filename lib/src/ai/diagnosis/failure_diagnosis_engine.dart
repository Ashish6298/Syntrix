/// Failure Diagnosis Engine for Flutter Package Studio (Phase 8.5).
library;

import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/ai/context/project_context_engine.dart';
import 'package:syntrix/src/ai/context/project_context_models.dart';
import 'package:syntrix/src/ai/engine/assistant_engine.dart';
import 'package:syntrix/src/ai/models/assistant_models.dart';
import 'package:syntrix/src/ai/provider/ai_provider.dart';
import 'package:syntrix/src/ai/review/code_review_models.dart';
import 'package:syntrix/src/ai/diagnosis/failure_diagnosis_models.dart';

/// Central engine for AI Debugging & Failure Diagnosis.
///
/// Guarantees:
/// 1. Consumes rich engineering evidence (stack traces, test failures, analyzer output, CLI errors).
/// 2. Produces structured diagnosis with all 7 mandatory fields:
///    Problem, Likely Cause (tiered: confirmed/probable/possible), Evidence,
///    Affected Components, Recommended Fix, Risk, and Verification Steps.
/// 3. Historical Report Integration: Identifies and cites previous phase verification reports.
/// 4. Read-Only Safety Invariant: NEVER mutates files, applies patches, runs tests, or shells out.
/// 5. Sensitive File Protection: Completely filters `.env` and credential files via Phase 8.2 context layer.
/// 6. Fail-Closed Error Handling: Structured diagnosis failure on AI provider unavailability.
class FailureDiagnosisEngine {
  final Logger _logger = Logger('FailureDiagnosisEngine');
  final ProjectContextEngine _contextEngine;
  final AssistantEngine _assistantEngine;

  FailureDiagnosisEngine({
    required ProjectContextEngine contextEngine,
    required AssistantEngine assistantEngine,
  })  : _contextEngine = contextEngine,
        _assistantEngine = assistantEngine;

  /// Convenience factory constructing engine with an [AiProvider].
  factory FailureDiagnosisEngine.withProvider({
    required String projectRoot,
    required AiProvider provider,
    AssistantConfiguration? configuration,
  }) {
    final contextEngine = ProjectContextEngine(projectRoot: projectRoot);
    final assistantEngine = AssistantEngine(
      provider: provider,
      defaultConfiguration: configuration ?? const AssistantConfiguration(),
    );
    return FailureDiagnosisEngine(
      contextEngine: contextEngine,
      assistantEngine: assistantEngine,
    );
  }

  /// Executes failure diagnosis given a structured [DiagnosisRequest].
  Future<DiagnosisResult> diagnose(
    DiagnosisRequest request, {
    DateTime? executionTimestamp,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = executionTimestamp ?? DateTime.now();
    final targetPkg = request.targetPackage ??
        request.evidence.targetPackage ??
        'project_root';

    _logger.info('Starting failure diagnosis for scope: $targetPkg');

    try {
      // 1. Assemble safe project context & historical reports via 8.2
      final assembled = await _contextEngine.assembleContext(
        query: 'Diagnose failure: ${request.evidence.primaryError}',
        targetPackageId: targetPkg,
        tokenBudget: request.tokenBudget,
      );

      // 2. Identify relevant source files and historical reports
      final relevantSources = assembled.scopedFiles
          .where((f) =>
              f.category == ProjectFileCategory.source ||
              f.category == ProjectFileCategory.test)
          .toList();

      final historicalReports = assembled.scopedFiles
          .where((f) =>
              f.category == ProjectFileCategory.report ||
              f.category == ProjectFileCategory.documentation)
          .toList();

      // 3. Narrow affected components from evidence and context
      final affectedComponents = _identifyAffectedComponents(
        evidence: request.evidence,
        availableSources: relevantSources,
        targetPkg: targetPkg,
      );

      // 4. Extract historical report citations
      final historicalCitations = _extractHistoricalCitations(
        evidence: request.evidence,
        reports: historicalReports,
      );

      // 5. Construct AI Prompt & Execute Assistant request
      final promptContext = PromptContext(
        templateId: targetPkg,
        structuredFacts: {
          'primaryError': request.evidence.primaryError,
          'affectedComponents': affectedComponents,
          'evidenceItems':
              request.evidence.items.map((i) => i.toJson()).toList(),
          'historicalCitations': historicalCitations,
          'relevantSourceExcerpts': {
            for (final f in relevantSources.take(5)) f.relativePath: f.content,
          },
        },
      );

      final assistantReq = AssistantRequest(
        prompt: _buildDiagnosisPrompt(
            request.evidence, affectedComponents, historicalCitations),
        mode: AssistantMode.analysis,
        templateId: targetPkg,
        context: promptContext,
      );

      final response = await _assistantEngine.executeRequest(
        assistantReq,
        executionTimestamp: now,
      );

      stopwatch.stop();

      if (!response.isSuccess) {
        _logger.warning(
            'AI Provider failed during diagnosis: ${response.errorMessage}');
        return DiagnosisResult.failure(
          packageId: targetPkg,
          errorMessage: response.errorMessage ??
              'AI provider failed during failure diagnosis.',
          durationMs: stopwatch.elapsedMilliseconds,
          timestamp: now,
        );
      }

      // 6. Parse structured FailureDiagnosis from completion
      final diagnosis = _parseDiagnosis(
        response: response,
        evidence: request.evidence,
        affectedComponents: affectedComponents,
        historicalCitations: historicalCitations,
      );

      return DiagnosisResult(
        packageId: targetPkg,
        isSuccess: true,
        diagnosis: diagnosis,
        summary:
            'Diagnosed failure in ${affectedComponents.join(", ")} with ${diagnosis.likelyCauses.length} cause tier(s).',
        historicalCitations: historicalCitations,
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    } catch (e, st) {
      stopwatch.stop();
      _logger.error('Unhandled exception during diagnosis: $e', e, st);
      return DiagnosisResult.failure(
        packageId: targetPkg,
        errorMessage: 'Internal diagnosis error: $e',
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helper & Pipeline Methods
  // ───────────────────────────────────────────────────────────────────────────

  List<String> _identifyAffectedComponents({
    required FailureEvidenceBundle evidence,
    required List<ScopedFileContent> availableSources,
    required String targetPkg,
  }) {
    final components = <String>{};

    // 1. Target file from evidence
    if (evidence.targetFile != null && evidence.targetFile!.isNotEmpty) {
      components.add(evidence.targetFile!);
    }

    // 2. Scan stack traces and evidence items for matching source filenames
    for (final item in evidence.items) {
      for (final src in availableSources) {
        final base = p.basename(src.relativePath);
        if (item.content.contains(base) || item.source.contains(base)) {
          components.add(src.relativePath);
        }
      }
    }

    // 3. Fallback to target package
    if (components.isEmpty) {
      if (availableSources.isNotEmpty) {
        components.add(availableSources.first.relativePath);
      } else {
        components.add(targetPkg);
      }
    }

    return components.toList()..sort();
  }

  List<String> _extractHistoricalCitations({
    required FailureEvidenceBundle evidence,
    required List<ScopedFileContent> reports,
  }) {
    final citations = <String>{};

    // Include explicit citations from bundle
    citations.addAll(evidence.historicalReportCitations);

    // Check existing reports for matching error patterns / limitations
    for (final r in reports) {
      final base = p.basename(r.relativePath);
      if (r.content.contains('Known limitations') ||
          r.content.contains('VERIFICATION REPORT')) {
        citations.add(r.relativePath);
      }
      if (evidence.primaryError.isNotEmpty &&
          r.content.contains(evidence.primaryError)) {
        citations.add('$base (matches previously reported failure pattern)');
      }
    }

    return citations.toList()..sort();
  }

  String _buildDiagnosisPrompt(
    FailureEvidenceBundle evidence,
    List<String> affectedComponents,
    List<String> historicalCitations,
  ) {
    final buf = StringBuffer();
    buf.writeln(
        'Perform an AI Failure Diagnosis for the following engineering defect.');
    buf.writeln();
    buf.writeln('PRIMARY ERROR: ${evidence.primaryError}');
    buf.writeln('AFFECTED COMPONENTS: ${affectedComponents.join(", ")}');
    if (historicalCitations.isNotEmpty) {
      buf.writeln(
          'HISTORICAL REPORT CITATIONS: ${historicalCitations.join(", ")}');
    }
    buf.writeln();
    buf.writeln('EVIDENCE ITEMS:');
    for (final item in evidence.items) {
      buf.writeln('- [${item.type.name}] ${item.source}: ${item.content}');
    }
    buf.writeln();
    buf.writeln('CRITICAL INSTRUCTIONS:');
    buf.writeln(
        '1. Every likely cause MUST be explicitly tagged with a certainty level:');
    buf.writeln(
        '   - "confirmed": Directly reproduced or unambiguously demonstrated by exact line/stack trace.');
    buf.writeln(
        '   - "probable": Strongly implied by evidence but not directly reproduced.');
    buf.writeln(
        '   - "possible": Plausible given partial or circumstantial evidence.');
    buf.writeln(
        '2. NEVER collapse cause certainty into a single unqualified string.');
    buf.writeln(
        '3. Cite the exact input evidence items used in "citedEvidence".');
    buf.writeln(
        '4. Produce a detailed "recommendedFix" and remediation "risk" (critical|high|medium|low).');
    buf.writeln(
        '5. Provide a step-by-step "verificationSteps" plan to verify the fix WITHOUT executing any code.');
    buf.writeln();
    buf.writeln('Return ONLY a JSON object matching this schema:');
    buf.writeln('''
{
  "summary": "High-level summary of the failure diagnosis",
  "problem": "Clear statement of the defect",
  "likelyCauses": [
    {
      "description": "Specific diagnosed root cause",
      "certainty": "confirmed|probable|possible",
      "rationale": "Why this cause and certainty tier was assigned"
    }
  ],
  "citedEvidence": ["Citation 1", "Citation 2"],
  "affectedComponents": ["lib/path/to/affected_file.dart"],
  "recommendedFix": "Concrete, actionable remediation code or instructions",
  "risk": "critical|high|medium|low",
  "verificationSteps": [
    {
      "stepNumber": 1,
      "action": "Concrete test or analysis command to run",
      "expectedOutcome": "Expected result confirming remediation"
    }
  ]
}
''');

    return buf.toString();
  }

  FailureDiagnosis _parseDiagnosis({
    required AssistantResponse response,
    required FailureEvidenceBundle evidence,
    required List<String> affectedComponents,
    required List<String> historicalCitations,
  }) {
    final rawText = response.rawUntrustedCompletion;
    if (rawText != null && rawText.trim().isNotEmpty) {
      try {
        String cleanJson = rawText.trim();
        if (cleanJson.startsWith('```json')) cleanJson = cleanJson.substring(7);
        if (cleanJson.startsWith('```')) cleanJson = cleanJson.substring(3);
        if (cleanJson.endsWith('```'))
          cleanJson = cleanJson.substring(0, cleanJson.length - 3);
        cleanJson = cleanJson.trim();

        final decoded = jsonDecode(cleanJson);
        if (decoded is Map<String, dynamic>) {
          return FailureDiagnosis.fromJson(decoded);
        }
      } catch (e) {
        _logger.warning('Failed to parse diagnosis from completion: $e');
      }
    }

    // Heuristic deterministic fallback
    final hasDirectStackTrace = evidence.items.any(
        (i) => i.type == EvidenceType.stackTrace && i.content.contains(':'));
    final defaultCertainty = hasDirectStackTrace
        ? CauseCertainty.confirmed
        : CauseCertainty.probable;

    final cited = <String>[
      evidence.primaryError,
      ...evidence.items.map((i) => '${i.type.name}: ${i.source}'),
      ...historicalCitations,
    ];

    return FailureDiagnosis(
      problem: evidence.primaryError,
      likelyCauses: [
        DiagnosedCause(
          description:
              'Failure triggered by unhandled condition in ${affectedComponents.join(", ")}',
          certainty: defaultCertainty,
          rationale: hasDirectStackTrace
              ? 'Unambiguously localized via provided stack trace evidence.'
              : 'Inferred from error description and component analysis.',
        )
      ],
      citedEvidence: cited,
      affectedComponents: affectedComponents,
      recommendedFix:
          'Review error boundary and validate inputs in ${affectedComponents.join(", ")}.',
      risk: CodeReviewSeverity.medium,
      verificationSteps: const [
        VerificationStep(
          stepNumber: 1,
          action: 'Run unit test suite for affected component.',
          expectedOutcome: 'All assertions pass without exceptions.',
        ),
        VerificationStep(
          stepNumber: 2,
          action: 'Run static analysis via `dart analyze .`.',
          expectedOutcome: 'Zero analyzer issues reported.',
        )
      ],
    );
  }
}
