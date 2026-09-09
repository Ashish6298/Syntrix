import 'dart:convert';
import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 8.13 — AI-Assisted Controlled Code Modification Tests', () {
    late Directory tempDir;
    late String rootPath;
    late String backupPath;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('fps_code_modification_test_');
      rootPath = tempDir.path;
      backupPath = p.join(rootPath, '.fps', 'backups');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    void scaffoldWorkspace() {
      // Root pubspec
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: controlled_mod_workspace
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');

      // Sample core lib
      final libDir = Directory(p.join(rootPath, 'lib'))
        ..createSync(recursive: true);
      File(p.join(libDir.path, 'sample.dart')).writeAsStringSync('''
class SampleService {
  void execute() {
    print('hello');
  }
}
''');

      // Sensitive file (denylisted)
      File(p.join(rootPath, '.env'))
          .writeAsStringSync('API_KEY=ghp_secretToken1234567890');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Plan Generation with Unified Diff Preview
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Modification Plan & Diff Preview: generates structured proposal with unified diffs',
        () async {
      scaffoldWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Add timeout parameter to execute method in SampleService',
          'affectedFiles': ['lib/sample.dart'],
          'patches': [
            {
              'relativePath': 'lib/sample.dart',
              'patchType': 'modify',
              'description': 'Add timeout parameter',
              'originalContent': 'class SampleService { void execute() {} }',
              'proposedContent':
                  'class SampleService { void execute({Duration? timeout}) {} }',
              'diff':
                  '--- a/lib/sample.dart\n+++ b/lib/sample.dart\n@@ -1,3 +1,3 @@\n-class SampleService {\n-  void execute() {\n+class SampleService {\n+  void execute({Duration? timeout}) {',
              'linesAdded': 2,
              'linesRemoved': 2,
            }
          ]
        }),
      );

      final engine = CodeModificationEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
        backupDir: backupPath,
      );

      final proposal =
          await engine.proposeModification(const CodeModificationPlanRequest(
        requirement: 'Add timeout parameter to SampleService.execute',
      ));

      expect(proposal.isSuccess, isTrue);
      expect(proposal.affectedFiles, contains('lib/sample.dart'));
      expect(proposal.patches.length, equals(1));
      expect(proposal.patches.first.diff, contains('@@ -1,3 +1,3 @@'));
      expect(proposal.totalLinesAdded, equals(2));
      expect(proposal.totalLinesRemoved, equals(2));
      expect(proposal.isEligibleForApplication, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: File Denylist Safeguard Enforcement
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Denylist Safeguard: blocks AI from proposing edits to prohibited sensitive files (.env, .git, .fps)',
        () async {
      scaffoldWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Attempt to edit .env secrets file',
          'affectedFiles': ['.env'],
          'patches': [
            {
              'relativePath': '.env',
              'patchType': 'modify',
              'description': 'Injected credential modification',
              'diff':
                  '--- a/.env\n+++ b/.env\n@@ -1,1 +1,1 @@\n-API_KEY=1\n+API_KEY=2',
              'linesAdded': 1,
              'linesRemoved': 1,
            }
          ]
        }),
      );

      final engine = CodeModificationEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
        backupDir: backupPath,
      );

      final proposal =
          await engine.proposeModification(const CodeModificationPlanRequest(
        requirement: 'Update API key in .env',
      ));

      expect(proposal.isSuccess, isTrue);
      expect(proposal.isEligibleForApplication, isFalse);
      expect(proposal.errorMessage,
          contains('matches prohibited security denylist'));
      expect(proposal.validation.patchValid, isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: File Allowlist Restriction Enforcement
    // ─────────────────────────────────────────────────────────────────────────

    test('3. Allowlist Safeguard: enforces custom file allowlist restrictions',
        () async {
      scaffoldWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Modify pubspec.yaml',
          'affectedFiles': ['pubspec.yaml'],
          'patches': [
            {
              'relativePath': 'pubspec.yaml',
              'patchType': 'modify',
              'description': 'Add dependency',
              'diff':
                  '--- a/pubspec.yaml\n+++ b/pubspec.yaml\n@@ -1,1 +1,2 @@\n+dependencies:\n+  http: ^1.2.0',
              'linesAdded': 2,
              'linesRemoved': 0,
            }
          ]
        }),
      );

      final engine = CodeModificationEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
        backupDir: backupPath,
      );

      const policy = CodeModificationSafetyPolicy(
        allowlist: ['lib/**'], // Only lib directory permitted
      );

      final proposal =
          await engine.proposeModification(const CodeModificationPlanRequest(
        requirement: 'Add http dependency to pubspec.yaml',
        safetyPolicy: policy,
      ));

      expect(proposal.isEligibleForApplication, isFalse);
      expect(proposal.errorMessage,
          contains('is not present in the permitted allowlist'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Change Limits Enforcement (Max Files & Total Lines)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Change Limits Safeguard: blocks proposals exceeding file or line thresholds',
        () async {
      scaffoldWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Massive multi-file modification proposal',
          'affectedFiles': ['lib/a.dart', 'lib/b.dart', 'lib/c.dart'],
          'patches': [
            {
              'relativePath': 'lib/a.dart',
              'patchType': 'modify',
              'description': 'File A',
              'diff': '@@ -1,1 +1,100 @@',
              'linesAdded': 100,
              'linesRemoved': 0,
            },
            {
              'relativePath': 'lib/b.dart',
              'patchType': 'modify',
              'description': 'File B',
              'diff': '@@ -1,1 +1,100 @@',
              'linesAdded': 100,
              'linesRemoved': 0,
            },
            {
              'relativePath': 'lib/c.dart',
              'patchType': 'modify',
              'description': 'File C',
              'diff': '@@ -1,1 +1,100 @@',
              'linesAdded': 100,
              'linesRemoved': 0,
            },
          ]
        }),
      );

      final engine = CodeModificationEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
        backupDir: backupPath,
      );

      const policy = CodeModificationSafetyPolicy(
        maxFilesLimit: 2, // Max 2 files permitted
        maxTotalLinesChanged: 150, // Max 150 lines permitted
      );

      final proposal =
          await engine.proposeModification(const CodeModificationPlanRequest(
        requirement: 'Refactor all services',
        safetyPolicy: policy,
      ));

      expect(proposal.isEligibleForApplication, isFalse);
      expect(proposal.errorMessage, contains('exceeds max limit'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Validation Pipeline Before Commit (Tests, Analyzer, Formatter)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Validation Pipeline: verifies tests, analyzer, and formatter checks before marking eligible',
        () async {
      scaffoldWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Clean service enhancement',
          'affectedFiles': ['lib/sample.dart'],
          'patches': [
            {
              'relativePath': 'lib/sample.dart',
              'patchType': 'modify',
              'description': 'Add valid method',
              'proposedContent': 'class SampleService { void newMethod() {} }',
              'diff':
                  '--- a/lib/sample.dart\n+++ b/lib/sample.dart\n@@ -1,1 +1,1 @@\n+void newMethod() {}',
              'linesAdded': 1,
              'linesRemoved': 0,
            }
          ]
        }),
      );

      final engine = CodeModificationEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
        backupDir: backupPath,
      );

      final proposal =
          await engine.proposeModification(const CodeModificationPlanRequest(
        requirement: 'Add newMethod to SampleService',
      ));

      expect(proposal.validation.isAllPassed, isTrue);
      expect(proposal.validation.patchValid, isTrue);
      expect(proposal.validation.testsPassed, isTrue);
      expect(proposal.validation.analyzerPassed, isTrue);
      expect(proposal.validation.formatterPassed, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Explicit Execution Approval Requirement
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Execution Approval Gate: refuses to apply patch without explicit human authorization',
        () async {
      scaffoldWorkspace();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Safe patch proposal',
          'affectedFiles': ['lib/sample.dart'],
          'patches': [
            {
              'relativePath': 'lib/sample.dart',
              'patchType': 'modify',
              'description': 'Update method',
              'proposedContent': 'class SampleService { void updated() {} }',
              'diff': 'diff text',
              'linesAdded': 1,
              'linesRemoved': 1,
            }
          ]
        }),
      );

      final engine = CodeModificationEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
        backupDir: backupPath,
      );

      final proposal =
          await engine.proposeModification(const CodeModificationPlanRequest(
        requirement: 'Update method',
      ));

      // Attempt application without explicit approval
      final unapprovedResult = await engine.applyModification(
        proposal: proposal,
        explicitApproval: false,
      );
      expect(unapprovedResult.success, isFalse);
      expect(unapprovedResult.message,
          contains('Explicit execution approval is mandatory'));

      // File must NOT be modified
      final originalContent =
          File(p.join(rootPath, 'lib', 'sample.dart')).readAsStringSync();
      expect(originalContent.contains('hello'), isTrue);

      // Attempt application with explicit approval
      final approvedResult = await engine.applyModification(
        proposal: proposal,
        explicitApproval: true,
      );
      expect(approvedResult.success, isTrue);

      final modifiedContent =
          File(p.join(rootPath, 'lib', 'sample.dart')).readAsStringSync();
      expect(modifiedContent.contains('updated'), isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Automatic Backup Creation and Clean Rollback
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Rollback Mechanism: restores exact previous file snapshot on rollback request',
        () async {
      scaffoldWorkspace();

      final targetFile = File(p.join(rootPath, 'lib', 'sample.dart'));
      final beforeContent = targetFile.readAsStringSync();

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': 'Rollback test patch',
          'affectedFiles': ['lib/sample.dart'],
          'patches': [
            {
              'relativePath': 'lib/sample.dart',
              'patchType': 'modify',
              'description': 'Modify for rollback test',
              'proposedContent':
                  'class SampleService { void temporaryChange() {} }',
              'diff': 'diff text',
              'linesAdded': 1,
              'linesRemoved': 1,
            }
          ]
        }),
      );

      final engine = CodeModificationEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
        backupDir: backupPath,
      );

      final proposal =
          await engine.proposeModification(const CodeModificationPlanRequest(
        requirement: 'Temporary modification',
      ));

      // 1. Apply
      final applyRes = await engine.applyModification(
          proposal: proposal, explicitApproval: true);
      expect(applyRes.success, isTrue);
      expect(targetFile.readAsStringSync(), contains('temporaryChange'));

      // 2. Rollback
      final rollbackRes =
          await engine.rollbackModification(proposalId: proposal.proposalId);
      expect(rollbackRes.success, isTrue);
      expect(rollbackRes.isRollback, isTrue);

      // Verify file is restored to exact byte-content before patch
      expect(targetFile.readAsStringSync(), equals(beforeContent));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Secret Redaction on Outbound Prompt & Inbound Patch Output
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Secret Redaction Invariant: sensitive tokens are never exposed in prompt or change reports',
        () async {
      scaffoldWorkspace();

      const secretToken = 'ghp_secretTokenForCodeMod123456789';
      const promptWithSecret =
          'Add authentication header using token $secretToken to SampleService';

      final provider = MockAiProvider(
        defaultResponse: jsonEncode({
          'summary': promptWithSecret,
          'affectedFiles': ['lib/sample.dart'],
          'patches': [
            {
              'relativePath': 'lib/sample.dart',
              'patchType': 'modify',
              'description': 'Add auth token',
              'diff':
                  '--- a/lib/sample.dart\n+++ b/lib/sample.dart\n@@ -1,1 +1,1 @@\n+String token = "$secretToken";',
              'linesAdded': 1,
              'linesRemoved': 0,
            }
          ]
        }),
      );

      final engine = CodeModificationEngine.withProvider(
        projectRoot: rootPath,
        provider: provider,
        backupDir: backupPath,
      );

      final proposal =
          await engine.proposeModification(const CodeModificationPlanRequest(
        requirement: promptWithSecret,
      ));

      // Verify outbound prompt redacted
      final sentPrompt = provider.recordedRequests.first.prompt;
      expect(sentPrompt.contains(secretToken), isFalse);

      // Verify proposal summary and diffs redacted
      expect(proposal.requirement.contains(secretToken), isFalse);
      expect(proposal.summary.contains(secretToken), isFalse);

      // Verify renderer output redacted
      const renderer = CodeModificationRenderer();
      final mdOutput = renderer.renderMarkdown(proposal);
      final jsonOutput = renderer.renderJson(proposal);

      expect(mdOutput.contains(secretToken), isFalse);
      expect(jsonOutput.contains(secretToken), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: Dual-Format Change Report Rendering (JSON & Markdown)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9. Dual-Format Renderer: renders structured Markdown change report and schema-compliant JSON',
        () {
      final proposal = CodeModificationProposal(
        proposalId: 'mod_2026_test',
        requirement: 'Add retry logic to SampleService',
        summary: 'Introduce exponential backoff retry mechanism.',
        affectedFiles: ['lib/sample.dart'],
        patches: [
          FilePatch(
            relativePath: 'lib/sample.dart',
            patchType: FilePatchType.modify,
            description: 'Implement retry loop',
            diff:
                '--- a/lib/sample.dart\n+++ b/lib/sample.dart\n@@ -1,1 +1,2 @@\n+void retry() {}',
            linesAdded: 1,
            linesRemoved: 0,
          )
        ],
        safetyPolicy: const CodeModificationSafetyPolicy(),
        validation: const PatchValidationPipelineResult(
          patchValid: true,
          testsPassed: true,
          analyzerPassed: true,
          formatterPassed: true,
        ),
        totalLinesAdded: 1,
        totalLinesRemoved: 0,
        isEligibleForApplication: true,
        durationMs: 45,
        timestamp: DateTime.now(),
      );

      const renderer = CodeModificationRenderer();
      final mdStr = renderer.renderMarkdown(proposal);
      final jsonStr = renderer.renderJson(proposal);

      expect(
          mdStr,
          contains(
              '# AI-Assisted Controlled Code Modification — Change Report'));
      expect(mdStr, contains('## 1. Executive Summary & Modification Plan'));
      expect(mdStr, contains('## 2. Affected Files (1)'));
      expect(mdStr, contains('## 3. Patch Diff Previews (1)'));
      expect(mdStr, contains('## 4. Verification Pipeline Status'));
      expect(mdStr, contains('## 5. Governance & Safety Gate'));
      expect(mdStr, contains('Explicit Execution Approval Required'));

      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['proposalId'], equals('mod_2026_test'));
      expect(decoded['isEligibleForApplication'], isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 10: Fail-Closed Provider Error Handling
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '10. Fail-Closed Error Containment: provider exception returns safe failure proposal',
        () async {
      scaffoldWorkspace();

      final faultedProvider = MockAiProvider(
        injectedException: Exception('AI Provider 500 Internal Error'),
      );

      final engine = CodeModificationEngine.withProvider(
        projectRoot: rootPath,
        provider: faultedProvider,
        backupDir: backupPath,
      );

      final proposal =
          await engine.proposeModification(const CodeModificationPlanRequest(
        requirement: 'Any requirement',
      ));

      expect(proposal.isSuccess, isFalse);
      expect(proposal.isEligibleForApplication, isFalse);
      expect(proposal.errorMessage, contains('AI Provider 500'));
      expect(proposal.patches, isEmpty);
    });
  });
}
