import 'dart:convert';
import 'dart:io';
import 'package:syntrix/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 9.4 — Enterprise Audit Logging Tests', () {
    late Directory tempDir;
    late String rootPath;

    setUp(() {
      tempDir =
          Directory.systemTemp.createTempSync('fps_enterprise_audit_test_');
      rootPath = tempDir.path;

      // Scaffold project workspace
      File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: audit_sample_pkg
version: 1.0.0
environment:
  sdk: '>=3.5.0 <4.0.0'
''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    const releaseManager = EnterpriseIdentity(
      id: 'usr_rel_99',
      displayName: 'Jane Doe',
      email: 'jane.doe@enterprise.corp',
      roles: [EnterpriseRole.releaseManager],
      organizationId: 'enterprise_corp',
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Record All 11 Required Enterprise Event Types
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Model & Event Conformance: records and persists all 11 required audit event types',
        () async {
      final engine = EnterpriseAuditEngine(projectRoot: rootPath);

      final eventTypes = [
        AuditEventType.projectInspected,
        AuditEventType.aiAnalysisExecuted,
        AuditEventType.securityAuditExecuted,
        AuditEventType.versionChanged,
        AuditEventType.artifactGenerated,
        AuditEventType.releaseVerified,
        AuditEventType.gitTagCreated,
        AuditEventType.packagePublished,
        AuditEventType.rollbackExecuted,
        AuditEventType.policyChanged,
        AuditEventType.permissionChanged,
      ];

      for (final type in eventTypes) {
        final record = await engine.recordEvent(
          eventType: type,
          actorIdentity: releaseManager,
          operation: 'Executed ${type.name}',
          packageOrProject: 'audit_sample_pkg',
          outcome: AuditEventOutcome.success,
          relevantVersion: '1.0.0',
        );

        expect(record.eventType, equals(type));
        expect(record.recordHash, isNotEmpty);
        expect(record.verifyIntegrity(), isTrue);
      }

      final all = await engine.readAllRecords();
      expect(all.length, equals(11));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Cryptographic Tamper-Evidence & Hash Chain Integrity
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Tamper-Evidence: verifies cryptographic hash chain and detects tampered records',
        () async {
      final engine = EnterpriseAuditEngine(projectRoot: rootPath);

      await engine.recordEvent(
        eventType: AuditEventType.projectInspected,
        actorIdentity: releaseManager,
        operation: 'Initial inspection',
        packageOrProject: 'pkg_a',
        outcome: AuditEventOutcome.success,
      );

      await engine.recordEvent(
        eventType: AuditEventType.securityAuditExecuted,
        actorIdentity: releaseManager,
        operation: 'Security audit scan',
        packageOrProject: 'pkg_a',
        outcome: AuditEventOutcome.success,
      );

      // Verify intact chain
      expect(await engine.verifyAuditTrailIntegrity(), isTrue);

      // Tamper with audit log file directly
      final auditFile =
          File(p.join(rootPath, '.fps', 'audit', 'audit_log.jsonl'));
      final lines = auditFile.readAsLinesSync();
      // Modify first line operation maliciously
      final modifiedFirstLine = lines[0]
          .replaceAll('Initial inspection', 'Maliciously Altered Entry');
      auditFile.writeAsStringSync('$modifiedFirstLine\n${lines[1]}\n');

      // Reloaded engine should fail cryptographic verification
      final tamperedEngine = EnterpriseAuditEngine(projectRoot: rootPath);
      expect(await tamperedEngine.verifyAuditTrailIntegrity(), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Secret and Credential Redaction Invariant
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Secret Redaction Invariant: never records raw tokens, keys, or passwords',
        () async {
      final engine = EnterpriseAuditEngine(projectRoot: rootPath);

      const secretToken = 'ghp_SECRETTOKEN99999999999999999999';
      const awsSecret = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY';

      final record = await engine.recordEvent(
        eventType: AuditEventType.packagePublished,
        actorIdentity: releaseManager,
        operation: 'Publish with token=$secretToken',
        packageOrProject: 'pkg_secret',
        command: 'fps publish --key=$awsSecret',
        failureInformation: 'Auth failed with $secretToken',
        policyDecision: 'Evaluated key=$awsSecret',
        outcome: AuditEventOutcome.failure,
        metadata: {'token_param': secretToken},
      );

      // Raw secrets must NEVER appear in record or JSON
      final rawJson = jsonEncode(record.toJson());
      expect(rawJson, isNot(contains(secretToken)));
      expect(rawJson, isNot(contains(awsSecret)));
      expect(rawJson, contains('[REDACTED_GITHUB_TOKEN]'));
      expect(rawJson, contains('[REDACTED_SECRET]'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Querying and Filtering Audit Trail
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Audit Querying: filters records by event type, actor, outcome, and correlation ID',
        () async {
      final engine = EnterpriseAuditEngine(projectRoot: rootPath);

      await engine.recordEvent(
        eventType: AuditEventType.projectInspected,
        actorIdentity: releaseManager,
        operation: 'Inspect',
        packageOrProject: 'pkg_1',
        outcome: AuditEventOutcome.success,
        correlationId: 'cid_100',
      );

      await engine.recordEvent(
        eventType: AuditEventType.packagePublished,
        actorIdentity: releaseManager,
        operation: 'Publish',
        packageOrProject: 'pkg_2',
        outcome: AuditEventOutcome.failure,
        correlationId: 'cid_200',
      );

      final failedPublishes = await engine.queryRecords(
        eventType: AuditEventType.packagePublished,
        outcome: AuditEventOutcome.failure,
      );
      expect(failedPublishes.length, equals(1));
      expect(failedPublishes.first.correlationId, equals('cid_200'));

      final byCid = await engine.queryRecords(correlationId: 'cid_100');
      expect(byCid.length, equals(1));
      expect(byCid.first.packageOrProject, equals('pkg_1'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Pure Audit Renderer Conformance
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Renderer Conformance: generates deterministic JSON and Markdown audit reports',
        () async {
      final engine = EnterpriseAuditEngine(projectRoot: rootPath);
      await engine.recordEvent(
        eventType: AuditEventType.releaseVerified,
        actorIdentity: releaseManager,
        operation: 'Verify Release 1.0.0',
        packageOrProject: 'audit_sample_pkg',
        outcome: AuditEventOutcome.success,
        relevantVersion: '1.0.0',
      );

      final records = await engine.readAllRecords();
      const renderer = EnterpriseAuditRenderer();

      final json1 = renderer.renderJson(records);
      final json2 = renderer.renderJson(records);
      expect(json1, equals(json2));

      final md = renderer.renderMarkdown(records);
      expect(md, contains('# Enterprise Audit Trail Report'));
      expect(md, contains('Total Events: 1'));
      expect(md, contains('[Release Verified] `Verify Release 1.0.0`'));
      expect(md,
          contains('**Actor**: `Jane Doe` (`usr_rel_99` / `releaseManager`)'));
    });
  });
}
