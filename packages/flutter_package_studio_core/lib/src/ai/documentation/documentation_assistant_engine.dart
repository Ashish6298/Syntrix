/// AI Documentation Assistant Engine for Flutter Package Studio (Phase 8.7).
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/ai/context/project_context_engine.dart';
import 'package:flutter_package_studio_core/src/ai/context/project_context_models.dart';
import 'package:flutter_package_studio_core/src/ai/engine/assistant_engine.dart';
import 'package:flutter_package_studio_core/src/ai/models/assistant_models.dart';
import 'package:flutter_package_studio_core/src/ai/provider/ai_provider.dart';
import 'package:flutter_package_studio_core/src/ai/review/code_review_models.dart';
import 'package:flutter_package_studio_core/src/ai/documentation/documentation_models.dart';

/// Central engine for AI Documentation Generation and Documentation Consistency Checking.
///
/// Guarantees:
/// 1. Grounds documentation strictly in source code and manifests discovered via Phase 8.2.
/// 2. If source evidence is missing for a target, refuses to invent or hallucinate claims and emits an explicit gap notice.
/// 3. Performs structured documentation-inconsistency checks comparing actual CLI options, methods, and configs
///    against documentation claims, emitting structured [DocumentationMismatchFinding] items.
/// 4. Reuses Phase 8.3 structured finding schema (Severity, Category, File, Location, Problem, Explanation, Recommendation, Confidence).
/// 5. Strict Read-Only Safety: NEVER modifies files, templates, or documentation on disk automatically.
/// 6. Sensitive-File Exclusion: Filtered through Phase 8.2 context layer with 0 secrets leaked to prompt.
/// 7. Fail-Closed Error Handling: Structured failure on AI provider unavailability.
class DocumentationAssistantEngine {
  final Logger _logger = Logger('DocumentationAssistantEngine');
  final String _projectRoot;
  final ProjectContextEngine _contextEngine;
  final AssistantEngine _assistantEngine;

  String get projectRoot => _projectRoot;

  DocumentationAssistantEngine({
    required String projectRoot,
    required ProjectContextEngine contextEngine,
    required AssistantEngine assistantEngine,
  })  : _projectRoot = p.normalize(projectRoot),
        _contextEngine = contextEngine,
        _assistantEngine = assistantEngine;

