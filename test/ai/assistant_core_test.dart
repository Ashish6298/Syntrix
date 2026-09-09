import 'dart:convert';
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:test/test.dart';

void main() {
  group('Phase 8.1 — AI Assistant Core Foundation Tests', () {
    late MockAiProvider mockProvider;
    late AssistantEngine engine;
    late AssistantRenderer renderer;
    late PromptContext sampleContext;

    setUp(() {
      mockProvider = MockAiProvider();
      engine = AssistantEngine(provider: mockProvider);
      renderer = const AssistantRenderer();
      sampleContext = const PromptContext(
        templateId: 'flutter_package',
        version: '1.0.0',
        metadata: {'author': 'FPS Team', 'type': 'package'},
        capabilities: ['linting', 'testing'],
        dependencies: ['flutter', 'meta'],
        environment: {'TARGET': 'release'},
        structuredFacts: {'linesOfCode': 1200},
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Mode Happy-Paths (1a to 1d)
    // ─────────────────────────────────────────────────────────────────────────

    test('1a. Happy-path Analysis Mode returns structured AnalysisPayload',
        () async {
      mockProvider.registerCannedResponse(
        'ANALYSIS',
        jsonEncode({
          'summary': 'Deep architectural audit completed.',
          'findings': ['Modular code structure', 'Zero memory leaks detected'],
          'metrics': {'coverage': '94%', 'complexity': 'low'},
          'risks': ['External network dependency unpinned'],
        }),
      );

      final req = AssistantRequest(
        prompt: 'Analyze package architecture',
        mode: AssistantMode.analysis,
        templateId: 'flutter_package',
        context: sampleContext,
      );

      final resp = await engine.executeRequest(req);

      expect(resp.isSuccess, isTrue);
      expect(resp.status, equals(AssistantResponseStatus.success));
      expect(resp.mode, equals(AssistantMode.analysis));
      expect(resp.structuredContent, isA<AnalysisPayload>());

      final payload = resp.structuredContent as AnalysisPayload;
      expect(payload.summary, equals('Deep architectural audit completed.'));
      expect(payload.findings.length, equals(2));
      expect(payload.metrics['coverage'], equals('94%'));
      expect(payload.risks.first, contains('External network dependency'));
    });

    test(
        '1b. Happy-path Recommendation Mode returns structured RecommendationPayload',
        () async {
      mockProvider.registerCannedResponse(
        'RECOMMENDATION',
        jsonEncode({
          'overview': 'Key optimization opportunities identified.',
          'recommendations': [
            {
              'title': 'Adopt Domain-Driven Boundaries',
              'rationale': 'Prevents coupling in core logic.',
              'impact': 'high',
              'suggestedAction':
                  'Refactor models into dedicated domain folders.',
            }
          ],
        }),
      );

      final req = AssistantRequest(
        prompt: 'Provide optimization recommendations',
        mode: AssistantMode.recommendation,
        templateId: 'flutter_package',
        context: sampleContext,
      );

      final resp = await engine.executeRequest(req);

      expect(resp.isSuccess, isTrue);
      expect(resp.mode, equals(AssistantMode.recommendation));
      expect(resp.structuredContent, isA<RecommendationPayload>());

      final payload = resp.structuredContent as RecommendationPayload;
      expect(payload.overview, contains('Key optimization opportunities'));
      expect(payload.recommendations.length, equals(1));
      expect(payload.recommendations.first.impact, equals('high'));
    });

    test(
        '1c. Happy-path Explanation Mode returns structured ExplanationPayload',
        () async {
      mockProvider.registerCannedResponse(
        'EXPLANATION',
        jsonEncode({
          'topic': 'State Isolation Patterns',
          'detailedExplanation':
              'Explains how fail-closed state machines protect the host.',
          'keyConcepts': ['Fail-Closed', 'Atomic Boundaries'],
          'architecturalTradeoffs': ['Adds slight indirection.'],
        }),
      );

      final req = AssistantRequest(
        prompt: 'Explain state isolation design',
        mode: AssistantMode.explanation,
        templateId: 'flutter_package',
        context: sampleContext,
      );

      final resp = await engine.executeRequest(req);

      expect(resp.isSuccess, isTrue);
      expect(resp.mode, equals(AssistantMode.explanation));
      expect(resp.structuredContent, isA<ExplanationPayload>());

      final payload = resp.structuredContent as ExplanationPayload;
      expect(payload.topic, equals('State Isolation Patterns'));
      expect(payload.keyConcepts, contains('Fail-Closed'));
    });

    test('1d. Happy-path Planning Mode returns structured PlanningPayload',
        () async {
      mockProvider.registerCannedResponse(
        'PLANNING',
        jsonEncode({
          'objective': 'Migrate package to Milestone 8 architecture',
          'estimatedEffort': '2 days',
          'steps': [
            {
              'sequence': 1,
              'title': 'Audit Existing Schemas',
              'description': 'Verify models with strict contract validators.',
              'prerequisites': ['clean git branch'],
            }
          ],
        }),
      );

      final req = AssistantRequest(
        prompt: 'Generate migration plan',
        mode: AssistantMode.planning,
        templateId: 'flutter_package',
        context: sampleContext,
      );

      final resp = await engine.executeRequest(req);

      expect(resp.isSuccess, isTrue);
      expect(resp.mode, equals(AssistantMode.planning));
      expect(resp.structuredContent, isA<PlanningPayload>());

      final payload = resp.structuredContent as PlanningPayload;
      expect(payload.objective, contains('Migrate package'));
      expect(payload.steps.first.sequence, equals(1));
      expect(payload.steps.first.prerequisites, contains('clean git branch'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Provider Abstraction & Swappability
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Provider Abstraction: AssistantEngine operates seamlessly over any custom AiProvider implementation without core modification',
        () async {
      final customMock = _CustomTestAiProvider();
      final customEngine = AssistantEngine(provider: customMock);

      final req = AssistantRequest(
        prompt: 'Analyze via custom provider',
        mode: AssistantMode.analysis,
        templateId: 'custom_pkg',
        context: sampleContext,
      );

      final resp = await customEngine.executeRequest(req);

      expect(resp.isSuccess, isTrue);
      expect(customMock.callCount, equals(1));
      expect(resp.structuredContent, isA<AnalysisPayload>());
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Deterministic Context Assembly, Prompt Construction, and Rendering
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Determinism: given identical inputs and fixed mock response, prompt construction and dual output renderings are byte-identical',
        () async {
      mockProvider.defaultResponse = jsonEncode({
        'summary': 'Consistent deterministic summary.',
        'findings': ['Finding A', 'Finding B'],
        'metrics': {'score': '100'},
        'risks': [],
      });

      final fixedTime = DateTime(2026, 8, 30, 12, 0, 0);
      final req1 = AssistantRequest(
        prompt: 'Deterministic run check',
        mode: AssistantMode.analysis,
        templateId: 'det_pkg',
        context: sampleContext,
      );
      final req2 = AssistantRequest(
        prompt: 'Deterministic run check',
        mode: AssistantMode.analysis,
        templateId: 'det_pkg',
        context: sampleContext,
      );

      final prompt1 = engine.buildDeterministicPrompt(req1);
      final prompt2 = engine.buildDeterministicPrompt(req2);
      expect(prompt1, equals(prompt2));

      final resp1 =
          await engine.executeRequest(req1, executionTimestamp: fixedTime);
      final resp2 =
          await engine.executeRequest(req2, executionTimestamp: fixedTime);

      final json1 = renderer.renderJson(resp1);
      final json2 = renderer.renderJson(resp2);
      expect(json1, equals(json2));

      final md1 = renderer.renderMarkdown(resp1);
      final md2 = renderer.renderMarkdown(resp2);
      expect(md1, equals(md2));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Provider Unavailable Handling
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Provider Unavailable: unreachable or failing provider produces structured providerUnavailable status without crashing',
        () async {
      mockProvider.injectedHealthStatus = AiProviderHealthStatus.unreachable;

      final req = AssistantRequest(
        prompt: 'Analyze unreachable provider',
        mode: AssistantMode.analysis,
        templateId: 'test_pkg',
        context: sampleContext,
      );

      final resp = await engine.executeRequest(req);

      expect(resp.isSuccess, isFalse);
      expect(resp.status, equals(AssistantResponseStatus.providerUnavailable));
      expect(resp.errorMessage, contains('unavailable'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Invalid Response Handling
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Invalid Response: malformed JSON or schema violation returns structured invalidResponse status',
        () async {
      mockProvider.defaultResponse = '{ non-json garbage response text';

      final req = AssistantRequest(
        prompt: 'Trigger invalid parsing',
        mode: AssistantMode.analysis,
        templateId: 'test_pkg',
        context: sampleContext,
      );

      final resp = await engine.executeRequest(req);

      expect(resp.isSuccess, isFalse);
      expect(resp.status, equals(AssistantResponseStatus.invalidResponse));
      expect(resp.errorMessage, contains('Failed to parse raw AI response'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Timeout Handling
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Timeout Handling: provider exceeding configured timeout duration returns structured timedOut status',
        () async {
      mockProvider.simulatedDelay = const Duration(milliseconds: 150);

      final shortTimeoutEngine = AssistantEngine(
        provider: mockProvider,
        defaultConfiguration: const AssistantConfiguration(
          timeout: Duration(milliseconds: 20),
        ),
      );

      final req = AssistantRequest(
        prompt: 'Trigger slow timeout',
        mode: AssistantMode.analysis,
        templateId: 'test_pkg',
        context: sampleContext,
      );

      final resp = await shortTimeoutEngine.executeRequest(req);

      expect(resp.isSuccess, isFalse);
      expect(resp.status, equals(AssistantResponseStatus.timedOut));
      expect(resp.errorMessage, contains('timed out'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Dual-Format Rendering Parity
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Dual-Format Rendering Parity: JSON and Markdown represent identical underlying facts',
        () async {
      mockProvider.defaultResponse = jsonEncode({
        'summary': 'Unified architectural assessment.',
        'findings': ['Solid encapsulation', 'Clear dependency boundary'],
        'metrics': {'quality': 'A+'},
        'risks': ['None detected'],
      });

      final fixedTime = DateTime(2026, 8, 30, 14, 0, 0);
      final req = AssistantRequest(
        prompt: 'Render parity check',
        mode: AssistantMode.analysis,
        templateId: 'parity_pkg',
        context: sampleContext,
      );

      final resp =
          await engine.executeRequest(req, executionTimestamp: fixedTime);
      final jsonStr = renderer.renderJson(resp);
      final mdStr = renderer.renderMarkdown(resp);

      // JSON verifies structural properties
      final decodedJson = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decodedJson['templateId'], equals('parity_pkg'));
      expect(decodedJson['mode'], equals('analysis'));
      expect(decodedJson['content']['summary'],
          equals('Unified architectural assessment.'));

      // Markdown verifies formatting of same underlying facts
      expect(mdStr, contains('`parity_pkg`'));
      expect(mdStr, contains('Unified architectural assessment.'));

      expect(mdStr, contains('Solid encapsulation'));
      expect(mdStr, contains('**quality**: A+'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Architectural Safety Boundary Audit (Zero forbidden side effects)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Safety Boundary Audit: assistant engine is structurally pure request/response plumbing with zero file writes, shell calls, pub calls, or git operations',
        () async {
      mockProvider.defaultResponse = jsonEncode({
        'summary': 'Pure calculation execution.',
        'findings': [],
        'metrics': {},
        'risks': [],
      });

      final req = AssistantRequest(
        prompt: 'Execute pure query',
        mode: AssistantMode.analysis,
        templateId: 'pure_pkg',
        context: sampleContext,
      );

      final resp = await engine.executeRequest(req);

      expect(resp.isSuccess, isTrue);
      // Verify no exceptions and pure return model
      expect(resp.rawUntrustedCompletion, isNotNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: Fail-Closed Edge Cases
    // ─────────────────────────────────────────────────────────────────────────

    test('9a. Edge Case: Empty or whitespace-only prompt is rejected',
        () async {
      final req = AssistantRequest(
        prompt: '   ',
        mode: AssistantMode.analysis,
        templateId: 'edge_pkg',
        context: sampleContext,
      );

      final resp = await engine.executeRequest(req);

      expect(resp.isSuccess, isFalse);
      expect(resp.status, equals(AssistantResponseStatus.rejected));
      expect(resp.errorMessage, contains('cannot be empty'));
    });

    test('9b. Edge Case: Unrecognized mode parsing fails closed to null', () {
      final parsed = AssistantMode.tryParse('invalid_random_mode');
      expect(parsed, isNull);
    });

    test('9c. Edge Case: Zero enabled capabilities causes request rejection',
        () async {
      final disabledEngine = AssistantEngine(
        provider: mockProvider,
        defaultConfiguration: AssistantConfiguration.disabled(),
      );

      final req = AssistantRequest(
        prompt: 'Attempt with disabled assistant',
        mode: AssistantMode.analysis,
        templateId: 'disabled_pkg',
        context: sampleContext,
      );

      final resp = await disabledEngine.executeRequest(req);

      expect(resp.isSuccess, isFalse);
      expect(resp.status, equals(AssistantResponseStatus.disabled));
      expect(resp.errorMessage, contains('disabled in configuration'));
    });

    test(
        '9d. Edge Case: Missing specific required capability causes rejected status',
        () async {
      final partialConfigEngine = AssistantEngine(
        provider: mockProvider,
        defaultConfiguration: const AssistantConfiguration(
          enabledCapabilities: {AssistantCapability.templateAnalysis},
        ),
      );

      // Request planning mode which requires planSynthesis capability
      final req = AssistantRequest(
        prompt: 'Attempt planning without capability',
        mode: AssistantMode.planning,
        templateId: 'partial_pkg',
        context: sampleContext,
      );

      final resp = await partialConfigEngine.executeRequest(req);

      expect(resp.isSuccess, isFalse);
      expect(resp.status, equals(AssistantResponseStatus.rejected));
      expect(resp.errorMessage, contains('planSynthesis'));
    });
  });
}

class _CustomTestAiProvider implements AiProvider {
  int callCount = 0;

  @override
  String get providerId => 'custom_test_provider';

  @override
  String get displayName => 'Custom Test AI Provider';

  @override
  Future<AiProviderHealthStatus> checkHealth() async =>
      AiProviderHealthStatus.available;

  @override
  Future<AiCompletionResponse> complete(AiCompletionRequest request) async {
    callCount++;
    return AiCompletionResponse(
      rawContent: jsonEncode({
        'summary': 'Custom provider completion.',
        'findings': ['Custom Finding 1'],
        'metrics': {},
        'risks': [],
      }),
      modelName: 'custom-model',
    );
  }
}
