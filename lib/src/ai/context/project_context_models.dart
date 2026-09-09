/// Models for Phase 8.2 — Project Context & Codebase Intelligence.
library;

/// Category classification for discovered project files.
enum ProjectFileCategory {
  /// Root package configuration / manifest (e.g. pubspec.yaml, analysis_options.yaml).
  configuration,

  /// Core application or package source code (e.g. lib/**.dart).
  source,

  /// Unit, widget, or integration test code (e.g. test/**_test.dart).
  test,

  /// Documentation and markdown assets (e.g. README.md, doc/**).
  documentation,

  /// Static analysis, test coverage, or security diagnostic reports (e.g. report/**, build/reports/**).
  report,

  /// Other known project files.
  other,
}

/// A discovered file entry within a project or package.
class DiscoveredProjectFile {
  /// Normalized relative path from the project root.
  final String relativePath;

  /// Absolute filesystem path.
  final String absolutePath;

  /// Classified category of the file.
  final ProjectFileCategory category;

  /// File size in bytes.
  final int sizeBytes;

  /// Last modified timestamp for deterministic prioritization.
  final DateTime lastModified;

  /// Associated package ID/name, if scoped inside a package directory.
  final String? packageId;

  const DiscoveredProjectFile({
    required this.relativePath,
    required this.absolutePath,
    required this.category,
    required this.sizeBytes,
    required this.lastModified,
    this.packageId,
  });

  Map<String, dynamic> toJson() => {
        'relativePath': relativePath,
        'category': category.name,
        'sizeBytes': sizeBytes,
        'lastModified': lastModified.toIso8601String(),
        if (packageId != null) 'packageId': packageId,
      };
}

/// Metadata and structure for a discovered Dart/Flutter package within the project.
class DiscoveredPackage {
  /// Package name (from pubspec.yaml `name`).
  final String name;

  /// Package version string (from pubspec.yaml `version`).
  final String version;

  /// Whether this package is a Flutter package/plugin vs pure Dart.
  final bool isFlutter;

  /// Relative directory path from project root (e.g. "packages/my_pkg" or ".").
  final String packagePath;

  /// Absolute directory path.
  final String absolutePath;

  /// Declared regular dependencies mapped to version constraints.
  final Map<String, String> dependencies;

  /// Declared dev dependencies mapped to version constraints.
  final Map<String, String> devDependencies;

  /// Relative source file paths under lib/.
  final List<String> sourceFiles;

  /// Relative test file paths under test/.
  final List<String> testFiles;

  /// Relative documentation file paths.
  final List<String> docFiles;

  /// Relative report file paths.
  final List<String> reportFiles;

  const DiscoveredPackage({
    required this.name,
    required this.version,
    required this.isFlutter,
    required this.packagePath,
    required this.absolutePath,
    this.dependencies = const {},
    this.devDependencies = const {},
    this.sourceFiles = const [],
    this.testFiles = const [],
    this.docFiles = const [],
    this.reportFiles = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'isFlutter': isFlutter,
        'packagePath': packagePath,
        'dependencies': Map<String, String>.fromEntries(
            dependencies.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key))),
        'devDependencies': Map<String, String>.fromEntries(
            devDependencies.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key))),
        'sourceFiles': List<String>.from(sourceFiles)..sort(),
        'testFiles': List<String>.from(testFiles)..sort(),
        'docFiles': List<String>.from(docFiles)..sort(),
        'reportFiles': List<String>.from(reportFiles)..sort(),
      };
}

/// Represents an edge in the package dependency graph.
class PackageDependencyEdge {
  final String sourcePackage;
  final String targetPackage;
  final String constraint;
  final bool isDevDependency;

  const PackageDependencyEdge({
    required this.sourcePackage,
    required this.targetPackage,
    required this.constraint,
    this.isDevDependency = false,
  });

  Map<String, dynamic> toJson() => {
        'sourcePackage': sourcePackage,
        'targetPackage': targetPackage,
        'constraint': constraint,
        'isDevDependency': isDevDependency,
      };
}

