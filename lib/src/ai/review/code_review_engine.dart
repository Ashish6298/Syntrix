/// Code Review Engine for Dart & Flutter Packages (Phase 8.3).
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

/// Central engine for executing AI Code Analysis & Review across 4 operating modes.
///
/// Guarantees:
/// 1. Non-Execution & Zero Side Effects: Read-only inspection; zero disk writes, zero git operations, zero processes spawned.
/// 2. Sensitive File Safety: All source scoping routes through Phase 8.2's [ProjectContextEngine] and [SensitiveFileFilter].
/// 3. Cross-Mode Finding Consistency: Same core schema across single-file, package-level, change-focused, and architecture-focused modes.
/// 4. Deduplication: Package-level cross-file duplication findings are deduplicated.
/// 5. Safe Failure: Structured error result on provider unavailability or timeout.
class CodeReviewEngine {
  final Logger _logger = Logger('CodeReviewEngine');
  final ProjectContextEngine _contextEngine;
  final AssistantEngine _assistantEngine;

  CodeReviewEngine({
    required ProjectContextEngine contextEngine,
    required AssistantEngine assistantEngine,
  })  : _contextEngine = contextEngine,
        _assistantEngine = assistantEngine;

  /// Convenience factory constructing engine with a specified [AiProvider].
  factory CodeReviewEngine.withProvider({
    required String projectRoot,
    required AiProvider provider,
    AssistantConfiguration? configuration,
  }) {
    final contextEngine = ProjectContextEngine(projectRoot: projectRoot);
    final assistantEngine = AssistantEngine(
      provider: provider,
      defaultConfiguration: configuration ?? const AssistantConfiguration(),
    );
    return CodeReviewEngine(
      contextEngine: contextEngine,
      assistantEngine: assistantEngine,
    );
  }

