import 'dart:io';
import 'package:flutter_package_studio_core/flutter_package_studio_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Phase 8.12 — AI Engineering Session & Knowledge Memory Tests', () {
    late Directory tempDir;
    late String rootPath;
    late String storagePath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('fps_session_memory_test_');
      rootPath = tempDir.path;
      storagePath = p.join(rootPath, '.fps', 'memory', 'sessions.json');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 1: Session Creation & Persistence
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '1. Session Lifecycle: SessionMemoryEngine creates, persists, and restores sessions',
        () async {
      final engine = SessionMemoryEngine(
        projectRoot: rootPath,
        storagePath: storagePath,
      );

      final session = await engine.createSession(
        sessionId: 'session_arch_2026',
        summary: 'Architecture decisions for multi-platform packaging',
      );

      expect(session.sessionId, equals('session_arch_2026'));
      expect(session.summary, contains('Architecture decisions'));
      expect(File(storagePath).existsSync(), isTrue);

      final loaded = await engine.loadSession('session_arch_2026');
      expect(loaded, isNotNull);
      expect(loaded!.sessionId, equals('session_arch_2026'));
      expect(loaded.summary, equals(session.summary));
      expect(loaded.entries, isEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 2: Knowledge Entry Types Coverage
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '2. Knowledge Types: supports all 8 required project engineering knowledge categories',
        () async {
      final engine = SessionMemoryEngine(
        projectRoot: rootPath,
        storagePath: storagePath,
      );

      final types = [
        KnowledgeEntryType.decision,
        KnowledgeEntryType.limitation,
        KnowledgeEntryType.architecture,
        KnowledgeEntryType.bug,
        KnowledgeEntryType.releaseHistory,
        KnowledgeEntryType.testHistory,
        KnowledgeEntryType.implementationReport,
        KnowledgeEntryType.repeatedIssue,
      ];

      for (final type in types) {
        final result = await engine.recordKnowledge(
          sessionId: 'session_all_types',
          type: type,
          title: '${type.label} Title',
          content: 'Details regarding ${type.name}',
          tags: [type.name],
        );
        expect(result.entry.type, equals(type));
        expect(result.entry.title, contains(type.label));
      }

      final session = await engine.loadSession('session_all_types');
      expect(session, isNotNull);
      expect(session!.entries.length, equals(8));

      // Verify serialization / deserialization roundtrip
      final allSessions = await engine.loadAllSessions();
      expect(allSessions.length, equals(1));
      expect(allSessions.first.entries.length, equals(8));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 3: Evidence References Anchoring
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '3. Evidence Grounding: records and restores concrete evidence references',
        () async {
      final engine = SessionMemoryEngine(
        projectRoot: rootPath,
        storagePath: storagePath,
      );

      final refs = [
        EvidenceReference(
          path: 'packages/core/lib/src/packager.dart',
          location: 'lines 45-60',
          description: 'Factory constructor for Debian packager',
        ),
        EvidenceReference(
          path: 'doc/architecture/ADR_004.md',
          description: 'Formal ADR document',
        ),
      ];

      final result = await engine.recordKnowledge(
        sessionId: 'session_grounded',
        type: KnowledgeEntryType.architecture,
        title: 'Adopt Layered Core-CLI Architecture',
        content:
            'Core package contains no terminal I/O; CLI package handles commands.',
        evidenceRefs: refs,
        tags: ['architecture', 'layering'],
      );

      expect(result.entry.evidenceRefs.length, equals(2));
      expect(result.entry.evidenceRefs[0].location, equals('lines 45-60'));

      final queryResult = await engine.query(const MemoryQueryRequest(
        query: 'Why did we choose layered architecture?',
      ));

      expect(queryResult.isSuccess, isTrue);
      expect(queryResult.entries, isNotEmpty);
      expect(queryResult.synthesis, contains('Evidence References:'));
      expect(queryResult.synthesis,
          contains('packages/core/lib/src/packager.dart'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 4: Conflict Detection (Contradicting Decisions)
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '4. Conflict Detection: flags contradictions between opposing architectural choices',
        () async {
      final engine = SessionMemoryEngine(
        projectRoot: rootPath,
        storagePath: storagePath,
      );

      // Record baseline decision
      await engine.recordKnowledge(
        sessionId: 'session_early',
        type: KnowledgeEntryType.architecture,
        title: 'State Management Architecture',
        content:
            'For UI state management, the system must use Riverpod for deterministic dependency injection.',
      );

      // Record contradicting decision
      final outcome = await engine.recordKnowledge(
        sessionId: 'session_late',
        type: KnowledgeEntryType.architecture,
        title: 'State Management Architecture Pattern',
        content:
            'For UI state management, the system must not use Riverpod and must use BLoC.',
      );

      expect(outcome.conflicts, isNotEmpty);
      expect(outcome.conflicts.first.severity, equals('critical'));
      expect(outcome.conflicts.first.reason, contains('Opposing statements'));

      // Query should also surface the conflict warning
      final queryRes = await engine.query(const MemoryQueryRequest(
        query: 'State Management Architecture',
      ));

      expect(queryRes.conflictsDetected, isNotEmpty);
      expect(queryRes.synthesis, contains('Architectural Conflicts Detected'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 5: Expiration & Purge
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '5. Expiration & Versioning: respects expiresAt and purges outdated entries',
        () async {
      final engine = SessionMemoryEngine(
        projectRoot: rootPath,
        storagePath: storagePath,
      );

      final now = DateTime(2026, 9, 4, 12, 0, 0);

      // Entry expired 1 day ago
      await engine.recordKnowledge(
        sessionId: 'session_expiry',
        type: KnowledgeEntryType.limitation,
        title: 'Temporary Workaround for Dart 3.4 Bug',
        content: 'Manual cast needed until Dart 3.5 upgrade.',
        expiresAt: now.subtract(const Duration(days: 1)),
        now: now.subtract(const Duration(days: 5)),
      );

      // Entry still valid (expires in 10 days)
      await engine.recordKnowledge(
        sessionId: 'session_expiry',
        type: KnowledgeEntryType.limitation,
        title: 'Permanent Database Size Limitation',
        content: 'Max SQLite file size limited to 2GB.',
        expiresAt: now.add(const Duration(days: 10)),
        now: now,
      );

      // Default query excludes expired
      final queryValid = await engine.query(
        const MemoryQueryRequest(query: 'Limitation', includeExpired: false),
        executionTimestamp: now,
      );
      expect(queryValid.entries.length, equals(1));
      expect(queryValid.entries.first.title, contains('Permanent Database'));

      // Query with includeExpired = true returns both
      final queryAll = await engine.query(
        const MemoryQueryRequest(query: 'Limitation', includeExpired: true),
        executionTimestamp: now,
      );
      expect(queryAll.entries.length, equals(2));

      // Purge expired entries
      final purged = await engine.purgeExpired(now: now);
      expect(purged, equals(1));

      final sessionAfter = await engine.loadSession('session_expiry');
      expect(sessionAfter!.entries.length, equals(1));
      expect(sessionAfter.entries.first.title, contains('Permanent Database'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 6: Question Answering Synthesis ("Why did we choose this architecture?")
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '6. Example Query: "Why did we choose this architecture?" resolves documented engineering decisions',
        () async {
      final engine = SessionMemoryEngine(
        projectRoot: rootPath,
        storagePath: storagePath,
      );

      await engine.recordKnowledge(
        sessionId: 'session_m8',
        type: KnowledgeEntryType.architecture,
        title: 'Milestone 8 Modular Subsystem Architecture',
        content:
            'We chose a modular subsystem architecture where each AI advisory capability (security, dependency, review, planner, memory) lives in its own directory with dedicated models, engine, and renderer to ensure fail-closed isolation and testability.',
        tags: ['architecture', 'modular', 'subsystems'],
      );

      final queryRes = await engine.query(const MemoryQueryRequest(
        query: 'Why did we choose this architecture?',
      ));

      expect(queryRes.isSuccess, isTrue);
      expect(queryRes.entries, isNotEmpty);
      expect(queryRes.entries.first.title, contains('Modular Subsystem'));
      expect(queryRes.synthesis, contains('modular subsystem architecture'));
      expect(queryRes.synthesis, contains('fail-closed isolation'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 7: Secret Redaction on Ingestion, Persistence, and Query Output
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '7. Secret Redaction: sensitive tokens are never written to disk or exposed in query outputs',
        () async {
      final engine = SessionMemoryEngine(
        projectRoot: rootPath,
        storagePath: storagePath,
      );

      const secretToken = 'ghp_superSecretPersonalAccessToken998877';
      const secretPassword = 'password: "SuperSecretPassword123!"';

      await engine.recordKnowledge(
        sessionId: 'session_secure',
        type: KnowledgeEntryType.decision,
        title: 'API Authentication Setup with $secretToken',
        content:
            'Configure private pub repository using $secretPassword and token $secretToken.',
      );

      // Verify file on disk is sanitized
      final diskContent = File(storagePath).readAsStringSync();
      expect(diskContent.contains(secretToken), isFalse);
      expect(diskContent.contains('[REDACTED_GITHUB_TOKEN]'), isTrue);

      // Verify query result is sanitized
      final queryRes = await engine.query(const MemoryQueryRequest(
        query: 'API Authentication',
      ));
      expect(queryRes.synthesis.contains(secretToken), isFalse);

      // Verify renderer output is sanitized
      const renderer = SessionMemoryRenderer();
      final md = renderer.renderQueryMarkdown(queryRes);
      expect(md.contains(secretToken), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 8: Read-Only Query Safety Invariant
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '8. Read-Only Query Invariant: querying memory does not modify project workspace files',
        () async {
      final engine = SessionMemoryEngine(
        projectRoot: rootPath,
        storagePath: storagePath,
      );

      await engine.recordKnowledge(
        sessionId: 'session_safety',
        type: KnowledgeEntryType.decision,
        title: 'Safety Invariant Test',
        content: 'Read-only guarantee test entry.',
      );

      final storageBefore = File(storagePath).readAsStringSync();

      await engine.query(const MemoryQueryRequest(
        query: 'Safety Invariant Test',
      ));

      final storageAfter = File(storagePath).readAsStringSync();
      expect(storageAfter, equals(storageBefore));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 9: Fail-Closed on Corrupted Storage File
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '9. Fail-Closed Error Containment: gracefully handles corrupted JSON storage file',
        () async {
      final engine = SessionMemoryEngine(
        projectRoot: rootPath,
        storagePath: storagePath,
      );

      // Write corrupted JSON
      final file = File(storagePath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('{{{ CORRUPTED MALFORMED JSON content');

      final sessions = await engine.loadAllSessions();
      expect(sessions, isEmpty);

      final queryRes = await engine.query(const MemoryQueryRequest(
        query: 'Any query',
      ));
      expect(queryRes.isSuccess, isTrue);
      expect(queryRes.entries, isEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // Test 10: Regression Check on AssistantCapability.crossSessionMemory
    // ─────────────────────────────────────────────────────────────────────────

    test(
        '10. Capability Alignment: verifies AssistantCapability.crossSessionMemory is registered',
        () {
      expect(AssistantCapability.values,
          contains(AssistantCapability.crossSessionMemory));
      expect(AssistantCapability.tryParse('crossSessionMemory'),
          equals(AssistantCapability.crossSessionMemory));
    });
  });
}
