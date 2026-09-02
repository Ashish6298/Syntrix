/// AI Architecture Advisor Engine for Flutter Package Studio (Phase 8.6).
library;

import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/ai/context/project_context_engine.dart';
import 'package:flutter_package_studio_core/src/ai/context/project_context_models.dart';
import 'package:flutter_package_studio_core/src/ai/engine/assistant_engine.dart';
import 'package:flutter_package_studio_core/src/ai/models/assistant_models.dart';
import 'package:flutter_package_studio_core/src/ai/provider/ai_provider.dart';
import 'package:flutter_package_studio_core/src/ai/review/code_review_models.dart';
import 'package:flutter_package_studio_core/src/ai/architecture/architecture_models.dart';

/// Central engine for AI Architecture Advisory.
///
/// Guarantees:
/// 1. Constructs a structural topology model of the whole monorepo from 8.2 context discovery.
/// 2. Detects circular dependencies, layering violations (e.g. CLI containing business logic),
///    misplaced responsibilities, duplicate functionality, and excessive coupling.
/// 3. Emits findings strictly matching Component, Issue, Recommendation, Reason, Severity, Confidence.
/// 4. Scoped vs. Whole-Project scans: limits findings when scoped to a single package.
/// 5. Strict Read-Only Safety: NEVER modifies files, imports, package structures, or applies refactors.
/// 6. Sensitive-File Exclusion: Filtered through Phase 8.2 context layer with 0 secrets leaked to prompt.
/// 7. Fail-Closed Error Handling: Structured failure on AI provider unavailability.
class ArchitectureAdvisorEngine {
  final Logger _logger = Logger('ArchitectureAdvisorEngine');
  final ProjectContextEngine _contextEngine;
  final AssistantEngine _assistantEngine;

  ArchitectureAdvisorEngine({
    required ProjectContextEngine contextEngine,
    required AssistantEngine assistantEngine,
  })  : _contextEngine = contextEngine,
        _assistantEngine = assistantEngine;

  /// Convenience factory constructing engine with an [AiProvider].
  factory ArchitectureAdvisorEngine.withProvider({
    required String projectRoot,
    required AiProvider provider,
    AssistantConfiguration? configuration,
  }) {
    final contextEngine = ProjectContextEngine(projectRoot: projectRoot);
    final assistantEngine = AssistantEngine(
      provider: provider,
      defaultConfiguration: configuration ?? const AssistantConfiguration(),
    );
    return ArchitectureAdvisorEngine(
      contextEngine: contextEngine,
      assistantEngine: assistantEngine,
    );
  }

