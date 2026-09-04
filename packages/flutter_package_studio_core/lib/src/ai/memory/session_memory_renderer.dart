/// Dual-format (JSON and Markdown) renderers for AI Engineering Session & Knowledge Memory (Phase 8.12).
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/ai/security/secret_redactor.dart';
import 'package:flutter_package_studio_core/src/ai/memory/session_memory_models.dart';

/// Single authority for pure, deterministic rendering of Session Knowledge Memory queries and session exports.
class SessionMemoryRenderer {
  const SessionMemoryRenderer();

  /// Escapes HTML special characters in [text] to prevent injection in Markdown/HTML output.
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Renders [result] to formatted, indented JSON with an absolute final redaction pass.
  String renderQueryJson(MemoryQueryResult result) {
    const encoder = JsonEncoder.withIndent('  ');
    final rawJson = encoder.convert(result.toJson());
    return SecretRedactor.redact(rawJson);
  }

  /// Renders [session] to formatted, indented JSON with an absolute final redaction pass.
  String renderSessionJson(MemorySession session) {
    const encoder = JsonEncoder.withIndent('  ');
    final rawJson = encoder.convert(session.toJson());
    return SecretRedactor.redact(rawJson);
  }

  /// Renders [sessions] list to formatted JSON.
  String renderSessionsJson(List<MemorySession> sessions) {
    const encoder = JsonEncoder.withIndent('  ');
    final rawJson = encoder.convert(sessions.map((s) => s.toJson()).toList());
    return SecretRedactor.redact(rawJson);
  }

  /// Renders [result] to human-readable Markdown format.
  String renderQueryMarkdown(MemoryQueryResult result) {
    final buf = StringBuffer();

    buf.writeln('# AI Engineering Knowledge Memory — Query Result');
    buf.writeln();
    buf.writeln('**Query**: "${_escapeHtml(result.query)}"  ');
    buf.writeln('**Matches Found**: `${result.entries.length}`  ');
    buf.writeln('**Duration**: `${result.durationMs}ms`  ');
    buf.writeln('**Timestamp**: `${result.timestamp.toIso8601String()}`');
    buf.writeln();

    if (!result.isSuccess) {
      buf.writeln('## ❌ Memory Retrieval Failed');
      buf.writeln(result.errorMessage ?? 'An unknown error occurred during memory retrieval.');
      return SecretRedactor.redact(buf.toString());
    }

    if (result.conflictsDetected.isNotEmpty) {
      buf.writeln('## ⚠️ Architectural Conflicts Detected');
      for (final c in result.conflictsDetected) {
        buf.writeln('- **[${c.severity.toUpperCase()}]** ${_escapeHtml(c.topic)}: ${_escapeHtml(c.reason)}');
      }
      buf.writeln();
    }

    buf.writeln('## Synthesis & Context Answer');
    buf.writeln(result.synthesis);
    buf.writeln();

    if (result.entries.isNotEmpty) {
      buf.writeln('## Documented Knowledge Entries');
      buf.writeln();
      for (final e in result.entries) {
        buf.writeln('### [${_escapeHtml(e.type.label)}] ${_escapeHtml(e.title)} (v${e.version})');
        buf.writeln('- **Session ID**: `${_escapeHtml(e.sessionId)}`');
        buf.writeln('- **Scope**: `${_escapeHtml(e.scope)}`');
        if (e.tags.isNotEmpty) {
          buf.writeln('- **Tags**: ${e.tags.map((t) => "`${_escapeHtml(t)}`").join(", ")}');
        }
        buf.writeln('- **Recorded**: `${e.createdAt.toIso8601String()}`');
        if (e.expiresAt != null) {
          buf.writeln('- **Expires**: `${e.expiresAt!.toIso8601String()}`');
        }
        buf.writeln();
        buf.writeln(e.content);
        buf.writeln();

        if (e.evidenceRefs.isNotEmpty) {
          buf.writeln('**Evidence References:**');
          for (final ref in e.evidenceRefs) {
            final loc = ref.location != null ? ' (location: `${_escapeHtml(ref.location!)}`)' : '';
            buf.writeln('- [`${_escapeHtml(ref.path)}`]$loc — ${_escapeHtml(ref.description)}');
          }
          buf.writeln();
        }
      }
    }

    return SecretRedactor.redact(buf.toString().trim());
  }

  /// Renders a [session] to human-readable Markdown format.
  String renderSessionMarkdown(MemorySession session) {
    final buf = StringBuffer();

    buf.writeln('# Engineering Session: ${_escapeHtml(session.sessionId)}');
    buf.writeln();
    buf.writeln('**Summary**: ${_escapeHtml(session.summary)}  ');
    buf.writeln('**Entries Recorded**: `${session.entries.length}`  ');
    buf.writeln('**Created**: `${session.createdAt.toIso8601String()}`  ');
    buf.writeln('**Last Updated**: `${session.lastAccessedAt.toIso8601String()}`');
    buf.writeln();

    if (session.entries.isEmpty) {
      buf.writeln('*No knowledge entries recorded in this session.*');
    } else {
      buf.writeln('## Knowledge Entries');
      buf.writeln();
      for (final e in session.entries) {
        buf.writeln('### [${_escapeHtml(e.type.label)}] ${_escapeHtml(e.title)} (v${e.version})');
        buf.writeln('- **ID**: `${_escapeHtml(e.id)}`');
        buf.writeln('- **Scope**: `${_escapeHtml(e.scope)}`');
        if (e.tags.isNotEmpty) {
          buf.writeln('- **Tags**: ${e.tags.map((t) => "`${_escapeHtml(t)}`").join(", ")}');
        }
        buf.writeln();
        buf.writeln(e.content);
        buf.writeln();

        if (e.evidenceRefs.isNotEmpty) {
          buf.writeln('**Evidence:**');
          for (final ref in e.evidenceRefs) {
            final loc = ref.location != null ? ' (`${_escapeHtml(ref.location!)}`)' : '';
            buf.writeln('- `${_escapeHtml(ref.path)}`$loc: ${_escapeHtml(ref.description)}');
          }
          buf.writeln();
        }
      }
    }

    return SecretRedactor.redact(buf.toString().trim());
  }
}
