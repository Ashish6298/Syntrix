/// Severity level of a migration finding.
enum TemplateMigrationSeverity {
  info,
  warning,
  error,
}

/// Conflict resolution policy for template migration actions.
enum TemplateMigrationConflictPolicy {
  /// Fail migration immediately if a user-modified file is affected.
  fail,

  /// Preserve existing user-modified file and skip incoming migration changes.
  preserve,

  /// Overwrite file with new template asset content.
  overwrite,

  /// Skip the migration step/action.
  skip,
}

/// Profile controlling strictness of migration rules and checks.
enum TemplateMigrationProfile {
  /// Basic structural migration checks.
  basic,

  /// Standard migration checks (preserves user changes, requires valid paths).
  standard,

  /// Strict migration checks (validates quality & testing eligibility).
  strict,

  /// Release gate migration checks (promotes warnings to errors, requires clean certification).
  release,
}

extension TemplateMigrationProfileX on TemplateMigrationProfile {
  bool get warningsAreErrors => this == TemplateMigrationProfile.release;

  static TemplateMigrationProfile fromString(String name) {
    switch (name.toLowerCase().trim()) {
      case 'basic':
        return TemplateMigrationProfile.basic;
      case 'standard':
        return TemplateMigrationProfile.standard;
      case 'strict':
        return TemplateMigrationProfile.strict;
      case 'release':
        return TemplateMigrationProfile.release;
      default:
        return TemplateMigrationProfile.standard;
    }
  }
}

/// Action type performed during a migration step.
enum TemplateMigrationActionType {
  createFile,
  updateFile,
  renameFile,
  deleteFile,
  updateMetadata,
  updateDependency,
}

/// Represents a single discrete action within a migration step.
class TemplateMigrationAction {
  final TemplateMigrationActionType type;
  final String path;
  final String? targetPath;
  final String? content;
  final String reason;

  const TemplateMigrationAction({
    required this.type,
    required this.path,
    this.targetPath,
    this.content,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'path': path,
        if (targetPath != null) 'targetPath': targetPath,
        'reason': reason,
      };
}

/// Discrete finding/diagnostic issue emitted during migration planning or execution.
class TemplateMigrationFinding implements Comparable<TemplateMigrationFinding> {
  final String code;
  final TemplateMigrationSeverity severity;
  final String message;
  final String? filePath;

  const TemplateMigrationFinding({
    required this.code,
    required this.severity,
    required this.message,
    this.filePath,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'severity': severity.name,
        'message': message,
        if (filePath != null) 'filePath': filePath,
      };

  @override
  int compareTo(TemplateMigrationFinding other) {
    final s = severity.index.compareTo(other.severity.index);
    if (s != 0) return s;
    final c = code.compareTo(other.code);
    if (c != 0) return c;
    return message.compareTo(other.message);
  }
}

/// Request to perform a migration planning or execution.
class TemplateMigrationRequest {
  final String projectPath;
  final String? sourceTemplateId;
  final String? sourceVersion;
  final String targetTemplateId;
  final String targetVersion;
  final TemplateMigrationProfile profile;
  final TemplateMigrationConflictPolicy conflictPolicy;

  const TemplateMigrationRequest({
    required this.projectPath,
    this.sourceTemplateId,
    this.sourceVersion,
    required this.targetTemplateId,
    required this.targetVersion,
    this.profile = TemplateMigrationProfile.standard,
    this.conflictPolicy = TemplateMigrationConflictPolicy.preserve,
  });

  Map<String, dynamic> toJson() => {
        'projectPath': projectPath,
        if (sourceTemplateId != null) 'sourceTemplateId': sourceTemplateId,
        if (sourceVersion != null) 'sourceVersion': sourceVersion,
        'targetTemplateId': targetTemplateId,
        'targetVersion': targetVersion,
        'profile': profile.name,
        'conflictPolicy': conflictPolicy.name,
      };
}

/// Single step in a migration chain (e.g. 1.0.0 -> 1.1.0).
class TemplateMigrationStep {
  final String migrationId;
  final String sourceVersion;
  final String targetVersion;
  final String description;
  final List<TemplateMigrationAction> actions;

  const TemplateMigrationStep({
    required this.migrationId,
    required this.sourceVersion,
    required this.targetVersion,
    required this.description,
    required this.actions,
  });

  Map<String, dynamic> toJson() => {
        'migrationId': migrationId,
        'sourceVersion': sourceVersion,
        'targetVersion': targetVersion,
        'description': description,
        'actions': actions.map((a) => a.toJson()).toList(),
      };
}

/// Preview plan of all migration steps, actions, and findings before execution.
class TemplateMigrationPlan {
  final String sourceTemplateId;
  final String sourceVersion;
  final String targetTemplateId;
  final String targetVersion;
  final TemplateMigrationProfile profile;
  final TemplateMigrationConflictPolicy conflictPolicy;
  final List<TemplateMigrationStep> steps;
  final List<TemplateMigrationFinding> findings;

  const TemplateMigrationPlan({
    required this.sourceTemplateId,
    required this.sourceVersion,
    required this.targetTemplateId,
    required this.targetVersion,
    required this.profile,
    required this.conflictPolicy,
    required this.steps,
    required this.findings,
  });

  bool get hasErrors =>
      findings.any((f) => f.severity == TemplateMigrationSeverity.error);

  int get totalActions =>
      steps.fold(0, (sum, step) => sum + step.actions.length);

  Map<String, dynamic> toJson() => {
        'sourceTemplateId': sourceTemplateId,
        'sourceVersion': sourceVersion,
        'targetTemplateId': targetTemplateId,
        'targetVersion': targetVersion,
        'profile': profile.name,
        'conflictPolicy': conflictPolicy.name,
        'totalActions': totalActions,
        'steps': steps.map((s) => s.toJson()).toList(),
        'findings': findings.map((f) => f.toJson()).toList(),
      };
}

/// Result of applying a migration plan.
class TemplateMigrationResult {
  final bool isSuccess;
  final String sourceVersion;
  final String targetVersion;
  final int actionsExecuted;
  final List<TemplateMigrationFinding> findings;
  final bool rollbackPerformed;

  const TemplateMigrationResult({
    required this.isSuccess,
    required this.sourceVersion,
    required this.targetVersion,
    required this.actionsExecuted,
    required this.findings,
    this.rollbackPerformed = false,
  });

  Map<String, dynamic> toJson() => {
        'isSuccess': isSuccess,
        'sourceVersion': sourceVersion,
        'targetVersion': targetVersion,
        'actionsExecuted': actionsExecuted,
        'rollbackPerformed': rollbackPerformed,
        'findings': findings.map((f) => f.toJson()).toList(),
      };
}
