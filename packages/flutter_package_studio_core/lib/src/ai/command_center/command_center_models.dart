/// Domain models for AI Engineering Command Center (Phase 8.14).
library;

import 'package:flutter_package_studio_core/src/ai/security/secret_redactor.dart';

/// All unified AI engineering capabilities exposed by the Command Center.
enum CommandCenterCapability {
  /// Deep architectural, dependency, and security analysis.
  analyze,

  /// Automated bug diagnosis, error analysis, and stack trace root-causing.
  debug,

  /// Automated code review and findings synthesis.
  review,

  /// Test intelligence and test suite generation.
  test,

  /// Documentation synthesis, READMEs, API docs, and architecture docs.
  document,

  /// Security and privacy audits, vulnerability scans, and secret leak detection.
  security,

  /// Architecture advice, modular pattern reviews, and structural audits.
  architecture,

  /// Dependency health checks, version upgrades, and conflict resolution.
  dependencies,

  /// Release readiness assessment, changelog checks, and pre-publish gates.
  release,

  /// 9-stage engineering workflow planning (facts vs. assumptions).
  plan,

  /// Architectural and pattern explanations.
  explain,

  /// Project engineering memory and persistent decision retrieval.
  memory,

  /// Controlled code modification and verified patch proposals.
  modify;

  /// Human-readable label.
  String get label {
    switch (this) {
      case CommandCenterCapability.analyze:
        return 'Analyze (Static & Context Analysis)';
      case CommandCenterCapability.debug:
        return 'Debug (Failure Diagnosis & Stacktrace Root Cause)';
      case CommandCenterCapability.review:
        return 'Review (Code Review & Finding Synthesis)';
      case CommandCenterCapability.test:
        return 'Test (Test Intelligence & Test Suite Generation)';
      case CommandCenterCapability.document:
        return 'Document (Documentation Assistant)';
      case CommandCenterCapability.security:
        return 'Security (Security & Privacy Audit)';
      case CommandCenterCapability.architecture:
        return 'Architecture (Architecture Advisor)';
      case CommandCenterCapability.dependencies:
        return 'Dependencies (Dependency & Compatibility Advisor)';
      case CommandCenterCapability.release:
        return 'Release (Release Readiness Advisor)';
      case CommandCenterCapability.plan:
        return 'Plan (Engineering Workflow Planner)';
      case CommandCenterCapability.explain:
        return 'Explain (Educational Pattern Explanation)';
      case CommandCenterCapability.memory:
        return 'Memory (Engineering Session & Knowledge Memory)';
      case CommandCenterCapability.modify:
        return 'Modify (Controlled Code Modification)';
    }
  }

  /// Parses a string into a [CommandCenterCapability].
  static CommandCenterCapability? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase().replaceAll(RegExp(r'[-_\s]'), '');
    for (final val in CommandCenterCapability.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    // Aliases
    if (clean == 'doc' || clean == 'docs' || clean == 'documentation') {
      return CommandCenterCapability.document;
    }
    if (clean == 'sec' || clean == 'audit') {
      return CommandCenterCapability.security;
    }
    if (clean == 'arch') {
      return CommandCenterCapability.architecture;
    }
    if (clean == 'deps' || clean == 'dependency' || clean == 'compatibility') {
      return CommandCenterCapability.dependencies;
    }
    if (clean == 'readiness' || clean == 'publish') {
      return CommandCenterCapability.release;
    }
    if (clean == 'diagnosis' || clean == 'fix') {
      return CommandCenterCapability.debug;
    }
    if (clean == 'aiplan' || clean == 'workflow') {
      return CommandCenterCapability.plan;
    }
    if (clean == 'patch' || clean == 'codemod') {
      return CommandCenterCapability.modify;
    }
    return null;
  }
}

/// Request payload submitted to the AI Engineering Command Center.
class CommandCenterRequest {
  /// Target AI capability / subsystem action.
  final CommandCenterCapability capability;

  /// Optional target identifier: template ID, package name, file path, or query string.
  final String? target;

  /// Primary user prompt, query instruction, or engineering requirement.
  final String prompt;

  /// Optional additional options and flags passed to specific subsystems.
  final Map<String, dynamic> options;

  /// Context token budget limit.
  final int tokenBudget;

  CommandCenterRequest({
    required this.capability,
    this.target,
    required String prompt,
    this.options = const {},
    this.tokenBudget = 4000,
  }) : prompt = SecretRedactor.redact(prompt);

  Map<String, dynamic> toJson() => {
        'capability': capability.name,
        if (target != null) 'target': target,
        'prompt': prompt,
        'options': SecretRedactor.redactJson(options),
        'tokenBudget': tokenBudget,
      };
}

/// Unified output response returned by the AI Engineering Command Center.
class CommandCenterResponse {
  /// Target capability executed.
  final CommandCenterCapability capability;

  /// High-level summary of the execution outcome.
  final String summary;

  /// Subsystem-specific structured result object.
  final dynamic structuredPayload;

  /// Execution duration in milliseconds.
  final int durationMs;

  /// Timestamp of command execution.
  final DateTime timestamp;

  /// Error message if execution failed or degraded.
  final String? errorMessage;

  /// Whether the command execution succeeded.
  final bool isSuccess;

  CommandCenterResponse({
    required this.capability,
    required String summary,
    this.structuredPayload,
    required this.durationMs,
    required this.timestamp,
    this.errorMessage,
    this.isSuccess = true,
  }) : summary = SecretRedactor.redact(summary);

  factory CommandCenterResponse.failure({
    required CommandCenterCapability capability,
    required String errorMessage,
    int durationMs = 0,
    DateTime? timestamp,
  }) =>
      CommandCenterResponse(
        capability: capability,
        summary:
            'Command Center execution failed for capability: ${capability.name}',
        durationMs: durationMs,
        timestamp: timestamp ?? DateTime.now(),
        errorMessage: SecretRedactor.redact(errorMessage),
        isSuccess: false,
      );

  Map<String, dynamic> toJson() {
    dynamic payloadJson;
    if (structuredPayload != null) {
      if (structuredPayload is Map<String, dynamic>) {
        payloadJson = structuredPayload;
      } else {
        try {
          payloadJson = (structuredPayload as dynamic).toJson();
        } catch (_) {
          payloadJson = structuredPayload.toString();
        }
      }
    }

    return {
      'capability': capability.name,
      'summary': summary,
      'isSuccess': isSuccess,
      if (structuredPayload != null) 'payload': payloadJson,
      'durationMs': durationMs,
      'timestamp': timestamp.toIso8601String(),
      if (errorMessage != null)
        'errorMessage': SecretRedactor.redact(errorMessage!),
    };
  }
}
