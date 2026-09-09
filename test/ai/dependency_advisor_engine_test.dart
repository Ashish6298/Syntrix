import 'dart:convert';
import 'dart:io';
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 8.8 — AI Dependency & Compatibility Advisor Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_deps_test_');
      rootPath = tempDir.path;
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    /// Helper to scaffold a monorepo workspace with known version conflicts, deprecations, and secrets.
    void scaffoldMonorepoWorkspace() {
      // 1. Root Pubspec
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: deps_test_workspace
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      // 2. Sensitive files
      File(p.join(rootPath, '.env')).writeAsStringSync('''
DEPS_SECRET_TOKEN=token_deps_secret_9999
AUTH_KEY=auth_key_secret_8888
''');
      File(p.join(rootPath, 'credentials.json')).writeAsStringSync('''
{"api_token": "my_deps_credential_secret"}
''');

      // 3. Package A (uses meta ^1.11.0, pedantic, SDK >=3.5.0 <4.0.0)
      final pkgADir = Directory(p.join(rootPath, 'packages', 'pkg_a'))
        ..createSync(recursive: true);
      File(p.join(pkgADir.path, 'pubspec.yaml')).writeAsStringSync('''
name: pkg_a
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
dependencies:
  meta: ^1.11.0
  pedantic: ^1.11.1
''');
      Directory(p.join(pkgADir.path, 'lib'))..createSync(recursive: true);
      File(p.join(pkgADir.path, 'lib', 'pkg_a.dart'))
          .writeAsStringSync('void runA() {}');

      // 4. Package B (deliberately conflicts on meta ^2.0.0, uses SDK >=3.2.0 <4.0.0)
      final pkgBDir = Directory(p.join(rootPath, 'packages', 'pkg_b'))
        ..createSync(recursive: true);
      File(p.join(pkgBDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: pkg_b
version: 1.0.0
environment:
  sdk: '>=3.2.0 <4.0.0'
dependencies:
  meta: ^2.0.0
  shared_preferences: ^2.2.0
''');
      Directory(p.join(pkgBDir.path, 'lib'))..createSync(recursive: true);
      File(p.join(pkgBDir.path, 'lib', 'pkg_b.dart'))
          .writeAsStringSync('void runB() {}');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Finding Model Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Finding Model Conformance: DependencyFinding conforms strictly to CodeReviewFinding schema and serializes compatibility certainty',
        () {
      const finding = DependencyFinding(
        severity: CodeReviewSeverity.high,
        category: CodeReviewCategory.maintainability,
        file: 'packages/pkg_a/pubspec.yaml',
        location: 'dependencies.meta',
        problem: 'Conflicting version constraints for meta',
        explanation: 'Package A uses ^1.11.0 whereas Package B uses ^2.0.0.',
        recommendation: 'Align all packages to meta ^2.0.0.',
        confidence: CodeReviewConfidence.high,
        dependencyName: 'meta',
        currentConstraint: '^1.11.0',
        artifactType: DependencyArtifactType.versionConflict,
        certainty: CompatibilityCertainty.locallyVerified,
        affectedPackages: ['pkg_a', 'pkg_b'],
      );

      final json = finding.toJson();
      expect(json['severity'], equals('high'));
      expect(json['category'], equals('maintainability'));
      expect(json['file'], equals('packages/pkg_a/pubspec.yaml'));
      expect(json['location'], equals('dependencies.meta'));
      expect(json['problem'], contains('Conflicting version constraints'));
      expect(json['explanation'], contains('^1.11.0'));
      expect(json['recommendation'], contains('^2.0.0'));
      expect(json['confidence'], equals('high'));
      expect(json['dependencyName'], equals('meta'));
      expect(json['currentConstraint'], equals('^1.11.0'));
      expect(json['artifactType'], equals('versionConflict'));
      expect(json['certainty'], equals('locallyVerified'));
      expect(json['affectedPackages'], equals(['pkg_a', 'pkg_b']));

      final restored = DependencyFinding.fromJson(json);
      expect(restored.severity, equals(CodeReviewSeverity.high));
      expect(restored.category, equals(CodeReviewCategory.maintainability));
      expect(restored.artifactType,
          equals(DependencyArtifactType.versionConflict));
      expect(
          restored.certainty, equals(CompatibilityCertainty.locallyVerified));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Deterministic Version Conflict Detection
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Deterministic Conflict Detection: detects conflicting version constraints for meta between pkg_a and pkg_b',
        () async {
      scaffoldMonorepoWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode(
            {'summary': 'Dependency analysis complete.', 'findings': []}),
      );

      final engine = DependencyAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const DependencyAnalysisRequest(
        scope: DependencyAnalysisScope.wholeProject,
      ));

      expect(result.isSuccess, isTrue);
      expect(result.findingCount, greaterThanOrEqualTo(1));

      final metaConflict = result.findings.firstWhere(
        (f) =>
            f.dependencyName == 'meta' &&
            f.artifactType == DependencyArtifactType.versionConflict,
      );
      expect(metaConflict.certainty,
          equals(CompatibilityCertainty.locallyVerified));
      expect(metaConflict.severity, equals(CodeReviewSeverity.high));
      expect(metaConflict.affectedPackages, containsAll(['pkg_a', 'pkg_b']));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Deterministic Deprecation Detection
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Deprecation Detection: identifies deprecated package `pedantic` with locally verified certainty',
        () async {
      scaffoldMonorepoWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode(
            {'summary': 'Dependency analysis complete.', 'findings': []}),
      );

      final engine = DependencyAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const DependencyAnalysisRequest(
        scope: DependencyAnalysisScope.wholeProject,
      ));

      expect(result.isSuccess, isTrue);
      final pedanticFinding = result.findings.firstWhere(
        (f) => f.dependencyName == 'pedantic',
      );
      expect(pedanticFinding.artifactType,
          equals(DependencyArtifactType.deprecatedPackage));
      expect(pedanticFinding.certainty,
          equals(CompatibilityCertainty.locallyVerified));
      expect(pedanticFinding.severity, equals(CodeReviewSeverity.high));
      expect(pedanticFinding.recommendation, contains('flutter_lints'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Compatibility Certainty Classification (All 3 Tiers)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Certainty Classification: verifies locallyVerified, inferred, and externallyResearched tiers are preserved',
        () async {
      scaffoldMonorepoWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'AI Dependency reasoning',
          'findings': [
            {
              'dependencyName': 'shared_preferences',
              'currentConstraint': '^2.2.0',
              'problem': 'Potential breaking change in next major release',
              'explanation':
                  'Major release 3.0 has breaking async initialization changes.',
              'recommendation': 'Evaluate upgrade migration path.',
              'severity': 'medium',
              'confidence': 'medium',
              'category': 'maintainability',
              'artifactType': 'upgradeRisk',
              'certainty': 'inferred',
              'file': 'packages/pkg_b/pubspec.yaml',
              'location': 'dependencies.shared_preferences',
              'affectedPackages': ['pkg_b']
            },
            {
              'dependencyName': 'external_unverified_dep',
              'currentConstraint': '^1.0.0',
              'problem':
                  'Community reports unverified incompatibility with Dart 3.5 wasm',
              'explanation':
                  'Ecosystem reports suggest native bindings may not compile to web wasm.',
              'recommendation':
                  'Verify against pub.dev wasm tag before deploying.',
              'severity': 'low',
              'confidence': 'low',
              'category': 'apiUsage',
              'artifactType': 'generalDependency',
              'certainty': 'externallyResearched',
              'file': 'packages/pkg_a/pubspec.yaml',
              'location': 'dependencies.external_unverified_dep',
              'affectedPackages': ['pkg_a']
            }
          ]
        }),
      );

      final engine = DependencyAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const DependencyAnalysisRequest(
        scope: DependencyAnalysisScope.wholeProject,
      ));

      expect(result.isSuccess, isTrue);

      final locallyVerifiedFindings = result.findings.where(
        (f) => f.certainty == CompatibilityCertainty.locallyVerified,
      );
      final inferredFindings = result.findings.where(
        (f) => f.certainty == CompatibilityCertainty.inferred,
      );
      final externalFindings = result.findings.where(
        (f) => f.certainty == CompatibilityCertainty.externallyResearched,
      );

      expect(locallyVerifiedFindings, isNotEmpty);
      expect(inferredFindings, isNotEmpty);
      expect(externalFindings, isNotEmpty);

      expect(
          inferredFindings.first.dependencyName, equals('shared_preferences'));
      expect(externalFindings.first.certainty,
          equals(CompatibilityCertainty.externallyResearched));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Scoped Package Analysis
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Scoped Package Analysis: filters analysis strictly to target package when specified',
        () async {
      scaffoldMonorepoWorkspace();

      final provider = MockAiProvider(
        defaultResponse:
            jsonEncode({'summary': 'Scoped to pkg_a', 'findings': []}),
      );

      final engine = DependencyAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const DependencyAnalysisRequest(
        scope: DependencyAnalysisScope.package,
        targetPackage: 'pkg_a',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.analyzedPackages, equals(['pkg_a']));
      for (final f in result.findings) {
        expect(f.affectedPackages.contains('pkg_b'), isFalse);
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Sensitive-File Respect (Zero Secrets Transmitted)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Sensitive-File Respect: .env and credentials.json contents are never transmitted to AI provider',
        () async {
      scaffoldMonorepoWorkspace();

      final provider = MockAiProvider(
        defaultResponse:
            jsonEncode({'summary': 'Inspection of safe files', 'findings': []}),
      );

      final engine = DependencyAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      await engine.analyze(const DependencyAnalysisRequest(
        scope: DependencyAnalysisScope.wholeProject,
      ));

      expect(provider.recordedRequests, isNotEmpty);
      final sentPrompt = provider.recordedRequests.first.prompt;
      expect(sentPrompt.contains('DEPS_SECRET_TOKEN'), isFalse);
      expect(sentPrompt.contains('token_deps_secret_9999'), isFalse);
      expect(sentPrompt.contains('AUTH_KEY'), isFalse);
      expect(sentPrompt.contains('auth_key_secret_8888'), isFalse);
      expect(sentPrompt.contains('my_deps_credential_secret'), isFalse);
      expect(sentPrompt.contains('.env'), isFalse);
      expect(sentPrompt.contains('credentials.json'), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: No-Execution / Zero-Mutation Safety Invariant
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. No-Execution Safety Invariant: dependency analysis never mutates pubspec or workspace files',
        () async {
      scaffoldMonorepoWorkspace();

      // Snapshot before
      final filesBefore = <String, String>{};
      for (final entity in Directory(rootPath).listSync(recursive: true)) {
        if (entity is File) {
          filesBefore[entity.path] = entity.readAsStringSync();
        }
      }

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({'summary': 'Safe scan', 'findings': []}),
      );

      final engine = DependencyAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      await engine.analyze(const DependencyAnalysisRequest(
        scope: DependencyAnalysisScope.wholeProject,
      ));

      // Snapshot after
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
    // Test 8: Fail-Closed Provider Failure Handling
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Provider Failure: unavailable provider returns structured failure without crashing',
        () async {
      scaffoldMonorepoWorkspace();

      final provider = MockAiProvider(
        injectedException:
            Exception('AI Dependency service timeout 504 Gateway Timeout.'),
      );

      final engine = DependencyAdvisorEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.analyze(const DependencyAnalysisRequest(
        scope: DependencyAnalysisScope.wholeProject,
      ));

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('AI Dependency service timeout'));
      expect(result.findings, isEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: Dual-Format Renderer (Valid JSON & Markdown)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9. Dual-Format Renderer: renders schema-valid JSON and structured Markdown reports',
        () {
      const finding = DependencyFinding(
        severity: CodeReviewSeverity.high,
        category: CodeReviewCategory.maintainability,
        file: 'packages/pkg_a/pubspec.yaml',
        location: 'dependencies.meta',
        problem: 'Conflicting version constraint',
        explanation: 'Conflict with pkg_b.',
        recommendation: 'Align to ^2.0.0.',
        confidence: CodeReviewConfidence.high,
        dependencyName: 'meta',
        currentConstraint: '^1.11.0',
        artifactType: DependencyArtifactType.versionConflict,
        certainty: CompatibilityCertainty.locallyVerified,
        affectedPackages: ['pkg_a', 'pkg_b'],
      );

      final result = DependencyAnalysisResult(
        scope: DependencyAnalysisScope.wholeProject,
        targetScopeId: 'whole_project',
        isSuccess: true,
        summary: 'Identified 1 conflict.',
        findings: const [finding],
        analyzedPackages: const ['pkg_a', 'pkg_b'],
        totalDependenciesCount: 4,
        durationMs: 35,
        timestamp: DateTime.now(),
      );

      const renderer = DependencyAdvisorRenderer();
      final jsonStr = renderer.renderJson(result);
      final mdStr = renderer.renderMarkdown(result);

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['isSuccess'], isTrue);
      expect(decoded['findingCount'], equals(1));
      expect(decoded['findings'][0]['certainty'], equals('locallyVerified'));
      expect(decoded['findings'][0]['dependencyName'], equals('meta'));

      expect(
          mdStr,
          contains(
              '# Flutter Package Studio — AI Dependency & Compatibility Advisory Report'));
      expect(mdStr, contains('[HIGH] Conflicting version constraint'));
      expect(mdStr, contains('`LOCALLYVERIFIED`'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 10: Regression Check
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '10. Regression check: verifies compatibility with prior AI assistant engine models',
        () {
      expect(DependencyArtifactType.values.length, greaterThanOrEqualTo(6));
      expect(CompatibilityCertainty.values.length, equals(3));
      expect(DependencyAnalysisScope.values.length, equals(2));
    });
  });
}
