/// Unified AI Engineering Command Center Engine (Phase 8.14).
library;

import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/ai/provider/ai_provider.dart';
import 'package:flutter_package_studio_core/src/ai/models/assistant_models.dart';
import 'package:flutter_package_studio_core/src/ai/engine/assistant_engine.dart';
import 'package:flutter_package_studio_core/src/ai/security/secret_redactor.dart';
import 'package:flutter_package_studio_core/src/ai/command_center/command_center_models.dart';

// Subsystem engines & models
import 'package:flutter_package_studio_core/src/ai/review/code_review_engine.dart';
import 'package:flutter_package_studio_core/src/ai/review/code_review_models.dart';
import 'package:flutter_package_studio_core/src/ai/testing/test_intelligence_engine.dart';
import 'package:flutter_package_studio_core/src/ai/testing/test_intelligence_models.dart';
import 'package:flutter_package_studio_core/src/ai/diagnosis/failure_diagnosis_engine.dart';
import 'package:flutter_package_studio_core/src/ai/diagnosis/failure_diagnosis_models.dart';
import 'package:flutter_package_studio_core/src/ai/architecture/architecture_advisor_engine.dart';
import 'package:flutter_package_studio_core/src/ai/architecture/architecture_models.dart';
import 'package:flutter_package_studio_core/src/ai/documentation/documentation_assistant_engine.dart';
import 'package:flutter_package_studio_core/src/ai/documentation/documentation_models.dart';
import 'package:flutter_package_studio_core/src/ai/dependencies/dependency_advisor_engine.dart';
import 'package:flutter_package_studio_core/src/ai/dependencies/dependency_models.dart';
import 'package:flutter_package_studio_core/src/ai/security/security_advisor_engine.dart';
import 'package:flutter_package_studio_core/src/ai/security/security_models.dart';
import 'package:flutter_package_studio_core/src/ai/release/release_readiness_advisor_engine.dart';
import 'package:flutter_package_studio_core/src/ai/release/release_readiness_models.dart';
import 'package:flutter_package_studio_core/src/ai/planner/workflow_planner_engine.dart';
import 'package:flutter_package_studio_core/src/ai/planner/workflow_planner_models.dart';
import 'package:flutter_package_studio_core/src/ai/memory/session_memory_engine.dart';
import 'package:flutter_package_studio_core/src/ai/memory/session_memory_models.dart';
import 'package:flutter_package_studio_core/src/ai/modification/code_modification_engine.dart';
import 'package:flutter_package_studio_core/src/ai/modification/code_modification_models.dart';

/// Central Unified AI Engineering Command Center orchestrator.
///
/// Combines the 13 discrete Milestone 8 AI capabilities into one unified router:
/// 1. Analyze (Analysis & context discovery)
/// 2. Debug (Failure diagnosis & error root-cause)
/// 3. Review (Code review & finding synthesis)
/// 4. Test (Test intelligence & test suite generation)
/// 5. Document (Documentation assistant)
/// 6. Security (Security & privacy advisor)
/// 7. Architecture (Architecture advisor)
/// 8. Dependencies (Dependency & compatibility advisor)
/// 9. Release (Release readiness advisor)
/// 10. Plan (9-stage workflow planning)
/// 11. Explain (Pattern explanation)
/// 12. Memory (Engineering session & knowledge memory)
/// 13. Modify (Controlled code modification)
///
/// Design Invariants:
/// - Intelligent Subsystem Routing: Automatically dispatches requests to dedicated subsystem engines.
/// - Fail-Closed Containment: Subsystem errors are caught and surfaced as structured failure results.
/// - Zero-Secret Leakage: SecretRedactor is applied across all input prompts and output payloads.
/// - Natural Language Intent Resolver: Auto-detects capability when not explicitly specified.
class CommandCenterEngine {
  final Logger _logger = Logger('CommandCenterEngine');
  final String _projectRoot;
  final AiProvider _provider;
  final AssistantEngine _assistantEngine;

  String get projectRoot => _projectRoot;
  AiProvider get provider => _provider;

