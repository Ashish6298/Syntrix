/// Mock AI Provider implementation for deterministic and isolated unit/integration tests (Phase 8.1).
library;

import 'dart:async';
import 'package:syntrix/src/error/exceptions.dart';
import 'package:syntrix/src/ai/provider/ai_provider.dart';

/// Configurable mock AI provider for testing without real network calls or API keys.
class MockAiProvider implements AiProvider {
  @override
  final String providerId;

  @override
  final String displayName;

  /// Canned responses mapped by prompt substring or exact match.
  final Map<String, String> _cannedResponses = {};

  /// Default response to return if no prompt match is found.
  String? defaultResponse;

  /// Injected exception to throw on the next call(s).
  Exception? injectedException;

  /// Simulated delay before returning completions.
  Duration simulatedDelay;

  /// Injected health status.
  AiProviderHealthStatus injectedHealthStatus;

  /// Recorded completion requests for test verification.
  final List<AiCompletionRequest> _recordedRequests = [];

  List<AiCompletionRequest> get recordedRequests =>
      List.unmodifiable(_recordedRequests);

  MockAiProvider({
    this.providerId = 'mock_ai_provider',
    this.displayName = 'Mock AI Provider',
    this.defaultResponse,
    this.injectedException,
    this.simulatedDelay = Duration.zero,
    this.injectedHealthStatus = AiProviderHealthStatus.available,
  });

  /// Registers a canned response triggered when `request.prompt` contains [promptSubstring].
  void registerCannedResponse(String promptSubstring, String response) {
    _cannedResponses[promptSubstring] = response;
  }

  /// Clears recorded call history.
  void clearHistory() {
    _recordedRequests.clear();
  }

  @override
  Future<AiProviderHealthStatus> checkHealth() async {
    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }
    return injectedHealthStatus;
  }

  @override
  Future<AiCompletionResponse> complete(AiCompletionRequest request) async {
    _recordedRequests.add(request);

    if (simulatedDelay > Duration.zero) {
      await Future<void>.delayed(simulatedDelay);
    }

    if (injectedException != null) {
      throw injectedException!;
    }

    if (injectedHealthStatus != AiProviderHealthStatus.available) {
      throw AiProviderException(
          'Provider "$providerId" is unavailable: ${injectedHealthStatus.name}');
    }

    // Find matching canned response
    for (final entry in _cannedResponses.entries) {
      if (request.prompt.contains(entry.key)) {
        return AiCompletionResponse(
          rawContent: entry.value,
          modelName: request.model,
          promptTokens: request.prompt.length ~/ 4,
          completionTokens: entry.value.length ~/ 4,
          durationMs: simulatedDelay.inMilliseconds,
        );
      }
    }

    if (defaultResponse != null) {
      return AiCompletionResponse(
        rawContent: defaultResponse!,
        modelName: request.model,
        promptTokens: request.prompt.length ~/ 4,
        completionTokens: defaultResponse!.length ~/ 4,
        durationMs: simulatedDelay.inMilliseconds,
      );
    }

    throw AiProviderException(
        'MockAiProvider has no canned or default response configured for prompt: "${request.prompt}"');
  }
}
