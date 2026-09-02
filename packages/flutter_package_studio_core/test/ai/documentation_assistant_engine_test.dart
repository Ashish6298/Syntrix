import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 8.7 — AI Documentation Assistant Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_doc_test_');
      rootPath = tempDir.path;
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    /// Helper to scaffold a monorepo workspace with source files, CLI commands, docs, and secrets.
    void scaffoldDocWorkspace() {
      // 1. Root Pubspec
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: doc_test_workspace
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      // 2. Sensitive files
      File(p.join(rootPath, '.env')).writeAsStringSync('''
DOC_SECRET_KEY=secret_key_doc_12345
DATABASE_PASS=prod_pass_9988
''');
      File(p.join(rootPath, 'credentials.json')).writeAsStringSync('''
{"token": "my_doc_credential_secret"}
''');

      // 3. Package Core
      final coreLib = Directory(p.join(rootPath, 'packages', 'pkg_core', 'lib'))
        ..createSync(recursive: true);
      File(p.join(rootPath, 'packages', 'pkg_core', 'pubspec.yaml'))
          .writeAsStringSync('''
name: pkg_core
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');
      File(p.join(coreLib.path, 'data_service.dart')).writeAsStringSync('''
class DataService {
  Future<String> fetchData() async {
    return 'data_payload';
  }
}
''');

      // 4. Package CLI
      final cliCommands = Directory(
          p.join(rootPath, 'packages', 'pkg_cli', 'lib', 'src', 'commands'))
        ..createSync(recursive: true);
      File(p.join(rootPath, 'packages', 'pkg_cli', 'pubspec.yaml'))
          .writeAsStringSync('''
name: pkg_cli
version: 1.0.0
dependencies:
  pkg_core:
    path: ../pkg_core
''');
      File(p.join(cliCommands.path, 'build_command.dart')).writeAsStringSync('''
import 'package:args/command_runner.dart';

class BuildCommand extends Command<int> {
  @override
  final String name = 'build';
  @override
  final String description = 'Build the project.';

  BuildCommand() {
    argParser.addOption('preset', help: 'Preset configuration profile.');
    argParser.addFlag('release', help: 'Build in release mode.');
  }

  @override
  Future<int> run() async => 0;
}
''');

      // 5. Documentation directory & README with deliberate mismatches
      final docDir = Directory(p.join(rootPath, 'docs'))
        ..createSync(recursive: true);
      File(p.join(rootPath, 'README.md')).writeAsStringSync('''
# Doc Test Workspace

## CLI Usage
Run `fps build --mode production` to compile the app.
// MISMATCH_FIXTURE_CLI_OPTION
''');

      File(p.join(docDir.path, 'api_guide.md')).writeAsStringSync('''
# API Guide
To fetch items, call `Future<Payload> fetchDataPayload()`.
// MISMATCH_FIXTURE_METHOD
''');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Documentation-finding model conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Documentation-finding model conformance: Severity, Category, Location, Problem, Explanation, Recommendation, and Confidence all conform to Phase 8.3 schema',
        () {
      const finding = DocumentationMismatchFinding(
        severity: CodeReviewSeverity.high,
        category: CodeReviewCategory.apiUsage,
        file: 'docs/cli.md',
        location: 'L15',
        problem: 'Documented CLI option --mode does not exist',
        explanation: 'The code defines --preset, not --mode.',
        recommendation: 'Update doc to reference --preset.',
        confidence: CodeReviewConfidence.high,
        artifactType: DocumentationArtifactType.cliOption,
        implementedReality: 'Implemented CLI option: --preset',
        documentedClaim: 'Documentation claims: --mode',
      );

      final json = finding.toJson();
      expect(json['severity'], equals('high'));
      expect(json['category'], equals('apiUsage'));
      expect(json['file'], equals('docs/cli.md'));
      expect(json['location'], equals('L15'));
      expect(json['problem'], contains('--mode'));
      expect(json['explanation'], contains('--preset'));
      expect(json['recommendation'], contains('--preset'));
      expect(json['confidence'], equals('high'));
      expect(json['artifactType'], equals('cliOption'));
      expect(json['implementedReality'], contains('--preset'));
      expect(json['documentedClaim'], contains('--mode'));

      final restored = DocumentationMismatchFinding.fromJson(json);
      expect(restored.severity, equals(CodeReviewSeverity.high));
      expect(restored.category, equals(CodeReviewCategory.apiUsage));
      expect(
          restored.artifactType, equals(DocumentationArtifactType.cliOption));
      expect(restored.confidence, equals(CodeReviewConfidence.high));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Grounded Documentation Generation (Source Evidence Manifest)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Grounded Doc Generation: generates documentation grounded in real source files with evidence manifest',
        () async {
      scaffoldDocWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Generated DataService API Docs',
          'markdownContent':
              '# DataService Documentation\n\nMethod: `fetchData()` returns `Future<String>`.',
          'sourceEvidenceManifest': ['packages/pkg_core/lib/data_service.dart']
        }),
      );

      final engine = DocumentationAssistantEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine
          .generateDocumentation(const DocumentationGenerationRequest(
        target: 'DataService',
        docType: DocumentationType.apiDoc,
      ));

      expect(result.isSuccess, isTrue);
      expect(result.markdownContent, contains('DataService Documentation'));
      expect(result.sourceEvidenceManifest, isNotEmpty);
      expect(
          result.sourceEvidenceManifest
              .any((p) => p.contains('data_service.dart')),
          isTrue);
      expect(result.evidenceGapNotice, isNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Anti-Hallucination Gate (Refuses to invent content for missing evidence)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Anti-Hallucination Gate: declines to fabricate unverified methods/classes when source evidence is missing',
        () async {
      scaffoldDocWorkspace();

      final provider = MockAiProvider();
      final engine = DocumentationAssistantEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      // Target that does NOT exist in the codebase
      final result = await engine
          .generateDocumentation(const DocumentationGenerationRequest(
        target: 'NonExistentQuantumPaymentProcessor',
        docType: DocumentationType.apiDoc,
      ));

      expect(result.isSuccess, isTrue);
      expect(result.evidenceGapNotice, isNotNull);
      expect(
          result.evidenceGapNotice, contains('No evidence found in codebase'));
      expect(result.markdownContent, contains('Evidence Gap Notice'));
      expect(result.markdownContent, contains('refuses to fabricate'));
      // Confirm the AI provider was NEVER called to invent fictitious text
      expect(provider.recordedRequests, isEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Documentation Inconsistency Detection (CLI Option Mismatch)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Inconsistency Detection: detects documented CLI option mismatch against implemented command parser',
        () async {
      scaffoldDocWorkspace();

      final provider = MockAiProvider(
        defaultResponse:
            jsonEncode({'summary': 'Consistency check', 'findings': []}),
      );

      final engine = DocumentationAssistantEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine
          .checkConsistency(const DocumentationConsistencyRequest());

      expect(result.isSuccess, isTrue);
      expect(result.findings, isNotEmpty);

      final cliMismatch = result.findings.firstWhere(
        (f) => f.artifactType == DocumentationArtifactType.cliOption,
      );
      expect(cliMismatch.file, contains('README.md'));
      expect(cliMismatch.problem, contains('--mode'));
      expect(cliMismatch.severity, equals(CodeReviewSeverity.high));
      expect(cliMismatch.confidence, equals(CodeReviewConfidence.high));
      expect(cliMismatch.implementedReality, contains('--preset'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Documentation Inconsistency Detection (API Signature Mismatch)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Inconsistency Detection: detects documented API signature mismatch against implemented Dart source',
        () async {
      scaffoldDocWorkspace();

      final provider = MockAiProvider(
        defaultResponse:
            jsonEncode({'summary': 'Consistency check', 'findings': []}),
      );

      final engine = DocumentationAssistantEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine
          .checkConsistency(const DocumentationConsistencyRequest());

      expect(result.isSuccess, isTrue);

      final apiMismatch = result.findings.firstWhere(
        (f) => f.artifactType == DocumentationArtifactType.apiMember,
      );
      expect(apiMismatch.file, contains('api_guide.md'));
      expect(apiMismatch.problem, contains('signature does not match'));
      expect(apiMismatch.implementedReality, contains('fetchData()'));
      expect(apiMismatch.documentedClaim, contains('fetchDataPayload()'));
      expect(apiMismatch.confidence, equals(CodeReviewConfidence.high));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Sensitive-File Respect (Zero Leaks to Outbound Prompt)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Sensitive-File Respect: .env and credentials.json contents are never transmitted to AI provider',
        () async {
      scaffoldDocWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'DataService doc',
          'markdownContent': '# Safe Doc',
          'sourceEvidenceManifest': []
        }),
      );

      final engine = DocumentationAssistantEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      await engine.generateDocumentation(const DocumentationGenerationRequest(
        target: 'DataService',
        docType: DocumentationType.apiDoc,
      ));

      expect(provider.recordedRequests, isNotEmpty);
      final sentPrompt = provider.recordedRequests.first.prompt;
      expect(sentPrompt.contains('DOC_SECRET_KEY'), isFalse);
      expect(sentPrompt.contains('secret_key_doc_12345'), isFalse);
      expect(sentPrompt.contains('DATABASE_PASS'), isFalse);
      expect(sentPrompt.contains('my_doc_credential_secret'), isFalse);
      expect(sentPrompt.contains('.env'), isFalse);
      expect(sentPrompt.contains('credentials.json'), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: No-Execution / Zero-Mutation Safety Invariant
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. No-Execution Safety: documentation assistant never mutates workspace files automatically',
        () async {
      scaffoldDocWorkspace();

      // Snapshot workspace file contents before execution
      final filesBefore = <String, String>{};
      for (final entity in Directory(rootPath).listSync(recursive: true)) {
        if (entity is File) {
          filesBefore[entity.path] = entity.readAsStringSync();
        }
      }

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Audit complete',
          'markdownContent': '# Generated Doc',
          'sourceEvidenceManifest': []
        }),
      );

      final engine = DocumentationAssistantEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      // Run generation and consistency check
      await engine.generateDocumentation(const DocumentationGenerationRequest(
        target: 'DataService',
        docType: DocumentationType.apiDoc,
      ));
      await engine.checkConsistency(const DocumentationConsistencyRequest());

      // Snapshot workspace after execution
      final filesAfter = <String, String>{};
      for (final entity in Directory(rootPath).listSync(recursive: true)) {
        if (entity is File) {
          filesAfter[entity.path] = entity.readAsStringSync();
        }
      }

      // Assert identical files and byte-for-byte contents
      expect(filesAfter.length, equals(filesBefore.length));
      for (final entry in filesBefore.entries) {
        expect(filesAfter[entry.key], equals(entry.value),
            reason: 'File ${entry.key} was mutated unexpectedly.');
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Terminology Preservation (Exact Command Names and Classes)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Terminology Preservation: preserves exact class, method, and command identifiers without renaming',
        () async {
      scaffoldDocWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Documentation for BuildCommand',
          'markdownContent':
              '# BuildCommand\n\nCommand: `fps build`\nOptions: `--preset`, `--release`',
          'sourceEvidenceManifest': [
            'packages/pkg_cli/lib/src/commands/build_command.dart'
          ]
        }),
      );

      final engine = DocumentationAssistantEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine
          .generateDocumentation(const DocumentationGenerationRequest(
        target: 'BuildCommand',
        docType: DocumentationType.cliDoc,
      ));

      expect(result.isSuccess, isTrue);
      expect(result.markdownContent, contains('BuildCommand'));
      expect(result.markdownContent, contains('fps build'));
      expect(result.markdownContent, contains('--preset'));
      expect(result.markdownContent, contains('--release'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: AI Provider Failure Handled Safely (Fail-Closed)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9. Provider Failure: unavailable provider returns structured failure without crashing',
        () async {
      scaffoldDocWorkspace();

      final provider = MockAiProvider(
        injectedException:
            Exception('AI Documentation service timeout 504 Gateway Timeout.'),
      );

      final engine = DocumentationAssistantEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final genResult = await engine
          .generateDocumentation(const DocumentationGenerationRequest(
        target: 'DataService',
        docType: DocumentationType.apiDoc,
      ));

      expect(genResult.isSuccess, isFalse);
      expect(
          genResult.errorMessage, contains('AI Documentation service timeout'));

      final checkResult = await engine
          .checkConsistency(const DocumentationConsistencyRequest());
      expect(checkResult.isSuccess, isFalse);
      expect(checkResult.errorMessage,
          contains('AI Documentation service timeout'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 10: Dual-Format Renderer (Valid JSON & Markdown)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '10. Dual-Format Renderer: renders schema-valid JSON and structured Markdown reports',
        () {
      const finding = DocumentationMismatchFinding(
        severity: CodeReviewSeverity.high,
        category: CodeReviewCategory.apiUsage,
        file: 'README.md',
        location: 'L10',
        problem: 'Outdated option --mode',
        explanation: 'Command actually accepts --preset.',
        recommendation: 'Update README to --preset.',
        confidence: CodeReviewConfidence.high,
        artifactType: DocumentationArtifactType.cliOption,
        implementedReality: '--preset',
        documentedClaim: '--mode',
      );

      final result = DocumentationConsistencyResult(
        targetScope: 'whole_project',
        isSuccess: true,
        findings: const [finding],
        comparedFiles: const [
          'README.md',
          'packages/pkg_cli/lib/src/commands/build_command.dart'
        ],
        summary: 'Identified 1 mismatch.',
        durationMs: 45,
        timestamp: DateTime.now(),
      );

      const renderer = DocumentationAssistantRenderer();
      final jsonStr = renderer.renderConsistencyJson(result);
      final mdStr = renderer.renderConsistencyMarkdown(result);

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['isSuccess'], isTrue);
      expect(decoded['mismatchCount'], equals(1));
      expect(decoded['findings'][0]['artifactType'], equals('cliOption'));

      expect(
          mdStr,
          contains(
              '# Flutter Package Studio — AI Documentation Consistency Report'));
      expect(mdStr, contains('[HIGH] Outdated option --mode'));
      expect(mdStr, contains('Implemented Reality'));
    });
  });
}