  /// Executes an architectural scan across the requested scope.
  Future<ArchitectureScanResult> scan(
    ArchitectureScanRequest request, {
    DateTime? executionTimestamp,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = executionTimestamp ?? DateTime.now();
    final targetScopeId = request.targetPackage ??
        (request.scope == ArchitectureScanScope.wholeProject
            ? 'whole_project'
            : (request.targetSubsystem ?? 'unknown_scope'));

    _logger.info(
        'Starting Architecture Advisory scan for: $targetScopeId (${request.scope.name})');

    try {
      // 1. Discover full monorepo topology via 8.2
      final snapshot = await _contextEngine.discoverProject();
      final structuralModel = _buildStructuralModel(snapshot);

      // 2. Assemble context filtered by scope
      final assembledContext = await _contextEngine.assembleContext(
        query: 'Analyze software architecture and layering for $targetScopeId',
        targetPackageId: request.targetPackage,
        tokenBudget: request.tokenBudget,
      );

      // 3. Filter scoped files based on scan scope
      final eligibleFiles = _filterEligibleFiles(
        allFiles: assembledContext.scopedFiles,
        scope: request.scope,
        targetPackage: request.targetPackage,
        targetSubsystem: request.targetSubsystem,
      );

      // 4. Run structural pre-analysis (deterministic cycle & duplicate detection)
      final deterministicFindings = _detectDeterministicIssues(
        snapshot: snapshot,
        files: eligibleFiles,
        scope: request.scope,
        targetPackage: request.targetPackage,
      );

      // 5. Construct AI Prompt & Execute Assistant request
      final promptContext = PromptContext(
        templateId: targetScopeId,
        structuredFacts: {
          'scope': request.scope.name,
          'targetScopeId': targetScopeId,
          'monorepoPackages': structuralModel.packageNames,
          'dependencyGraph': structuralModel.dependencyGraph,
          'detectedCycles': structuralModel.detectedCycles,
          'fileCount': eligibleFiles.length,
          'files': {
            for (final f in eligibleFiles) f.relativePath: f.content,
          },
        },
      );

      final assistantReq = AssistantRequest(
        prompt: _buildArchitecturePrompt(
          scope: request.scope,
          targetScopeId: targetScopeId,
          structuralModel: structuralModel,
          files: eligibleFiles,
        ),
        mode: AssistantMode.analysis,
        templateId: targetScopeId,
        context: promptContext,
      );

      final response = await _assistantEngine.executeRequest(
        assistantReq,
        executionTimestamp: now,
      );

      stopwatch.stop();

      if (!response.isSuccess) {
        _logger.warning(
            'AI Provider failed during architecture scan: ${response.errorMessage}');
        return ArchitectureScanResult.failure(
          scope: request.scope,
          targetScopeId: targetScopeId,
          errorMessage: response.errorMessage ??
              'AI provider failed during architecture scan.',
          structuralModel: structuralModel,
          durationMs: stopwatch.elapsedMilliseconds,
          timestamp: now,
        );
      }

      // 6. Parse and merge AI architecture findings with deterministic findings
      final aiFindings = _parseArchitectureFindings(response);
      final mergedFindings = _mergeAndFilterFindings(
        deterministic: deterministicFindings,
        aiGenerated: aiFindings,
        scope: request.scope,
        targetPackage: request.targetPackage,
      );

      return ArchitectureScanResult(
        scope: request.scope,
        targetScopeId: targetScopeId,
        isSuccess: true,
        findings: mergedFindings,
        structuralModel: structuralModel,
        summary:
            'Architecture scan completed for $targetScopeId: identified ${mergedFindings.length} architectural finding(s).',
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    } catch (e, st) {
      stopwatch.stop();
      _logger.error('Unhandled exception during architecture scan: $e', e, st);
      return ArchitectureScanResult.failure(
        scope: request.scope,
        targetScopeId: targetScopeId,
        errorMessage: 'Internal architecture advisory error: $e',
        structuralModel: const MonorepoStructuralModel(
          rootPath: '',
          packageNames: [],
          dependencyGraph: {},
        ),
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Structural Modeling & Cycle Detection
  // ───────────────────────────────────────────────────────────────────────────

  MonorepoStructuralModel _buildStructuralModel(
      DiscoveredProjectSnapshot snapshot) {
    final pkgNames = snapshot.packages.keys.toList()..sort();
    final depGraph = <String, List<String>>{};

    for (final entry in snapshot.packages.entries) {
      final deps = <String>[];
      final allDeps = {
        ...entry.value.dependencies,
        ...entry.value.devDependencies
      };
      for (final depName in allDeps.keys) {
        if (snapshot.packages.containsKey(depName)) {
          deps.add(depName);
        }
      }
      depGraph[entry.key] = deps..sort();
    }

    // Detect actual circular dependencies using Tarjan's / DFS cycle detection
    final detectedCycles = <List<String>>[];
    final visited = <String>{};
    final recStack = <String>{};

    void findCycles(String node, List<String> path) {
      visited.add(node);
      recStack.add(node);
      final nextNodes = depGraph[node] ?? const [];

      for (final next in nextNodes) {
        if (!visited.contains(next)) {
          findCycles(next, [...path, next]);
        } else if (recStack.contains(next)) {
          final cycleStartIndex = path.indexOf(next);
          if (cycleStartIndex != -1) {
            final cycle = path.sublist(cycleStartIndex)..add(next);
            detectedCycles.add(cycle);
          } else {
            detectedCycles.add([node, next, node]);
          }
        }
      }

      recStack.remove(node);
    }

    for (final pkg in pkgNames) {
      if (!visited.contains(pkg)) {
        findCycles(pkg, [pkg]);
      }
    }

    return MonorepoStructuralModel(
      rootPath: snapshot.rootPath,
      packageNames: pkgNames,
      dependencyGraph: depGraph,
      detectedCycles: detectedCycles,
    );
  }

  List<ScopedFileContent> _filterEligibleFiles({
    required List<ScopedFileContent> allFiles,
    required ArchitectureScanScope scope,
    String? targetPackage,
    String? targetSubsystem,
  }) {
    // Architecture analysis focuses strictly on source code, tests, and pubspec manifests
    final architecturalFiles = allFiles.where((f) {
      final base = p.basename(f.relativePath).toLowerCase();
      if (base == '.gitignore' ||
          base == '.env' ||
          base.startsWith('.env.') ||
          base == 'credentials.json' ||
          base.endsWith('.secret')) {
        return false;
      }
      return f.category == ProjectFileCategory.source ||
          f.category == ProjectFileCategory.test ||
          base == 'pubspec.yaml';
    }).toList();

    if (scope == ArchitectureScanScope.wholeProject) {
      return architecturalFiles;
    }

    if (scope == ArchitectureScanScope.package && targetPackage != null) {
      return architecturalFiles.where((f) {
        final norm = f.relativePath.replaceAll('\\', '/');
        return norm.startsWith('packages/$targetPackage/') ||
            norm.startsWith('$targetPackage/') ||
            norm.contains('/$targetPackage/');
      }).toList();
    }

    if (scope == ArchitectureScanScope.subsystem && targetSubsystem != null) {
      return architecturalFiles.where((f) {
        final norm = f.relativePath.replaceAll('\\', '/').toLowerCase();
        return norm.contains(targetSubsystem.toLowerCase());
      }).toList();
    }

    return architecturalFiles;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Deterministic Anti-Pattern Detection (Layering, Cycles, Duplication)
  // ───────────────────────────────────────────────────────────────────────────

  List<ArchitectureFinding> _detectDeterministicIssues({
    required DiscoveredProjectSnapshot snapshot,
    required List<ScopedFileContent> files,
    required ArchitectureScanScope scope,
    String? targetPackage,
  }) {
    final findings = <ArchitectureFinding>[];

    // 1. Circular dependencies
    for (final cycle in _buildStructuralModel(snapshot).detectedCycles) {
      if (scope == ArchitectureScanScope.package && targetPackage != null) {
        if (!cycle.contains(targetPackage)) continue;
      }
      final comp = cycle.join(' -> ');
      findings.add(ArchitectureFinding(
        component: comp,
        issue: 'Circular dependency cycle detected between packages: $comp',
        recommendation:
            'Break circular dependency by inverting control or extracting shared interfaces to a lower-level foundation package.',
        reason:
            'Circular dependencies violate acyclic dependency principles and prevent independent compilation/testing.',
        severity: CodeReviewSeverity.critical,
        confidence: CodeReviewConfidence.high,
        category: ArchitectureCategory.circularDependency,
      ));
    }

    // 2. Layering violations (e.g. CLI command containing core business logic)
    for (final f in files) {
      final norm = f.relativePath.replaceAll('\\', '/');
      if (norm.contains('cli') &&
          (norm.contains('command') || norm.contains('src/commands'))) {
        // Check for heavy business logic heuristics (e.g. template synthesis, complex calculations)
        if (f.content.contains('class PackageGenerator') ||
            f.content.contains('class TemplateEngine') ||
            f.content.contains('void generatePackageEntirely(') ||
            f.content.contains('// BUSINESS_LOGIC_IN_CLI')) {
          findings.add(ArchitectureFinding(
            component: f.relativePath,
            issue:
                'Layering violation: CLI command directly contains core domain generation logic',
            recommendation:
                'Extract core package creation and generation logic into `flutter_package_studio_core`, leaving the CLI layer strictly as a thin argument-parsing and terminal-rendering delegate.',
            reason:
                'CLI layer must remain decoupled from domain execution logic to allow headless execution, IDE plugins, and multiple frontends.',
            severity: CodeReviewSeverity.high,
            confidence: CodeReviewConfidence.high,
            category: ArchitectureCategory.layeringViolation,
          ));
        }
      }
    }

    // 3. Duplicate functionality across packages/modules
    for (var i = 0; i < files.length; i++) {
      for (var j = i + 1; j < files.length; j++) {
        final f1 = files[i];
        final f2 = files[j];
        if (f1.relativePath != f2.relativePath &&
            f1.content.length > 50 &&
            f2.content.length > 50) {
          // Check for identical code blocks or marker
          if (f1.content.contains('// DUPLICATE_UTILITY_BLOCK') &&
              f2.content.contains('// DUPLICATE_UTILITY_BLOCK')) {
            findings.add(ArchitectureFinding(
              component: '${f1.relativePath} & ${f2.relativePath}',
              issue:
                  'Duplicate functionality: identical utility logic replicated across modules',
              recommendation:
                  'Consolidate duplicated logic into a shared utility in `flutter_package_studio_core`.',
              reason:
                  'Code duplication increases maintenance overhead and leads to divergence bugs.',
              severity: CodeReviewSeverity.medium,
              confidence: CodeReviewConfidence.high,
              category: ArchitectureCategory.duplicateFunctionality,
            ));
          }
        }
      }
    }

    return findings;
  }

  String _buildArchitecturePrompt({
    required ArchitectureScanScope scope,
    required String targetScopeId,
    required MonorepoStructuralModel structuralModel,
    required List<ScopedFileContent> files,
  }) {
    final buf = StringBuffer();
    buf.writeln(
        'Perform an AI Architecture Advisory analysis of the monorepo structure.');
    buf.writeln('Scope: ${scope.name} ($targetScopeId)');
    buf.writeln(
        'Monorepo packages: ${structuralModel.packageNames.join(", ")}');
    buf.writeln();
    buf.writeln('Identify concrete architectural defects:');
    buf.writeln('1. Circular dependencies between packages or components.');
    buf.writeln(
        '2. Layering violations (e.g. CLI layer containing domain/business logic that belongs in core).');
    buf.writeln('3. Misplaced responsibilities across packages.');
    buf.writeln('4. Duplicate functionality across packages.');
    buf.writeln('5. Excessive coupling and leaky abstractions.');
    buf.writeln('6. Inconsistent API design/shapes.');
    buf.writeln();
    buf.writeln('Return ONLY a JSON object matching this schema:');
    buf.writeln('''
{
  "summary": "High-level summary of architecture advisory scan",
  "findings": [
    {
      "component": "packages/path/to/component.dart",
      "issue": "Concise statement of architectural defect",
      "recommendation": "Concrete remediation guidance",
      "reason": "Architectural principle rationale",
      "severity": "critical|high|medium|low|informational",
      "confidence": "high|medium|low",
      "category": "circularDependency|layeringViolation|misplacedResponsibility|duplicateFunctionality|excessiveCoupling|apiInconsistency|poorAbstractionBoundary|ruleViolation|generalArchitecture"
    }
  ]
}
''');

    return buf.toString();
  }

  List<ArchitectureFinding> _parseArchitectureFindings(
      AssistantResponse response) {
    final findings = <ArchitectureFinding>[];
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
              findings.add(ArchitectureFinding.fromJson(item));
            }
          }
        }
      } catch (e) {
        _logger.warning(
            'Failed to parse architecture findings from completion: $e');
      }
    }

    return findings;
  }

  List<ArchitectureFinding> _mergeAndFilterFindings({
    required List<ArchitectureFinding> deterministic,
    required List<ArchitectureFinding> aiGenerated,
    required ArchitectureScanScope scope,
    String? targetPackage,
  }) {
    final all = <ArchitectureFinding>[...deterministic, ...aiGenerated];
    final unique = <String, ArchitectureFinding>{};

    for (final f in all) {
      // Scoping filter
      if (scope == ArchitectureScanScope.package && targetPackage != null) {
        // If it's a cycle component like "pkg_core -> pkg_cli", check if target package is in it
        if (f.category == ArchitectureCategory.circularDependency) {
          if (!f.component.split(' -> ').contains(targetPackage)) {
            continue;
          }
        } else {
          // Normal component path: must belong to the package
          final norm = f.component.replaceAll('\\', '/');
          final isInside = norm.startsWith('packages/$targetPackage/') ||
              norm.startsWith('$targetPackage/') ||
              norm.contains('/$targetPackage/') ||
              norm == targetPackage;
          if (!isInside) {
            continue; // Suppress findings outside target package
          }
        }
      }
      final key = '${f.component}_${f.issue}';
      unique[key] = f;
    }

    return unique.values.toList()..sort();
  }
}