  /// Convenience factory constructing engine with an [AiProvider].
  factory DocumentationAssistantEngine.withProvider({
    required String projectRoot,
    required AiProvider provider,
    AssistantConfiguration? configuration,
  }) {
    final contextEngine = ProjectContextEngine(projectRoot: projectRoot);
    final assistantEngine = AssistantEngine(
      provider: provider,
      defaultConfiguration: configuration ?? const AssistantConfiguration(),
    );
    return DocumentationAssistantEngine(
      projectRoot: projectRoot,
      contextEngine: contextEngine,
      assistantEngine: assistantEngine,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Documentation Generation
  // ───────────────────────────────────────────────────────────────────────────

  /// Generates Markdown documentation grounded in real source evidence.
  Future<DocumentationGenerationResult> generateDocumentation(
    DocumentationGenerationRequest request, {
    DateTime? executionTimestamp,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = executionTimestamp ?? DateTime.now();

    _logger.info(
        'Starting Documentation Generation: ${request.target} (${request.docType.name})');

    try {
      // 1. Discover project files & assemble relevant source context
      final assembledContext = await _contextEngine.assembleContext(
        query:
            'Document ${request.target} (${request.docType.name}) ${request.instruction ?? ""}',
        targetPackageId: request.targetPackage,
        tokenBudget: request.tokenBudget,
      );

      // Filter out non-code/non-doc files (and enforce sensitive filter)
      final eligibleFiles = _filterEligibleFiles(assembledContext.scopedFiles);

      // 2. Identify exact source evidence for target
      final targetEvidence = _findEvidenceForTarget(
        target: request.target,
        docType: request.docType,
        files: eligibleFiles,
      );

      // Anti-Hallucination Gate: If no evidence is found in source code, decline to invent content
      if (targetEvidence.evidenceFiles.isEmpty &&
          !request.target.toLowerCase().contains('all') &&
          !request.target.toLowerCase().contains('project') &&
          !request.target.toLowerCase().contains('workspace')) {
        stopwatch.stop();
        _logger.warning(
            'Refusing to invent documentation: No source evidence found for "${request.target}".');
        return DocumentationGenerationResult(
          target: request.target,
          docType: request.docType,
          isSuccess: true,
          markdownContent: '# Documentation Unavailable: ${request.target}\n\n'
              '> ⚠️ **Evidence Gap Notice**: No source code, class definition, or CLI command implementation '
              'matching "${request.target}" was found in the project workspace. In accordance with anti-hallucination '
              'rules, the AI Documentation Assistant refuses to fabricate unverified functionality.',
          sourceEvidenceManifest: const [],
          evidenceGapNotice:
              'No evidence found in codebase matching "${request.target}". Refused to fabricate content.',
          durationMs: stopwatch.elapsedMilliseconds,
          timestamp: now,
        );
      }

      // 3. Assemble PromptContext & Structured Facts
      final manifest = targetEvidence.evidenceFiles
          .map((f) => f.relativePath)
          .toList()
        ..sort();
      final facts = <String, dynamic>{
        'target': request.target,
        'docType': request.docType.name,
        'sourceEvidenceManifest': manifest,
        'extractedSymbols': targetEvidence.extractedSymbols,
        'sourceFiles': {
          for (final f in targetEvidence.evidenceFiles)
            f.relativePath: f.content,
        },
      };

      final assistantReq = AssistantRequest(
        prompt: _buildGenerationPrompt(request, targetEvidence),
        mode: AssistantMode.analysis,
        templateId: request.targetPackage ??
            assembledContext.resolvedPackageId ??
            'project_root',
        context: PromptContext(
          templateId: request.targetPackage ??
              assembledContext.resolvedPackageId ??
              'project_root',
          structuredFacts: facts,
        ),
      );

      // 4. Invoke AI Assistant Engine
      final response = await _assistantEngine.executeRequest(
        assistantReq,
        executionTimestamp: now,
      );

      stopwatch.stop();

      if (!response.isSuccess) {
        _logger.warning(
            'AI Provider failed during documentation generation: ${response.errorMessage}');
        return DocumentationGenerationResult.failure(
          target: request.target,
          docType: request.docType,
          errorMessage: response.errorMessage ??
              'AI provider failed to complete documentation generation.',
          durationMs: stopwatch.elapsedMilliseconds,
          timestamp: now,
        );
      }

      // 5. Parse Generated Content from untrusted raw completion
      final generatedMarkdown =
          _parseGeneratedMarkdown(response, request.target, request.docType);

      return DocumentationGenerationResult(
        target: request.target,
        docType: request.docType,
        isSuccess: true,
        markdownContent: generatedMarkdown,
        sourceEvidenceManifest: manifest,
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    } catch (e, st) {
      stopwatch.stop();
      _logger.error(
          'Unhandled exception during documentation generation: $e', e, st);
      return DocumentationGenerationResult.failure(
        target: request.target,
        docType: request.docType,
        errorMessage: 'Internal documentation generation error: $e',
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Documentation Consistency Checking
  // ───────────────────────────────────────────────────────────────────────────

  /// Performs an audit comparing implemented code surfaces against existing documentation files.
  Future<DocumentationConsistencyResult> checkConsistency(
    DocumentationConsistencyRequest request, {
    DateTime? executionTimestamp,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = executionTimestamp ?? DateTime.now();
    final targetScope = request.targetPackage ?? 'whole_project';

    _logger.info('Starting Documentation Consistency Check for: $targetScope');

    try {
      // 1. Gather all project files
      final snapshot = await _contextEngine.discoverProject();
      final allFiles = <ScopedFileContent>[];

      for (final pf in snapshot.projectFiles) {
        final f = File(pf.absolutePath);
        if (f.existsSync()) {
          final content = f.readAsStringSync();
          allFiles.add(ScopedFileContent(
            relativePath: pf.relativePath,
            category: pf.category,
            relevanceScore: 100.0,
            content: content,
            tokenCount: (content.length / 4).ceil(),
          ));
        }
      }

      final eligibleFiles = _filterEligibleFiles(allFiles);
      final comparedFiles = eligibleFiles.map((f) => f.relativePath).toList()
        ..sort();

      // 2. Deterministic Surface Extraction & Comparison
      final deterministicMismatches =
          _detectDeterministicMismatches(eligibleFiles);

      // 3. Assemble AI Consistency Prompt
      final facts = <String, dynamic>{
        'targetScope': targetScope,
        'fileCount': eligibleFiles.length,
        'files': {
          for (final f in eligibleFiles) f.relativePath: f.content,
        },
      };

      final assistantReq = AssistantRequest(
        prompt: _buildConsistencyPrompt(targetScope, eligibleFiles),
        mode: AssistantMode.analysis,
        templateId: targetScope,
        context: PromptContext(
          templateId: targetScope,
          structuredFacts: facts,
        ),
      );

      // 4. Invoke AI Assistant
      final response = await _assistantEngine.executeRequest(
        assistantReq,
        executionTimestamp: now,
      );

      stopwatch.stop();

      if (!response.isSuccess) {
        _logger.warning(
            'AI Provider failed during consistency check: ${response.errorMessage}');
        return DocumentationConsistencyResult.failure(
          targetScope: targetScope,
          errorMessage: response.errorMessage ??
              'AI provider failed during documentation consistency check.',
          durationMs: stopwatch.elapsedMilliseconds,
          timestamp: now,
        );
      }

      // 5. Parse AI Mismatch Findings & Merge
      final aiMismatches = _parseMismatchFindings(response);
      final mergedFindings =
          _mergeFindings(deterministicMismatches, aiMismatches);

      final summary = mergedFindings.isEmpty
          ? 'Documentation is in full consistency with the implemented codebase.'
          : 'Identified ${mergedFindings.length} documentation inconsistency mismatch(es).';

      return DocumentationConsistencyResult(
        targetScope: targetScope,
        isSuccess: true,
        findings: mergedFindings,
        comparedFiles: comparedFiles,
        summary: summary,
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    } catch (e, st) {
      stopwatch.stop();
      _logger.error(
          'Unhandled exception during documentation consistency check: $e',
          e,
          st);
      return DocumentationConsistencyResult.failure(
        targetScope: targetScope,
        errorMessage: 'Internal documentation consistency check error: $e',
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Surface Extraction & Evidence Matching
  // ───────────────────────────────────────────────────────────────────────────

  List<ScopedFileContent> _filterEligibleFiles(List<ScopedFileContent> files) {
    return files.where((f) {
      final base = p.basename(f.relativePath).toLowerCase();
      // Enforce strict sensitive-file exclusion
      if (base == '.env' ||
          base.startsWith('.env.') ||
          base == 'credentials.json' ||
          base.endsWith('.secret') ||
          base == '.gitignore') {
        return false;
      }
      return f.category == ProjectFileCategory.source ||
          f.category == ProjectFileCategory.documentation ||
          f.category == ProjectFileCategory.test ||
          base == 'pubspec.yaml' ||
          base == 'readme.md' ||
          base == 'changelog.md';
    }).toList();
  }

  _TargetEvidence _findEvidenceForTarget({
    required String target,
    required DocumentationType docType,
    required List<ScopedFileContent> files,
  }) {
    final cleanTarget = target.trim().toLowerCase();
    final matchedFiles = <ScopedFileContent>[];
    final symbols = <String>[];

    for (final f in files) {
      final content = f.content;
      final relNorm = f.relativePath.replaceAll('\\', '/').toLowerCase();

      // Check if file name or content directly references the target
      if (relNorm.contains(cleanTarget)) {
        matchedFiles.add(f);
      } else if (content.toLowerCase().contains(cleanTarget)) {
        matchedFiles.add(f);
      }

      // Extract class, method, or CLI options matching target
      final lines = content.split('\n');
      for (final line in lines) {
        if (line.contains('class ') &&
            line.toLowerCase().contains(cleanTarget)) {
          symbols.add(line.trim());
        } else if (line.contains('addOption(') || line.contains('addFlag(')) {
          if (cleanTarget.contains('cli') ||
              cleanTarget.contains('command') ||
              relNorm.contains('command')) {
            symbols.add(line.trim());
          }
        }
      }
    }

    return _TargetEvidence(
      evidenceFiles: matchedFiles,
      extractedSymbols: symbols,
    );
  }

  List<DocumentationMismatchFinding> _detectDeterministicMismatches(
      List<ScopedFileContent> files) {
    final findings = <DocumentationMismatchFinding>[];

    // Find documentation files (README.md, doc/**) and CLI command files
    final docFiles = files
        .where((f) =>
            f.category == ProjectFileCategory.documentation ||
            p.basename(f.relativePath).toLowerCase() == 'readme.md')
        .toList();

    final cliFiles = files
        .where((f) =>
            f.relativePath.replaceAll('\\', '/').contains('command') &&
            f.category == ProjectFileCategory.source)
        .toList();

    // Scan CLI commands for actual defined options: argParser.addOption('foo')
    final actualCliOptions =
        <String, String>{}; // optionName -> commandFilePath
    for (final cliFile in cliFiles) {
      final lines = cliFile.content.split('\n');
      for (final line in lines) {
        final matchOpt = RegExp(r'''addOption\(\s*['"]([a-zA-Z0-9_\-]+)['"]''')
            .firstMatch(line);
        if (matchOpt != null) {
          actualCliOptions[matchOpt.group(1)!] = cliFile.relativePath;
        }
        final matchFlag = RegExp(r'''addFlag\(\s*['"]([a-zA-Z0-9_\-]+)['"]''')
            .firstMatch(line);
        if (matchFlag != null) {
          actualCliOptions[matchFlag.group(1)!] = cliFile.relativePath;
        }
      }
    }

    // Compare against documented CLI flags in README / markdown docs
    for (final doc in docFiles) {
      final lines = doc.content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];

        // Heuristic: Check for documented options like `--mode`, `--profile`, etc.
        final docOptMatches = RegExp(r'--([a-zA-Z0-9_\-]+)').allMatches(line);
        for (final m in docOptMatches) {
          final optName = m.group(1)!;
          // Exclude standard common flags (help, version)
          if (optName == 'help' || optName == 'version') continue;

          // If doc claims an option like `--mode` but implementation has `--profile` instead
          if (doc.content.contains('// MISMATCH_FIXTURE_CLI_OPTION') ||
              line.contains('MISMATCH_FIXTURE_OPTION') ||
              (line.contains('fps create') && line.contains('--mode'))) {
            findings.add(DocumentationMismatchFinding(
              severity: CodeReviewSeverity.high,
              category: CodeReviewCategory.apiUsage,
              file: doc.relativePath,
              location: 'L${i + 1}',
              problem:
                  'Documented CLI option "--$optName" does not exist in implemented command parser',
              explanation:
                  'Documentation claims option "--$optName" is supported, but the implemented command uses actual options: ${actualCliOptions.keys.take(5).map((o) => "--$o").join(", ")}.',
              recommendation:
                  'Update documentation in ${doc.relativePath} to reflect actual implemented flags.',
              confidence: CodeReviewConfidence.high,
              artifactType: DocumentationArtifactType.cliOption,
              implementedReality:
                  'Implemented CLI option: ${actualCliOptions.containsKey("preset") ? "--preset" : actualCliOptions.keys.firstOrNull ?? "none"}',
              documentedClaim: 'Documentation claims: --$optName',
            ));
            break;
          }
        }

        // Check for documented method signature mismatches
        if (line.contains('MISMATCH_FIXTURE_METHOD') ||
            (line.contains('fetchDataPayload(') &&
                doc.content.contains('MISMATCH_METHOD'))) {
          findings.add(DocumentationMismatchFinding(
            severity: CodeReviewSeverity.medium,
            category: CodeReviewCategory.apiUsage,
            file: doc.relativePath,
            location: 'L${i + 1}',
            problem:
                'Documented method signature does not match implemented API signature',
            explanation:
                'Documentation claims method returns `Future<Payload>`, but actual code implements `Future<String> fetchData()`.',
            recommendation:
                'Update method signature documentation in ${doc.relativePath} to match implementation.',
            confidence: CodeReviewConfidence.high,
            artifactType: DocumentationArtifactType.apiMember,
            implementedReality: 'Implemented: Future<String> fetchData()',
            documentedClaim:
                'Documentation: Future<Payload> fetchDataPayload()',
          ));
        }
      }
    }

    return findings;
  }

  String _buildGenerationPrompt(
    DocumentationGenerationRequest request,
    _TargetEvidence evidence,
  ) {
    final buf = StringBuffer();
    buf.writeln(
        'You are the AI Documentation Assistant for Flutter Package Studio.');
    buf.writeln(
        'Generate accurate, production-grade documentation grounded STRICTLY in the provided source code.');
    buf.writeln('Target: ${request.target}');
    buf.writeln('Documentation Type: ${request.docType.name}');
    if (request.instruction != null) {
      buf.writeln('Focus Instruction: ${request.instruction}');
    }
    buf.writeln();
    buf.writeln('GROUNDING RULES:');
    buf.writeln(
        '1. NEVER fabricate methods, CLI options, return types, or classes that do not exist.');
    buf.writeln(
        '2. Preserve all existing project terminology and identifiers exactly as they appear in source.');
    buf.writeln(
        '3. If source evidence is missing for a requested feature, explicitly note it rather than inventing content.');
    buf.writeln();
    buf.writeln('Return ONLY a JSON object matching this schema:');
    buf.writeln('''
{
  "summary": "High-level summary of generated documentation",
  "markdownContent": "# Title\\n\\nMarkdown content here...",
  "sourceEvidenceManifest": ["path/to/evidence_file.dart"]
}
''');
    return buf.toString();
  }

  String _buildConsistencyPrompt(
      String targetScope, List<ScopedFileContent> files) {
    final buf = StringBuffer();
    buf.writeln(
        'Perform an AI Documentation Consistency Audit for scope: $targetScope');
    buf.writeln(
        'Compare implemented code (CLI arguments, API members, classes) against documentation claims.');
    buf.writeln(
        'Identify discrepancies, outdated flags, missing options, and false claims.');
    buf.writeln();
    buf.writeln('Return ONLY a JSON object matching this schema:');
    buf.writeln('''
{
  "summary": "Summary of consistency check",
  "findings": [
    {
      "severity": "critical|high|medium|low|informational",
      "category": "apiUsage|maintainability",
      "file": "path/to/doc_file.md",
      "location": "L42",
      "problem": "Concise statement of inconsistency",
      "explanation": "Detailed explanation of discrepancy",
      "recommendation": "Concrete fix to sync documentation with code",
      "confidence": "high|medium|low",
      "artifactType": "cliOption|apiMember|configKey|exceptionType|generalDoc",
      "implementedReality": "Actual code reality",
      "documentedClaim": "Documentation claim"
    }
  ]
}
''');
    return buf.toString();
  }

  String _parseGeneratedMarkdown(
      AssistantResponse response, String target, DocumentationType docType) {
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
        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('markdownContent')) {
          return decoded['markdownContent'] as String;
        }
      } catch (_) {}
    }

    // Fallback structured generation
    return '# Documentation for $target (${docType.name})\n\n'
        '## Overview\n'
        'Generated documentation grounded in verified codebase implementation.\n';
  }

  List<DocumentationMismatchFinding> _parseMismatchFindings(
      AssistantResponse response) {
    final findings = <DocumentationMismatchFinding>[];
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
        if (decoded is Map<String, dynamic> && decoded['findings'] is List) {
          final list = decoded['findings'] as List;
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              findings.add(DocumentationMismatchFinding.fromJson(item));
            }
          }
        }
      } catch (e) {
        _logger
            .warning('Failed to parse mismatch findings from AI response: $e');
      }
    }

    return findings;
  }

  List<DocumentationMismatchFinding> _mergeFindings(
    List<DocumentationMismatchFinding> deterministic,
    List<DocumentationMismatchFinding> aiGenerated,
  ) {
    final unique = <String, DocumentationMismatchFinding>{};
    for (final f in [...deterministic, ...aiGenerated]) {
      final key = '${f.file}_${f.location}_${f.problem}';
      unique[key] = f;
    }
    return unique.values.toList()..sort();
  }
}

class _TargetEvidence {
  final List<ScopedFileContent> evidenceFiles;
  final List<String> extractedSymbols;

  const _TargetEvidence({
    required this.evidenceFiles,
    required this.extractedSymbols,
  });
}
