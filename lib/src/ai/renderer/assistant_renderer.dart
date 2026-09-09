/// Dual-format (JSON and Markdown) pure renderers for Assistant Responses (Phase 8.1).
library;

import 'dart:convert';
import 'package:syntrix/src/ai/models/assistant_models.dart';

/// Single authority for pure, deterministic dual-rendering of [AssistantResponse] objects.
class AssistantRenderer {
  const AssistantRenderer();

  /// Renders [response] to a formatted, indented JSON string.
  String renderJson(AssistantResponse response) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(response.toJson());
  }

  /// Renders [response] to a formatted Markdown string.
  String renderMarkdown(AssistantResponse response) {
    final buf = StringBuffer();

    buf.writeln('# Flutter Package Studio — AI Assistant Report');
    buf.writeln();
    buf.writeln('**Template ID**: `${response.templateId}`  ');
    buf.writeln('**Mode**: `${response.mode.name.toUpperCase()}`  ');
    buf.writeln('**Status**: `${response.status.name.toUpperCase()}`  ');
    buf.writeln('**Model**: `${response.modelName}`  ');
    buf.writeln('**Timestamp**: `${response.timestamp.toIso8601String()}`');
    buf.writeln();

    if (!response.isSuccess) {
      buf.writeln('## Failure Details');
      buf.writeln(
          '- **Error**: ${response.errorMessage ?? "An unexpected assistant failure occurred."}');
      buf.writeln('- **Status Code**: `${response.status.name}`');
      return buf.toString();
    }

    final content = response.structuredContent;
    if (content is AnalysisPayload) {
      buf.writeln('## Analysis Summary');
      buf.writeln(content.summary);
      buf.writeln();

      if (content.findings.isNotEmpty) {
        buf.writeln('### Key Findings');
        for (final finding in content.findings) {
          buf.writeln('- $finding');
        }
        buf.writeln();
      }

      if (content.metrics.isNotEmpty) {
        buf.writeln('### Evaluation Metrics');
        final sortedKeys = content.metrics.keys.toList()..sort();
        for (final k in sortedKeys) {
          buf.writeln('- **$k**: ${content.metrics[k]}');
        }
        buf.writeln();
      }

      if (content.risks.isNotEmpty) {
        buf.writeln('### Identified Risks');
        for (final risk in content.risks) {
          buf.writeln('- ⚠️ $risk');
        }
        buf.writeln();
      }
    } else if (content is RecommendationPayload) {
      buf.writeln('## Recommendations Overview');
      buf.writeln(content.overview);
      buf.writeln();

      if (content.recommendations.isNotEmpty) {
        buf.writeln('### Actionable Recommendations');
        for (var i = 0; i < content.recommendations.length; i++) {
          final rec = content.recommendations[i];
          buf.writeln('#### ${i + 1}. ${rec.title}');
          buf.writeln('**Impact**: `${rec.impact.toUpperCase()}`  ');
          buf.writeln('**Rationale**: ${rec.rationale}  ');
          buf.writeln('**Action**: ${rec.suggestedAction}');
          buf.writeln();
        }
      }
    } else if (content is ExplanationPayload) {
      buf.writeln('## Topic: ${content.topic}');
      buf.writeln();
      buf.writeln('### Explanation');
      buf.writeln(content.detailedExplanation);
      buf.writeln();

      if (content.keyConcepts.isNotEmpty) {
        buf.writeln('### Key Concepts');
        for (final c in content.keyConcepts) {
          buf.writeln('- **$c**');
        }
        buf.writeln();
      }

      if (content.architecturalTradeoffs.isNotEmpty) {
        buf.writeln('### Architectural Tradeoffs');
        for (final t in content.architecturalTradeoffs) {
          buf.writeln('- $t');
        }
        buf.writeln();
      }
    } else if (content is PlanningPayload) {
      buf.writeln('## Objective: ${content.objective}');
      buf.writeln('**Estimated Effort**: `${content.estimatedEffort}`');
      buf.writeln();

      if (content.steps.isNotEmpty) {
        buf.writeln('### Execution Steps');
        for (final step in content.steps) {
          buf.writeln('#### Step ${step.sequence}: ${step.title}');
          buf.writeln(step.description);
          if (step.prerequisites.isNotEmpty) {
            buf.writeln('**Prerequisites**:');
            for (final pre in step.prerequisites) {
              buf.writeln('  - $pre');
            }
          }
          buf.writeln();
        }
      }
    }

    buf.writeln('---');
    buf.writeln('### Execution Metadata');
    buf.writeln('- **Prompt Tokens**: `${response.promptTokens}`');
    buf.writeln('- **Completion Tokens**: `${response.completionTokens}`');
    buf.writeln('- **Duration**: `${response.durationMs}ms`');

    return buf.toString();
  }
}