/// Dependency graph modeling inter-package relationships across a workspace.
class PackageDependencyGraph {
  final Map<String, List<PackageDependencyEdge>> outgoingEdges;
  final Map<String, List<PackageDependencyEdge>> incomingEdges;

  const PackageDependencyGraph({
    required this.outgoingEdges,
    required this.incomingEdges,
  });

  /// Computes graph from a list of discovered packages.
  factory PackageDependencyGraph.fromPackages(
      List<DiscoveredPackage> packages) {
    final outgoing = <String, List<PackageDependencyEdge>>{};
    final incoming = <String, List<PackageDependencyEdge>>{};
    final packageNames = packages.map((p) => p.name).toSet();

    for (final pkg in packages) {
      outgoing[pkg.name] = [];
      incoming.putIfAbsent(pkg.name, () => []);

      for (final entry in pkg.dependencies.entries) {
        final edge = PackageDependencyEdge(
          sourcePackage: pkg.name,
          targetPackage: entry.key,
          constraint: entry.value,
          isDevDependency: false,
        );
        outgoing[pkg.name]!.add(edge);
        if (packageNames.contains(entry.key)) {
          incoming.putIfAbsent(entry.key, () => []).add(edge);
        }
      }

      for (final entry in pkg.devDependencies.entries) {
        final edge = PackageDependencyEdge(
          sourcePackage: pkg.name,
          targetPackage: entry.key,
          constraint: entry.value,
          isDevDependency: true,
        );
        outgoing[pkg.name]!.add(edge);
        if (packageNames.contains(entry.key)) {
          incoming.putIfAbsent(entry.key, () => []).add(edge);
        }
      }
    }

    return PackageDependencyGraph(
      outgoingEdges: outgoing,
      incomingEdges: incoming,
    );
  }

  /// Returns internal workspace packages that depend on [packageName].
  List<String> getDependents(String packageName) {
    final edges = incomingEdges[packageName] ?? [];
    return edges.map((e) => e.sourcePackage).toSet().toList()..sort();
  }

  /// Returns internal workspace packages that [packageName] depends on.
  List<String> getInternalDependencies(String packageName) {
    final edges = outgoingEdges[packageName] ?? [];
    return edges
        .where((e) => incomingEdges.containsKey(e.targetPackage))
        .map((e) => e.targetPackage)
        .toSet()
        .toList()
      ..sort();
  }

  Map<String, dynamic> toJson() {
    final sortedOut = <String, dynamic>{};
    for (final k in outgoingEdges.keys.toList()..sort()) {
      sortedOut[k] = outgoingEdges[k]!.map((e) => e.toJson()).toList();
    }
    return {'outgoingEdges': sortedOut};
  }
}

/// Complete structural snapshot of a project repository discovered non-executively.
class DiscoveredProjectSnapshot {
  /// Root directory path of the project.
  final String rootPath;

  /// Whether this project is a monorepo containing multiple packages.
  final bool isMonorepo;

  /// Discovered packages indexed by package name.
  final Map<String, DiscoveredPackage> packages;

  /// Workspace dependency graph.
  final PackageDependencyGraph dependencyGraph;

  /// All non-sensitive, categorized project files.
  final List<DiscoveredProjectFile> projectFiles;

  /// Existing report files across the project.
  final List<String> existingReports;

  /// Root and package configuration files.
  final List<String> configurationFiles;

  const DiscoveredProjectSnapshot({
    required this.rootPath,
    required this.isMonorepo,
    required this.packages,
    required this.dependencyGraph,
    required this.projectFiles,
    required this.existingReports,
    required this.configurationFiles,
  });

  Map<String, dynamic> toJson() {
    final sortedPkgs = <String, dynamic>{};
    for (final k in packages.keys.toList()..sort()) {
      sortedPkgs[k] = packages[k]!.toJson();
    }

    return {
      'rootPath': rootPath,
      'isMonorepo': isMonorepo,
      'packages': sortedPkgs,
      'dependencyGraph': dependencyGraph.toJson(),
      'projectFiles': projectFiles.map((f) => f.toJson()).toList(),
      'existingReports': List<String>.from(existingReports)..sort(),
      'configurationFiles': List<String>.from(configurationFiles)..sort(),
    };
  }
}

