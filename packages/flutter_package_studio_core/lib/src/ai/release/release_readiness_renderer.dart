/// Pure dual-format (JSON and Markdown) renderers for Release Readiness Advisor results (Phase 8.10).
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/ai/security/secret_redactor.dart';
import 'package:flutter_package_studio_core/src/ai/release/release_readiness_models.dart';

/// Single authority for pure, deterministic dual-rendering of Release Readiness results with mandatory secret redaction.
class ReleaseReadinessRenderer {
  const ReleaseReadinessRenderer();

  /// Renders [assessment] to formatted, indented JSON with an absolute final redaction pass.
  String renderJson(ReleaseReadinessAssessment assessment) {
    const encoder = JsonEncoder.withIndent('  ');
    final rawJson = encoder.convert(assessment.toJson());
    // Mandatory final redaction pass
    return SecretRedactor.redact(rawJson);
  }

  /// Renders [assessment] to structured Markdown with status banners, blockers, warnings, and recommendations.
  String renderMarkdown(ReleaseReadinessAssessment assessment) {
    final buf = StringBuffer();

    buf.writeln(
        '# Flutter Package Studio — AI Release Readiness Advisory Report');
    buf.writeln();
    buf.writeln(
        '**Candidate**: `${assessment.targetScopeId}` (`${assessment.version}`)  ');
    buf.writeln('**Scope**: `${assessment.scope.name.toUpperCase()}`  ');
    buf.writeln(
        '**Overall Decision**: **`${assessment.status.name.toUpperCase()}`**  ');
    buf.writeln(
        '**Assessment Confidence**: `${assessment.confidence.name.toUpperCase()}`  ');
    buf.writeln(
        '**AI Narrative Synthesized**: `${assessment.isAiSynthesized}`  ');
    buf.writeln(
        '**Total Evidence Collected**: `${assessment.totalEvidenceCount}`  ');
    buf.writeln('**Duration**: `${assessment.durationMs}ms`  ');
    buf.writeln('**Timestamp**: `${assessment.timestamp.toIso8601String()}`');
    buf.writeln();

    // Prominent Status Banner
    switch (assessment.status) {
      case ReleaseReadinessStatus.ready:
        buf.writeln('> 🚀 **RELEASE CANDIDATE STATUS: READY**  ');
        buf.writeln(
            '> All mandatory release gates, security audits, and verification stages passed.');
        break;
      case ReleaseReadinessStatus.notReady:
        buf.writeln('> 🛑 **RELEASE CANDIDATE STATUS: NOT READY / BLOCKED**  ');
        buf.writeln(
            '> One or more mandatory release gates failed. Publishing is strictly prohibited.');
        break;
      case ReleaseReadinessStatus.needsReview:
        buf.writeln('> ⚠️ **RELEASE CANDIDATE STATUS: NEEDS REVIEW**  ');
        buf.writeln(
            '> Mandatory gates passed, but non-blocking concerns or pending items require human review.');
        break;
    }
    buf.writeln();

    buf.writeln('## Executive Summary');
    buf.writeln(assessment.summary);
    buf.writeln();

    // Mandatory Gate Audits
    buf.writeln(
        '## 🛡️ Mandatory Release Gates (${assessment.mandatoryGatesEvaluated.length})');
    buf.writeln();
    for (final gate in assessment.mandatoryGatesEvaluated) {
      final isFailed = assessment.failedMandatoryGates.contains(gate);
      buf.writeln('- [${isFailed ? "❌ FAILED" : "✓ PASSED"}] $gate');
    }
    buf.writeln();

    // Blockers Section
    if (assessment.blockers.isNotEmpty) {
      buf.writeln('## 🛑 Release Blockers (${assessment.blockers.length})');
      buf.writeln();
      for (var i = 0; i < assessment.blockers.length; i++) {
        final b = assessment.blockers[i];
        buf.writeln('${i + 1}. **${b.description}**');
        buf.writeln('   - *Evidence Source*: `${b.evidenceSource}`');
      }
      buf.writeln();
    }

    // Warnings Section
    if (assessment.warnings.isNotEmpty) {
      buf.writeln('## ⚠️ Release Warnings (${assessment.warnings.length})');
      buf.writeln();
      for (var i = 0; i < assessment.warnings.length; i++) {
        final w = assessment.warnings[i];
        buf.writeln('${i + 1}. **${w.description}**');
        buf.writeln('   - *Evidence Source*: `${w.evidenceSource}`');
      }
      buf.writeln();
    }

    // Strengths Section
    if (assessment.strengths.isNotEmpty) {
      buf.writeln('## ✅ Verified Strengths (${assessment.strengths.length})');
      buf.writeln();
      for (var i = 0; i < assessment.strengths.length; i++) {
        final s = assessment.strengths[i];
        buf.writeln('${i + 1}. **${s.description}**');
        buf.writeln('   - *Evidence Source*: `${s.evidenceSource}`');
      }
      buf.writeln();
    }

    // Recommended Actions Section
    if (assessment.recommendedActions.isNotEmpty) {
      buf.writeln('## 📋 Recommended Next Actions');
      buf.writeln();
      for (var i = 0; i < assessment.recommendedActions.length; i++) {
        final a = assessment.recommendedActions[i];
        buf.writeln('${i + 1}. ${a.description} *(${a.evidenceSource})*');
      }
      buf.writeln();
    }

    // Final redaction pass immediately before returning
    return SecretRedactor.redact(buf.toString());
  }
}
