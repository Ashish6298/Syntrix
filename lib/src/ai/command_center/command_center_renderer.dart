/// Pure dual-format (JSON and Markdown) renderers for AI Engineering Command Center responses (Phase 8.14).
library;

import 'dart:convert';
import 'package:syntrix/src/ai/security/secret_redactor.dart';
import 'package:syntrix/src/ai/command_center/command_center_models.dart';

// Subsystem renderers & models
import 'package:syntrix/src/ai/review/code_review_renderer.dart';
import 'package:syntrix/src/ai/review/code_review_models.dart';
import 'package:syntrix/src/ai/testing/test_intelligence_renderer.dart';
import 'package:syntrix/src/ai/testing/test_intelligence_models.dart';
import 'package:syntrix/src/ai/diagnosis/failure_diagnosis_renderer.dart';
import 'package:syntrix/src/ai/diagnosis/failure_diagnosis_models.dart';
import 'package:syntrix/src/ai/architecture/architecture_advisor_renderer.dart';
import 'package:syntrix/src/ai/architecture/architecture_models.dart';
import 'package:syntrix/src/ai/documentation/documentation_assistant_renderer.dart';
import 'package:syntrix/src/ai/documentation/documentation_models.dart';
import 'package:syntrix/src/ai/dependencies/dependency_advisor_renderer.dart';
import 'package:syntrix/src/ai/dependencies/dependency_models.dart';
import 'package:syntrix/src/ai/security/security_advisor_renderer.dart';
import 'package:syntrix/src/ai/security/security_models.dart';
import 'package:syntrix/src/ai/release/release_readiness_renderer.dart';
import 'package:syntrix/src/ai/release/release_readiness_models.dart';
import 'package:syntrix/src/ai/planner/workflow_planner_renderer.dart';
import 'package:syntrix/src/ai/planner/workflow_planner_models.dart';
import 'package:syntrix/src/ai/memory/session_memory_renderer.dart';
import 'package:syntrix/src/ai/memory/session_memory_models.dart';
import 'package:syntrix/src/ai/modification/code_modification_renderer.dart';
import 'package:syntrix/src/ai/modification/code_modification_models.dart';

/// Single authority for pure, deterministic dual-rendering of Command Center responses with mandatory secret redaction.
class CommandCenterRenderer {
  const CommandCenterRenderer();

  /// Escapes HTML special characters in [text] to prevent injection.
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Renders [response] to formatted, indented JSON with an absolute final redaction pass.
  String renderJson(CommandCenterResponse response) {
    const encoder = JsonEncoder.withIndent('  ');
    final rawJson = encoder.convert(response.toJson());
    return SecretRedactor.redact(rawJson);
  }

  /// Renders [response] to structured Markdown report, delegating to specialized subsystem renderers when available.
  String renderMarkdown(CommandCenterResponse response) {
    final buf = StringBuffer();

    buf.writeln('# AI Engineering Command Center — Execution Report');
    buf.writeln();
    buf.writeln(
        '**Capability**: `${_escapeHtml(response.capability.label)}`  ');
    buf.writeln(
        '**Status**: ${response.isSuccess ? "✅ SUCCESS" : "❌ FAILURE"}  ');
    buf.writeln('**Duration**: `${response.durationMs}ms`  ');
    buf.writeln('**Timestamp**: `${response.timestamp.toIso8601String()}`');
    buf.writeln();

    if (!response.isSuccess) {
      buf.writeln('## ❌ Execution Error');
      buf.writeln(response.errorMessage ??
          'An unknown error occurred during Command Center execution.');
      return SecretRedactor.redact(buf.toString());
    }

    buf.writeln('## Executive Summary');
    buf.writeln(_escapeHtml(response.summary));
    buf.writeln();

    // Delegate to specialized subsystem renderer if available
    final payload = response.structuredPayload;
    if (payload != null) {
      buf.writeln('---');
      buf.writeln();

      if (payload is CodeReviewResult) {
        buf.writeln(const CodeReviewRenderer().renderMarkdown(payload));
      } else if (payload is TestIntelligenceResult) {
        buf.writeln(const TestIntelligenceRenderer().renderMarkdown(payload));
      } else if (payload is DiagnosisResult) {
        buf.writeln(const FailureDiagnosisRenderer().renderMarkdown(payload));
      } else if (payload is ArchitectureScanResult) {
        buf.writeln(
            const ArchitectureAdvisorRenderer().renderMarkdown(payload));
      } else if (payload is DocumentationGenerationResult) {
        buf.writeln(payload.markdownContent);
      } else if (payload is DocumentationConsistencyResult) {
        buf.writeln(const DocumentationAssistantRenderer()
            .renderConsistencyMarkdown(payload));
      } else if (payload is DependencyAnalysisResult) {
        buf.writeln(const DependencyAdvisorRenderer().renderMarkdown(payload));
      } else if (payload is SecurityAnalysisResult) {
        buf.writeln(const SecurityAdvisorRenderer().renderMarkdown(payload));
      } else if (payload is ReleaseReadinessAssessment) {
        buf.writeln(const ReleaseReadinessRenderer().renderMarkdown(payload));
      } else if (payload is WorkflowPlanResult) {
        buf.writeln(const WorkflowPlannerRenderer().renderMarkdown(payload));
      } else if (payload is MemoryQueryResult) {
        buf.writeln(const SessionMemoryRenderer().renderQueryMarkdown(payload));
      } else if (payload is CodeModificationProposal) {
        buf.writeln(const CodeModificationRenderer().renderMarkdown(payload));
      } else {
        const encoder = JsonEncoder.withIndent('  ');
        buf.writeln('```json');
        try {
          buf.writeln(encoder.convert((payload as dynamic).toJson()));
        } catch (_) {
          buf.writeln(encoder.convert(payload));
        }
        buf.writeln('```');
      }
    }

    return SecretRedactor.redact(buf.toString().trim());
  }
}
