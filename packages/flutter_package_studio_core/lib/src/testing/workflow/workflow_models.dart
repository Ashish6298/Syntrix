/// Status of an individual workflow stage.
enum WorkflowStageStatus {
  planned,
  running,
  passed,
  failed,
  skipped,
  blocked,
  unavailable,
  notRun,
  insufficientEvidence,
  completed,
}

/// Execution profiles for unified testing workflow.
enum WorkflowProfile {
  plan,
  test,
  full,
  regression,
  certify,
  all,
}

/// A single stage in the testing workflow orchestration graph.
class WorkflowStage {
  final String id;
  final String name;
  final WorkflowStageStatus status;
  final String description;

  const WorkflowStage({
    required this.id,
    required this.name,
    required this.status,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status.name,
        'description': description,
      };
}

/// Options configuring the unified testing workflow execution.
class WorkflowOptions {
  final String packageName;
  final WorkflowProfile profile;
  final bool execute;
  final String outputDir;

  const WorkflowOptions({
    required this.packageName,
    this.profile = WorkflowProfile.all,
    this.execute = false,
    this.outputDir = 'doc/testing_workflow',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile.name,
        'execute': execute,
        'outputDir': outputDir,
      };
}

/// Plan for the unified testing workflow.
class WorkflowPlan {
  final String packageName;
  final WorkflowProfile profile;
  final List<WorkflowStage> stages;
  final String outputDir;

  const WorkflowPlan({
    required this.packageName,
    required this.profile,
    required this.stages,
    required this.outputDir,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile.name,
        'stageCount': stages.length,
        'stages': stages.map((s) => s.toJson()).toList(),
        'outputDir': outputDir,
      };
}

/// Result of executing the unified testing workflow.
class WorkflowResult {
  final String packageName;
  final WorkflowProfile profile;
  final List<WorkflowStage> stages;
  final bool isSuccess;

  const WorkflowResult({
    required this.packageName,
    required this.profile,
    required this.stages,
    required this.isSuccess,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Unified Testing Workflow Report: $packageName');
    buf.writeln();
    buf.writeln('**Workflow Profile**: ${profile.name.toUpperCase()}');
    buf.writeln(
        '**Workflow Status**: ${isSuccess ? "PASSED ✓" : "FAILED / BLOCKED ✗"}');
    buf.writeln();
    buf.writeln('| Stage ID | Name | Status | Description |');
    buf.writeln('|---|---|---|---|');
    for (final s in stages) {
      buf.writeln(
          '| ${s.id} | ${s.name} | ${s.status.name.toUpperCase()} | ${s.description} |');
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'profile': profile.name,
        'isSuccess': isSuccess,
        'stageCount': stages.length,
        'stages': stages.map((s) => s.toJson()).toList(),
      };
}
