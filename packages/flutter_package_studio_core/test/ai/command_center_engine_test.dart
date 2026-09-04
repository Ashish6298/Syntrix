import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 8.14 — AI Engineering Command Center Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_command_center_test_');
      rootPath = tempDir.path;
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    void scaffoldWorkspace() {
      // Root pubspec
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: command_center_workspace
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      // Sample core lib
      final libDir = Directory(p.join(rootPath, 'lib'))..createSync(recursive: true);
      File(p.join(libDir.path, 'main.dart')).writeAsStringSync('''
void main() {
  print('Command Center Workspace');
}
''');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Full Capability Enum & Label Coverage
    // ─────────────────────────────────────────────────────────────────────────

    test('1. Capability Coverage: supports all 13 unified engineering capabilities and alias parsing', () {
      final capabilities = CommandCenterCapability.values;
      expect(capabilities.length, equals(13));

      expect(CommandCenterCapability.tryParse('analyze'), equals(CommandCenterCapability.analyze));
      expect(CommandCenterCapability.tryParse('debug'), equals(CommandCenterCapability.debug));
      expect(CommandCenterCapability.tryParse('review'), equals(CommandCenterCapability.review));
      expect(CommandCenterCapability.tryParse('test'), equals(CommandCenterCapability.test));
      expect(CommandCenterCapability.tryParse('document'), equals(CommandCenterCapability.document));
      expect(CommandCenterCapability.tryParse('docs'), equals(CommandCenterCapability.document));
      expect(CommandCenterCapability.tryParse('security'), equals(CommandCenterCapability.security));
      expect(CommandCenterCapability.tryParse('sec'), equals(CommandCenterCapability.security));
      expect(CommandCenterCapability.tryParse('architecture'), equals(CommandCenterCapability.architecture));
      expect(CommandCenterCapability.tryParse('arch'), equals(CommandCenterCapability.architecture));
      expect(CommandCenterCapability.tryParse('dependencies'), equals(CommandCenterCapability.dependencies));
      expect(CommandCenterCapability.tryParse('deps'), equals(CommandCenterCapability.dependencies));
      expect(CommandCenterCapability.tryParse('release'), equals(CommandCenterCapability.release));
      expect(CommandCenterCapability.tryParse('plan'), equals(CommandCenterCapability.plan));
      expect(CommandCenterCapability.tryParse('explain'), equals(CommandCenterCapability.explain));
      expect(CommandCenterCapability.tryParse('memory'), equals(CommandCenterCapability.memory));
      expect(CommandCenterCapability.tryParse('modify'), equals(CommandCenterCapability.modify));
      expect(CommandCenterCapability.tryParse('patch'), equals(CommandCenterCapability.modify));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Natural Language Intent Resolver
    // ─────────────────────────────────────────────────────────────────────────

    test('2. Intent Resolution: automatically routes natural-language queries to appropriate capability', () {
      expect(
        CommandCenterEngine.resolveCapabilityFromIntent('Check for secret tokens and security vulnerabilities'),
        equals(CommandCenterCapability.security),
      );
      expect(
        CommandCenterEngine.resolveCapabilityFromIntent('Diagnose why the test crashed with LateInitializationError'),
        equals(CommandCenterCapability.debug),
      );
      expect(
        CommandCenterEngine.resolveCapabilityFromIntent('Generate unit test suite for packager core'),
        equals(CommandCenterCapability.test),
      );
      expect(
        CommandCenterEngine.resolveCapabilityFromIntent('Review this pull request for code smells and lints'),
        equals(CommandCenterCapability.review),
      );
      expect(
        CommandCenterEngine.resolveCapabilityFromIntent('Synthesize README documentation and API guide'),
        equals(CommandCenterCapability.document),
      );
      expect(
        CommandCenterEngine.resolveCapabilityFromIntent('Upgrade dependencies and resolve pubspec version conflict'),
        equals(CommandCenterCapability.dependencies),
      );
      expect(
        CommandCenterEngine.resolveCapabilityFromIntent('Evaluate release readiness and changelog milestone'),
        equals(CommandCenterCapability.release),
      );
      expect(
        CommandCenterEngine.resolveCapabilityFromIntent('Plan 9-stage engineering roadmap for Debian packaging'),
        equals(CommandCenterCapability.plan),
      );
      expect(
        CommandCenterEngine.resolveCapabilityFromIntent('Why did we choose this modular architecture?'),
        equals(CommandCenterCapability.memory),
      );
      expect(
        CommandCenterEngine.resolveCapabilityFromIntent('Apply controlled code modification patch to client'),
        equals(CommandCenterCapability.modify),
      );
      expect(
        CommandCenterEngine.resolveCapabilityFromIntent('Explain how state isolation pattern works'),
        equals(CommandCenterCapability.explain),
      );
      expect(
        CommandCenterEngine.resolveCapabilityFromIntent('Review architecture boundaries and layered design'),
        equals(CommandCenterCapability.architecture),
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Subsystem Routing — Analyze & Explain
    // ─────────────────────────────────────────────────────────────────────────

    test('3. Subsystem Routing (Analyze & Explain): dispatches to AssistantEngine successfully', () async {
      scaffoldWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Deep analysis summary for target package.',
          'findings': ['Clean architecture confirmed.'],
          'metrics': {'health': '95%'},
          'risks': [],
        }),
      );

      final engine = CommandCenterEngine(
        projectRoot: rootPath,
        provider: provider,
      );

      final resp = await engine.execute(CommandCenterRequest(
        capability: CommandCenterCapability.analyze,
        target: 'packager_core',
        prompt: 'Analyze package architecture',
      ));

      expect(resp.isSuccess, isTrue);
      expect(resp.capability, equals(CommandCenterCapability.analyze));
      expect(resp.summary, contains('Completed deep analysis'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Subsystem Routing — Review & Security
    // ─────────────────────────────────────────────────────────────────────────

    test('4. Subsystem Routing (Review & Security): dispatches to CodeReviewEngine and SecurityAdvisorEngine', () async {
      scaffoldWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Security and review analysis completed cleanly.',
          'findings': [],
          'risks': [],
        }),
      );

      final engine = CommandCenterEngine(
        projectRoot: rootPath,
        provider: provider,
      );

      // Review
      final reviewResp = await engine.execute(CommandCenterRequest(
        capability: CommandCenterCapability.review,
        target: 'lib/main.dart',
        prompt: 'Review main.dart',
      ));
      expect(reviewResp.isSuccess, isTrue);
      expect(reviewResp.capability, equals(CommandCenterCapability.review));

      // Security
      final secResp = await engine.execute(CommandCenterRequest(
        capability: CommandCenterCapability.security,
        prompt: 'Audit project for credentials and vulnerabilities',
      ));
      expect(secResp.isSuccess, isTrue);
      expect(secResp.capability, equals(CommandCenterCapability.security));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Subsystem Routing — Debug, Test, & Document
    // ─────────────────────────────────────────────────────────────────────────

    test('5. Subsystem Routing (Debug, Test, Document): dispatches to diagnostic, test, and doc engines', () async {
      scaffoldWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Subsystem diagnostic and generation output.',
          'tests': [],
          'findings': [],
        }),
      );

      final engine = CommandCenterEngine(
        projectRoot: rootPath,
        provider: provider,
      );

      // Debug
      final debugResp = await engine.execute(CommandCenterRequest(
        capability: CommandCenterCapability.debug,
        prompt: 'Unhandled exception in main.dart: NoSuchMethodError',
      ));
      expect(debugResp.isSuccess, isTrue);
      expect(debugResp.capability, equals(CommandCenterCapability.debug));

      // Test
      final testResp = await engine.execute(CommandCenterRequest(
        capability: CommandCenterCapability.test,
        prompt: 'Plan unit tests for main.dart',
      ));
      expect(testResp.isSuccess, isTrue);
      expect(testResp.capability, equals(CommandCenterCapability.test));

      // Document
      final docResp = await engine.execute(CommandCenterRequest(
        capability: CommandCenterCapability.document,
        prompt: 'Generate README.md',
      ));
      expect(docResp.isSuccess, isTrue);
      expect(docResp.capability, equals(CommandCenterCapability.document));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Subsystem Routing — Architecture, Dependencies, & Release
    // ─────────────────────────────────────────────────────────────────────────

    test('6. Subsystem Routing (Architecture, Dependencies, Release): dispatches to advisory engines', () async {
      scaffoldWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Advisory engine recommendations.',
          'recommendations': [],
        }),
      );

      final engine = CommandCenterEngine(
        projectRoot: rootPath,
        provider: provider,
      );

      // Architecture
      final archResp = await engine.execute(CommandCenterRequest(
        capability: CommandCenterCapability.architecture,
        prompt: 'Evaluate layered architecture boundaries',
      ));
      expect(archResp.isSuccess, isTrue);
      expect(archResp.capability, equals(CommandCenterCapability.architecture));

      // Dependencies
      final depResp = await engine.execute(CommandCenterRequest(
        capability: CommandCenterCapability.dependencies,
        prompt: 'Check dependency health and compatibility',
      ));
      expect(depResp.isSuccess, isTrue);
      expect(depResp.capability, equals(CommandCenterCapability.dependencies));

      // Release
      final relResp = await engine.execute(CommandCenterRequest(
        capability: CommandCenterCapability.release,
        prompt: 'Assess release readiness for v1.0.0',
      ));
      expect(relResp.isSuccess, isTrue);
      expect(relResp.capability, equals(CommandCenterCapability.release));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Subsystem Routing — Plan, Memory, & Modify
    // ─────────────────────────────────────────────────────────────────────────

    test('7. Subsystem Routing (Plan, Memory, Modify): dispatches to planning, memory, and modification engines', () async {
      scaffoldWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'objective': 'Add Debian packaging',
          'scope': 'workspace',
          'requirementAnalysis': [],
          'affectedComponents': [],
          'affectedFiles': [],
          'dependencies': [],
          'architectureChanges': 'Clean architecture',
          'implementationSteps': [],
          'tests': [],
          'securityChecks': [],
          'documentationRequirements': [],
          'regressionChecks': [],
          'acceptanceCriteria': [],
          'nextPhaseRecommendation': 'Next phase',
          'confidence': 'high'
        }),
      );

      final engine = CommandCenterEngine(
        projectRoot: rootPath,
        provider: provider,
      );

      // Plan
      final planResp = await engine.execute(CommandCenterRequest(
        capability: CommandCenterCapability.plan,
        prompt: 'Add Debian packaging support',
      ));
      expect(planResp.isSuccess, isTrue);
      expect(planResp.capability, equals(CommandCenterCapability.plan));

      // Memory
      final memResp = await engine.execute(CommandCenterRequest(
        capability: CommandCenterCapability.memory,
        prompt: 'Why did we choose this architecture?',
      ));
      expect(memResp.isSuccess, isTrue);
      expect(memResp.capability, equals(CommandCenterCapability.memory));

      // Modify
      final modResp = await engine.execute(CommandCenterRequest(
        capability: CommandCenterCapability.modify,
        prompt: 'Add timeout parameter to Client',
      ));
      expect(modResp.isSuccess, isTrue);
      expect(modResp.capability, equals(CommandCenterCapability.modify));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Secret Redaction Across All Command Center Channels
    // ─────────────────────────────────────────────────────────────────────────

    test('8. Secret Redaction: sensitive tokens are never exposed in prompts, responses, or reports', () async {
      scaffoldWorkspace();

      const secretToken = 'ghp_secretTokenInCommandCenter998877';
      const promptWithSecret = 'Review code using token $secretToken';

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': promptWithSecret,
          'findings': [],
        }),
      );

      final engine = CommandCenterEngine(
        projectRoot: rootPath,
        provider: provider,
      );

      final resp = await engine.execute(CommandCenterRequest(
        capability: CommandCenterCapability.review,
        prompt: promptWithSecret,
      ));

      // Outbound prompt redacted
      expect(provider.recordedRequests.first.prompt.contains(secretToken), isFalse);

      // Inbound response redacted
      expect(resp.summary.contains(secretToken), isFalse);

      // Renderer output redacted
      const renderer = CommandCenterRenderer();
      final mdStr = renderer.renderMarkdown(resp);
      final jsonStr = renderer.renderJson(resp);

      expect(mdStr.contains(secretToken), isFalse);
      expect(jsonStr.contains(secretToken), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: Dual-Format Rendering (JSON and Markdown)
    // ─────────────────────────────────────────────────────────────────────────

    test('9. Dual-Format Renderer: renders unified Markdown execution report and valid JSON', () {
      final response = CommandCenterResponse(
        capability: CommandCenterCapability.plan,
        summary: 'Generated 9-stage engineering implementation plan.',
        structuredPayload: {
          'objective': 'Add Debian packaging support',
          'status': 'planned',
        },
        durationMs: 50,
        timestamp: DateTime.now(),
      );

      const renderer = CommandCenterRenderer();
      final mdStr = renderer.renderMarkdown(response);
      final jsonStr = renderer.renderJson(response);

      expect(mdStr, contains('# AI Engineering Command Center — Execution Report'));
      expect(mdStr, contains('**Capability**: `Plan (Engineering Workflow Planner)`'));
      expect(mdStr, contains('**Status**: ✅ SUCCESS'));
      expect(mdStr, contains('## Executive Summary'));

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['capability'], equals('plan'));
      expect(decoded['isSuccess'], isTrue);
      expect(decoded['summary'], contains('Generated 9-stage'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 10: Fail-Closed Error Containment
    // ─────────────────────────────────────────────────────────────────────────

    test('10. Fail-Closed Containment: provider failure wraps in structured error response without crashing', () async {
      scaffoldWorkspace();

      final faultedProvider = MockAiProvider(
        injectedException: Exception('Command Center AI Provider 503 Unavailable'),
      );

      final engine = CommandCenterEngine(
        projectRoot: rootPath,
        provider: faultedProvider,
      );

      final resp = await engine.execute(CommandCenterRequest(
        capability: CommandCenterCapability.analyze,
        prompt: 'Analyze package',
      ));

      expect(resp.isSuccess, isFalse);
      expect(resp.errorMessage, contains('503 Unavailable'));
    });
  });
}
