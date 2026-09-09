import 'dart:convert';
import 'dart:io';
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 8.3 — AI Code Analysis & Review Engine Tests', () {
    late Directory tempRoot;
    late String rootPath;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('fps_phase_8_3_test_');
      rootPath = tempRoot.path;
    });

    tearDown(() {
      if (tempRoot.existsSync()) {
        try {
          tempRoot.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    /// Helper to scaffold a sample package with realistic Dart/Flutter code.
    void scaffoldSamplePackage() {
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: review_sample_pkg
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
dependencies:
  meta: ^1.11.0
''');
      File(p.join(rootPath, '.gitignore')).writeAsStringSync('''
.dart_tool/
build/
.env
*.secret
''');

      Directory(p.join(rootPath, 'lib')).createSync(recursive: true);
      Directory(p.join(rootPath, 'test')).createSync(recursive: true);

      // File 1: Single file with lifecycle and async issues
      File(p.join(rootPath, 'lib', 'widget_view.dart')).writeAsStringSync('''
import 'package:flutter/material.dart';

class UserWidget extends StatefulWidget {
  const UserWidget({super.key});

  @override
  State<UserWidget> createState() => _UserWidgetState();
}

class _UserWidgetState extends State<UserWidget> {
  String data = '';

  void fetchData() async {
    await Future.delayed(const Duration(seconds: 1));
    // BuildContext across async gap issue:
    Navigator.of(context).pop();
    setState(() {
      data = 'loaded';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');

      // File 2: Service with duplication block
      File(p.join(rootPath, 'lib', 'service_a.dart')).writeAsStringSync('''
class ServiceA {
  int calculateScore(int a, int b) {
    // Duplicated block
    final sum = a + b;
    final normalized = sum > 100 ? 100 : sum;
    return normalized * 2;
  }
}
''');

      // File 3: Service with identical duplication block
      File(p.join(rootPath, 'lib', 'service_b.dart')).writeAsStringSync('''
class ServiceB {
  int calculateScore(int a, int b) {
    // Duplicated block
    final sum = a + b;
    final normalized = sum > 100 ? 100 : sum;
    return normalized * 2;
  }
}
''');

      // File 4: Architecture-heavy API class
      File(p.join(rootPath, 'lib', 'monolithic_manager.dart'))
          .writeAsStringSync('''
class MonolithicManager {
  // Excessive coupling and high complexity
  void doEverything() {
    print("Database call");
    print("Network call");
    print("UI update");
    print("File IO");
  }
}
''');

      // Test file
      File(p.join(rootPath, 'test', 'widget_view_test.dart'))
          .writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('sample test', () {});
}
''');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Findings Schema Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Findings schema conformance: all required fields present, correctly typed, and constrained to enums',
        () {
      final finding = const CodeReviewFinding(
        severity: CodeReviewSeverity.high,
        category: CodeReviewCategory.flutterLifecycle,
        file: 'lib/widget_view.dart',
        location: 'L16',
        problem:
            'BuildContext accessed across an asynchronous gap without mounted check',
        explanation:
            'Using context across an await without if (!mounted) return may cause runtime exceptions if widget was unmounted.',
        recommendation:
            'Guard the Navigator call with `if (!mounted) return;`.',
        confidence: CodeReviewConfidence.high,
      );

      final jsonMap = finding.toJson();
      expect(jsonMap['severity'], equals('high'));
      expect(jsonMap['category'], equals('flutterLifecycle'));
      expect(jsonMap['confidence'], equals('high'));
      expect(jsonMap['file'], equals('lib/widget_view.dart'));
      expect(jsonMap['location'], equals('L16'));
      expect(jsonMap['problem'], contains('BuildContext'));
      expect(jsonMap['explanation'], contains('mounted'));
      expect(jsonMap['recommendation'], contains('mounted'));

      final parsed = CodeReviewFinding.fromJson(jsonMap);
      expect(parsed.severity, equals(CodeReviewSeverity.high));
      expect(parsed.category, equals(CodeReviewCategory.flutterLifecycle));
      expect(parsed.confidence, equals(CodeReviewConfidence.high));
      expect(parsed.file, equals(finding.file));
      expect(parsed.location, equals(finding.location));
      expect(parsed.problem, equals(finding.problem));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Single-File Analysis Mode
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Single-file analysis mode: scopes review strictly to specified file',
        () async {
      scaffoldSamplePackage();

      final mockJson = jsonEncode({
        'summary': 'Single-file review of widget_view.dart',
        'findings': [
          {
            'severity': 'high',
            'category': 'flutterLifecycle',
            'file': 'lib/widget_view.dart',
            'location': 'L16',
            'problem': 'BuildContext accessed across async gap',
            'explanation': 'Unsafe context access after await delay.',
            'recommendation': 'Add mounted check before Navigator call.',
            'confidence': 'high',
          }
        ]
      });

      final provider = MockAiProvider(defaultResponse: mockJson);
      final engine = CodeReviewEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.review(const CodeReviewRequest(
        mode: CodeReviewMode.singleFile,
        targetFile: 'lib/widget_view.dart',
      ));

      expect(result.isSuccess, isTrue);
      expect(result.mode, equals(CodeReviewMode.singleFile));
      expect(result.inspectedFiles.length, equals(1));
      expect(result.inspectedFiles.first, contains('widget_view.dart'));
      expect(result.findings.length, equals(1));
      expect(result.findings.first.category,
          equals(CodeReviewCategory.flutterLifecycle));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Package-Level Analysis Mode & Cross-File Deduplication
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Package-level analysis mode: aggregates package files and deduplicates cross-file duplication findings',
        () async {
      scaffoldSamplePackage();

      final mockJson = jsonEncode({
        'summary': 'Package-level review across all files',
        'findings': [
          {
            'severity': 'medium',
            'category': 'duplication',
            'file': 'lib/service_a.dart',
            'location': 'L3-L7',
            'problem': 'Identical score calculation logic duplicated',
            'explanation': 'Logic in ServiceA is copy-pasted in ServiceB.',
            'recommendation':
                'Extract shared calculation to ScoreCalculator utility class.',
            'confidence': 'high',
          },
          {
            'severity': 'medium',
            'category': 'duplication',
            'file': 'lib/service_b.dart',
            'location': 'L3-L7',
            'problem': 'Identical score calculation logic duplicated',
            'explanation': 'Logic in ServiceB is copy-pasted in ServiceA.',
            'recommendation':
                'Extract shared calculation to ScoreCalculator utility class.',
            'confidence': 'high',
          },
          {
            'severity': 'high',
            'category': 'flutterLifecycle',
            'file': 'lib/widget_view.dart',
            'location': 'L16',
            'problem': 'BuildContext accessed across async gap',
            'explanation': 'Unsafe context access.',
            'recommendation': 'Add if (!mounted) check.',
            'confidence': 'high',
          }
        ]
      });

      final provider = MockAiProvider(defaultResponse: mockJson);
      final engine = CodeReviewEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.review(const CodeReviewRequest(
        mode: CodeReviewMode.packageLevel,
      ));

      expect(result.isSuccess, isTrue);
      expect(result.inspectedFiles.length, greaterThanOrEqualTo(4));
      // Cross-file duplication was reported in 2 files, but deduplication should reduce it to 1
      final dupFindings = result.findings
          .where((f) => f.category == CodeReviewCategory.duplication)
          .toList();
      expect(dupFindings.length, equals(1));
      expect(result.findings.length,
          equals(2)); // 1 deduped duplication + 1 lifecycle
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Change-Focused Analysis Mode
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Change-focused analysis mode: scopes findings strictly to modified files',
        () async {
      scaffoldSamplePackage();

      final mockJson = jsonEncode({
        'summary': 'Change-focused review',
        'findings': [
          {
            'severity': 'high',
            'category': 'flutterLifecycle',
            'file': 'lib/widget_view.dart',
            'location': 'L16',
            'problem': 'BuildContext across async gap',
            'explanation': 'Unsafe context access.',
            'recommendation': 'Add mounted check.',
            'confidence': 'high',
          },
          {
            'severity': 'low',
            'category': 'codeSmell',
            'file': 'lib/service_a.dart',
            'location': 'L1',
            'problem': 'Magic number in service_a',
            'explanation': 'Magic number used.',
            'recommendation': 'Define const.',
            'confidence': 'medium',
          }
        ]
      });

      final provider = MockAiProvider(defaultResponse: mockJson);
      final engine = CodeReviewEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      // Only widget_view.dart was changed in this PR/diff
      final result = await engine.review(const CodeReviewRequest(
        mode: CodeReviewMode.changeFocused,
        changedFiles: {'lib/widget_view.dart'},
      ));

      expect(result.isSuccess, isTrue);
      expect(result.findings.length, equals(1));
      expect(result.findings.first.file, contains('widget_view.dart'));
      // service_a finding was filtered out because it was not in changedFiles
      expect(result.findings.any((f) => f.file.contains('service_a.dart')),
          isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Architecture-Focused Analysis Mode
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Architecture-focused analysis mode: reports architectural and complexity issues while suppressing line-level nitpicks',
        () async {
      scaffoldSamplePackage();

      final mockJson = jsonEncode({
        'summary': 'Architecture analysis pass',
        'findings': [
          {
            'severity': 'high',
            'category': 'architecture',
            'file': 'lib/monolithic_manager.dart',
            'location': 'L1-L10',
            'problem': 'God object violating single responsibility principle',
            'explanation':
                'MonolithicManager combines database, network, UI, and IO in one class.',
            'recommendation':
                'Decompose into separate repository, client, and controller layers.',
            'confidence': 'high',
          },
          {
            'severity': 'low',
            'category': 'codeSmell',
            'file': 'lib/service_a.dart',
            'location': 'L5',
            'problem': 'Unnecessary local variable sum',
            'explanation': 'Can inline expression.',
            'recommendation': 'Inline variable.',
            'confidence': 'medium',
          }
        ]
      });

      final provider = MockAiProvider(defaultResponse: mockJson);
      final engine = CodeReviewEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.review(const CodeReviewRequest(
        mode: CodeReviewMode.architectureFocused,
      ));

      expect(result.isSuccess, isTrue);
      // Low-level style/codeSmell was suppressed; only architecture was retained
      expect(result.findings.length, equals(1));
      expect(result.findings.first.category,
          equals(CodeReviewCategory.architecture));
      expect(result.findings.first.problem, contains('God object'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Safety Invariant (Zero Mutation, Zero Disk Write, Zero Process Exec)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Safety Invariant: review execution is strictly read-only with byte-identical project before and after',
        () async {
      scaffoldSamplePackage();

      // Collect file hashes / contents before run
      final filesBefore = <String, String>{};
      for (final entity in tempRoot.listSync(recursive: true)) {
        if (entity is File) {
          filesBefore[entity.path] = entity.readAsStringSync();
        }
      }

      final mockJson =
          jsonEncode({'summary': 'Safety check review', 'findings': []});

      final provider = MockAiProvider(defaultResponse: mockJson);
      final engine = CodeReviewEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.review(const CodeReviewRequest(
        mode: CodeReviewMode.packageLevel,
      ));
      expect(result.isSuccess, isTrue);

      // Verify all files are byte-identical after run
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
        '7. Sensitive-File Respect: .env and credentials files are never sent to AI provider',
        () async {
      scaffoldSamplePackage();

      // Add sensitive files
      File(p.join(rootPath, '.env'))
          .writeAsStringSync('SECRET_API_KEY=AIzaSyA1234567890abcdef');
      File(p.join(rootPath, 'credentials.json'))
          .writeAsStringSync('{"client_secret": "my_super_secret"}');

      final provider = MockAiProvider(
          defaultResponse: jsonEncode(
              {'summary': 'Inspection of safe files', 'findings': []}));

      final engine = CodeReviewEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.review(const CodeReviewRequest(
        mode: CodeReviewMode.packageLevel,
      ));

      expect(result.isSuccess, isTrue);
      // Check request history on MockAiProvider to confirm sensitive content was NEVER sent
      expect(provider.recordedRequests, isNotEmpty);
      final sentPrompt = provider.recordedRequests.first.prompt;
      expect(sentPrompt.contains('SECRET_API_KEY'), isFalse);
      expect(sentPrompt.contains('my_super_secret'), isFalse);
      expect(sentPrompt.contains('.env'), isFalse);
      expect(sentPrompt.contains('credentials.json'), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: AI Provider Failure Handled Safely
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Provider Failure: unavailable or faulted AI provider returns structured failure without crashing',
        () async {
      scaffoldSamplePackage();

      final provider = MockAiProvider(
        injectedException: Exception('Simulated AI Provider Failure'),
      );
      final engine = CodeReviewEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
      );

      final result = await engine.review(const CodeReviewRequest(
        mode: CodeReviewMode.packageLevel,
      ));

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('Simulated AI Provider Failure'));
      expect(result.findings, isEmpty);
      expect(result.summary, contains('Code review failed'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: Dual-Format Rendering (JSON and Markdown)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9. Dual-Format Renderer: renders schema-valid JSON and readable Markdown',
        () {
      final finding = const CodeReviewFinding(
        severity: CodeReviewSeverity.critical,
        category: CodeReviewCategory.bugRisk,
        file: 'lib/core.dart',
        location: 'L42',
        problem: 'Null pointer dereference on uninitialized field',
        explanation: 'Field `_data` is accessed before `init()` is called.',
        recommendation:
            'Initialize `_data` eagerly or check for null before access.',
        confidence: CodeReviewConfidence.high,
      );

      final result = CodeReviewResult(
        mode: CodeReviewMode.singleFile,
        isSuccess: true,
        findings: [finding],
        summary: 'Identified 1 critical bug in core.dart',
        inspectedFiles: ['lib/core.dart'],
        durationMs: 120,
        timestamp: DateTime.parse('2026-09-02T12:00:00.000Z'),
      );

      const renderer = CodeReviewRenderer();
      final jsonOutput = renderer.renderJson(result);
      final mdOutput = renderer.renderMarkdown(result);

      // JSON assertions
      final decoded = jsonDecode(jsonOutput) as Map<String, dynamic>;
      expect(decoded['isSuccess'], isTrue);
      expect(decoded['findingCount'], equals(1));
      expect(decoded['severityCounts']['critical'], equals(1));
      expect(decoded['findings'][0]['severity'], equals('critical'));

      // Markdown assertions
      expect(
          mdOutput,
          contains(
              '# Flutter Package Studio — AI Code Analysis & Review Report'));
      expect(mdOutput, contains('🚨 [CRITICAL] Null pointer dereference'));
      expect(mdOutput, contains('**File**: `lib/core.dart` (L42)'));
      expect(mdOutput, contains('**Confidence**: `HIGH`'));
    });
  });
}
