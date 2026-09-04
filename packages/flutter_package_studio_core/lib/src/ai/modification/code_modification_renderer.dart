/// Pure dual-format (JSON and Markdown) renderers for AI Code Modification proposals (Phase 8.13).
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/ai/security/secret_redactor.dart';
import 'package:flutter_package_studio_core/src/ai/modification/code_modification_models.dart';

/// Single authority for pure, deterministic rendering of Code Modification proposals and change reports.
class CodeModificationRenderer {
  const CodeModificationRenderer();

  /// Escapes HTML special characters in [text] to prevent injection in Markdown/HTML output.
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Renders [proposal] to formatted, indented JSON with an absolute final redaction pass.
  String renderJson(CodeModificationProposal proposal) {
    const encoder = JsonEncoder.withIndent('  ');
    final rawJson = encoder.convert(proposal.toJson());
    return SecretRedactor.redact(rawJson);
  }

  /// Renders [result] to formatted JSON.
  String renderApplyResultJson(CodeModificationApplyResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    final rawJson = encoder.convert(result.toJson());
    return SecretRedactor.redact(rawJson);
  }

  /// Renders [proposal] to a structured Markdown change report.
  String renderMarkdown(CodeModificationProposal proposal) {
    final buf = StringBuffer();

    buf.writeln('# AI-Assisted Controlled Code Modification — Change Report');
    buf.writeln();
    buf.writeln('**Proposal ID**: `${proposal.proposalId}`  ');
    buf.writeln('**Requirement**: "${_escapeHtml(proposal.requirement)}"  ');
    buf.writeln('**Status**: ${proposal.isEligibleForApplication ? "✅ ELIGIBLE FOR APPLICATION" : "❌ INELIGIBLE (SAFETY / VALIDATION FAILED)"}  ');
    buf.writeln('**Affected Files**: `${proposal.affectedFiles.length}` (Limit: ${proposal.safetyPolicy.maxFilesLimit})  ');
    buf.writeln('**Total Lines Changed**: `+${proposal.totalLinesAdded} / -${proposal.totalLinesRemoved}` (Limit: ${proposal.safetyPolicy.maxTotalLinesChanged})  ');
    buf.writeln('**Duration**: `${proposal.durationMs}ms`  ');
    buf.writeln('**Timestamp**: `${proposal.timestamp.toIso8601String()}`');
    buf.writeln();

    if (!proposal.isSuccess) {
      buf.writeln('## ❌ Proposal Generation Failed');
      buf.writeln(proposal.errorMessage ?? 'An unknown error occurred during modification planning.');
      return SecretRedactor.redact(buf.toString());
    }

    if (proposal.errorMessage != null && !proposal.isEligibleForApplication) {
      buf.writeln('## ⚠️ Policy Violations / Safeguard Blocks');
      buf.writeln(proposal.errorMessage!);
      buf.writeln();
    }

    // 1. Executive Summary
    buf.writeln('## 1. Executive Summary & Modification Plan');
    buf.writeln(_escapeHtml(proposal.summary));
    buf.writeln();

    // 2. Affected Files
    buf.writeln('## 2. Affected Files (${proposal.affectedFiles.length})');
    if (proposal.affectedFiles.isEmpty) {
      buf.writeln('*No files affected.*');
    } else {
      for (final f in proposal.affectedFiles) {
        buf.writeln('- `${_escapeHtml(f)}`');
      }
    }
    buf.writeln();

    // 3. Diff Previews & Patch Details
    buf.writeln('## 3. Patch Diff Previews (${proposal.patches.length})');
    buf.writeln();
    for (final patch in proposal.patches) {
      buf.writeln('### `${_escapeHtml(patch.relativePath)}` [${patch.patchType.name.toUpperCase()}]');
      buf.writeln('**Description**: ${_escapeHtml(patch.description)}  ');
      buf.writeln('**Changes**: `+${patch.linesAdded} / -${patch.linesRemoved}`');
      buf.writeln();
      buf.writeln('```diff');
      buf.writeln(patch.diff);
      buf.writeln('```');
      buf.writeln();
    }

    // 4. Validation Pipeline Results
    buf.writeln('## 4. Verification Pipeline Status');
    buf.writeln();
    buf.writeln('- **Patch Syntax Validity**: ${proposal.validation.patchValid ? "✅ PASS" : "❌ FAIL"}');
    buf.writeln('- **Automated Tests**: ${proposal.validation.testsPassed ? "✅ PASS" : "❌ FAIL"}');
    if (proposal.validation.testOutput != null) {
      buf.writeln('  - *Detail*: ${_escapeHtml(proposal.validation.testOutput!)}');
    }
    buf.writeln('- **Dart Analyzer Check**: ${proposal.validation.analyzerPassed ? "✅ PASS" : "❌ FAIL"}');
    if (proposal.validation.analyzerOutput != null) {
      buf.writeln('  - *Detail*: ${_escapeHtml(proposal.validation.analyzerOutput!)}');
    }
    buf.writeln('- **Code Formatter Check**: ${proposal.validation.formatterPassed ? "✅ PASS" : "❌ FAIL"}');
    if (proposal.validation.formatterOutput != null) {
      buf.writeln('  - *Detail*: ${_escapeHtml(proposal.validation.formatterOutput!)}');
    }
    buf.writeln();

    // 5. Governance & Execution Approval
    buf.writeln('## 5. Governance & Safety Gate');
    if (proposal.safetyPolicy.requireExplicitApproval) {
      buf.writeln('🔒 **Explicit Execution Approval Required**: Human confirmation is mandatory before these patches can be applied to the repository.');
    } else {
      buf.writeln('⚠️ Automated application enabled under relaxed policy.');
    }
    buf.writeln();

    return SecretRedactor.redact(buf.toString().trim());
  }
}
