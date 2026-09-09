/// Pure dual-format (JSON and Markdown) renderers for Engineering Workflow Planner results (Phase 8.11).
library;

import 'dart:convert';
import 'package:syntrix/src/ai/security/secret_redactor.dart';
import 'package:syntrix/src/ai/planner/workflow_planner_models.dart';

/// Single authority for pure, deterministic dual-rendering of Workflow Planner results with mandatory secret redaction.
class WorkflowPlannerRenderer {
  const WorkflowPlannerRenderer();

  /// Escapes HTML special characters in [text] to prevent injection in Markdown/HTML output.
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Renders [plan] to formatted, indented JSON with an absolute final redaction pass.
  String renderJson(WorkflowPlanResult plan) {
    const encoder = JsonEncoder.withIndent('  ');
    final rawJson = encoder.convert(plan.toJson());
    // Mandatory final redaction pass
    return SecretRedactor.redact(rawJson);
  }

  /// Renders [plan] to structured Markdown with all 9 workflow pipeline stages.
  String renderMarkdown(WorkflowPlanResult plan) {
    final buf = StringBuffer();

    buf.writeln(
        '# Flutter Package Studio — AI Engineering Implementation Plan');
    buf.writeln();
    buf.writeln('**Objective**: ${_escapeHtml(plan.objective)}  ');
    buf.writeln('**Scope**: `${_escapeHtml(plan.scope)}`  ');
    buf.writeln('**Confidence**: `${plan.confidence.name.toUpperCase()}`  ');
    buf.writeln('**Duration**: `${plan.durationMs}ms`  ');
    buf.writeln('**Timestamp**: `${plan.timestamp.toIso8601String()}`');
    buf.writeln();

    if (!plan.isSuccess) {
      buf.writeln('## ❌ Planning Failure');
      buf.writeln(plan.errorMessage ??
          'An unknown error occurred during workflow plan generation.');
      return SecretRedactor.redact(buf.toString());
    }

    // 1. Requirement Analysis (Facts vs. Assumptions)
    buf.writeln('## 1. Requirement Analysis (Facts vs. Assumptions)');
    buf.writeln();
    final facts = plan.requirementAnalysis.where((r) => r.isFact).toList();
    final assumptions =
        plan.requirementAnalysis.where((r) => !r.isFact).toList();

    buf.writeln('### Verified Facts (Grounded in Workspace)');
    if (facts.isEmpty) {
      buf.writeln('*No explicit workspace facts recorded.*');
    } else {
      for (final f in facts) {
        buf.writeln(
            '- **[FACT]** ${_escapeHtml(f.text)} *(Evidence: `${_escapeHtml(f.evidence)}`)*');
      }
    }
    buf.writeln();

    buf.writeln('### Inferred Assumptions (Requires Verification)');
    if (assumptions.isEmpty) {
      buf.writeln('*No assumptions recorded.*');
    } else {
      for (final a in assumptions) {
        buf.writeln(
            '- **[ASSUMPTION]** ${_escapeHtml(a.text)} *(Note: ${_escapeHtml(a.evidence)})*');
      }
    }
    buf.writeln();

    // 2. Affected Components & Files
    buf.writeln('## 2. Affected Components & Files');
    buf.writeln();
    buf.writeln(
        '**Components**: ${plan.affectedComponents.isEmpty ? "None specified" : plan.affectedComponents.map(_escapeHtml).join(", ")}  ');
    buf.writeln(
        '**Dependencies**: ${plan.dependencies.isEmpty ? "None required" : plan.dependencies.map(_escapeHtml).join(", ")}');
    buf.writeln();
    if (plan.affectedFiles.isNotEmpty) {
      buf.writeln('**Likely Affected Files**:');
      for (final f in plan.affectedFiles) {
        buf.writeln('- `${_escapeHtml(f)}`');
      }
      buf.writeln();
    }

    // 3. Architecture Changes
    buf.writeln('## 3. Architecture Changes');
    buf.writeln(_escapeHtml(plan.architectureChanges));
    buf.writeln();

    // 4. Implementation Steps
    buf.writeln(
        '## 4. Implementation Steps (${plan.implementationSteps.length})');
    buf.writeln();
    for (final step in plan.implementationSteps) {
      buf.writeln('### Step ${step.stepNumber}: ${_escapeHtml(step.title)}');
      buf.writeln('**Component**: `${_escapeHtml(step.targetComponent)}`  ');
      buf.writeln(_escapeHtml(step.description));
      if (step.estimatedFiles.isNotEmpty) {
        buf.writeln(
            '- *Files*: ${step.estimatedFiles.map((e) => "`${_escapeHtml(e)}`").join(", ")}');
      }
      if (step.dependencies.isNotEmpty) {
        buf.writeln(
            '- *Dependencies*: ${step.dependencies.map(_escapeHtml).join(", ")}');
      }
      buf.writeln();
    }

    // 5. Tests
    buf.writeln('## 5. Test Strategy (${plan.tests.length})');
    buf.writeln();
    for (final t in plan.tests) {
      buf.writeln(
          '- **[${_escapeHtml(t.testType.toUpperCase())}]** ${_escapeHtml(t.description)} → `${_escapeHtml(t.targetFile)}`');
    }
    buf.writeln();

    // 6. Security Checks
    buf.writeln('## 6. Security Checks & Considerations');
    if (plan.securityChecks.isEmpty) {
      buf.writeln('*Standard security practices apply.*');
    } else {
      for (final sec in plan.securityChecks) {
        buf.writeln('- 🔒 ${_escapeHtml(sec)}');
      }
    }
    buf.writeln();

    // 7. Documentation
    buf.writeln('## 7. Documentation Requirements');
    if (plan.documentationRequirements.isEmpty) {
      buf.writeln('*Standard documentation updates apply.*');
    } else {
      for (final doc in plan.documentationRequirements) {
        buf.writeln('- 📝 ${_escapeHtml(doc)}');
      }
    }
    buf.writeln();

    // 8. Verification (Regression Checks & Acceptance Criteria)
    buf.writeln('## 8. Verification & Acceptance Criteria');
    buf.writeln();
    buf.writeln('### Regression Checks');
    for (final reg in plan.regressionChecks) {
      buf.writeln('- 🔄 ${_escapeHtml(reg)}');
    }
    buf.writeln();
    buf.writeln('### Acceptance Criteria');
    for (final acc in plan.acceptanceCriteria) {
      buf.writeln('- [ ] ${_escapeHtml(acc)}');
    }
    buf.writeln();

    // 9. Next Phase Recommendation
    buf.writeln('## 9. Next Phase Recommendation');
    buf.writeln('👉 ${_escapeHtml(plan.nextPhaseRecommendation)}');
    buf.writeln();

    // Final redaction pass immediately before returning
    return SecretRedactor.redact(buf.toString());
  }
}
