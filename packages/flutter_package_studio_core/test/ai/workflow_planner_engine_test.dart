import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 8.11 — AI Engineering Workflow Planner Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('fps_workflow_planner_test_');
      rootPath = tempDir.path;
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    void scaffoldMonorepoWorkspace() {
      // Root pubspec
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: debian_packaging_workspace
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
dependencies:
  meta: ^1.11.0
''');

      // Core package
      final pkgDir = Directory(p.join(rootPath, 'packages', 'packager_core'))
        ..createSync(recursive: true);
      File(p.join(pkgDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: packager_core
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
dependencies:
  archive: ^3.6.1
''');
      final libDir = Directory(p.join(pkgDir.path, 'lib'))
        ..createSync(recursive: true);
      File(p.join(libDir.path, 'packager.dart'))
          .writeAsStringSync('class Packager {}');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Plan Model Serialization & Schema Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Plan Model Conformance: WorkflowPlanResult serializes and deserializes all 9 stages accurately',
        () {
      final plan = WorkflowPlanResult(
        objective: 'Add support for generating Debian packages.',
        scope: 'packager_core',
        requirementAnalysis: [
          GroundedItem.fact('packager_core exists in workspace',
              'packages/packager_core/pubspec.yaml'),
          GroundedItem.assumption('Target Linux system has dpkg-deb installed'),
        ],
        affectedComponents: ['packager_core/artifacts', 'cli/commands'],
        affectedFiles: ['packages/packager_core/lib/src/debian.dart'],
        dependencies: ['tar', 'archive'],
        architectureChanges:
            'Introduce DebianArchiveBuilder interface implementing ArtifactBuilder.',
        implementationSteps: [
          WorkflowImplementationStep(
            stepNumber: 1,
            title: 'Define Debian package metadata schema',
            description: 'Create DebianControlFile and DebianConfig classes.',
            targetComponent: 'packager_core',
            estimatedFiles: [
              'packages/packager_core/lib/src/debian_models.dart'
            ],
            dependencies: [],
          ),
        ],
        tests: [
          WorkflowTestRequirement(
            testType: 'unit',
            description: 'Validate control file generation format.',
            targetFile: 'packages/packager_core/test/debian_test.dart',
          ),
        ],
        securityChecks: [
          'Verify path traversal prevention in debian archive extraction.'
        ],
        documentationRequirements: [
          'Document fps package --debian CLI options in doc/cli.md.'
        ],
        regressionChecks: [
          'Run existing tarball and zip artifact verification tests.'
        ],
        acceptanceCriteria: [
          'Generates valid .deb archive installable via dpkg.'
        ],
        nextPhaseRecommendation:
            'Add RPM and AppImage packaging support in Phase 8.12.',
        confidence: CodeReviewConfidence.high,
        durationMs: 45,
        timestamp: DateTime.now(),
        isSuccess: true,
      );

      final json = plan.toJson();
      expect(json['objective'], contains('Debian packages'));
      expect(json['requirementAnalysis'], isNotEmpty);
      expect(json['implementationSteps'], isNotEmpty);
      expect(json['tests'], isNotEmpty);
      expect(json['securityChecks'], isNotEmpty);
      expect(json['acceptanceCriteria'], isNotEmpty);

      final restored = WorkflowPlanResult.fromJson(json);
      expect(restored.objective, equals(plan.objective));
      expect(restored.scope, equals('packager_core'));
      expect(restored.requirementAnalysis.length, equals(2));
      expect(restored.requirementAnalysis[0].isFact, isTrue);
      expect(restored.requirementAnalysis[1].isFact, isFalse);
      expect(restored.confidence, equals(CodeReviewConfidence.high));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Explicit Facts vs Assumptions Distinction
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Grounding Invariant: planner explicitly distinguishes verified workspace facts from inferred assumptions',
        () async {
      scaffoldMonorepoWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'objective': 'Add support for generating Debian packages.',
          'scope': 'packager_core',
          'requirementAnalysis': [
            {
              'text':
                  'Dependency archive ^3.6.1 is present in packager_core pubspec',
              'isFact': true,
              'evidence': 'packages/packager_core/pubspec.yaml'
            },
            {
              'text': 'Users will build packages on Debian/Ubuntu environments',
              'isFact': false,
              'evidence': 'Inferred operational assumption'
            }
          ],
          'affectedComponents': ['packager_core'],
          'affectedFiles': ['lib/debian.dart'],
          'dependencies': ['archive'],
          'architectureChanges': 'Implement DebianBuilder.',
          'implementationSteps': [
            {
              'stepNumber': 1,
              'title': 'Debian models',
              'description': 'Models step',
              'targetComponent': 'packager_core',
              'estimatedFiles': ['lib/debian.dart'],
              'dependencies': []
            }
          ],
          'tests': [
            {
              'testType': 'unit',
              'description': 'Debian unit test',
              'targetFile': 'test/debian_test.dart'
            }
          ],
          'securityChecks': ['Validate permissions.'],
          'documentationRequirements': ['Update docs.'],
          'regressionChecks': ['Check existing tests.'],
          'acceptanceCriteria': ['Valid .deb generated.'],
          'nextPhaseRecommendation': 'Follow-up RPM builder.',
          'confidence': 'high'
        }),
      );

      final engine = WorkflowPlannerEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final plan = await engine.plan(const WorkflowPlanRequest(
        request: 'Add support for generating Debian packages.',
      ));

      expect(plan.isSuccess, isTrue);

      // Verify facts are present and marked isFact: true
      final verifiedFacts =
          plan.requirementAnalysis.where((item) => item.isFact).toList();
      expect(verifiedFacts, isNotEmpty);
      expect(
          verifiedFacts.any((f) =>
              f.evidence.contains('ProjectContextEngine') ||
              f.evidence.contains('pubspec')),
          isTrue);

      // Verify assumptions are present and marked isFact: false
      final assumptions =
          plan.requirementAnalysis.where((item) => !item.isFact).toList();
      expect(assumptions, isNotEmpty);
      expect(assumptions.first.isFact, isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Complete 9-Stage Plan Generation
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. 9-Stage Pipeline Completeness: verifies all 9 workflow pipeline stages are populated',
        () async {
      scaffoldMonorepoWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'objective': 'Add support for generating Debian packages.',
          'scope': 'workspace',
          'requirementAnalysis': [
            {
              'text': 'Verified workspace layout',
              'isFact': true,
              'evidence': 'FileSystem'
            }
          ],
          'affectedComponents': ['packager_core'],
          'affectedFiles': ['lib/debian.dart'],
          'dependencies': ['archive'],
          'architectureChanges': 'Pipeline adapter addition.',
          'implementationSteps': [
            {
              'stepNumber': 1,
              'title': 'Debian pipeline step',
              'description': 'Implementation step 1',
              'targetComponent': 'packager_core',
              'estimatedFiles': ['lib/debian.dart'],
              'dependencies': []
            }
          ],
          'tests': [
            {
              'testType': 'unit',
              'description': 'Debian test',
              'targetFile': 'test/debian_test.dart'
            }
          ],
          'securityChecks': ['Security check 1'],
          'documentationRequirements': ['Doc requirement 1'],
          'regressionChecks': ['Regression check 1'],
          'acceptanceCriteria': ['Acceptance criteria 1'],
          'nextPhaseRecommendation': 'Phase 8.12 memory persistence',
          'confidence': 'high'
        }),
      );

      final engine = WorkflowPlannerEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final plan = await engine.plan(const WorkflowPlanRequest(
        request: 'Add support for generating Debian packages.',
      ));

      expect(plan.isSuccess, isTrue);
      // Stage 1: Requirement Analysis
      expect(plan.requirementAnalysis, isNotEmpty);
      // Stage 2: Affected Components
      expect(plan.affectedComponents, isNotEmpty);
      // Stage 3: Architecture Changes
      expect(plan.architectureChanges, isNotEmpty);
      // Stage 4: Implementation Steps
      expect(plan.implementationSteps, isNotEmpty);
      // Stage 5: Tests
      expect(plan.tests, isNotEmpty);
      // Stage 6: Security Checks
      expect(plan.securityChecks, isNotEmpty);
      // Stage 7: Documentation
      expect(plan.documentationRequirements, isNotEmpty);
      // Stage 8: Verification (Regression & Acceptance)
      expect(plan.regressionChecks, isNotEmpty);
      expect(plan.acceptanceCriteria, isNotEmpty);
      // Stage 9: Next Phase Recommendation
      expect(plan.nextPhaseRecommendation, isNotEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Secret Redaction on Outbound Prompt & Inbound Output
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Secret Redaction: sensitive tokens in requests or workspace are 100% absent from prompts, JSON, and Markdown',
        () async {
      scaffoldMonorepoWorkspace();

      const injectedToken = 'ghp_secretTokenForDebianWorkflow123456';
      const promptWithSecret =
          'Add support for Debian packaging using token $injectedToken';

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'objective': promptWithSecret,
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

      final engine = WorkflowPlannerEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final plan = await engine.plan(const WorkflowPlanRequest(
        request: promptWithSecret,
      ));

      // A) Inspect AI outbound prompt
      expect(provider.recordedRequests, isNotEmpty);
      final sentPrompt = provider.recordedRequests.first.prompt;
      expect(sentPrompt.contains(injectedToken), isFalse);

      // B) Inspect Plan model
      expect(plan.objective.contains(injectedToken), isFalse);

      // C) Inspect Rendered JSON & Markdown
      const renderer = WorkflowPlannerRenderer();
      final jsonOutput = renderer.renderJson(plan);
      final mdOutput = renderer.renderMarkdown(plan);

      expect(jsonOutput.contains(injectedToken), isFalse);
      expect(mdOutput.contains(injectedToken), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: No-Execution / Zero-Mutation Safety Invariant
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. No-Execution Safety Invariant: workflow planning never mutates workspace files',
        () async {
      scaffoldMonorepoWorkspace();

      final filesBefore = <String, String>{};
      for (final entity in Directory(rootPath).listSync(recursive: true)) {
        if (entity is File) {
          filesBefore[entity.path] = entity.readAsStringSync();
        }
      }

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'objective': 'Add Debian packaging',
          'scope': 'workspace',
          'requirementAnalysis': [],
          'affectedComponents': [],
          'affectedFiles': [],
          'dependencies': [],
          'architectureChanges': 'None',
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

      final engine = WorkflowPlannerEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      await engine.plan(const WorkflowPlanRequest(
        request: 'Add Debian packaging',
      ));

      final filesAfter = <String, String>{};
      for (final entity in Directory(rootPath).listSync(recursive: true)) {
        if (entity is File) {
          filesAfter[entity.path] = entity.readAsStringSync();
        }
      }

      expect(filesAfter.length, equals(filesBefore.length));
      for (final entry in filesBefore.entries) {
        expect(filesAfter[entry.key], equals(entry.value),
            reason: 'File ${entry.key} was mutated unexpectedly.');
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Fail-Closed Provider Error Handling
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Fail-Closed Error Handling: provider timeout returns structured failure result without crashing',
        () async {
      scaffoldMonorepoWorkspace();

      final faultedProvider = MockAiProvider(
        injectedException:
            Exception('AI Model Service 503 Service Unavailable'),
      );

      final engine = WorkflowPlannerEngine.withProvider(
        projectRoot: rootPath,
        provider: faultedProvider,
      );

      final plan = await engine.plan(const WorkflowPlanRequest(
        request: 'Add Debian packaging',
      ));

      expect(plan.isSuccess, isFalse);
      expect(plan.errorMessage, contains('AI Model Service 503'));
      expect(plan.implementationSteps, isEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Dual-Format Renderer (Valid JSON & Markdown)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Dual-Format Renderer: renders schema-valid JSON and structured 9-stage Markdown report',
        () {
      final plan = WorkflowPlanResult(
        objective: 'Add support for generating Debian packages.',
        scope: 'packager_core',
        requirementAnalysis: [
          GroundedItem.fact('packager_core exists', 'pubspec.yaml'),
          GroundedItem.assumption('dpkg-deb is available'),
        ],
        affectedComponents: ['packager_core'],
        affectedFiles: ['lib/debian.dart'],
        dependencies: ['archive'],
        architectureChanges: 'Implement DebianPackageBuilder.',
        implementationSteps: [
          WorkflowImplementationStep(
            stepNumber: 1,
            title: 'Define models',
            description: 'Debian models',
            targetComponent: 'packager_core',
            estimatedFiles: ['lib/debian_models.dart'],
            dependencies: [],
          ),
        ],
        tests: [
          WorkflowTestRequirement(
            testType: 'unit',
            description: 'Test debian archive',
            targetFile: 'test/debian_test.dart',
          ),
        ],
        securityChecks: ['Validate safe archive file permissions.'],
        documentationRequirements: ['Add documentation.'],
        regressionChecks: ['Run unit tests.'],
        acceptanceCriteria: ['Valid package created.'],
        nextPhaseRecommendation: 'Proceed to RPM packaging.',
        confidence: CodeReviewConfidence.high,
        durationMs: 32,
        timestamp: DateTime.now(),
        isSuccess: true,
      );

      const renderer = WorkflowPlannerRenderer();
      final jsonStr = renderer.renderJson(plan);
      final mdStr = renderer.renderMarkdown(plan);

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['isSuccess'], isTrue);
      expect(decoded['objective'], contains('Debian packages'));
      expect(decoded['implementationSteps'].length, equals(1));

      expect(
          mdStr,
          contains(
              '# Flutter Package Studio — AI Engineering Implementation Plan'));
      expect(mdStr,
          contains('## 1. Requirement Analysis (Facts vs. Assumptions)'));
      expect(mdStr, contains('## 2. Affected Components & Files'));
      expect(mdStr, contains('## 3. Architecture Changes'));
      expect(mdStr, contains('## 4. Implementation Steps (1)'));
      expect(mdStr, contains('## 5. Test Strategy (1)'));
      expect(mdStr, contains('## 6. Security Checks & Considerations'));
      expect(mdStr, contains('## 7. Documentation Requirements'));
      expect(mdStr, contains('## 8. Verification & Acceptance Criteria'));
      expect(mdStr, contains('## 9. Next Phase Recommendation'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Scoped Target Package
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Scoped Target Package: sets scope strictly to target package when provided',
        () async {
      scaffoldMonorepoWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'objective': 'Add Debian packaging',
          'scope': 'packager_core',
          'requirementAnalysis': [],
          'affectedComponents': [],
          'affectedFiles': [],
          'dependencies': [],
          'architectureChanges': 'None',
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

      final engine = WorkflowPlannerEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final plan = await engine.plan(const WorkflowPlanRequest(
        request: 'Add Debian packaging',
        targetPackage: 'packager_core',
      ));

      expect(plan.isSuccess, isTrue);
      expect(plan.scope, equals('packager_core'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: Markdown Heading and HTML Escaping Invariant
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9. Escaping Invariant: user prompt text cannot inject malformed headings or script tags',
        () async {
      scaffoldMonorepoWorkspace();

      const maliciousRequest =
          '<script>alert("xss")</script> Add debian package';

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'objective': maliciousRequest,
          'scope': 'workspace',
          'requirementAnalysis': [],
          'affectedComponents': [],
          'affectedFiles': [],
          'dependencies': [],
          'architectureChanges': 'Clean',
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

      final engine = WorkflowPlannerEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final plan = await engine.plan(const WorkflowPlanRequest(
        request: maliciousRequest,
      ));

      const renderer = WorkflowPlannerRenderer();
      final mdStr = renderer.renderMarkdown(plan);
      expect(mdStr.contains('<script>'), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 10: Regression Check
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '10. Regression Check: verifies compatibility with prior AI assistant engine models',
        () {
      expect(CodeReviewConfidence.values.length, equals(3));
      expect(AssistantMode.values, contains(AssistantMode.planning));
    });
  });
}
