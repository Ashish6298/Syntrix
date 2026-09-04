/// Orchestrator for deterministic prompt construction, provider invocation, schema validation, and error containment (Phase 8.1).
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/ai/models/assistant_models.dart';
import 'package:flutter_package_studio_core/src/ai/provider/ai_provider.dart';

/// Central engine executing AI Assistant requests over an abstracted [AiProvider].
class AssistantEngine {
  final Logger _logger = Logger('AssistantEngine');
  final AiProvider _provider;
  final AssistantConfiguration _defaultConfiguration;

  AiProvider get provider => _provider;
  AssistantConfiguration get defaultConfiguration => _defaultConfiguration;

  AssistantEngine({
    required AiProvider provider,
    AssistantConfiguration defaultConfiguration =
        const AssistantConfiguration(),
  })  : _provider = provider,
        _defaultConfiguration = defaultConfiguration;

  /// Executes an [AssistantRequest] and returns a structured, verified [AssistantResponse].
  ///
  /// Guarantees:
  /// 1. Deterministic Prompt Assembly: Context and prompts are assembled in canonical order.
  /// 2. Redaction: Sensitive tokens/secrets are sanitized before sending.
  /// 3. Structural Validation: Raw provider output is parsed against expected JSON schemas per mode.
  /// 4. Error Containment: Failures, timeouts, and malformed outputs return safe structured error responses.
  Future<AssistantResponse> executeRequest(
    AssistantRequest request, {
    DateTime? executionTimestamp,
  }) async {
    final now = executionTimestamp ?? DateTime.now();
    final config = request.configuration ?? _defaultConfiguration;
    final responseId = 'ai_resp_${now.microsecondsSinceEpoch}';

    // 1. Fail-Closed Validation: Global Enabled Gate
    if (!config.isEnabled) {
      _logger.warning('Assistant invocation refused: Globally disabled.');
      return AssistantResponse(
        responseId: responseId,
        mode: request.mode,
        status: AssistantResponseStatus.disabled,
        templateId: request.templateId,
        errorMessage: 'AI Assistant is currently disabled in configuration.',
        timestamp: now,
      );
    }

    // 2. Fail-Closed Validation: Capability Gate
    final requiredCapability = _mapModeToCapability(request.mode);
    if (!config.enabledCapabilities.contains(requiredCapability)) {
      _logger.warning(
          'Assistant invocation refused: Missing capability ${requiredCapability.name}');
      return AssistantResponse(
        responseId: responseId,
        mode: request.mode,
        status: AssistantResponseStatus.rejected,
        templateId: request.templateId,
        errorMessage:
            'Required assistant capability "${requiredCapability.name}" is not enabled in configuration.',
        timestamp: now,
      );
    }

    // 3. Fail-Closed Validation: Empty or Invalid Prompt
    if (request.prompt.trim().isEmpty) {
      return AssistantResponse(
        responseId: responseId,
        mode: request.mode,
        status: AssistantResponseStatus.rejected,
        templateId: request.templateId,
        errorMessage: 'Assistant request prompt cannot be empty.',
        timestamp: now,
      );
    }

    // 4. Deterministic Prompt Construction & Redaction
    final assembledPrompt = buildDeterministicPrompt(request);

    // 5. Invoke Provider with Timeout Racing
    final completionRequest = AiCompletionRequest(
      prompt: assembledPrompt,
      model: config.model,
      temperature: config.temperature,
      metadata: {
        'mode': request.mode.name,
        'templateId': request.templateId,
      },
    );

    try {
      final completionResponse =
          await _provider.complete(completionRequest).timeout(
                config.timeout,
                onTimeout: () => throw AiTimeoutException(
                    'AI Provider "${_provider.providerId}" timed out after ${config.timeout.inMilliseconds}ms.'),
              );

      // 6. Schema Parsing and Validation of Untrusted Raw Output
      final structuredPayload = _parseAndValidatePayload(
        mode: request.mode,
        rawContent: completionResponse.rawContent,
      );

      return AssistantResponse(
        responseId: responseId,
        mode: request.mode,
        status: AssistantResponseStatus.success,
        templateId: request.templateId,
        structuredContent: structuredPayload,
        rawUntrustedCompletion: completionResponse.rawContent,
        promptTokens: completionResponse.promptTokens,
        completionTokens: completionResponse.completionTokens,
        durationMs: completionResponse.durationMs,
        modelName: completionResponse.modelName,
        timestamp: now,
      );
    } on AiTimeoutException catch (e) {
      _logger.warning('AI completion timed out: ${e.message}');
      return AssistantResponse(
        responseId: responseId,
        mode: request.mode,
        status: AssistantResponseStatus.timedOut,
        templateId: request.templateId,
        errorMessage: e.message,
        timestamp: now,
      );
    } on AiInvalidResponseException catch (e) {
      _logger.warning('AI response validation failed: ${e.message}');
      return AssistantResponse(
        responseId: responseId,
        mode: request.mode,
        status: AssistantResponseStatus.invalidResponse,
        templateId: request.templateId,
        errorMessage: e.message,
        timestamp: now,
      );
    } on AiProviderException catch (e) {
      _logger.warning('AI provider error: ${e.message}');
      return AssistantResponse(
        responseId: responseId,
        mode: request.mode,
        status: AssistantResponseStatus.providerUnavailable,
        templateId: request.templateId,
        errorMessage: e.message,
        timestamp: now,
      );
    } catch (e, st) {
      _logger.error('Unexpected failure during assistant execution: $e', e, st);
      return AssistantResponse(
        responseId: responseId,
        mode: request.mode,
        status: AssistantResponseStatus.providerUnavailable,
        templateId: request.templateId,
        errorMessage: 'Provider failure: $e',
        timestamp: now,
      );
    }
  }

