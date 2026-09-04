/// Domain models for AI-Assisted Controlled Code Modification (Phase 8.13).
library;

import 'package:flutter_package_studio_core/src/ai/security/secret_redactor.dart';

/// Modification type for a discrete file patch.
enum FilePatchType {
  /// Modify existing file.
  modify,

  /// Create new file.
  create,

  /// Delete existing file.
  delete;

  /// Parses a string into a [FilePatchType].
  static FilePatchType? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in FilePatchType.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    if (clean == 'add' || clean == 'new' || clean == 'created') return FilePatchType.create;
    if (clean == 'remove' || clean == 'deleted') return FilePatchType.delete;
    if (clean == 'update' || clean == 'modified' || clean == 'edit') return FilePatchType.modify;
    return null;
  }
}

/// A unified diff hunk representing a contiguous set of line additions/removals.
class DiffHunk {
  final int oldStart;
  final int oldLines;
  final int newStart;
  final int newLines;
  final List<String> lines;

  const DiffHunk({
    required this.oldStart,
    required this.oldLines,
    required this.newStart,
    required this.newLines,
    required this.lines,
  });

  factory DiffHunk.fromJson(Map<String, dynamic> json) => DiffHunk(
        oldStart: json['oldStart'] as int? ?? 1,
        oldLines: json['oldLines'] as int? ?? 0,
        newStart: json['newStart'] as int? ?? 1,
        newLines: json['newLines'] as int? ?? 0,
        lines: (json['lines'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      );

  Map<String, dynamic> toJson() => {
        'oldStart': oldStart,
        'oldLines': oldLines,
        'newStart': newStart,
        'newLines': newLines,
        'lines': lines,
      };

  /// Formats this hunk in unified diff format (e.g. `@@ -1,5 +1,6 @@`).
  String toUnifiedHeader() => '@@ -$oldStart,$oldLines +$newStart,$newLines @@';
}

/// A discrete proposed modification to a single target file.
class FilePatch {
  /// Target file path relative to workspace root (e.g. `lib/src/utils.dart`).
  final String relativePath;

  /// Action to perform on the file.
  final FilePatchType patchType;

  /// Brief explanation of this file's modifications.
  final String description;

  /// Full original content (for modify/delete operations, if known).
  final String? originalContent;

  /// Proposed new content (for modify/create operations).
  final String? proposedContent;

  /// Standard unified diff patch format text.
  final String diff;

  /// Structured diff hunks.
  final List<DiffHunk> hunks;

  /// Number of lines added.
  final int linesAdded;

  /// Number of lines removed.
  final int linesRemoved;

  FilePatch({
    required String relativePath,
    required this.patchType,
    required String description,
    this.originalContent,
    this.proposedContent,
    required String diff,
    this.hunks = const [],
    this.linesAdded = 0,
    this.linesRemoved = 0,
  })  : relativePath = SecretRedactor.redact(relativePath.replaceAll('\\', '/')),
        description = SecretRedactor.redact(description),
        diff = SecretRedactor.redact(diff);

  factory FilePatch.fromJson(Map<String, dynamic> json) {
    final typeStr = json['patchType'] as String?;
    final pType = FilePatchType.tryParse(typeStr) ?? FilePatchType.modify;

    final rawHunks = json['hunks'] as List<dynamic>? ?? const [];
    final hunks = rawHunks.whereType<Map<String, dynamic>>().map(DiffHunk.fromJson).toList();

    return FilePatch(
      relativePath: json['relativePath'] as String? ?? '',
      patchType: pType,
      description: json['description'] as String? ?? '',
      originalContent: json['originalContent'] as String?,
      proposedContent: json['proposedContent'] as String?,
      diff: json['diff'] as String? ?? '',
      hunks: hunks,
      linesAdded: json['linesAdded'] as int? ?? 0,
      linesRemoved: json['linesRemoved'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'relativePath': relativePath,
        'patchType': patchType.name,
        'description': description,
        if (originalContent != null) 'originalContent': originalContent,
        if (proposedContent != null) 'proposedContent': proposedContent,
        'diff': diff,
        'hunks': hunks.map((h) => h.toJson()).toList(),
        'linesAdded': linesAdded,
        'linesRemoved': linesRemoved,
      };
}

/// Safety policy defining strict boundaries on AI code modification proposals.
class CodeModificationSafetyPolicy {
  /// File path globs explicitly permitted for modification.
  final List<String> allowlist;

  /// File path globs strictly prohibited from AI modification (e.g. `.git/**`, `*.env`, `.fps/**`, `pubspec.lock`).
  final List<String> denylist;

  /// Maximum number of files permitted to be modified in a single patch plan.
  final int maxFilesLimit;

  /// Maximum total lines changed (additions + removals) permitted across the patch.
  final int maxTotalLinesChanged;

  /// Whether automated tests must pass before a patch is eligible for commit.
  final bool requireTestsPass;

  /// Whether analyzer check must pass with 0 errors before a patch is eligible for commit.
  final bool requireAnalyzerPass;

  /// Whether code formatter must be run and pass.
  final bool requireFormatterPass;

  /// Whether human execution approval is mandatory.
  final bool requireExplicitApproval;

  const CodeModificationSafetyPolicy({
    this.allowlist = const ['*'],
    this.denylist = const [
      '.git/**',
      '.github/**',
      '.fps/**',
      '**/*.env',
      '**/*.pem',
      '**/*.key',
      '**/*.lock',
      '**/pubspec.lock',
      'build/**',
      '.dart_tool/**',
    ],
    this.maxFilesLimit = 10,
    this.maxTotalLinesChanged = 500,
    this.requireTestsPass = true,
    this.requireAnalyzerPass = true,
    this.requireFormatterPass = true,
    this.requireExplicitApproval = true,
  });

  /// Evaluates whether a [filePath] violates this safety policy.
  ({bool allowed, String? reason}) evaluateFilePath(String filePath) {
    final clean = filePath.replaceAll('\\', '/').trim();

    // 1. Check denylist
    for (final pattern in denylist) {
      if (_matchesGlob(clean, pattern)) {
        return (
          allowed: false,
          reason: 'File path "$clean" matches prohibited security denylist pattern "$pattern".'
        );
      }
    }

    // 2. Check allowlist (if not default '*')
    if (allowlist.isNotEmpty && !allowlist.contains('*')) {
      final inAllowlist = allowlist.any((pattern) => _matchesGlob(clean, pattern));
      if (!inAllowlist) {
        return (
          allowed: false,
          reason: 'File path "$clean" is not present in the permitted allowlist: ${allowlist.join(", ")}.'
        );
      }
    }

    return (allowed: true, reason: null);
  }

  static bool _matchesGlob(String path, String pattern) {
    if (pattern == '*' || pattern == '**') return true;
    final normalizedPath = path.replaceAll('\\', '/');
    final normalizedPattern = pattern.replaceAll('\\', '/');

    if (normalizedPath == normalizedPattern) return true;

    // Fast exact or suffix match
    if (normalizedPattern.startsWith('**/')) {
      final suffix = normalizedPattern.substring(3);
      if (normalizedPath.endsWith(suffix) ||
          normalizedPath.contains('/$suffix') ||
          normalizedPath == suffix ||
          normalizedPath == suffix.replaceFirst('*.', '.') ||
          (suffix.startsWith('*.') && normalizedPath.endsWith(suffix.substring(1)))) {
        return true;
      }
    }
    if (normalizedPattern.endsWith('/**')) {
      final prefix = normalizedPattern.substring(0, normalizedPattern.length - 3);
      if (normalizedPath.startsWith('$prefix/') || normalizedPath == prefix) return true;
    }
    if (normalizedPattern.startsWith('*.')) {
      final ext = normalizedPattern.substring(1);
      if (normalizedPath.endsWith(ext) || normalizedPath == ext) return true;
    }

    return normalizedPath == normalizedPattern || normalizedPath.contains(normalizedPattern);
  }

  Map<String, dynamic> toJson() => {
        'allowlist': allowlist,
        'denylist': denylist,
        'maxFilesLimit': maxFilesLimit,
        'maxTotalLinesChanged': maxTotalLinesChanged,
        'requireTestsPass': requireTestsPass,
        'requireAnalyzerPass': requireAnalyzerPass,
        'requireFormatterPass': requireFormatterPass,
        'requireExplicitApproval': requireExplicitApproval,
      };
}

/// Result of patch verification pipeline (tests, analyzer, formatter).
class PatchValidationPipelineResult {
  /// Whether patch syntax itself is structurally valid and applicable cleanly.
  final bool patchValid;

  /// Whether automated test suite executed and passed.
  final bool testsPassed;

  /// Test run output or summary.
  final String? testOutput;

  /// Whether Dart analyzer check passed with 0 errors.
  final bool analyzerPassed;

  /// Analyzer diagnostics or report.
  final String? analyzerOutput;

  /// Whether code formatter executed cleanly.
  final bool formatterPassed;

  /// Formatting status message.
  final String? formatterOutput;

  /// Detailed validation error message if any stage failed.
  final String? failureReason;

  const PatchValidationPipelineResult({
    required this.patchValid,
    required this.testsPassed,
    this.testOutput,
    required this.analyzerPassed,
    this.analyzerOutput,
    required this.formatterPassed,
    this.formatterOutput,
    this.failureReason,
  });

  /// All verification gates passed.
  bool get isAllPassed => patchValid && testsPassed && analyzerPassed && formatterPassed;

  Map<String, dynamic> toJson() => {
        'patchValid': patchValid,
        'testsPassed': testsPassed,
        if (testOutput != null) 'testOutput': testOutput,
        'analyzerPassed': analyzerPassed,
        if (analyzerOutput != null) 'analyzerOutput': analyzerOutput,
        'formatterPassed': formatterPassed,
        if (formatterOutput != null) 'formatterOutput': formatterOutput,
        'isAllPassed': isAllPassed,
        if (failureReason != null) 'failureReason': failureReason,
      };
}

/// Request to generate a controlled code modification proposal.
class CodeModificationPlanRequest {
  /// Natural language description of the code change requirement.
  final String requirement;

  /// Specific target file or component scope (optional).
  final String? targetScope;

  /// Safety policy constraints (defaults to standard strict safety policy).
  final CodeModificationSafetyPolicy safetyPolicy;

  /// Specific file paths to restrict modification to (optional override).
  final List<String> restrictedFileAllowlist;

  const CodeModificationPlanRequest({
    required this.requirement,
    this.targetScope,
    this.safetyPolicy = const CodeModificationSafetyPolicy(),
    this.restrictedFileAllowlist = const [],
  });

  Map<String, dynamic> toJson() => {
        'requirement': SecretRedactor.redact(requirement),
        if (targetScope != null) 'targetScope': targetScope,
        'safetyPolicy': safetyPolicy.toJson(),
        if (restrictedFileAllowlist.isNotEmpty) 'restrictedFileAllowlist': restrictedFileAllowlist,
      };
}

/// Complete proposal and verification report for an AI-Assisted Controlled Code Modification.
class CodeModificationProposal {
  /// Unique modification proposal ID (e.g. `mod_1719200000_abc`).
  final String proposalId;

  /// Original user/engineering requirement.
  final String requirement;

  /// Executive summary of the modification plan.
  final String summary;

  /// Affected files list.
  final List<String> affectedFiles;

  /// Ordered discrete file patches with unified diffs.
  final List<FilePatch> patches;

  /// Safety policy applied during analysis.
  final CodeModificationSafetyPolicy safetyPolicy;

  /// Validation pipeline outcome (patch valid, tests, analyzer, formatter).
  final PatchValidationPipelineResult validation;

  /// Total lines added across all patches.
  final int totalLinesAdded;

  /// Total lines removed across all patches.
  final int totalLinesRemoved;

  /// Whether this proposal satisfies all safety boundaries and validation gates.
  final bool isEligibleForApplication;

  /// Generation and validation duration in milliseconds.
  final int durationMs;

  /// Timestamp of proposal creation.
  final DateTime timestamp;

  /// Error message if proposal creation or validation failed.
  final String? errorMessage;

  /// Whether proposal generation was successful.
  final bool isSuccess;

  CodeModificationProposal({
    required this.proposalId,
    required String requirement,
    required String summary,
    required this.affectedFiles,
    required this.patches,
    required this.safetyPolicy,
    required this.validation,
    required this.totalLinesAdded,
    required this.totalLinesRemoved,
    required this.isEligibleForApplication,
    required this.durationMs,
    required this.timestamp,
    this.errorMessage,
    this.isSuccess = true,
  })  : requirement = SecretRedactor.redact(requirement),
        summary = SecretRedactor.redact(summary);

  factory CodeModificationProposal.failure({
    required String proposalId,
    required String requirement,
    required String errorMessage,
    int durationMs = 0,
    DateTime? timestamp,
  }) =>
      CodeModificationProposal(
        proposalId: proposalId,
        requirement: requirement,
        summary: 'Modification proposal generation failed.',
        affectedFiles: const [],
        patches: const [],
        safetyPolicy: const CodeModificationSafetyPolicy(),
        validation: const PatchValidationPipelineResult(
          patchValid: false,
          testsPassed: false,
          analyzerPassed: false,
          formatterPassed: false,
          failureReason: 'Generation failed before pipeline execution.',
        ),
        totalLinesAdded: 0,
        totalLinesRemoved: 0,
        isEligibleForApplication: false,
        durationMs: durationMs,
        timestamp: timestamp ?? DateTime.now(),
        errorMessage: SecretRedactor.redact(errorMessage),
        isSuccess: false,
      );

  factory CodeModificationProposal.fromJson(Map<String, dynamic> json) {
    final rawPatches = json['patches'] as List<dynamic>? ?? const [];
    final patches = rawPatches.whereType<Map<String, dynamic>>().map(FilePatch.fromJson).toList();

    final rawFiles = json['affectedFiles'] as List<dynamic>? ?? const [];
    final affectedFiles = rawFiles.map((e) => e.toString()).toList();

    final valJson = json['validation'] as Map<String, dynamic>? ?? const {};
    final validation = PatchValidationPipelineResult(
      patchValid: valJson['patchValid'] as bool? ?? false,
      testsPassed: valJson['testsPassed'] as bool? ?? false,
      testOutput: valJson['testOutput'] as String?,
      analyzerPassed: valJson['analyzerPassed'] as bool? ?? false,
      analyzerOutput: valJson['analyzerOutput'] as String?,
      formatterPassed: valJson['formatterPassed'] as bool? ?? false,
      formatterOutput: valJson['formatterOutput'] as String?,
      failureReason: valJson['failureReason'] as String?,
    );

    final policyJson = json['safetyPolicy'] as Map<String, dynamic>? ?? const {};
    final safetyPolicy = CodeModificationSafetyPolicy(
      allowlist: (policyJson['allowlist'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ['*'],
      denylist: (policyJson['denylist'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          const ['.git/**', '**/*.env', 'build/**'],
      maxFilesLimit: policyJson['maxFilesLimit'] as int? ?? 10,
      maxTotalLinesChanged: policyJson['maxTotalLinesChanged'] as int? ?? 500,
      requireTestsPass: policyJson['requireTestsPass'] as bool? ?? true,
      requireAnalyzerPass: policyJson['requireAnalyzerPass'] as bool? ?? true,
      requireFormatterPass: policyJson['requireFormatterPass'] as bool? ?? true,
      requireExplicitApproval: policyJson['requireExplicitApproval'] as bool? ?? true,
    );

    return CodeModificationProposal(
      proposalId: json['proposalId'] as String? ?? 'mod_unknown',
      requirement: json['requirement'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      affectedFiles: affectedFiles,
      patches: patches,
      safetyPolicy: safetyPolicy,
      validation: validation,
      totalLinesAdded: json['totalLinesAdded'] as int? ?? 0,
      totalLinesRemoved: json['totalLinesRemoved'] as int? ?? 0,
      isEligibleForApplication: json['isEligibleForApplication'] as bool? ?? false,
      durationMs: json['durationMs'] as int? ?? 0,
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : DateTime.now(),
      errorMessage: json['errorMessage'] as String?,
      isSuccess: json['isSuccess'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'proposalId': proposalId,
        'requirement': SecretRedactor.redact(requirement),
        'summary': SecretRedactor.redact(summary),
        'affectedFiles': affectedFiles,
        'patches': patches.map((p) => p.toJson()).toList(),
        'safetyPolicy': safetyPolicy.toJson(),
        'validation': validation.toJson(),
        'totalLinesAdded': totalLinesAdded,
        'totalLinesRemoved': totalLinesRemoved,
        'isEligibleForApplication': isEligibleForApplication,
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
        'isSuccess': isSuccess,
        if (errorMessage != null) 'errorMessage': SecretRedactor.redact(errorMessage!),
      };
}

/// Result of applying a patch proposal (or rolling back a patch proposal).
class CodeModificationApplyResult {
  /// Whether all file changes were successfully written to disk.
  final bool success;

  /// Proposal identifier that was applied/rolled back.
  final String proposalId;

  /// Files written or updated.
  final List<String> modifiedFiles;

  /// Backup paths created for rollback (if applicable).
  final Map<String, String> backupPaths;

  /// Whether this operation was a rollback.
  final bool isRollback;

  /// Detailed human-readable status message or error.
  final String message;

  const CodeModificationApplyResult({
    required this.success,
    required this.proposalId,
    this.modifiedFiles = const [],
    this.backupPaths = const {},
    this.isRollback = false,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'success': success,
        'proposalId': proposalId,
        'modifiedFiles': modifiedFiles,
        'backupPaths': backupPaths,
        'isRollback': isRollback,
        'message': SecretRedactor.redact(message),
      };
}
