/// Domain models and structured payloads for the AI Assistant Core Foundation (Phase 8.1).
library;

/// The four distinct operating modes supported by the AI Assistant.
enum AssistantMode {
  /// Deep architectural, dependency, and security analysis of templates/packages.
  analysis,

  /// Actionable best-practice recommendations for optimization and maintainability.
  recommendation,

  /// Educational explanations of design choices, patterns, and code components.
  explanation,

  /// Step-by-step migration, refactoring, and feature implementation planning.
  planning;

  /// Parses a string mode name into an [AssistantMode], returning null on invalid input.
  static AssistantMode? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase();
    for (final val in AssistantMode.values) {
      if (val.name.toLowerCase() == clean) {
        return val;
      }
    }
    return null;
  }
}

/// Closed, enumerable set of assistant capabilities.
enum AssistantCapability {
  /// Ability to inspect template and package manifest metadata.
  templateAnalysis,

  /// Ability to provide dependency recommendations.
  dependencyAdvice,

  /// Ability to explain architectural design patterns.
  architecturalExplanation,

  /// Ability to synthesize multi-step migration/generation plans.
  planSynthesis,

  /// Streaming token responses (reserved for Phase 8.14).
  streaming,

  /// Long-term durable cross-session memory (reserved for Phase 8.12).
  crossSessionMemory;

  static AssistantCapability? tryParse(String raw) {
    final clean = raw.trim().toLowerCase();
    for (final val in AssistantCapability.values) {
      if (val.name.toLowerCase() == clean) return val;
    }
    return null;
  }
}

/// Installation configuration and capability controls for the AI Assistant.
class AssistantConfiguration {
  /// Default provider ID (e.g. 'mock', 'gemini', 'openai').
  final String providerId;

  /// Default model identifier.
  final String model;

  /// Invocation timeout before failing closed.
  final Duration timeout;

  /// Closed set of enabled capabilities.
  final Set<AssistantCapability> enabledCapabilities;

  /// Sampling temperature.
  final double temperature;

  /// Whether assistant operations are globally enabled.
  final bool isEnabled;

  const AssistantConfiguration({
    this.providerId = 'mock_ai_provider',
    this.model = 'mock-model',
    this.timeout = const Duration(seconds: 30),
    this.enabledCapabilities = const {
      AssistantCapability.templateAnalysis,
      AssistantCapability.dependencyAdvice,
      AssistantCapability.architecturalExplanation,
      AssistantCapability.planSynthesis,
    },
    this.temperature = 0.0,
    this.isEnabled = true,
  });

  /// Factory creating configuration with zero enabled capabilities.
  factory AssistantConfiguration.disabled() => const AssistantConfiguration(
        isEnabled: false,
        enabledCapabilities: {},
      );

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'model': model,
        'timeoutMs': timeout.inMilliseconds,
        'enabledCapabilities': enabledCapabilities.map((c) => c.name).toList()
          ..sort(),
        'temperature': temperature,
        'isEnabled': isEnabled,
      };
}

/// A structured, programmatically composable prompt context representation.
class PromptContext {
  /// Target template or package ID.
  final String templateId;

  /// Target template version, if known.
  final String? version;

  /// Structured metadata key-value pairs.
  final Map<String, dynamic> metadata;

  /// Declared capabilities of the template.
  final List<String> capabilities;

  /// Dependencies declared by the package/template.
  final List<String> dependencies;

  /// Redacted environment or config tags.
  final Map<String, String> environment;

  /// Additional domain facts sorted deterministically.
  final Map<String, dynamic> structuredFacts;

  const PromptContext({
    required this.templateId,
    this.version,
    this.metadata = const {},
    this.capabilities = const [],
    this.dependencies = const [],
    this.environment = const {},
    this.structuredFacts = const {},
  });

  /// Produces a byte-identical canonical JSON map representation.
  Map<String, dynamic> toJson() {
    final sortedCaps = List<String>.from(capabilities)..sort();
    final sortedDeps = List<String>.from(dependencies)..sort();
    final sortedEnv = Map<String, String>.fromEntries(
        environment.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    final sortedFacts = Map<String, dynamic>.fromEntries(
        structuredFacts.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)));
    final sortedMeta = Map<String, dynamic>.fromEntries(
        metadata.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));

    return {
      'templateId': templateId,
      if (version != null) 'version': version,
      'metadata': sortedMeta,
      'capabilities': sortedCaps,
      'dependencies': sortedDeps,
      'environment': sortedEnv,
      'structuredFacts': sortedFacts,
    };
  }
}

