/// Abstract AI Provider interface and completion models for Milestone 8 (Phase 8.1).
library;

/// Request payload sent to an [AiProvider].
class AiCompletionRequest {
  /// The assembled, deterministic prompt text.
  final String prompt;

  /// Model identifier or alias (e.g. 'gemini-1.5-pro', 'mock-model').
  final String model;

  /// Sampling temperature (typically 0.0 to 1.0).
  final double temperature;

  /// Maximum tokens to generate in the completion.
  final int maxTokens;

  /// Stop sequences to truncate completion generation.
  final List<String> stopSequences;

  /// Optional metadata tags for tracking and diagnostic inspection.
  final Map<String, dynamic> metadata;

  const AiCompletionRequest({
    required this.prompt,
    this.model = 'mock-model',
    this.temperature = 0.0,
    this.maxTokens = 2048,
    this.stopSequences = const [],
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'model': model,
        'temperature': temperature,
        'maxTokens': maxTokens,
        'stopSequences': stopSequences,
        'metadata': metadata,
      };
}

/// Raw response returned by an [AiProvider].
///
/// Untrusted boundary: Downstream consumers must treat [rawContent] as untrusted
/// input and validate/parse it through the Assistant Engine.
class AiCompletionResponse {
  /// The raw generated text content from the provider.
  final String rawContent;

  /// Model name that performed the completion.
  final String modelName;

  /// Number of tokens consumed in the prompt.
  final int promptTokens;

  /// Number of tokens generated in the completion.
  final int completionTokens;

  /// Total duration in milliseconds for provider execution.
  final int durationMs;

  /// Optional provider-specific response metadata (e.g., finishReason, safetyRatings).
  final Map<String, dynamic> providerMetadata;

  const AiCompletionResponse({
    required this.rawContent,
    this.modelName = 'mock-model',
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.durationMs = 0,
    this.providerMetadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'rawContent': rawContent,
        'modelName': modelName,
        'promptTokens': promptTokens,
        'completionTokens': completionTokens,
        'durationMs': durationMs,
        'providerMetadata': providerMetadata,
      };
}

/// Status of provider health / connectivity check.
enum AiProviderHealthStatus {
  available,
  unreachable,
  rateLimited,
  unauthorized,
  misconfigured,
}

/// Abstract AI Provider interface.
///
/// Single authority for communicating with remote or local AI generation backends.
/// All implementations (real Gemini, OpenAI, Claude, or mock) conform to this interface.
abstract interface class AiProvider {
  /// Provider unique identifier (e.g. 'mock', 'gemini', 'openai').
  String get providerId;

  /// Human-readable display name.
  String get displayName;

  /// Checks if the provider is currently reachable and operational.
  Future<AiProviderHealthStatus> checkHealth();

  /// Executes a single completion request.
  ///
  /// Throws [AiProviderException] on provider failure, network loss, or timeout.
  Future<AiCompletionResponse> complete(AiCompletionRequest request);
}