  /// Runs code analysis and review against the project per [request].
  Future<CodeReviewResult> review(
    CodeReviewRequest request, {
    DateTime? executionTimestamp,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = executionTimestamp ?? DateTime.now();

    _logger.info('Starting AI Code Review in mode: ${request.mode.name}');

    try {
      // 1. Build project/package context via 8.2 Context Engine
      final contextQuery = _buildContextQuery(request);
      final assembledContext = await _contextEngine.assembleContext(
        query: contextQuery,
        targetPackageId: request.targetPackage,
        tokenBudget: request.tokenBudget,
      );

      // 2. Filter scoped files according to review mode
      final eligibleFiles = _filterFilesForMode(
        assembledContext: assembledContext,
        request: request,
      );

      if (eligibleFiles.isEmpty) {
        stopwatch.stop();
        return CodeReviewResult(
          mode: request.mode,
          isSuccess: true,
          findings: const [],
          summary:
              'No eligible safe source files found for review in mode "${request.mode.name}".',
          inspectedFiles: const [],
          durationMs: stopwatch.elapsedMilliseconds,
          timestamp: now,
        );
      }

      final inspectedFilePaths =
          eligibleFiles.map((f) => f.relativePath).toList();

      // 3. Assemble PromptContext & Review Prompt
      final promptContext = _buildReviewPromptContext(
        assembledContext: assembledContext,
        eligibleFiles: eligibleFiles,
        request: request,
      );

      final assistantReq = AssistantRequest(
        prompt: _buildReviewPromptInstruction(request, eligibleFiles),
        mode: AssistantMode.analysis,
        templateId: request.targetPackage ??
            assembledContext.resolvedPackageId ??
            'project_root',
        context: promptContext,
      );

      // 4. Invoke AI Assistant Engine
      final response = await _assistantEngine.executeRequest(
        assistantReq,
        executionTimestamp: now,
      );

      stopwatch.stop();

      if (!response.isSuccess) {
        _logger.warning(
            'AI Provider failed during review: ${response.errorMessage}');
        return CodeReviewResult.failure(
          mode: request.mode,
          errorMessage: response.errorMessage ??
              'AI provider failed to complete review request.',
          inspectedFiles: inspectedFilePaths,
          durationMs: stopwatch.elapsedMilliseconds,
          timestamp: now,
        );
      }

      // 5. Parse and Validate Review Findings
      final rawFindings =
          _extractFindingsFromResponse(response, inspectedFilePaths);

      // 6. Post-process findings per mode (deduplication, architecture filtering, change-scoping)
      final processedFindings = _postProcessFindings(
        findings: rawFindings,
        mode: request.mode,
        changedFiles: request.changedFiles,
      );

      return CodeReviewResult(
        mode: request.mode,
        isSuccess: true,
        findings: processedFindings,
        summary:
            'Successfully inspected ${inspectedFilePaths.length} file(s) and identified ${processedFindings.length} finding(s).',
        inspectedFiles: inspectedFilePaths,
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    } catch (e, st) {
      stopwatch.stop();
      _logger.error('Unhandled exception during code review: $e', e, st);
      return CodeReviewResult.failure(
        mode: request.mode,
        errorMessage: 'Internal review engine error: $e',
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helper Methods
  // ───────────────────────────────────────────────────────────────────────────

  String _buildContextQuery(CodeReviewRequest request) {
    if (request.targetFile != null) {
      return 'Inspect file ${request.targetFile}';
    }
    if (request.targetPackage != null) {
      return 'Review package ${request.targetPackage}';
    }
    if (request.changedFiles != null && request.changedFiles!.isNotEmpty) {
      return 'Review changed files: ${request.changedFiles!.join(", ")}';
    }
    return 'Full project code review and architectural analysis';
  }

  List<ScopedFileContent> _filterFilesForMode({
    required AssembledProjectContext assembledContext,
    required CodeReviewRequest request,
  }) {
    final allFiles = assembledContext.scopedFiles;

    switch (request.mode) {
      case CodeReviewMode.singleFile:
        if (request.targetFile == null) return allFiles;
        final targetNorm =
            p.normalize(request.targetFile!).replaceAll('\\', '/');
        return allFiles.where((f) {
          final relNorm = p.normalize(f.relativePath).replaceAll('\\', '/');
          return relNorm == targetNorm || relNorm.endsWith(targetNorm);
        }).toList();

      case CodeReviewMode.changeFocused:
        if (request.changedFiles == null || request.changedFiles!.isEmpty) {
          return allFiles;
        }
        final changedNormalized = request.changedFiles!
            .map((c) => p.normalize(c).replaceAll('\\', '/'))
            .toSet();
        return allFiles.where((f) {
          final relNorm = p.normalize(f.relativePath).replaceAll('\\', '/');
          return changedNormalized
              .any((c) => relNorm == c || relNorm.endsWith(c));
        }).toList();

      case CodeReviewMode.packageLevel:
      case CodeReviewMode.architectureFocused:
        // Include source and test files
        return allFiles.where((f) {
          return f.category == ProjectFileCategory.source ||
              f.category == ProjectFileCategory.configuration ||
              f.category == ProjectFileCategory.test;
        }).toList();
    }
  }

  PromptContext _buildReviewPromptContext({
    required AssembledProjectContext assembledContext,
    required List<ScopedFileContent> eligibleFiles,
    required CodeReviewRequest request,
  }) {
    final fileContents = <String, String>{};
    for (final f in eligibleFiles) {
      fileContents[f.relativePath] = f.content;
    }

    final facts = <String, dynamic>{
      'reviewMode': request.mode.name,
      'fileCount': eligibleFiles.length,
      'files': fileContents,
      'projectSummary': assembledContext.projectSummary,
    };

    return PromptContext(
      templateId: request.targetPackage ??
          assembledContext.resolvedPackageId ??
          'project_root',
      structuredFacts: facts,
    );
  }

  String _buildReviewPromptInstruction(
    CodeReviewRequest request,
    List<ScopedFileContent> files,
  ) {
    final buf = StringBuffer();
    buf.writeln(
        'Perform an in-depth AI Code Analysis & Review of the provided Dart/Flutter files.');
    buf.writeln('Operating Mode: ${request.mode.name.toUpperCase()}');
    buf.writeln();
    buf.writeln('Inspect the source for:');
    buf.writeln('1. Potential bugs, logic errors, and null safety pitfalls.');
    buf.writeln(
        '2. Flutter widget lifecycle errors (BuildContext across async gaps, improper setState, disposal leaks).');
    buf.writeln(
        '3. Incorrect async behavior (unawaited futures, race conditions, StreamController leaks).');
    buf.writeln('4. Architectural flaws, tight coupling, and high complexity.');
    buf.writeln('5. Redundancy and code duplication.');
    buf.writeln('6. Error handling weaknesses and security/unsafe patterns.');
    buf.writeln();

    if (request.customInstruction != null &&
        request.customInstruction!.isNotEmpty) {
      buf.writeln('Custom Instruction: ${request.customInstruction}');
      buf.writeln();
    }

    buf.writeln('Return a JSON object matching this schema:');
    buf.writeln('''
{
  "summary": "High-level summary of the code review",
  "findings": [
    {
      "severity": "critical|high|medium|low|informational",
      "category": "bugRisk|codeSmell|architecture|apiUsage|errorHandling|maintainability|duplication|complexity|asyncBehavior|unsafePattern|flutterLifecycle",
      "file": "path/to/file.dart",
      "location": "L42 or symbol_name",
      "problem": "Concise description of the problem",
      "explanation": "Detailed explanation of the risk or root cause",
      "recommendation": "Actionable instructions to remediate",
      "confidence": "high|medium|low"
    }
  ]
}
''');

    return buf.toString();
  }

  List<CodeReviewFinding> _extractFindingsFromResponse(
    AssistantResponse response,
    List<String> validFiles,
  ) {
    final findings = <CodeReviewFinding>[];

    // Try parsing structured content or raw untrusted completion
    final rawText = response.rawUntrustedCompletion;
    if (rawText == null || rawText.trim().isEmpty) {
      // If mock response returned standard AnalysisPayload
      if (response.structuredContent is AnalysisPayload) {
        final payload = response.structuredContent as AnalysisPayload;
        for (var i = 0; i < payload.findings.length; i++) {
          final fStr = payload.findings[i];
          findings.add(CodeReviewFinding(
            severity: CodeReviewSeverity.medium,
            category: CodeReviewCategory.codeSmell,
            file:
                validFiles.isNotEmpty ? validFiles.first : 'lib/src/main.dart',
            location: 'L1',
            problem: fStr,
            explanation: 'Identified during assistant code review analysis.',
            recommendation:
                'Refactor code to follow standard Dart/Flutter best practices.',
            confidence: CodeReviewConfidence.medium,
          ));
        }
      }
      return findings;
    }

    try {
      String cleanJson = rawText.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7);
      } else if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3);
      }
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
      cleanJson = cleanJson.trim();

      final decoded = jsonDecode(cleanJson);
      if (decoded is Map<String, dynamic> && decoded['findings'] is List) {
        final list = decoded['findings'] as List;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            findings.add(CodeReviewFinding.fromJson(item));
          }
        }
      }
    } catch (e) {
      _logger.warning('Failed to parse findings array from raw completion: $e');
    }