/// Single conversational turn message within a session.
class SessionMessage {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  final DateTime timestamp;

  const SessionMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Explicit, identifiable abstraction for a sequence of related requests.
class ConversationSession {
  /// Unique session UUID or identifier.
  final String sessionId;

  /// When the session was started.
  final DateTime createdAt;

  /// When the session was last updated.
  final DateTime updatedAt;

  /// Message sequence history.
  final List<SessionMessage> history;

  const ConversationSession({
    required this.sessionId,
    required this.createdAt,
    required this.updatedAt,
    this.history = const [],
  });

  /// Creates a new empty conversation session.
  factory ConversationSession.create({String? sessionId, DateTime? now}) {
    final t = now ?? DateTime.now();
    final id = sessionId ?? 'session_${t.microsecondsSinceEpoch}';
    return ConversationSession(
      sessionId: id,
      createdAt: t,
      updatedAt: t,
      history: const [],
    );
  }

  ConversationSession addTurn({
    required String userPrompt,
    required String assistantResponse,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    return ConversationSession(
      sessionId: sessionId,
      createdAt: createdAt,
      updatedAt: t,
      history: [
        ...history,
        SessionMessage(role: 'user', content: userPrompt, timestamp: t),
        SessionMessage(
            role: 'assistant', content: assistantResponse, timestamp: t),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'history': history.map((m) => m.toJson()).toList(),
      };
}

/// Input request given to the Assistant Engine.
class AssistantRequest {
  /// The user-supplied or automated prompt instruction.
  final String prompt;

  /// Target assistant mode.
  final AssistantMode mode;

  /// Target template or package ID.
  final String templateId;

  /// Optional conversation session context.
  final ConversationSession? session;

  /// Structured prompt context.
  final PromptContext context;

  /// Optional overriding configuration.
  final AssistantConfiguration? configuration;

  const AssistantRequest({
    required this.prompt,
    required this.mode,
    required this.templateId,
    required this.context,
    this.session,
    this.configuration,
  });

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'mode': mode.name,
        'templateId': templateId,
        'context': context.toJson(),
        if (session != null) 'sessionId': session!.sessionId,
      };
}

/// Structured payload for [AssistantMode.analysis].
class AnalysisPayload {
  final String summary;
  final List<String> findings;
  final Map<String, String> metrics;
  final List<String> risks;

  const AnalysisPayload({
    required this.summary,
    this.findings = const [],
    this.metrics = const {},
    this.risks = const [],
  });

  factory AnalysisPayload.fromJson(Map<String, dynamic> json) {
    return AnalysisPayload(
      summary: json['summary'] as String? ?? 'No analysis summary available.',
      findings: (json['findings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      metrics: (json['metrics'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
      risks: (json['risks'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'findings': findings,
        'metrics': metrics,
        'risks': risks,
      };
}

/// Structured payload for [AssistantMode.recommendation].
class RecommendationItem {
  final String title;
  final String rationale;
  final String impact; // 'high' | 'medium' | 'low'
  final String suggestedAction;

  const RecommendationItem({
    required this.title,
    required this.rationale,
    required this.impact,
    required this.suggestedAction,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) =>
      RecommendationItem(
        title: json['title'] as String? ?? 'General Recommendation',
        rationale: json['rationale'] as String? ?? '',
        impact: json['impact'] as String? ?? 'medium',
        suggestedAction: json['suggestedAction'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'rationale': rationale,
        'impact': impact,
        'suggestedAction': suggestedAction,
      };
}

/// Structured payload for [AssistantMode.recommendation].
class RecommendationPayload {
  final String overview;
  final List<RecommendationItem> recommendations;

  const RecommendationPayload({
    required this.overview,
    this.recommendations = const [],
  });

  factory RecommendationPayload.fromJson(Map<String, dynamic> json) {
    final rawList = json['recommendations'] as List<dynamic>? ?? const [];
    return RecommendationPayload(
      overview: json['overview'] as String? ?? 'No recommendations overview.',
      recommendations: rawList
          .whereType<Map<String, dynamic>>()
          .map(RecommendationItem.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'overview': overview,
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
      };
}

/// Structured payload for [AssistantMode.explanation].
class ExplanationPayload {
  final String topic;
  final String detailedExplanation;
  final List<String> keyConcepts;
  final List<String> architecturalTradeoffs;

  const ExplanationPayload({
    required this.topic,
    required this.detailedExplanation,
    this.keyConcepts = const [],
    this.architecturalTradeoffs = const [],
  });

  factory ExplanationPayload.fromJson(Map<String, dynamic> json) {
    return ExplanationPayload(
      topic: json['topic'] as String? ?? 'Topic Explanation',
      detailedExplanation: json['detailedExplanation'] as String? ?? '',
      keyConcepts: (json['keyConcepts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      architecturalTradeoffs: (json['architecturalTradeoffs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'detailedExplanation': detailedExplanation,
        'keyConcepts': keyConcepts,
        'architecturalTradeoffs': architecturalTradeoffs,
      };
}

/// Step item in planning payload.
class PlanStep {
  final int sequence;
  final String title;
  final String description;
  final List<String> prerequisites;

  const PlanStep({
    required this.sequence,
    required this.title,
    required this.description,
    this.prerequisites = const [],
  });

  factory PlanStep.fromJson(Map<String, dynamic> json) => PlanStep(
        sequence: json['sequence'] as int? ?? 1,
        title: json['title'] as String? ?? 'Plan Step',
        description: json['description'] as String? ?? '',
        prerequisites: (json['prerequisites'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'sequence': sequence,
        'title': title,
        'description': description,
        'prerequisites': prerequisites,
      };
}

/// Structured payload for [AssistantMode.planning].
class PlanningPayload {
  final String objective;
  final List<PlanStep> steps;
  final String estimatedEffort;

  const PlanningPayload({
    required this.objective,
    this.steps = const [],
    this.estimatedEffort = 'medium',
  });

  factory PlanningPayload.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? const [];
    return PlanningPayload(
      objective: json['objective'] as String? ?? 'Execution Plan',
      steps: rawSteps
          .whereType<Map<String, dynamic>>()
          .map(PlanStep.fromJson)
          .toList(),
      estimatedEffort: json['estimatedEffort'] as String? ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() => {
        'objective': objective,
        'steps': steps.map((s) => s.toJson()).toList(),
        'estimatedEffort': estimatedEffort,
      };
}

/// Status of assistant response execution.
enum AssistantResponseStatus {
  success,
  providerUnavailable,
  invalidResponse,
  timedOut,
  disabled,
  rejected,
}

/// Root output response produced by the Assistant Engine.
class AssistantResponse {
  /// Response identifier.
  final String responseId;

  /// Target mode executed.
  final AssistantMode mode;

  /// High-level execution status.
  final AssistantResponseStatus status;

  /// Target template or package ID.
  final String templateId;

  /// Structured content payload (AnalysisPayload, RecommendationPayload, etc.).
  final dynamic structuredContent;

  /// Human-readable error message on failure.
  final String? errorMessage;

  /// The raw untrusted completion text received from the provider (if available).
  final String? rawUntrustedCompletion;

  /// Token metrics.
  final int promptTokens;
  final int completionTokens;
  final int durationMs;

  /// Model name that served the completion.
  final String modelName;

  /// Deterministic ISO timestamp.
  final DateTime timestamp;

  const AssistantResponse({
    required this.responseId,
    required this.mode,
    required this.status,
    required this.templateId,
    this.structuredContent,
    this.errorMessage,
    this.rawUntrustedCompletion,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.durationMs = 0,
    this.modelName = 'mock-model',
    required this.timestamp,
  });

  bool get isSuccess => status == AssistantResponseStatus.success;

  Map<String, dynamic> toJson() {
    dynamic contentJson;
    if (structuredContent is AnalysisPayload) {
      contentJson = (structuredContent as AnalysisPayload).toJson();
    } else if (structuredContent is RecommendationPayload) {
      contentJson = (structuredContent as RecommendationPayload).toJson();
    } else if (structuredContent is ExplanationPayload) {
      contentJson = (structuredContent as ExplanationPayload).toJson();
    } else if (structuredContent is PlanningPayload) {
      contentJson = (structuredContent as PlanningPayload).toJson();
    } else if (structuredContent is Map<String, dynamic>) {
      contentJson = structuredContent;
    }

    return {
      'responseId': responseId,
      'mode': mode.name,
      'status': status.name,
      'templateId': templateId,
      'isSuccess': isSuccess,
      if (structuredContent != null) 'content': contentJson,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'metrics': {
        'promptTokens': promptTokens,
        'completionTokens': completionTokens,
        'durationMs': durationMs,
        'modelName': modelName,
      },
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
