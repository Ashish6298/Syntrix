import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 8.6 — AI Architecture Advisor Tests', () {
    late Directory tempRoot;
    late String rootPath;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('fps_phase_8_6_test_');
      rootPath = tempRoot.path;
    });

    tearDown(() {
      if (tempRoot.existsSync()) {
        try {
          tempRoot.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    /// Helper to scaffold a monorepo with circular dependencies, layering violations, and duplicate logic.
    void scaffoldArchitectureMonorepo() {
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: syntrix_arch_monorepo
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');
      File(p.join(rootPath, '.gitignore')).writeAsStringSync('''
.dart_tool/
build/
.env
*.secret
''');

      // 1. Package A: pkg_core
      final pkgCore = p.join(rootPath, 'packages', 'pkg_core');
      Directory(p.join(pkgCore, 'lib', 'src')).createSync(recursive: true);
      File(p.join(pkgCore, 'pubspec.yaml')).writeAsStringSync('''
name: pkg_core
version: 1.0.0
dependencies:
  pkg_cli: ^1.0.0
''');
      File(p.join(pkgCore, 'lib', 'src', 'core_service.dart'))
          .writeAsStringSync('''
// DUPLICATE_UTILITY_BLOCK
class DuplicateValidator {
  bool isValidIdentifier(String s) => s.isNotEmpty && !s.contains(' ');
}
''');

      // 2. Package B: pkg_cli (has circular dependency on pkg_core, plus layering violation)
      final pkgCli = p.join(rootPath, 'packages', 'pkg_cli');
      Directory(p.join(pkgCli, 'lib', 'src', 'commands'))
          .createSync(recursive: true);
      File(p.join(pkgCli, 'pubspec.yaml')).writeAsStringSync('''
name: pkg_cli
version: 1.0.0
dependencies:
  pkg_core: ^1.0.0
''');
      // Layering violation fixture: CLI command containing core domain generator logic
      File(p.join(pkgCli, 'lib', 'src', 'commands', 'create_command.dart'))
          .writeAsStringSync('''
// BUSINESS_LOGIC_IN_CLI
class CreateCommand {
  void generatePackageEntirely(String path) {
    // Heavy domain business logic embedded directly in CLI command
    print("Generating files, creating git repo, writing CI workflows...");
  }
}
''');
      // Duplicate utility in pkg_cli matching pkg_core
      File(p.join(pkgCli, 'lib', 'src', 'cli_utils.dart')).writeAsStringSync('''
// DUPLICATE_UTILITY_BLOCK
class DuplicateValidator {
  bool isValidIdentifier(String s) => s.isNotEmpty && !s.contains(' ');
}
''');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Architecture Finding Model Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Architecture-finding model conformance: Component, Issue, Recommendation, Reason, Severity, and Confidence all present and correctly typed',
        () {
      final finding = const ArchitectureFinding(
        component: 'packages/pkg_cli/lib/src/commands/create_command.dart',
        issue: 'Layering violation: CLI command contains business logic',
        recommendation:
            'Move package generation logic to flutter_package_studio_core',
        reason: 'CLI layer must remain decoupled from domain execution logic',
        severity: CodeReviewSeverity.high,
        confidence: CodeReviewConfidence.high,
        category: ArchitectureCategory.layeringViolation,
      );

      final jsonMap = finding.toJson();
      expect(jsonMap['component'], contains('create_command.dart'));
      expect(jsonMap['issue'], contains('Layering violation'));
      expect(
          jsonMap['recommendation'], contains('flutter_package_studio_core'));
      expect(jsonMap['reason'], contains('decoupled'));
      expect(jsonMap['severity'], equals('high'));
      expect(jsonMap['confidence'], equals('high'));
      expect(jsonMap['category'], equals('layeringViolation'));

      final parsed = ArchitectureFinding.fromJson(jsonMap);
      expect(parsed.component, equals(finding.component));
      expect(parsed.severity, equals(CodeReviewSeverity.high));
      expect(parsed.confidence, equals(CodeReviewConfidence.high));
      expect(parsed.category, equals(ArchitectureCategory.layeringViolation));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Circular-Dependency Detection
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Circular-dependency detection: detects real cycle between pkg_core and pkg_cli',
        () async {
      scaffoldArchitectureMonorepo();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode(
            {'summary': 'Circular dependency detected', 'findings': []}),
      );

      final engine = ArchitectureAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.scan(const ArchitectureScanRequest(
        scope: ArchitectureScanScope.wholeProject,
      ));

      expect(result.isSuccess, isTrue);
      expect(result.structuralModel.detectedCycles, isNotEmpty);
      final cycle = result.structuralModel.detectedCycles.first;
      expect(cycle.contains('pkg_core'), isTrue);
      expect(cycle.contains('pkg_cli'), isTrue);

      final cycleFindings = result.findings
          .where((f) => f.category == ArchitectureCategory.circularDependency)
          .toList();
      expect(cycleFindings, isNotEmpty);
      expect(cycleFindings.first.severity, equals(CodeReviewSeverity.critical));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Layering-Violation Detection
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Layering-violation detection: flags CLI command containing core domain generation logic',
        () async {
      scaffoldArchitectureMonorepo();

      final provider = MockAiProvider(
        defaultResponse:
            jsonEncode({'summary': 'Layering analysis', 'findings': []}),
      );

      final engine = ArchitectureAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.scan(const ArchitectureScanRequest(
        scope: ArchitectureScanScope.wholeProject,
      ));

      expect(result.isSuccess, isTrue);
      final layeringFindings = result.findings
          .where((f) => f.category == ArchitectureCategory.layeringViolation)
          .toList();
      expect(layeringFindings, isNotEmpty);
      expect(layeringFindings.first.component, contains('create_command.dart'));
      expect(layeringFindings.first.recommendation,
          contains('flutter_package_studio_core'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Duplicate-Functionality Detection
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Duplicate-functionality detection: surfaces near-identical logic duplicated across modules',
        () async {
      scaffoldArchitectureMonorepo();

      final provider = MockAiProvider(
        defaultResponse:
            jsonEncode({'summary': 'Duplicate analysis', 'findings': []}),
      );

      final engine = ArchitectureAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.scan(const ArchitectureScanRequest(
        scope: ArchitectureScanScope.wholeProject,
      ));

      expect(result.isSuccess, isTrue);
      final dupFindings = result.findings
          .where(
              (f) => f.category == ArchitectureCategory.duplicateFunctionality)
          .toList();
      expect(dupFindings, isNotEmpty);
      expect(dupFindings.first.issue, contains('Duplicate functionality'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Scoped-vs-Whole-Project Scan Correctness
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Scoped-vs-whole-project scan correctness: package-scoped scan returns only findings for that package',
        () async {
      scaffoldArchitectureMonorepo();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Scoped scan',
          'findings': [
            {
              'component': 'packages/pkg_core/lib/src/core_service.dart',
              'issue': 'Misplaced responsibility in pkg_core',
              'recommendation': 'Refactor service',
              'reason': 'SRP violation',
              'severity': 'medium',
              'confidence': 'high',
              'category': 'misplacedResponsibility'
            },
            {
              'component':
                  'packages/pkg_cli/lib/src/commands/create_command.dart',
              'issue': 'CLI issue outside target scope',
              'recommendation': 'Ignore',
              'reason': 'Other pkg',
              'severity': 'low',
              'confidence': 'low',
              'category': 'generalArchitecture'
            }
          ]
        }),
      );

      final engine = ArchitectureAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      // Scoped strictly to pkg_core
      final result = await engine.scan(const ArchitectureScanRequest(
        scope: ArchitectureScanScope.package,
        targetPackage: 'pkg_core',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.findings, isNotEmpty);
      // Findings for pkg_cli should be filtered out when scoped to pkg_core
      final cliFindings = result.findings
          .where((f) =>
              f.component ==
              'packages/pkg_cli/lib/src/commands/create_command.dart')
          .toList();
      expect(cliFindings, isEmpty);
      // Target package finding is retained
      final coreFindings = result.findings
          .where((f) => f.component.contains('pkg_core'))
          .toList();
      expect(coreFindings, isNotEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: No-Execution / Zero-Mutation Safety Invariant
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. No-Execution Safety Invariant: architecture scan is strictly read-only with byte-identical workspace before and after',
        () async {
      scaffoldArchitectureMonorepo();

      // Snapshot workspace before scan
      final filesBefore = <String, String>{};
      for (final entity in tempRoot.listSync(recursive: true)) {
        if (entity is File) {
          filesBefore[entity.path] = entity.readAsStringSync();
        }
      }

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({'summary': 'Safety scan', 'findings': []}),
      );

      final engine = ArchitectureAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.scan(const ArchitectureScanRequest(
        scope: ArchitectureScanScope.wholeProject,
      ));

      expect(result.isSuccess, isTrue);

      // Verify all files are byte-for-byte identical after run
      final filesAfter = <String, String>{};
      for (final entity in tempRoot.listSync(recursive: true)) {
        if (entity is File) {
          filesAfter[entity.path] = entity.readAsStringSync();
        }
      }

      expect(filesAfter.length, equals(filesBefore.length));
      for (final path in filesBefore.keys) {
        expect(filesAfter[path], equals(filesBefore[path]));
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Sensitive-File Exclusion Respected
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Sensitive-File Respect: .env and credentials files are completely excluded from AI provider prompt',
        () async {
      scaffoldArchitectureMonorepo();

      File(p.join(rootPath, '.env'))
          .writeAsStringSync('ARCH_SECRET_TOKEN=super_secret_arch_123');
      File(p.join(rootPath, 'credentials.json'))
          .writeAsStringSync('{"database_url": "postgres://secret"}');

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({'summary': 'Safe scan', 'findings': []}),
      );

      final engine = ArchitectureAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.scan(const ArchitectureScanRequest(
        scope: ArchitectureScanScope.wholeProject,
      ));

      expect(result.isSuccess, isTrue);
      expect(provider.recordedRequests, isNotEmpty);
      final sentPrompt = provider.recordedRequests.first.prompt;
      expect(sentPrompt.contains('ARCH_SECRET_TOKEN'), isFalse);
      expect(sentPrompt.contains('super_secret_arch_123'), isFalse);
      expect(sentPrompt.contains('database_url'), isFalse);
      expect(sentPrompt.contains('.env'), isFalse);
      expect(sentPrompt.contains('credentials.json'), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: AI Provider Failure Handled Safely
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Provider Failure: unavailable provider returns structured failure result without crashing',
        () async {
      scaffoldArchitectureMonorepo();

      final provider = MockAiProvider(
        injectedException:
            Exception('Simulated Architecture AI Provider Failure'),
      );
      final engine = ArchitectureAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.scan(const ArchitectureScanRequest(
        scope: ArchitectureScanScope.wholeProject,
      ));

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage,
          contains('Simulated Architecture AI Provider Failure'));
      expect(result.findings, isEmpty);
      expect(result.summary, contains('failed'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: Dual-Format Rendering (JSON and Markdown)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9. Dual-Format Renderer: renders schema-valid JSON and structured Markdown',
        () {
      final now = DateTime.parse('2026-09-02T12:00:00.000Z');
      final result = ArchitectureScanResult(
        scope: ArchitectureScanScope.wholeProject,
        targetScopeId: 'whole_project',
        isSuccess: true,
        findings: const [
          ArchitectureFinding(
            component: 'packages/pkg_cli/lib/src/commands/create.dart',
            issue: 'Layering violation in CLI',
            recommendation: 'Delegate to core',
            reason: 'CLI must be thin',
            severity: CodeReviewSeverity.high,
            confidence: CodeReviewConfidence.high,
            category: ArchitectureCategory.layeringViolation,
          )
        ],
        structuralModel: const MonorepoStructuralModel(
          rootPath: '/repo',
          packageNames: ['pkg_core', 'pkg_cli'],
          dependencyGraph: {
            'pkg_core': ['pkg_cli'],
            'pkg_cli': ['pkg_core'],
          },
          detectedCycles: [
            ['pkg_core', 'pkg_cli', 'pkg_core']
          ],
        ),
        summary: 'Identified 1 layering violation.',
        durationMs: 80,
        timestamp: now,
      );

      const renderer = ArchitectureAdvisorRenderer();
      final jsonOutput = renderer.renderJson(result);
      final mdOutput = renderer.renderMarkdown(result);

      // JSON validation
      final decoded = jsonDecode(jsonOutput) as Map<String, dynamic>;
      expect(decoded['isSuccess'], isTrue);
      expect(decoded['findingCount'], equals(1));
      expect(decoded['findings'][0]['severity'], equals('high'));
      expect(decoded['structuralModel']['detectedCycles'].length, equals(1));

      // Markdown validation
      expect(
          mdOutput,
          contains(
              '# Flutter Package Studio — AI Architecture Advisory Report'));
      expect(mdOutput, contains('Circular Dependency Cycles Detected'));
      expect(mdOutput, contains('Layering violation in CLI'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 10: Regression Check
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '10. Regression check: verifies compatibility with prior AI engine models',
        () {
      expect(ArchitectureCategory.values.length, greaterThanOrEqualTo(8));
      expect(ArchitectureScanScope.values.length, equals(3));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 11: AI Architectural Judgment — Excessive Coupling & Leaky Abstractions
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '11. AI Architectural Judgment: parses and qualifies excessive coupling and poor abstraction boundary with confidence rating',
        () async {
      scaffoldArchitectureMonorepo();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Architectural coupling analysis',
          'findings': [
            {
              'component': 'packages/pkg_core/lib/src/core_service.dart',
              'issue':
                  'Excessive coupling: module directly depends on 14 internal implementation classes of auth subsystem',
              'recommendation':
                  'Introduce a narrow AuthFacade interface to hide internal auth handlers',
              'reason':
                  'Violates Demeter principle and creates high change ripple risk across packages',
              'severity': 'high',
              'confidence': 'medium',
              'category': 'excessiveCoupling'
            },
            {
              'component': 'packages/pkg_core/lib/src/god_manager.dart',
              'issue':
                  'Poor abstraction boundary: god class managing lifecycle, networking, caching, and serialization',
              'recommendation':
                  'Decompose into specialized single-responsibility services',
              'reason': 'High cohesion and low coupling violated',
              'severity': 'medium',
              'confidence': 'high',
              'category': 'poorAbstractionBoundary'
            }
          ]
        }),
      );

      final engine = ArchitectureAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.scan(const ArchitectureScanRequest(
        scope: ArchitectureScanScope.wholeProject,
      ));

      expect(result.isSuccess, isTrue);

      final couplingFinding = result.findings.firstWhere(
          (f) => f.category == ArchitectureCategory.excessiveCoupling);
      expect(couplingFinding.component, contains('core_service.dart'));
      expect(couplingFinding.confidence, equals(CodeReviewConfidence.medium));
      expect(couplingFinding.severity, equals(CodeReviewSeverity.high));
      expect(couplingFinding.recommendation, contains('AuthFacade'));

      final boundaryFinding = result.findings.firstWhere(
          (f) => f.category == ArchitectureCategory.poorAbstractionBoundary);
      expect(boundaryFinding.confidence, equals(CodeReviewConfidence.high));
      expect(boundaryFinding.issue, contains('god class'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 12: AI Architectural Judgment — API Inconsistencies Across Packages
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '12. AI Architectural Judgment: detects and qualifies API inconsistency across packages',
        () async {
      scaffoldArchitectureMonorepo();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'API shape consistency audit',
          'findings': [
            {
              'component': 'packages/pkg_core & packages/pkg_cli',
              'issue':
                  'API inconsistency: divergent naming convention for configuration retrieval',
              'recommendation':
                  'Standardize on `resolveConfiguration()` across both core and CLI surfaces',
              'reason':
                  'Diverging vocabulary across packages increases cognitive load and causes friction in public APIs',
              'severity': 'low',
              'confidence': 'high',
              'category': 'apiInconsistency'
            }
          ]
        }),
      );

      final engine = ArchitectureAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.scan(const ArchitectureScanRequest(
        scope: ArchitectureScanScope.wholeProject,
      ));

      expect(result.isSuccess, isTrue);

      final apiFinding = result.findings.firstWhere(
          (f) => f.category == ArchitectureCategory.apiInconsistency);
      expect(apiFinding.severity, equals(CodeReviewSeverity.low));
      expect(apiFinding.confidence, equals(CodeReviewConfidence.high));
      expect(apiFinding.recommendation, contains('resolveConfiguration'));
    });
  });
}
