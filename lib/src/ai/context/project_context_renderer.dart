/// Dual JSON and Markdown rendering for Project Context artifacts (Phase 8.2).
library;

import 'dart:convert';
import 'package:syntrix/src/ai/context/project_context_models.dart';

/// Single authority for pure, deterministic dual-rendering of [AssembledProjectContext] and [DiscoveredProjectSnapshot].
class ProjectContextRenderer {
  const ProjectContextRenderer();

  /// Renders [context] to formatted, indented JSON.
  String renderJson(AssembledProjectContext context) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(context.toJson());
  }

  /// Renders [snapshot] to formatted, indented JSON.
  String renderSnapshotJson(DiscoveredProjectSnapshot snapshot) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(snapshot.toJson());
  }

  /// Renders [context] to formatted, deterministic Markdown.
  String renderMarkdown(AssembledProjectContext context) {
    final buf = StringBuffer();

    buf.writeln(
        '# Flutter Package Studio — Project Context & Codebase Intelligence');
    buf.writeln();
    buf.writeln('**Root Path**: `${context.projectSummary["rootPath"]}`  ');
    buf.writeln('**Monorepo**: `${context.projectSummary["isMonorepo"]}`  ');
    buf.writeln(
        '**Package Count**: `${context.projectSummary["packageCount"]}`  ');
    if (context.resolvedPackageId != null) {
      buf.writeln('**Target Package**: `${context.resolvedPackageId}`  ');
    }
    buf.writeln(
        '**Total Context Tokens**: `${context.totalTokens}` / `${context.budgetLimitTokens}`');
    buf.writeln();

    if (context.isAmbiguousPackage && context.ambiguityNote != null) {
      buf.writeln('## ⚠️ Ambiguity Advisory');
      buf.writeln(context.ambiguityNote);
      buf.writeln();
    }

    buf.writeln('## Prioritized Scoped Files (${context.scopedFiles.length})');
    if (context.scopedFiles.isEmpty) {
      buf.writeln(
          'No relevant safe files were selected within the token budget.');
      buf.writeln();
    } else {
      for (var i = 0; i < context.scopedFiles.length; i++) {
        final f = context.scopedFiles[i];
        buf.writeln('### ${i + 1}. `${f.relativePath}`');
        buf.writeln(
            '**Category**: `${f.category.name}` | **Score**: `${f.relevanceScore.toStringAsFixed(2)}` | **Tokens**: `${f.tokenCount}`');
        buf.writeln('```dart');
        buf.writeln(f.content.length > 500
            ? '${f.content.substring(0, 500)}\n[... preview truncated ...]'
            : f.content);
        buf.writeln('```');
        buf.writeln();
      }
    }

    buf.writeln('## Context Audit & Filtering Trail');
    buf.writeln('| Relative Path | Status | Score | Reason / Rationale |');
    buf.writeln('|---|---|---|---|');

    // Sort audit records deterministically
    final sortedAudits = List<FileContextAuditRecord>.from(context.auditRecords)
      ..sort((a, b) => a.relativePath.compareTo(b.relativePath));

    for (final audit in sortedAudits) {
      final status = audit.isIncluded ? 'INCLUDED' : 'EXCLUDED';
      final reason = audit.exclusionReason != null
          ? '`[${audit.exclusionReason!.name}]` '
          : '';
      buf.writeln(
          '| `${audit.relativePath}` | **$status** | `${audit.relevanceScore.toStringAsFixed(2)}` | $reason${audit.rationale} |');
    }

    return buf.toString();
  }
}