  /// Builds a byte-identical, deterministic prompt string from [request].
  String buildDeterministicPrompt(AssistantRequest request) {
    final buf = StringBuffer();

    buf.writeln('=== SYSTEM INSTRUCTION ===');
    buf.writeln(
        'You are the Flutter Package Studio AI Assistant operating in "${request.mode.name.toUpperCase()}" mode.');
    buf.writeln(
        'Return ONLY a valid JSON object matching the required schema for this mode.');
    buf.writeln();

    buf.writeln('=== CONTEXT: TEMPLATE ID ===');
    buf.writeln(request.templateId);
    buf.writeln();

    // Canonical context JSON
    final contextJson = jsonEncode(request.context.toJson());
    final redactedContext = _redactSensitiveData(contextJson);
    buf.writeln('=== CONTEXT: STRUCTURED FACTS ===');
    buf.writeln(redactedContext);
    buf.writeln();

    if (request.session != null && request.session!.history.isNotEmpty) {
      buf.writeln('=== CONVERSATION HISTORY ===');
      for (final msg in request.session!.history) {
        buf.writeln(
            '[${msg.role.toUpperCase()}]: ${_redactSensitiveData(msg.content)}');
      }
      buf.writeln();
    }

    buf.writeln('=== USER PROMPT ===');
    buf.writeln(_redactSensitiveData(request.prompt.trim()));

    return buf.toString();
  }

  /// Sanitizes sensitive secrets, API keys, and environment tokens.
  String _redactSensitiveData(String input) {
    var sanitized = input;
    // Redact Bearer / API tokens
    sanitized = sanitized.replaceAll(
        RegExp(r'(Bearer\s+[A-Za-z0-9_\-\.]{10,})', caseSensitive: false),
        '[REDACTED_TOKEN]');
    sanitized = sanitized.replaceAll(
        RegExp(r'(ghp_[A-Za-z0-9]{20,})'), '[REDACTED_GITHUB_TOKEN]');
    sanitized = sanitized.replaceAll(
        RegExp(r'(github_pat_[A-Za-z0-9_]{20,})'), '[REDACTED_GITHUB_PAT]');
    sanitized = sanitized.replaceAll(
        RegExp(r'(AIza[0-9A-Za-z-_]{35})'), '[REDACTED_GOOGLE_API_KEY]');
    return sanitized;
  }

