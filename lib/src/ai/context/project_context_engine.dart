/// Project Context & Codebase Intelligence Engine for Flutter Package Studio (Phase 8.2).
library;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:syntrix/src/logging/logger.dart';

import 'package:syntrix/src/ai/context/project_context_models.dart';
import 'package:syntrix/src/ai/context/sensitive_file_filter.dart';
import 'package:syntrix/src/ai/models/assistant_models.dart';

/// Central engine for non-executively discovering project structure, resolving packages,
/// prioritizing relevant files, and assembling fail-closed AI context.
class ProjectContextEngine {
  final Logger _logger = Logger('ProjectContextEngine');
  final String _projectRoot;
  final SensitiveFileFilter _filter;

  /// Maximum character limit per individual file before snippet truncation.
  static const int maxFileCharBudget = 8000;

  /// Default total token limit for assembled context.
  static const int defaultTokenBudget = 4000;

  String get projectRoot => _projectRoot;
  SensitiveFileFilter get filter => _filter;

  ProjectContextEngine({
    required String projectRoot,
    SensitiveFileFilter? filter,
  })  : _projectRoot = p.normalize(projectRoot),
        _filter = filter ?? SensitiveFileFilter.fromProjectRoot(projectRoot);

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Non-Executing Project Context Discovery
  // ───────────────────────────────────────────────────────────────────────────

