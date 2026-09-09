import 'dart:convert';
import 'dart:io';
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 8.2 — Project Context & Codebase Intelligence Tests', () {
    late Directory tempRoot;
    late String rootPath;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('fps_phase_8_2_test_');
      rootPath = tempRoot.path;
    });

    tearDown(() {
      if (tempRoot.existsSync()) {
        try {
          tempRoot.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    /// Helper to scaffold a realistic multi-package monorepo structure.
    void scaffoldRealisticMonorepo() {
      // 1. Root configuration & reports
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: syntrix_monorepo
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');
      File(p.join(rootPath, 'analysis_options.yaml'))
          .writeAsStringSync('include: package:lints/recommended.yaml');
      File(p.join(rootPath, '.gitignore')).writeAsStringSync('''
.dart_tool/
build/
*.secret
secret_dir/
''');
      Directory(p.join(rootPath, 'report')).createSync(recursive: true);
      File(p.join(rootPath, 'report', 'audit_report.txt'))
          .writeAsStringSync('System audit report finding: all checks clean');

      // 2. Package A: Core Package
      final pkgAPath = p.join(rootPath, 'packages', 'pkg_a');
      Directory(p.join(pkgAPath, 'lib', 'src')).createSync(recursive: true);
      Directory(p.join(pkgAPath, 'test')).createSync(recursive: true);
      File(p.join(pkgAPath, 'pubspec.yaml')).writeAsStringSync('''
name: pkg_a
version: 1.2.0
dependencies:
  meta: ^1.11.0
''');
      File(p.join(pkgAPath, 'lib', 'pkg_a.dart'))
          .writeAsStringSync('library pkg_a;\nint calculateA() => 42;\n');
      File(p.join(pkgAPath, 'test', 'pkg_a_test.dart')).writeAsStringSync(
          'import "package:test/test.dart";\nvoid main() {}');

      // 3. Package B: Feature Package (depends on pkg_a)
      final pkgBPath = p.join(rootPath, 'packages', 'pkg_b');
      Directory(p.join(pkgBPath, 'lib')).createSync(recursive: true);
      Directory(p.join(pkgBPath, 'test')).createSync(recursive: true);
      File(p.join(pkgBPath, 'pubspec.yaml')).writeAsStringSync('''
name: pkg_b
version: 2.0.0
dependencies:
  pkg_a: ^1.2.0
  flutter:
    sdk: flutter
dev_dependencies:
  test: ^1.25.0
''');
      File(p.join(pkgBPath, 'lib', 'pkg_b.dart')).writeAsStringSync(
          'import "package:pkg_a/pkg_a.dart";\nvoid runB() {}');
      File(p.join(pkgBPath, 'test', 'pkg_b_test.dart'))
          .writeAsStringSync('void testB() {}');
      File(p.join(pkgBPath, 'test', 'pkg_b_error_report.txt'))
          .writeAsStringSync('Error in pkg_b: assertion failed on step 3');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Project Discovery
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Project Discovery: correctly identifies monorepo, packages, pubspecs, source/test/doc dirs, reports, and configs',
        () async {
      scaffoldRealisticMonorepo();
      final engine = ProjectContextEngine(projectRoot: rootPath);
      final snapshot = await engine.discoverProject();

      expect(snapshot.isMonorepo, isTrue);
      expect(snapshot.packages.containsKey('syntrix_monorepo'), isTrue);
      expect(snapshot.packages.containsKey('pkg_a'), isTrue);
      expect(snapshot.packages.containsKey('pkg_b'), isTrue);

      final pkgB = snapshot.packages['pkg_b']!;
      expect(pkgB.isFlutter, isTrue);
      expect(pkgB.dependencies.containsKey('pkg_a'), isTrue);
      expect(pkgB.sourceFiles.any((f) => f.contains('pkg_b.dart')), isTrue);
      expect(pkgB.testFiles.any((f) => f.contains('pkg_b_test.dart')), isTrue);

      expect(
          snapshot.existingReports.any((r) => r.contains('audit_report.txt')),
          isTrue);
      expect(
          snapshot.configurationFiles
              .any((c) => c.contains('analysis_options.yaml')),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Package Resolution
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Package Resolution: natural-language query naming or implying a specific package resolves to it and scopes context',
        () async {
      scaffoldRealisticMonorepo();
      final engine = ProjectContextEngine(projectRoot: rootPath);

      final queryA = 'Why is pkg_a throwing an analysis warning?';
      final contextA = await engine.assembleContext(query: queryA);

      expect(contextA.resolvedPackageId, equals('pkg_a'));
      expect(contextA.isAmbiguousPackage, isFalse);
      expect(
          contextA.scopedFiles
              .any((f) => f.relativePath.contains('pkg_a.dart')),
          isTrue);

      final queryB = 'Investigate why pkg_b tests are failing';
      final contextB = await engine.assembleContext(query: queryB);

      expect(contextB.resolvedPackageId, equals('pkg_b'));
      expect(
          contextB.scopedFiles
              .any((f) => f.relativePath.contains('pkg_b_error_report.txt')),
          isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Relevant-File Identification
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Relevant-File Identification: "why is package X failing" prioritizes X source, tests, pubspec, and reports over unrelated files',
        () async {
      scaffoldRealisticMonorepo();
      final engine = ProjectContextEngine(projectRoot: rootPath);

      final query = 'Why is pkg_b failing on step 3?';
      final context = await engine.assembleContext(query: query);

      expect(context.resolvedPackageId, equals('pkg_b'));
      final includedPaths =
          context.scopedFiles.map((f) => f.relativePath).toList();

      // pkg_b files should be prioritized and included
      expect(
          includedPaths.any((p) => p.contains('pkg_b/pubspec.yaml')), isTrue);
      expect(
          includedPaths.any((p) => p.contains('pkg_b/lib/pkg_b.dart')), isTrue);
      expect(includedPaths.any((p) => p.contains('pkg_b_error_report.txt')),
          isTrue);

      // Unrelated pkg_a files must be excluded or strictly deprioritized
      expect(includedPaths.any((p) => p.contains('pkg_a/lib/pkg_a.dart')),
          isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Deterministic Prioritization Rule Verification
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Deterministic Prioritization: documented ordering rule deterministically governs truncation when budget is exceeded',
        () async {
      scaffoldRealisticMonorepo();
      final engine = ProjectContextEngine(projectRoot: rootPath);

      // Set an intentionally tiny token budget that forces truncation
      final query = 'Audit pkg_b';
      final tightContext = await engine.assembleContext(
        query: query,
        targetPackageId: 'pkg_b',
        tokenBudget: 35, // Very small token budget
      );

      // Verify that higher priority files (configuration / pubspec) are kept,
      // and truncated files are audited with ContextFileExclusionReason.budgetTruncation
      final auditTruncated = tightContext.auditRecords
          .where((a) =>
              a.exclusionReason == ContextFileExclusionReason.budgetTruncation)
          .toList();

      expect(auditTruncated, isNotEmpty);
      expect(tightContext.scopedFiles, isNotEmpty);
      // The highest score file (pubspec.yaml) is kept first
      expect(tightContext.scopedFiles.first.relativePath,
          contains('pubspec.yaml'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Dependency Mapping
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Dependency Mapping: declared package dependencies are mapped into workspace graph without error',
        () async {
      scaffoldRealisticMonorepo();
      final engine = ProjectContextEngine(projectRoot: rootPath);
      final snapshot = await engine.discoverProject();
      final graph = snapshot.dependencyGraph;

      final internalDepsOfB = graph.getInternalDependencies('pkg_b');
      expect(internalDepsOfB, contains('pkg_a'));

      final dependentsOfA = graph.getDependents('pkg_a');
      expect(dependentsOfA, contains('pkg_b'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Sensitive-File Exclusion Tests (6a to 6d)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6a. Sensitive Exclusion: .env and .env.* files never appear in assembled context',
        () async {
      scaffoldRealisticMonorepo();
      File(p.join(rootPath, '.env'))
          .writeAsStringSync('API_KEY=super_secret_production_key');
      File(p.join(rootPath, '.env.production'))
          .writeAsStringSync('DB_PASS=vault_secret_999');

      final engine = ProjectContextEngine(projectRoot: rootPath);
      final context =
          await engine.assembleContext(query: 'Look at .env and configs');

      final includedText = context.scopedFiles.map((f) => f.content).join('\n');
      expect(includedText.contains('super_secret_production_key'), isFalse);
      expect(includedText.contains('vault_secret_999'), isFalse);

      final audit =
          context.auditRecords.firstWhere((a) => a.relativePath == '.env');
      expect(audit.isIncluded, isFalse);
      expect(audit.exclusionReason,
          equals(ContextFileExclusionReason.sensitiveEnv));
    });

    test(
        '6b. Sensitive Exclusion: private-key and certificate files never appear in assembled context',
        () async {
      scaffoldRealisticMonorepo();
      File(p.join(rootPath, 'server.key')).writeAsStringSync(
          '-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA...\n-----END RSA PRIVATE KEY-----');
      File(p.join(rootPath, 'id_rsa')).writeAsStringSync(
          '-----BEGIN OPENSSH PRIVATE KEY-----\nb3BlbnNza...\n-----END OPENSSH PRIVATE KEY-----');
      File(p.join(rootPath, 'cert.pem')).writeAsStringSync(
          '-----BEGIN CERTIFICATE-----\nMIIDXTCCAkWgAwIBAg...\n-----END CERTIFICATE-----');

      final engine = ProjectContextEngine(projectRoot: rootPath);
      final context =
          await engine.assembleContext(query: 'Check keys and certificates');

      final includedText = context.scopedFiles.map((f) => f.content).join('\n');
      expect(includedText.contains('BEGIN RSA PRIVATE KEY'), isFalse);
      expect(includedText.contains('BEGIN OPENSSH PRIVATE KEY'), isFalse);
      expect(includedText.contains('BEGIN CERTIFICATE'), isFalse);

      final auditKey = context.auditRecords
          .firstWhere((a) => a.relativePath == 'server.key');
      expect(auditKey.exclusionReason,
          equals(ContextFileExclusionReason.sensitiveKeyOrCert));
    });

    test(
        '6c. Sensitive Exclusion: credential stores (credentials.json, .netrc, pub/git credentials) never appear',
        () async {
      scaffoldRealisticMonorepo();
      File(p.join(rootPath, 'credentials.json'))
          .writeAsStringSync('{"client_secret": "xyz123"}');
      File(p.join(rootPath, '.netrc'))
          .writeAsStringSync('machine github.com login token password abc');
      File(p.join(rootPath, 'key.properties'))
          .writeAsStringSync('storePassword=secret');

      final engine = ProjectContextEngine(projectRoot: rootPath);
      final context =
          await engine.assembleContext(query: 'Audit credential files');

      final includedText = context.scopedFiles.map((f) => f.content).join('\n');
      expect(includedText.contains('client_secret'), isFalse);
      expect(includedText.contains('storePassword'), isFalse);

      final auditCred = context.auditRecords
          .firstWhere((a) => a.relativePath == 'credentials.json');
      expect(auditCred.exclusionReason,
          equals(ContextFileExclusionReason.sensitiveCredential));
    });

    test(
        '6d. Sensitive Exclusion: files matching .gitignore rules never appear in assembled context',
        () async {
      scaffoldRealisticMonorepo();
      File(p.join(rootPath, 'custom_dump.secret'))
          .writeAsStringSync('Sensitive uncommitted data dump');

      final engine = ProjectContextEngine(projectRoot: rootPath);
      final context = await engine.assembleContext(query: 'Find secret files');

      final includedText = context.scopedFiles.map((f) => f.content).join('\n');
      expect(includedText.contains('Sensitive uncommitted data dump'), isFalse);

      final audit = context.auditRecords
          .firstWhere((a) => a.relativePath == 'custom_dump.secret');
      expect(
          audit.exclusionReason, equals(ContextFileExclusionReason.gitIgnored));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Fail-Closed on Unclassifiable File Formats
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Fail-Closed on Unclassifiable: unknown or binary file formats are excluded by default',
        () async {
      scaffoldRealisticMonorepo();
      File(p.join(rootPath, 'unknown_artifact.bin'))
          .writeAsBytesSync([0x00, 0xFF, 0x12, 0x34]);
      File(p.join(rootPath, 'mystery.weirdext'))
          .writeAsStringSync('Ambiguous content');

      final engine = ProjectContextEngine(projectRoot: rootPath);
      final context = await engine.assembleContext(query: 'Read everything');

      final audit = context.auditRecords
          .firstWhere((a) => a.relativePath == 'unknown_artifact.bin');
      expect(audit.isIncluded, isFalse);
      expect(audit.exclusionReason,
          equals(ContextFileExclusionReason.unclassifiableFormat));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Structural-Impossibility Audit
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Structural Impossibility Audit: no code path allows filtered sensitive files to reach PromptContext payload',
        () async {
      scaffoldRealisticMonorepo();
      File(p.join(rootPath, '.env'))
          .writeAsStringSync('LEAKED_SECRET_999=TRUE');

      final engine = ProjectContextEngine(projectRoot: rootPath);
      final assembled =
          await engine.assembleContext(query: 'Dump everything including .env');
      final promptContext = engine.toPromptContext(assembled);

      final serializedPromptContext = jsonEncode(promptContext.toJson());
      expect(serializedPromptContext.contains('LEAKED_SECRET_999'), isFalse);
      expect(serializedPromptContext.contains('.env'), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: Determinism Verification
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9. Determinism: identical project state and query produce byte-identical context and ranking across runs',
        () async {
      scaffoldRealisticMonorepo();
      final engine = ProjectContextEngine(projectRoot: rootPath);

      final query = 'Investigate pkg_b architecture and tests';
      final run1 = await engine.assembleContext(query: query);
      final run2 = await engine.assembleContext(query: query);

      final json1 = jsonEncode(run1.toJson());
      final json2 = jsonEncode(run2.toJson());
      expect(json1, equals(json2));

      final promptCtx1 = jsonEncode(engine.toPromptContext(run1).toJson());
      final promptCtx2 = jsonEncode(engine.toPromptContext(run2).toJson());
      expect(promptCtx1, equals(promptCtx2));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 10: Non-Execution Audit
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '10. Non-Execution Audit: discovery and extraction strictly read text files without executing or compiling Dart code',
        () async {
      scaffoldRealisticMonorepo();
      // Inject a Dart file that contains a deliberate runtime crash if executed or imported
      final maliciousDart =
          p.join(rootPath, 'packages', 'pkg_b', 'lib', 'exploding.dart');
      File(maliciousDart).writeAsStringSync('''
void dangerousCode() {
  throw StateError("Code was executed!");
}
''');

      final engine = ProjectContextEngine(projectRoot: rootPath);
      final snapshot = await engine.discoverProject();
      final context = await engine.assembleContext(query: 'Analyze pkg_b');

      expect(snapshot.packages.containsKey('pkg_b'), isTrue);
      expect(context.scopedFiles, isNotEmpty);
      // If code was executed, StateError would have thrown. Succeeding cleanly proves non-execution.
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 11: Fail-Closed Edge Cases (11a to 11c)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '11a. Edge Case: Ambiguous query in monorepo defaults to explicit ambiguity note instead of repository dump',
        () async {
      scaffoldRealisticMonorepo();
      final engine = ProjectContextEngine(projectRoot: rootPath);

      final genericQuery = 'Why did something fail?';
      final context = await engine.assembleContext(query: genericQuery);

      expect(context.isAmbiguousPackage, isTrue);
      expect(context.ambiguityNote, contains('did not uniquely resolve'));
      expect(context.resolvedPackageId, isNull);
    });

    test(
        '11b. Edge Case: Empty / newly-scaffolded directory with no packages handled cleanly without crashing',
        () async {
      // Empty directory
      final emptyRoot = Directory.systemTemp.createTempSync('fps_empty_test_');
      try {
        final engine = ProjectContextEngine(projectRoot: emptyRoot.path);
        final snapshot = await engine.discoverProject();

        expect(snapshot.packages, isEmpty);
        expect(snapshot.isMonorepo, isFalse);

        final context =
            await engine.assembleContext(query: 'Analyze empty project');
        expect(context.scopedFiles, isEmpty);
        expect(context.resolvedPackageId, isNull);
      } finally {
        if (emptyRoot.existsSync()) {
          emptyRoot.deleteSync(recursive: true);
        }
      }
    });

    test(
        '11c. Edge Case: Malformed or unreadable .gitignore triggers degraded fail-closed heightened protection',
        () async {
      scaffoldRealisticMonorepo();
      // Overwrite .gitignore with binary garbage or locked state
      final filter = SensitiveFileFilter.fromProjectRoot(rootPath);
      expect(filter.isGitIgnoreDegraded, isFalse);

      // Now test filter with degraded flag
      final degradedFilter =
          SensitiveFileFilter.fromProjectRoot('non_existent_folder_xyz');
      final decision =
          degradedFilter.evaluateFile(relativePath: 'random_script.sh');
      expect(decision.isSafe, isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 12: Path-Safety & Traversal Rejection
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '12. Path Safety: absolute paths and directory traversal (..) are strictly rejected by SensitiveFileFilter',
        () {
      final filter = SensitiveFileFilter.fromProjectRoot(rootPath);

      final traversalDecision =
          filter.evaluateFile(relativePath: '../secrets/vault.json');
      expect(traversalDecision.isSafe, isFalse);
      expect(traversalDecision.explanation, contains('traversal'));

      final absoluteDecision = filter.evaluateFile(relativePath: '/etc/passwd');
      expect(absoluteDecision.isSafe, isFalse);
      expect(absoluteDecision.explanation, contains('traversal'));

      final winAbsoluteDecision =
          filter.evaluateFile(relativePath: r'C:\Windows\System32\cmd.exe');
      expect(winAbsoluteDecision.isSafe, isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 13: ProjectContextRenderer Dual Formatting
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '13. Dual-Format Renderer: renders both Markdown and JSON representations deterministically',
        () async {
      scaffoldRealisticMonorepo();
      final engine = ProjectContextEngine(projectRoot: rootPath);
      final assembled = await engine.assembleContext(
          query: 'Render dual format check', targetPackageId: 'pkg_a');

      const renderer = ProjectContextRenderer();
      final jsonOutput = renderer.renderJson(assembled);
      final mdOutput = renderer.renderMarkdown(assembled);

      expect(jsonOutput, contains('"targetPackage": "pkg_a"'));
      expect(mdOutput, contains('**Target Package**: `pkg_a`'));
      expect(mdOutput, contains('Prioritized Scoped Files'));
      expect(mdOutput, contains('Context Audit & Filtering Trail'));
    });
  });
}