  /// Parses and validates untrusted raw AI output into a mode-specific structured payload.
  dynamic _parseAndValidatePayload({
    required AssistantMode mode,
    required String rawContent,
  }) {
    // Extract JSON block if surrounded by markdown fences
    String cleanJson = rawContent.trim();
    if (cleanJson.startsWith('```json')) {
      cleanJson = cleanJson.substring(7);
    } else if (cleanJson.startsWith('```')) {
      cleanJson = cleanJson.substring(3);
    }
    if (cleanJson.endsWith('```')) {
      cleanJson = cleanJson.substring(0, cleanJson.length - 3);
    }
    cleanJson = cleanJson.trim();

    Map<String, dynamic> jsonMap;
    try {
      final decoded = jsonDecode(cleanJson);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected top-level JSON object.');
      }
      jsonMap = decoded;
    } catch (e) {
      throw AiInvalidResponseException(
          'Failed to parse raw AI response as JSON: $e');
    }

    switch (mode) {
      case AssistantMode.analysis:
        if (!jsonMap.containsKey('summary')) {
          throw AiInvalidResponseException(
              'Analysis payload missing required "summary" property.');
        }
        return AnalysisPayload.fromJson(jsonMap);

      case AssistantMode.recommendation:
        if (!jsonMap.containsKey('overview') ||
            !jsonMap.containsKey('recommendations')) {
          throw AiInvalidResponseException(
              'Recommendation payload missing required "overview" or "recommendations" properties.');
        }
        return RecommendationPayload.fromJson(jsonMap);

      case AssistantMode.explanation:
        if (!jsonMap.containsKey('topic') ||
            !jsonMap.containsKey('detailedExplanation')) {
          throw AiInvalidResponseException(
              'Explanation payload missing required "topic" or "detailedExplanation" properties.');
        }
        return ExplanationPayload.fromJson(jsonMap);

      case AssistantMode.planning:
        // Accept (objective + steps/implementationSteps) for workflow planning OR (summary/objective + patches) for code modification.
        final hasSteps = jsonMap.containsKey('steps') ||
            jsonMap.containsKey('implementationSteps');
        final hasPatches = jsonMap.containsKey('patches');
        final hasObjectiveOrSummary = jsonMap.containsKey('objective') || jsonMap.containsKey('summary');

        if (hasPatches && hasObjectiveOrSummary) {
          // Normalize to PlanningPayload for code modification proposals
          final obj = (jsonMap['objective'] ?? jsonMap['summary'] ?? 'Code modification proposal').toString();
          final rawPatches = (jsonMap['patches'] as List<dynamic>?) ?? const [];
          final steps = rawPatches.map((p) {
            final pMap = p is Map<String, dynamic> ? p : <String, dynamic>{};
            return PlanStep(
              sequence: 1,
              title: pMap['description']?.toString() ?? 'Patch ${pMap["relativePath"] ?? ""}',
              description: pMap['diff']?.toString() ?? '',
            );
          }).toList();
          return PlanningPayload(
            objective: obj,
            steps: steps,
          );
        }

        if (!jsonMap.containsKey('objective') || !hasSteps) {
          throw AiInvalidResponseException(
              'Planning payload missing required "objective" or "steps"/"implementationSteps" properties.');
        }
        // Normalise to 'steps' key for PlanningPayload.fromJson
        if (!jsonMap.containsKey('steps') &&
            jsonMap.containsKey('implementationSteps')) {
          jsonMap = Map<String, dynamic>.from(jsonMap)
            ..['steps'] = jsonMap['implementationSteps'];
        }
        return PlanningPayload.fromJson(jsonMap);
    }
  }

  AssistantCapability _mapModeToCapability(AssistantMode mode) {
    switch (mode) {
      case AssistantMode.analysis:
        return AssistantCapability.templateAnalysis;
      case AssistantMode.recommendation:
        return AssistantCapability.dependencyAdvice;
      case AssistantMode.explanation:
        return AssistantCapability.architecturalExplanation;
      case AssistantMode.planning:
        return AssistantCapability.planSynthesis;
    }
  }
}