    return findings;
  }

  List<CodeReviewFinding> _postProcessFindings({
    required List<CodeReviewFinding> findings,
    required CodeReviewMode mode,
    Set<String>? changedFiles,
  }) {
    var result = List<CodeReviewFinding>.from(findings);

    // 1. Architecture-focused mode: Suppress line-level nitpicks (codeSmell, style, maintainability)
    if (mode == CodeReviewMode.architectureFocused) {
      result = result.where((f) {
        return f.category == CodeReviewCategory.architecture ||
            f.category == CodeReviewCategory.apiUsage ||
            f.category == CodeReviewCategory.complexity ||
            f.severity == CodeReviewSeverity.critical ||
            f.severity == CodeReviewSeverity.high;
      }).toList();
    }

    // 2. Change-focused mode: Strictly scope to modified files
    if (mode == CodeReviewMode.changeFocused &&
        changedFiles != null &&
        changedFiles.isNotEmpty) {
      final changedNorm =
          changedFiles.map((c) => p.normalize(c).replaceAll('\\', '/')).toSet();
      result = result.where((f) {
        final fileNorm = p.normalize(f.file).replaceAll('\\', '/');
        return changedNorm.any((c) => fileNorm == c || fileNorm.endsWith(c));
      }).toList();
    }

    // 3. Package-level mode: Deduplicate cross-file duplication findings
    if (mode == CodeReviewMode.packageLevel) {
      final seenDuplicationSignatures = <String>{};
      final deduped = <CodeReviewFinding>[];

      for (final f in result) {
        if (f.category == CodeReviewCategory.duplication) {
          final sig =
              '${f.problem.trim().toLowerCase()}_${f.recommendation.trim().toLowerCase()}';
          if (seenDuplicationSignatures.contains(sig)) {
            continue; // Deduplicate
          }
          seenDuplicationSignatures.add(sig);
        }
        deduped.add(f);
      }
      result = deduped;
    }

    return result..sort();
  }
}