/// Reason code for excluding or filtering a file during context extraction.
enum ContextFileExclusionReason {
  /// Matched sensitive environment pattern (.env, .env.*).
  sensitiveEnv,

  /// Matched private key or certificate pattern (.pem, .key, id_rsa).
  sensitiveKeyOrCert,

  /// Matched credential store pattern (credentials.json, .netrc, etc.).
  sensitiveCredential,

  /// Classified as secret by pattern matching / entropy heuristics.
  sensitiveSecret,

  /// Excluded by project .gitignore rule.
  gitIgnored,

  /// Unclassifiable or unsupported binary file format (fail-closed).
  unclassifiableFormat,

  /// Truncated due to context budget constraint.
  budgetTruncation,

  /// Deemed irrelevant to target query/package.
  outOfScope,
}

/// Audit record explaining inclusion or exclusion of a file in assembled context.
class FileContextAuditRecord {
  final String relativePath;
  final bool isIncluded;
  final double relevanceScore;
  final ContextFileExclusionReason? exclusionReason;
  final String rationale;

  const FileContextAuditRecord({
    required this.relativePath,
    required this.isIncluded,
    this.relevanceScore = 0.0,
    this.exclusionReason,
    required this.rationale,
  });

  Map<String, dynamic> toJson() => {
        'relativePath': relativePath,
        'isIncluded': isIncluded,
        'relevanceScore': relevanceScore,
        if (exclusionReason != null) 'exclusionReason': exclusionReason!.name,
        'rationale': rationale,
      };
}

/// A relevant file selected for inclusion in the AI context payload.
class ScopedFileContent {
  final String relativePath;
  final ProjectFileCategory category;
  final double relevanceScore;
  final String content;
  final int tokenCount;

  const ScopedFileContent({
    required this.relativePath,
    required this.category,
    required this.relevanceScore,
    required this.content,
    required this.tokenCount,
  });

  Map<String, dynamic> toJson() => {
        'relativePath': relativePath,
        'category': category.name,
        'relevanceScore': relevanceScore,
        'tokenCount': tokenCount,
        'content': content,
      };
}

/// Output payload from the Project Context Engine ready for prompt assembly.
class AssembledProjectContext {
  /// Target package ID resolved from the query (or null if general workspace query).
  final String? resolvedPackageId;

  /// Whether the query was ambiguous with respect to target package.
  final bool isAmbiguousPackage;

  /// Explanatory message when package resolution is ambiguous or general.
  final String? ambiguityNote;

  /// High-level project metadata facts.
  final Map<String, dynamic> projectSummary;

  /// Verified safe, prioritized file contents within the token budget.
  final List<ScopedFileContent> scopedFiles;

  /// Full audit trail detailing why every candidate file was included or excluded.
  final List<FileContextAuditRecord> auditRecords;

  /// Total tokens used by scoped file contents.
  final int totalTokens;

  /// Token budget limit configured for this context assembly.
  final int budgetLimitTokens;

  const AssembledProjectContext({
    this.resolvedPackageId,
    this.isAmbiguousPackage = false,
    this.ambiguityNote,
    required this.projectSummary,
    required this.scopedFiles,
    required this.auditRecords,
    required this.totalTokens,
    required this.budgetLimitTokens,
  });

  Map<String, dynamic> toJson() {
    final sortedSummary = Map<String, dynamic>.fromEntries(
        projectSummary.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)));

    return {
      if (resolvedPackageId != null) 'resolvedPackageId': resolvedPackageId,
      'isAmbiguousPackage': isAmbiguousPackage,
      if (ambiguityNote != null) 'ambiguityNote': ambiguityNote,
      'projectSummary': sortedSummary,
      'scopedFiles': scopedFiles.map((f) => f.toJson()).toList(),
      'auditRecords': auditRecords.map((a) => a.toJson()).toList(),
      'totalTokens': totalTokens,
      'budgetLimitTokens': budgetLimitTokens,
    };
  }
}