  /// Scans the project directory non-executively, discovering monorepo packages,
  /// dependency graphs, reports, and categorized files.
  Future<DiscoveredProjectSnapshot> discoverProject() async {
    _logger.info('Starting non-executive project discovery at: $_projectRoot');

    final rootDir = Directory(_projectRoot);
    if (!rootDir.existsSync()) {
      return DiscoveredProjectSnapshot(
        rootPath: _projectRoot,
        isMonorepo: false,
        packages: const {},
        dependencyGraph: const PackageDependencyGraph(
          outgoingEdges: {},
          incomingEdges: {},
        ),
        projectFiles: const [],
        existingReports: const [],
        configurationFiles: const [],
      );
    }

    final discoveredPackages = <String, DiscoveredPackage>{};
    final projectFiles = <DiscoveredProjectFile>[];
    final existingReports = <String>[];
    final configurationFiles = <String>[];

    // Find all pubspec.yaml files across project
    final pubspecs = _findPubspecFiles(rootDir);

    for (final pubspecFile in pubspecs) {
      final pkg = _parsePackageNonExecutively(pubspecFile);
      if (pkg != null) {
        discoveredPackages[pkg.name] = pkg;
      }
    }

    // Traverse all files non-executively
    final candidateEntities = _listAllFilesNonExecutively(rootDir);
    for (final entity in candidateEntities) {
      final relPath =
          p.relative(entity.path, from: _projectRoot).replaceAll('\\', '/');
      final stat = entity.statSync();
      final category = _categorizeFile(relPath);
      final pkgId = _resolvePackageIdForPath(relPath);

      final discoveredFile = DiscoveredProjectFile(
        relativePath: relPath,
        absolutePath: entity.path,
        category: category,
        sizeBytes: stat.size,
        lastModified: stat.modified,
        packageId: pkgId,
      );

      // Only add to non-sensitive snapshot projectFiles if it passes base sensitivity filter
      final filterDecision = _filter.evaluateFile(relativePath: relPath);
      if (filterDecision.isSafe) {
        projectFiles.add(discoveredFile);
        if (category == ProjectFileCategory.report) {
          existingReports.add(relPath);
        } else if (category == ProjectFileCategory.configuration) {
          configurationFiles.add(relPath);
        }
      }
    }

    // Populate source, test, doc, and report lists on each discovered package
    final finalizedPackages = <String, DiscoveredPackage>{};
    for (final entry in discoveredPackages.entries) {
      final pkg = entry.value;
      final pkgPrefix = pkg.packagePath == '.' ? '' : '${pkg.packagePath}/';

      final pkgSources = projectFiles
          .where((f) =>
              f.category == ProjectFileCategory.source &&
              (pkgPrefix.isEmpty || f.relativePath.startsWith(pkgPrefix)))
          .map((f) => f.relativePath)
          .toList();
      final pkgTests = projectFiles
          .where((f) =>
              f.category == ProjectFileCategory.test &&
              (pkgPrefix.isEmpty || f.relativePath.startsWith(pkgPrefix)))
          .map((f) => f.relativePath)
          .toList();
      final pkgDocs = projectFiles
          .where((f) =>
              f.category == ProjectFileCategory.documentation &&
              (pkgPrefix.isEmpty || f.relativePath.startsWith(pkgPrefix)))
          .map((f) => f.relativePath)
          .toList();
      final pkgReports = projectFiles
          .where((f) =>
              f.category == ProjectFileCategory.report &&
              (pkgPrefix.isEmpty || f.relativePath.startsWith(pkgPrefix)))
          .map((f) => f.relativePath)
          .toList();

      finalizedPackages[entry.key] = DiscoveredPackage(
        name: pkg.name,
        version: pkg.version,
        isFlutter: pkg.isFlutter,
        packagePath: pkg.packagePath,
        absolutePath: pkg.absolutePath,
        dependencies: pkg.dependencies,
        devDependencies: pkg.devDependencies,
        sourceFiles: pkgSources,
        testFiles: pkgTests,
        docFiles: pkgDocs,
        reportFiles: pkgReports,
      );
    }

    final isMonorepo = finalizedPackages.length > 1;
    final dependencyGraph =
        PackageDependencyGraph.fromPackages(finalizedPackages.values.toList());

    return DiscoveredProjectSnapshot(
      rootPath: _projectRoot,
      isMonorepo: isMonorepo,
      packages: finalizedPackages,
      dependencyGraph: dependencyGraph,
      projectFiles: projectFiles,
      existingReports: existingReports,
      configurationFiles: configurationFiles,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Package Context Resolution & Relevance Scoping
  // ───────────────────────────────────────────────────────────────────────────

  /// Resolves the intended package from a user query or explicit package hint.
  ///
  /// If the query mentions a package name, or if only 1 package exists in the project,
  /// it resolves unambiguously. If multiple candidates match or none match in a monorepo,
  /// it marks [isAmbiguousPackage] as true and provides an explanatory ambiguity note.
  String? resolvePackageFromQuery({
    required String query,
    required Map<String, DiscoveredPackage> availablePackages,
  }) {
    if (availablePackages.isEmpty) return null;

    final lowerQuery = query.toLowerCase();

    // 1. Exact or word-boundary match in query
    for (final name in availablePackages.keys) {
      final pattern = RegExp(
          '(^|[^a-zA-Z0-9_])${RegExp.escape(name.toLowerCase())}([^a-zA-Z0-9_]|\$)',
          caseSensitive: false);
      if (pattern.hasMatch(lowerQuery)) {
        return name;
      }
    }

    // 2. If single package project, default to it
    if (availablePackages.length == 1) {
      return availablePackages.keys.first;
    }

    // 3. Ambiguous in monorepo
    return null;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. Relevant-File Identification & Deterministic Prioritization
  // ───────────────────────────────────────────────────────────────────────────

  /// Assembles a fail-closed, prioritized [AssembledProjectContext] from a query.
  ///
  /// Priority Ordering Rule (Deterministic and Inspectable):
  /// 1. Target Package Manifest (`pubspec.yaml`) & Root Configuration
  /// 2. Directly Implicated Source/Test Files (explicitly referenced in query or target package error reports)
  /// 3. Target Package Test Files (`test/**_test.dart`)
  /// 4. Target Package Public Library Files (`lib/**.dart`)
  /// 5. Existing Diagnostic / Failure Reports (`report/**`, `build/reports/**`)
  /// 6. Target Package Documentation (`README.md`, `doc/**`)
  /// 7. Within same tier: Sorted descending by `lastModified`, then ascending by `relativePath` (byte-identical tiebreaker).
  Future<AssembledProjectContext> assembleContext({
    required String query,
    String? targetPackageId,
    int tokenBudget = defaultTokenBudget,
  }) async {
    final snapshot = await discoverProject();
    final auditRecords = <FileContextAuditRecord>[];

    // Determine target package
    String? resolvedPkg = targetPackageId;
    var isAmbiguous = false;
    String? ambiguityNote;

    if (resolvedPkg == null) {
      resolvedPkg = resolvePackageFromQuery(
        query: query,
        availablePackages: snapshot.packages,
      );
      if (resolvedPkg == null && snapshot.isMonorepo) {
        isAmbiguous = true;
        ambiguityNote =
            'Query did not uniquely resolve to a single package in monorepo. Candidate packages: ${snapshot.packages.keys.join(", ")}';
      }
    }

    final targetPackage =
        resolvedPkg != null ? snapshot.packages[resolvedPkg] : null;

    // Filter and score candidate files from the entire project root
    final allEntities = _listAllFilesNonExecutively(Directory(_projectRoot));
    final scoredFiles = <_ScoredCandidateFile>[];

    for (final entity in allEntities) {
      final relPath =
          p.relative(entity.path, from: _projectRoot).replaceAll('\\', '/');
      final stat = entity.statSync();
      final category = _categorizeFile(relPath);
      final pkgId = _resolvePackageIdForPath(relPath);

      final file = DiscoveredProjectFile(
        relativePath: relPath,
        absolutePath: entity.path,
        category: category,
        sizeBytes: stat.size,
        lastModified: stat.modified,
        packageId: pkgId,
      );

      // Mandatory Non-Optional Sensitivity Check
      final filterDecision =
          _filter.evaluateFile(relativePath: file.relativePath);
      if (!filterDecision.isSafe) {
        auditRecords.add(FileContextAuditRecord(
          relativePath: file.relativePath,
          isIncluded: false,
          exclusionReason: filterDecision.reason,
          rationale: filterDecision.explanation,
        ));
        continue;
      }

      // Compute relevance score
      final score = _calculateRelevanceScore(
        file: file,
        query: query,
        targetPackage: targetPackage,
        isAmbiguous: isAmbiguous,
      );

      if (score <= 0.0) {
        auditRecords.add(FileContextAuditRecord(
          relativePath: file.relativePath,
          isIncluded: false,
          relevanceScore: score,
          exclusionReason: ContextFileExclusionReason.outOfScope,
          rationale:
              'File score ($score) is below threshold or out of package scope',
        ));
        continue;
      }

      scoredFiles.add(_ScoredCandidateFile(file: file, score: score));
    }

    // Deterministic Sort according to documented priority rule
    scoredFiles.sort((a, b) {
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) return scoreCmp;

      final timeCmp = b.file.lastModified.compareTo(a.file.lastModified);
      if (timeCmp != 0) return timeCmp;

      return a.file.relativePath.compareTo(b.file.relativePath);
    });

    // Budget Management: Read contents safely and pack into token budget
    final scopedContents = <ScopedFileContent>[];
    var currentTokens = 0;

    for (final candidate in scoredFiles) {
      final file = File(candidate.file.absolutePath);
      if (!file.existsSync()) continue;

      String content;
      try {
        content = file.readAsStringSync();
      } catch (e) {
        auditRecords.add(FileContextAuditRecord(
          relativePath: candidate.file.relativePath,
          isIncluded: false,
          exclusionReason: ContextFileExclusionReason.unclassifiableFormat,
          rationale: 'Failed to read file non-executively: $e',
        ));
        continue;
      }

      // Check content against in-flight regex heuristics
      final contentCheck = _filter.evaluateFile(
        relativePath: candidate.file.relativePath,
        fileContentSample:
            content.substring(0, content.length > 512 ? 512 : content.length),
      );
      if (!contentCheck.isSafe) {
        auditRecords.add(FileContextAuditRecord(
          relativePath: candidate.file.relativePath,
          isIncluded: false,
          exclusionReason: contentCheck.reason,
          rationale: contentCheck.explanation,
        ));
        continue;
      }

      if (content.length > maxFileCharBudget) {
        content =
            '${content.substring(0, maxFileCharBudget)}\n\n[... Truncated due to size limit ...]';
      }

      final fileTokens = (content.length / 4).ceil();
      if (currentTokens + fileTokens > tokenBudget) {
        auditRecords.add(FileContextAuditRecord(
          relativePath: candidate.file.relativePath,
          isIncluded: false,
          relevanceScore: candidate.score,
          exclusionReason: ContextFileExclusionReason.budgetTruncation,
          rationale:
              'Exceeded token budget limit ($tokenBudget tokens). File would add $fileTokens tokens.',
        ));
        continue;
      }

      currentTokens += fileTokens;
      scopedContents.add(ScopedFileContent(
        relativePath: candidate.file.relativePath,
        category: candidate.file.category,
        relevanceScore: candidate.score,
        content: content,
        tokenCount: fileTokens,
      ));

      auditRecords.add(FileContextAuditRecord(
        relativePath: candidate.file.relativePath,
        isIncluded: true,
        relevanceScore: candidate.score,
        rationale:
            'Included with priority score ${candidate.score.toStringAsFixed(2)}',
      ));
    }

    final projectSummary = <String, dynamic>{
      'rootPath': snapshot.rootPath,
      'isMonorepo': snapshot.isMonorepo,
      'packageCount': snapshot.packages.length,
      'packages': snapshot.packages.keys.toList()..sort(),
      if (resolvedPkg != null) 'targetPackage': resolvedPkg,
    };

    return AssembledProjectContext(
      resolvedPackageId: resolvedPkg,
      isAmbiguousPackage: isAmbiguous,
      ambiguityNote: ambiguityNote,
      projectSummary: projectSummary,
      scopedFiles: scopedContents,
      auditRecords: auditRecords,
      totalTokens: currentTokens,
      budgetLimitTokens: tokenBudget,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. PromptContext Conversion Bridge for Phase 8.1
  // ───────────────────────────────────────────────────────────────────────────

  /// Converts [AssembledProjectContext] into Phase 8.1's [PromptContext] domain model.
  PromptContext toPromptContext(
    AssembledProjectContext assembled, {
    String? templateId,
  }) {
    final targetId = templateId ??
        assembled.resolvedPackageId ??
        (assembled.projectSummary['targetPackage'] as String?) ??
        'workspace_root';

    final structuredFacts = <String, dynamic>{
      'isMonorepo': assembled.projectSummary['isMonorepo'],
      'isAmbiguousPackage': assembled.isAmbiguousPackage,
      if (assembled.ambiguityNote != null)
        'ambiguityNote': assembled.ambiguityNote,
      'includedFiles': assembled.scopedFiles.map((f) => f.relativePath).toList()
        ..sort(),
      'totalContextTokens': assembled.totalTokens,
    };

    return PromptContext(
      templateId: targetId,
      metadata: {
        'packageCount': assembled.projectSummary['packageCount'],
      },
      structuredFacts: structuredFacts,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Internal Helpers
  // ───────────────────────────────────────────────────────────────────────────

  double _calculateRelevanceScore({
    required DiscoveredProjectFile file,
    required String query,
    DiscoveredPackage? targetPackage,
    required bool isAmbiguous,
  }) {
    var score = 0.0;
    final lowerQuery = query.toLowerCase();
    final lowerRel = file.relativePath.toLowerCase();

    final isTargetPkgFile = targetPackage != null &&
        (file.packageId == targetPackage.name ||
            lowerRel.startsWith(targetPackage.packagePath.toLowerCase()));

    if (targetPackage != null && !isTargetPkgFile) {
      // In monorepo with specific target package, deprioritize or exclude files of other packages
      if (file.packageId != null && file.packageId != targetPackage.name) {
        return 0.0; // Exclude out-of-scope package files
      }
    }

    // 1. Category-based base score
    switch (file.category) {
      case ProjectFileCategory.configuration:
        score += isTargetPkgFile ? 100.0 : 40.0;
        break;
      case ProjectFileCategory.test:
        score += isTargetPkgFile ? 80.0 : 30.0;
        break;
      case ProjectFileCategory.source:
        score += isTargetPkgFile ? 70.0 : 20.0;
        break;
      case ProjectFileCategory.report:
        score += isTargetPkgFile ? 60.0 : 50.0;
        break;
      case ProjectFileCategory.documentation:
        score += isTargetPkgFile ? 40.0 : 10.0;
        break;
      case ProjectFileCategory.other:
        score += 5.0;
        break;
    }

    // 2. Query keywords matching filename or path
    final queryTokens =
        lowerQuery.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();

    for (final token in queryTokens) {
      if (lowerRel.contains(token)) {
        score += 25.0;
      }
    }

    // 3. Failing/error query context boost
    if (lowerQuery.contains('fail') ||
        lowerQuery.contains('error') ||
        lowerQuery.contains('broken')) {
      if (file.category == ProjectFileCategory.test ||
          file.category == ProjectFileCategory.report) {
        score += 30.0;
      }
    }

    return score;
  }

  List<File> _findPubspecFiles(Directory dir) {
    final pubspecs = <File>[];
    try {
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File && p.basename(entity.path) == 'pubspec.yaml') {
          pubspecs.add(entity);
        }
      }
    } catch (_) {}
    return pubspecs;
  }

  DiscoveredPackage? _parsePackageNonExecutively(File pubspecFile) {
    try {
      final content = pubspecFile.readAsStringSync();
      final pkgDir = pubspecFile.parent;
      final relPkgPath = p.relative(pkgDir.path, from: _projectRoot);

      // Lightweight non-evaluating regex extraction of YAML fields
      final nameMatch = RegExp(r'^name:\s*([a-zA-Z0-9_]+)', multiLine: true)
          .firstMatch(content);
      final versionMatch =
          RegExp(r'^version:\s*([^\s#]+)', multiLine: true).firstMatch(content);
      final isFlutter =
          content.contains('sdk: flutter') || content.contains('flutter:');

      if (nameMatch == null) return null;
      final name = nameMatch.group(1)!;
      final version = versionMatch?.group(1) ?? '0.0.0';

      final deps = _extractYamlSection(content, 'dependencies');
      final devDeps = _extractYamlSection(content, 'dev_dependencies');

      return DiscoveredPackage(
        name: name,
        version: version,
        isFlutter: isFlutter,
        packagePath:
            relPkgPath.isEmpty ? '.' : relPkgPath.replaceAll('\\', '/'),
        absolutePath: pkgDir.path,
        dependencies: deps,
        devDependencies: devDeps,
      );
    } catch (e) {
      _logger.warning('Failed to parse pubspec.yaml non-executively: $e');
      return null;
    }
  }

  Map<String, String> _extractYamlSection(
      String yamlContent, String sectionHeader) {
    final result = <String, String>{};
    final lines = yamlContent.split('\n');
    var inSection = false;

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.startsWith('$sectionHeader:')) {
        inSection = true;
        continue;
      }
      if (inSection) {
        if (line.isEmpty || line.trim().startsWith('#')) continue;
        if (!line.startsWith(' ') && !line.startsWith('\t')) {
          // Exited section
          break;
        }

        final trimmed = line.trim();
        final parts = trimmed.split(':');
        if (parts.isNotEmpty) {
          final depName = parts[0].trim();
          final depConstraint =
              parts.length > 1 ? parts.sublist(1).join(':').trim() : '*';
          if (depName.isNotEmpty && !depName.startsWith('sdk')) {
            result[depName] = depConstraint.isEmpty ? '*' : depConstraint;
          }
        }
      }
    }
    return result;
  }

  ProjectFileCategory _categorizeFile(String relativePath) {
    final lower = relativePath.toLowerCase();
    final filename = p.basename(lower);

    if (filename == 'pubspec.yaml' ||
        filename == 'analysis_options.yaml' ||
        filename == 'build.yaml' ||
        filename == 'changelog.md' ||
        filename == 'license') {
      return ProjectFileCategory.configuration;
    }

    if (lower.contains('report') ||
        lower.endsWith('.report.txt') ||
        lower.endsWith('.report.json')) {
      return ProjectFileCategory.report;
    }

    if (lower.startsWith('test/') ||
        lower.contains('/test/') ||
        lower.endsWith('_test.dart')) {
      return ProjectFileCategory.test;
    }

    if (lower.startsWith('lib/') ||
        lower.contains('/lib/') ||
        lower.endsWith('.dart')) {
      return ProjectFileCategory.source;
    }

    if (lower.startsWith('doc/') ||
        lower.contains('/doc/') ||
        lower.endsWith('.md')) {
      return ProjectFileCategory.documentation;
    }

    return ProjectFileCategory.other;
  }

  List<File> _listAllFilesNonExecutively(Directory dir) {
    final files = <File>[];
    try {
      if (!dir.existsSync()) return files;
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          files.add(entity);
        }
      }
    } catch (_) {}
    return files;
  }

  String? _resolvePackageIdForPath(String relativePath) {
    final lower = relativePath.toLowerCase();
    if (lower.startsWith('packages/')) {
      final parts = relativePath.split('/');
      if (parts.length > 1) {
        return parts[1];
      }
    }
    return null;
  }
}

class _ScoredCandidateFile {
  final DiscoveredProjectFile file;
  final double score;

  const _ScoredCandidateFile({
    required this.file,
    required this.score,
  });
}