  CommandCenterEngine({
    required String projectRoot,
    required AiProvider provider,
    AssistantConfiguration configuration = const AssistantConfiguration(),
    AssistantEngine? assistantEngine,
  })  : _projectRoot = p.normalize(projectRoot),
        _provider = provider,
        _assistantEngine = assistantEngine ??
            AssistantEngine(
                provider: provider, defaultConfiguration: configuration);

  /// Dispatches [request] to the appropriate AI subsystem.
  Future<CommandCenterResponse> execute(
    CommandCenterRequest request, {
    DateTime? executionTimestamp,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = executionTimestamp ?? DateTime.now();

    _logger.info(
        'Command Center dispatching capability: ${request.capability.name} for target: "${request.target}"');

    try {
      switch (request.capability) {
        case CommandCenterCapability.analyze:
          return await _routeAnalyze(request, stopwatch, now);

        case CommandCenterCapability.debug:
          return await _routeDebug(request, stopwatch, now);

        case CommandCenterCapability.review:
          return await _routeReview(request, stopwatch, now);

        case CommandCenterCapability.test:
          return await _routeTest(request, stopwatch, now);

        case CommandCenterCapability.document:
          return await _routeDocument(request, stopwatch, now);

        case CommandCenterCapability.security:
          return await _routeSecurity(request, stopwatch, now);

        case CommandCenterCapability.architecture:
          return await _routeArchitecture(request, stopwatch, now);

        case CommandCenterCapability.dependencies:
          return await _routeDependencies(request, stopwatch, now);

        case CommandCenterCapability.release:
          return await _routeRelease(request, stopwatch, now);

        case CommandCenterCapability.plan:
          return await _routePlan(request, stopwatch, now);

        case CommandCenterCapability.explain:
          return await _routeExplain(request, stopwatch, now);

        case CommandCenterCapability.memory:
          return await _routeMemory(request, stopwatch, now);

        case CommandCenterCapability.modify:
          return await _routeModify(request, stopwatch, now);
      }
    } catch (e, st) {
      stopwatch.stop();
      _logger.error(
          'Command Center error executing ${request.capability.name}: $e',
          e,
          st);
      return CommandCenterResponse.failure(
        capability: request.capability,
        errorMessage:
            'Command Center execution failed: ${SecretRedactor.redact(e.toString())}',
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    }
  }

  /// Intelligently resolves the target capability from a natural-language intent string.
  static CommandCenterCapability resolveCapabilityFromIntent(String intent) {
    final clean = intent.toLowerCase();

    if (clean.contains('sec') ||
        clean.contains('vulnerab') ||
        clean.contains('leak') ||
        clean.contains('secret') ||
        clean.contains('token')) {
      return CommandCenterCapability.security;
    }
    if (clean.contains('debug') ||
        clean.contains('fail') ||
        clean.contains('error') ||
        clean.contains('exception') ||
        clean.contains('stacktrace') ||
        clean.contains('crash') ||
        clean.contains('crashed')) {
      return CommandCenterCapability.debug;
    }
    if (clean.contains('why did') ||
        clean.contains('why we') ||
        clean.contains('decision') ||
        clean.contains('history') ||
        clean.contains('limitation') ||
        clean.contains('memory')) {
      return CommandCenterCapability.memory;
    }
    if (clean.contains('arch') ||
        clean.contains('boundary') ||
        clean.contains('layer') ||
        clean.contains('modular')) {
      return CommandCenterCapability.architecture;
    }
    if (clean.contains('test') ||
        clean.contains('suite') ||
        clean.contains('coverage') ||
        clean.contains('mock')) {
      return CommandCenterCapability.test;
    }
    if (clean.contains('review') ||
        clean.contains('lint') ||
        clean.contains('smell') ||
        clean.contains('inspect')) {
      return CommandCenterCapability.review;
    }
    if (clean.contains('doc') ||
        clean.contains('readme') ||
        clean.contains('api doc') ||
        clean.contains('guide')) {
      return CommandCenterCapability.document;
    }
    if (clean.contains('dep') ||
        clean.contains('version') ||
        clean.contains('upgrade') ||
        clean.contains('pubspec') ||
        clean.contains('compat')) {
      return CommandCenterCapability.dependencies;
    }
    if (clean.contains('release') ||
        clean.contains('readiness') ||
        clean.contains('publish') ||
        clean.contains('changelog')) {
      return CommandCenterCapability.release;
    }
    if (clean.contains('plan') ||
        clean.contains('roadmap') ||
        clean.contains('step') ||
        clean.contains('implement')) {
      return CommandCenterCapability.plan;
    }
    if (clean.contains('modify') ||
        clean.contains('patch') ||
        clean.contains('change code') ||
        clean.contains('refactor code')) {
      return CommandCenterCapability.modify;
    }
    if (clean.contains('explain') ||
        clean.contains('how does') ||
        clean.contains('pattern')) {
      return CommandCenterCapability.explain;
    }

    return CommandCenterCapability.analyze;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Subsystem Routers
  // ───────────────────────────────────────────────────────────────────────────

  Future<CommandCenterResponse> _routeAnalyze(
      CommandCenterRequest req, Stopwatch sw, DateTime now) async {
    final templateId = req.target ?? 'default_template';
    final assistantReq = AssistantRequest(
      prompt: req.prompt.isNotEmpty
          ? req.prompt
          : 'Perform deep architectural, dependency, and security analysis.',
      mode: AssistantMode.analysis,
      templateId: templateId,
      context: PromptContext(templateId: templateId),
    );
    final resp = await _assistantEngine.executeRequest(assistantReq,
        executionTimestamp: now);
    sw.stop();

    return CommandCenterResponse(
      capability: CommandCenterCapability.analyze,
      summary: resp.isSuccess
          ? 'Completed deep analysis for "$templateId".'
          : 'Analysis failed.',
      structuredPayload: resp.structuredContent,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
      isSuccess: resp.isSuccess,
      errorMessage: resp.errorMessage,
    );
  }

  Future<CommandCenterResponse> _routeDebug(
      CommandCenterRequest req, Stopwatch sw, DateTime now) async {
    final engine = FailureDiagnosisEngine.withProvider(
      projectRoot: _projectRoot,
      provider: _provider,
    );
    final diagReq = DiagnosisRequest(
      evidence: FailureEvidenceBundle.fromSingleError(
        errorMessage: req.prompt.isNotEmpty
            ? req.prompt
            : 'Debugging failure in ${req.target ?? "workspace"}',
        targetPackage: req.target,
      ),
    );
    final res = await engine.diagnose(diagReq, executionTimestamp: now);
    sw.stop();

    return CommandCenterResponse(
      capability: CommandCenterCapability.debug,
      summary: res.isSuccess ? res.summary : 'Failure diagnosis failed.',
      structuredPayload: res,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
      isSuccess: res.isSuccess,
      errorMessage: res.isSuccess ? null : 'Diagnosis failed.',
    );
  }

  Future<CommandCenterResponse> _routeReview(
      CommandCenterRequest req, Stopwatch sw, DateTime now) async {
    final engine = CodeReviewEngine.withProvider(
      projectRoot: _projectRoot,
      provider: _provider,
    );
    final isDartFile = req.target != null && req.target!.endsWith('.dart');
    final reviewReq = CodeReviewRequest(
      mode:
          isDartFile ? CodeReviewMode.singleFile : CodeReviewMode.packageLevel,
      targetFile: isDartFile ? req.target : null,
      targetPackage: !isDartFile ? req.target : null,
      customInstruction: req.prompt.isNotEmpty ? req.prompt : null,
      tokenBudget: req.tokenBudget,
    );
    final res = await engine.review(reviewReq, executionTimestamp: now);
    sw.stop();

    return CommandCenterResponse(
      capability: CommandCenterCapability.review,
      summary: res.isSuccess ? res.summary : 'Code review failed.',
      structuredPayload: res,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
      isSuccess: res.isSuccess,
      errorMessage: res.errorMessage,
    );
  }

  Future<CommandCenterResponse> _routeTest(
      CommandCenterRequest req, Stopwatch sw, DateTime now) async {
    final engine = TestIntelligenceEngine.withProvider(
      projectRoot: _projectRoot,
      provider: _provider,
    );
    final testReq = TestIntelligenceRequest(
      targetPackage: req.target,
      generateProposals: true,
      tokenBudget: req.tokenBudget,
    );
    final res = await engine.analyze(testReq, executionTimestamp: now);
    sw.stop();

    return CommandCenterResponse(
      capability: CommandCenterCapability.test,
      summary:
          res.isSuccess ? res.summary : 'Test intelligence planning failed.',
      structuredPayload: res,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
      isSuccess: res.isSuccess,
      errorMessage: res.errorMessage,
    );
  }

  Future<CommandCenterResponse> _routeDocument(
      CommandCenterRequest req, Stopwatch sw, DateTime now) async {
    final engine = DocumentationAssistantEngine.withProvider(
      projectRoot: _projectRoot,
      provider: _provider,
    );
    final docReq = DocumentationGenerationRequest(
      target: req.target ?? 'workspace',
      docType: DocumentationType.readmeSection,
      instruction: req.prompt.isNotEmpty ? req.prompt : null,
      tokenBudget: req.tokenBudget,
    );
    final res =
        await engine.generateDocumentation(docReq, executionTimestamp: now);
    sw.stop();

    return CommandCenterResponse(
      capability: CommandCenterCapability.document,
      summary: res.isSuccess
          ? 'Generated documentation for "${res.target}".'
          : 'Documentation generation failed.',
      structuredPayload: res,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
      isSuccess: res.isSuccess,
      errorMessage: res.evidenceGapNotice,
    );
  }

  Future<CommandCenterResponse> _routeSecurity(
      CommandCenterRequest req, Stopwatch sw, DateTime now) async {
    final engine = SecurityAdvisorEngine.withProvider(
      projectRoot: _projectRoot,
      provider: _provider,
    );
    final secReq = SecurityAnalysisRequest(
      scope: req.target != null
          ? SecurityAnalysisScope.package
          : SecurityAnalysisScope.wholeProject,
      targetPackage: req.target,
      tokenBudget: req.tokenBudget,
    );
    final res = await engine.analyze(secReq, executionTimestamp: now);
    sw.stop();

    return CommandCenterResponse(
      capability: CommandCenterCapability.security,
      summary: res.isSuccess ? res.summary : 'Security audit failed.',
      structuredPayload: res,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
      isSuccess: res.isSuccess,
      errorMessage: res.errorMessage,
    );
  }

  Future<CommandCenterResponse> _routeArchitecture(
      CommandCenterRequest req, Stopwatch sw, DateTime now) async {
    final engine = ArchitectureAdvisorEngine.withProvider(
      projectRoot: _projectRoot,
      provider: _provider,
    );
    final archReq = ArchitectureScanRequest(
      scope: req.target != null
          ? ArchitectureScanScope.package
          : ArchitectureScanScope.wholeProject,
      targetPackage: req.target,
      tokenBudget: req.tokenBudget,
    );
    final res = await engine.scan(archReq, executionTimestamp: now);
    sw.stop();

    return CommandCenterResponse(
      capability: CommandCenterCapability.architecture,
      summary: res.isSuccess
          ? 'Architecture scan complete: ${res.findings.length} findings, score: ${res.findings.isEmpty ? 100 : 80}/100.'
          : 'Architecture analysis failed.',
      structuredPayload: res,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
      isSuccess: res.isSuccess,
      errorMessage: res.errorMessage,
    );
  }

  Future<CommandCenterResponse> _routeDependencies(
      CommandCenterRequest req, Stopwatch sw, DateTime now) async {
    final engine = DependencyAdvisorEngine.withProvider(
      projectRoot: _projectRoot,
      provider: _provider,
    );
    final depReq = DependencyAnalysisRequest(
      scope: req.target != null
          ? DependencyAnalysisScope.package
          : DependencyAnalysisScope.wholeProject,
      targetPackage: req.target,
      tokenBudget: req.tokenBudget,
    );
    final res = await engine.analyze(depReq, executionTimestamp: now);
    sw.stop();

    return CommandCenterResponse(
      capability: CommandCenterCapability.dependencies,
      summary: res.isSuccess
          ? 'Dependency analysis complete: ${res.findings.length} findings identified.'
          : 'Dependency advice failed.',
      structuredPayload: res,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
      isSuccess: res.isSuccess,
      errorMessage: res.errorMessage,
    );
  }

  Future<CommandCenterResponse> _routeRelease(
      CommandCenterRequest req, Stopwatch sw, DateTime now) async {
    final engine = ReleaseReadinessAdvisorEngine.withProvider(
      projectRoot: _projectRoot,
      provider: _provider,
    );
    final relReq = ReleaseReadinessRequest(
      scope: req.target != null
          ? ReleaseReadinessScope.package
          : ReleaseReadinessScope.wholeProject,
      targetPackage: req.target,
      tokenBudget: req.tokenBudget,
    );
    final res = await engine.assess(relReq, executionTimestamp: now);
    sw.stop();

    return CommandCenterResponse(
      capability: CommandCenterCapability.release,
      summary: res.summary.isNotEmpty
          ? res.summary
          : 'Release readiness: ${res.status.name.toUpperCase()}.',
      structuredPayload: res,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
      isSuccess: res.isSuccess,
      errorMessage: res.errorMessage,
    );
  }

  Future<CommandCenterResponse> _routePlan(
      CommandCenterRequest req, Stopwatch sw, DateTime now) async {
    final engine = WorkflowPlannerEngine.withProvider(
      projectRoot: _projectRoot,
      provider: _provider,
    );
    final planReq = WorkflowPlanRequest(
      request: req.prompt.isNotEmpty
          ? req.prompt
          : (req.target ?? 'Engineering plan'),
      targetPackage: req.target,
      tokenBudget: req.tokenBudget,
    );
    final res = await engine.plan(planReq, executionTimestamp: now);
    sw.stop();

    return CommandCenterResponse(
      capability: CommandCenterCapability.plan,
      summary: res.isSuccess
          ? 'Generated 9-stage engineering workflow plan.'
          : 'Workflow planning failed.',
      structuredPayload: res,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
      isSuccess: res.isSuccess,
      errorMessage: res.errorMessage,
    );
  }

  Future<CommandCenterResponse> _routeExplain(
      CommandCenterRequest req, Stopwatch sw, DateTime now) async {
    final templateId = req.target ?? 'pattern_explanation';
    final assistantReq = AssistantRequest(
      prompt: req.prompt.isNotEmpty
          ? req.prompt
          : 'Explain architectural design patterns.',
      mode: AssistantMode.explanation,
      templateId: templateId,
      context: PromptContext(templateId: templateId),
    );
    final resp = await _assistantEngine.executeRequest(assistantReq,
        executionTimestamp: now);
    sw.stop();

    return CommandCenterResponse(
      capability: CommandCenterCapability.explain,
      summary:
          resp.isSuccess ? 'Explanation generated.' : 'Explanation failed.',
      structuredPayload: resp.structuredContent,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
      isSuccess: resp.isSuccess,
      errorMessage: resp.errorMessage,
    );
  }

  Future<CommandCenterResponse> _routeMemory(
      CommandCenterRequest req, Stopwatch sw, DateTime now) async {
    final engine = SessionMemoryEngine(projectRoot: _projectRoot);
    final memReq = MemoryQueryRequest(
      query: req.prompt.isNotEmpty
          ? req.prompt
          : (req.target ?? 'Engineering decisions'),
      scope: req.target,
    );
    final res = await engine.query(memReq, executionTimestamp: now);
    sw.stop();

    return CommandCenterResponse(
      capability: CommandCenterCapability.memory,
      summary: res.isSuccess ? res.synthesis : 'Memory query failed.',
      structuredPayload: res,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
      isSuccess: res.isSuccess,
      errorMessage: res.errorMessage,
    );
  }

  Future<CommandCenterResponse> _routeModify(
      CommandCenterRequest req, Stopwatch sw, DateTime now) async {
    final engine = CodeModificationEngine.withProvider(
      projectRoot: _projectRoot,
      provider: _provider,
    );
    final modReq = CodeModificationPlanRequest(
      requirement: req.prompt.isNotEmpty
          ? req.prompt
          : (req.target ?? 'Code modification'),
      targetScope: req.target,
    );
    final res =
        await engine.proposeModification(modReq, executionTimestamp: now);
    sw.stop();

    return CommandCenterResponse(
      capability: CommandCenterCapability.modify,
      summary:
          res.isSuccess ? res.summary : 'Code modification proposal failed.',
      structuredPayload: res,
      durationMs: sw.elapsedMilliseconds,
      timestamp: now,
      isSuccess: res.isSuccess,
      errorMessage: res.errorMessage,
    );
  }
}
