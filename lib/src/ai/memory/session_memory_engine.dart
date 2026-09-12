/// Central engine for AI Engineering Session & Knowledge Memory (Phase 8.12).
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/ai/security/secret_redactor.dart';
import 'package:syntrix/src/ai/memory/session_memory_models.dart';

/// Central persistent engineering-session context & project knowledge memory engine.
///
/// Design Invariants:
/// 1. Project-Scoped Knowledge: Retains project-level engineering facts, architectural decisions,
///    known limitations, resolved bugs, release notes, and test histories.
/// 2. Session IDs & Summaries: Groups knowledge entries under discrete engineering sessions.
/// 3. Evidence References: Anchors knowledge entries to concrete files, line ranges, or docs.
/// 4. Expiration & Versioning: Detects expired knowledge and supports clean version evolution.
/// 5. Conflict Detection: Identifies contradictions across decisions (e.g. opposing architecture choices).
/// 6. Strict Secret Redaction: All data passed through is scrubbed by [SecretRedactor].
/// 7. Fail-Closed Error Containment: Invalid or corrupted storage files are handled gracefully.
class SessionMemoryEngine {
  final Logger _logger = Logger('SessionMemoryEngine');
  final String _projectRoot;
  final String _storagePath;

  String get projectRoot => _projectRoot;
  String get storagePath => _storagePath;

  SessionMemoryEngine({
    required String projectRoot,
    String? storagePath,
  })  : _projectRoot = p.normalize(projectRoot),
        _storagePath = storagePath != null
            ? p.normalize(storagePath)
            : p.join(
                p.normalize(projectRoot), '.fps', 'memory', 'sessions.json');

  /// Creates a new engineering session.
  Future<MemorySession> createSession({
    String? sessionId,
    String summary = 'Active engineering session',
    DateTime? now,
  }) async {
    final t = now ?? DateTime.now();
    final session = MemorySession.create(
      projectRoot: _projectRoot,
      sessionId: sessionId,
      summary: summary,
      now: t,
    );
    await saveSession(session);
    _logger
        .info('Created new engineering memory session: ${session.sessionId}');
    return session;
  }

  /// Loads all stored memory sessions for the project.
  Future<List<MemorySession>> loadAllSessions() async {
    final file = File(_storagePath);
    if (!file.existsSync()) {
      return [];
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(MemorySession.fromJson)
            .toList();
      } else if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('sessions') && decoded['sessions'] is List) {
          return (decoded['sessions'] as List)
              .whereType<Map<String, dynamic>>()
              .map(MemorySession.fromJson)
              .toList();
        }
        return [MemorySession.fromJson(decoded)];
      }
      return [];
    } catch (e) {
      _logger.warning(
          'Failed to load session memory storage from $_storagePath: $e');
      return [];
    }
  }

  /// Loads a specific session by its [sessionId].
  Future<MemorySession?> loadSession(String sessionId) async {
    final all = await loadAllSessions();
    for (final s in all) {
      if (s.sessionId == sessionId) return s;
    }
    return null;
  }

  /// Persists or updates a [session] to disk.
  Future<void> saveSession(MemorySession session) async {
    try {
      final file = File(_storagePath);
      final parentDir = file.parent;
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }

      final all = await loadAllSessions();
      final idx = all.indexWhere((s) => s.sessionId == session.sessionId);
      if (idx >= 0) {
        all[idx] = session;
      } else {
        all.add(session);
      }

      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(all.map((s) => s.toJson()).toList());
      final redacted = SecretRedactor.redact(jsonString);

      await file.writeAsString(redacted);
      _logger
          .info('Saved memory session ${session.sessionId} to $_storagePath');
    } catch (e, st) {
      _logger.error('Failed to save session memory: $e', e, st);
      rethrow;
    }
  }

  /// Records a new [KnowledgeEntry] into the specified [sessionId].
  /// Automatically analyzes and detects potential conflicts with existing entries.
  Future<({KnowledgeEntry entry, List<ConflictReport> conflicts})>
      recordKnowledge({
    required String sessionId,
    required KnowledgeEntryType type,
    required String title,
    required String content,
    List<EvidenceReference> evidenceRefs = const [],
    List<String> tags = const [],
    String scope = 'workspace',
    DateTime? expiresAt,
    DateTime? now,
  }) async {
    final t = now ?? DateTime.now();
    var session = await loadSession(sessionId);
    session ??= MemorySession.create(
      projectRoot: _projectRoot,
      sessionId: sessionId,
      summary: 'Active engineering session',
      now: t,
    );

    final entryId =
        'ke_${t.millisecondsSinceEpoch}_${title.hashCode.abs().toRadixString(16)}';
    final entry = KnowledgeEntry(
      id: entryId,
      sessionId: sessionId,
      type: type,
      title: title,
      content: content,
      evidenceRefs: evidenceRefs,
      tags: tags,
      scope: scope,
      createdAt: t,
      expiresAt: expiresAt,
    );

    // Conflict detection across all entries in the project
    final allSessions = await loadAllSessions();
    final allEntries = allSessions.expand((s) => s.entries).toList();
    final conflicts = detectConflicts(entry, allEntries);

    session = session.withEntry(entry, now: t);
    await saveSession(session);

    _logger.info(
        'Recorded knowledge entry "$title" in session "$sessionId" with ${conflicts.length} conflict(s).');
    return (entry: entry, conflicts: conflicts);
  }

  /// Analyzes potential conflicts between a candidate [candidate] entry and existing [allEntries].
  List<ConflictReport> detectConflicts(
    KnowledgeEntry candidate,
    List<KnowledgeEntry> allEntries,
  ) {
    final conflicts = <ConflictReport>[];
    final candWords = candidate.title
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 3)
        .toSet();
    final candContent = candidate.content.toLowerCase();

    for (final existing in allEntries) {
      if (existing.id == candidate.id) continue;

      // 1. Check same category and high title word overlap
      final existingWords = existing.title
          .toLowerCase()
          .split(RegExp(r'\W+'))
          .where((w) => w.length > 3)
          .toSet();
      final overlap = candWords.intersection(existingWords);

      final isHighTopicOverlap = overlap.length >= 2 ||
          (candWords.isNotEmpty && overlap.length == candWords.length);

      if (isHighTopicOverlap) {
        final existingContent = existing.content.toLowerCase();

        // 2. Check for contradicting phrases (e.g. "use X" vs "do not use X" or "rejected" vs "chosen")
        final contradicts = _detectContradiction(candContent, existingContent);

        if (contradicts != null) {
          conflicts.add(ConflictReport(
            existingEntryId: existing.id,
            competingEntryId: candidate.id,
            topic: candidate.title,
            reason:
                'Contradiction detected with existing entry "${existing.title}": $contradicts',
            severity: candidate.type == KnowledgeEntryType.architecture ||
                    candidate.type == KnowledgeEntryType.decision
                ? 'critical'
                : 'warning',
          ));
        } else if (candidate.type == existing.type &&
            candidate.title.trim().toLowerCase() ==
                existing.title.trim().toLowerCase()) {
          conflicts.add(ConflictReport(
            existingEntryId: existing.id,
            competingEntryId: candidate.id,
            topic: candidate.title,
            reason:
                'Duplicate entry title with different content in session "${existing.sessionId}". Consider versioning or updating.',
            severity: 'warning',
          ));
        }
      }
    }

    return conflicts;
  }

  /// Simple rule-based contradiction detection.
  String? _detectContradiction(String textA, String textB) {
    // Negation pairs
    final pairs = [
      ('must use', 'must not use'),
      ('required', 'forbidden'),
      ('prohibited', 'permitted'),
      ('allowed', 'disallowed'),
      ('enabled', 'disabled'),
      ('use riverpod', 'use bloc'),
      ('monorepo', 'multirepo'),
      ('synchronous', 'asynchronous'),
      ('sqlite', 'hive'),
      ('offline-only', 'cloud-sync'),
    ];

    for (final pair in pairs) {
      final hasA1 = textA.contains(pair.$1);
      final hasA2 = textA.contains(pair.$2);
      final hasB1 = textB.contains(pair.$1);
      final hasB2 = textB.contains(pair.$2);

      if ((hasA1 && hasB2) || (hasA2 && hasB1)) {
        return 'Opposing statements regarding "${pair.$1}" vs "${pair.$2}".';
      }
    }

    // Check explicit rejection keywords
    if ((textA.contains('chosen') ||
            textA.contains('approved') ||
            textA.contains('adopted')) &&
        (textB.contains('rejected') ||
            textB.contains('deprecated') ||
            textB.contains('avoid'))) {
      return 'One entry approves/adopts this approach while the other marks it as rejected/avoided.';
    }
    if ((textB.contains('chosen') ||
            textB.contains('approved') ||
            textB.contains('adopted')) &&
        (textA.contains('rejected') ||
            textA.contains('deprecated') ||
            textA.contains('avoid'))) {
      return 'One entry approves/adopts this approach while the other marks it as rejected/avoided.';
    }

    return null;
  }

  /// Queries stored engineering knowledge using natural language keywords and optional filters.
  Future<MemoryQueryResult> query(
    MemoryQueryRequest request, {
    DateTime? executionTimestamp,
  }) async {
    final stopwatch = Stopwatch()..start();
    final now = executionTimestamp ?? DateTime.now();

    try {
      final sessions = await loadAllSessions();
      var candidateEntries = sessions.expand((s) => s.entries).toList();

      // Filter expired unless requested
      if (!request.includeExpired) {
        candidateEntries =
            candidateEntries.where((e) => !e.isExpired(now)).toList();
      }

      // Filter by session ID
      if (request.sessionId != null && request.sessionId!.isNotEmpty) {
        candidateEntries = candidateEntries
            .where((e) => e.sessionId == request.sessionId)
            .toList();
      }

      // Filter by type
      if (request.type != null) {
        candidateEntries =
            candidateEntries.where((e) => e.type == request.type).toList();
      }

      // Filter by scope
      if (request.scope != null && request.scope!.isNotEmpty) {
        candidateEntries = candidateEntries
            .where((e) => e.scope == request.scope || e.scope == 'workspace')
            .toList();
      }

      // Filter by tags
      if (request.tags.isNotEmpty) {
        candidateEntries = candidateEntries
            .where((e) => request.tags.any((t) => e.tags.contains(t)))
            .toList();
      }

      // Score and rank matches by query terms
      final queryKeywords = request.query
          .toLowerCase()
          .split(RegExp(r'\W+'))
          .where((w) => w.length >= 3 && !_commonStopWords.contains(w))
          .toList();

      final scored = <({KnowledgeEntry entry, int score})>[];

      for (final entry in candidateEntries) {
        int score = 0;
        final titleLower = entry.title.toLowerCase();
        final contentLower = entry.content.toLowerCase();
        final tagsLower = entry.tags.map((t) => t.toLowerCase()).toList();

        // Exact match on title
        if (titleLower.contains(request.query.toLowerCase())) {
          score += 20;
        }

        // Match type label or type name
        if (entry.type.name
                .toLowerCase()
                .contains(request.query.toLowerCase()) ||
            entry.type.label
                .toLowerCase()
                .contains(request.query.toLowerCase())) {
          score += 10;
        }

        for (final kw in queryKeywords) {
          if (titleLower.contains(kw)) score += 5;
          if (contentLower.contains(kw)) score += 2;
          if (tagsLower.contains(kw)) score += 4;
          if (entry.type.name.toLowerCase().contains(kw) ||
              entry.type.label.toLowerCase().contains(kw)) {
            score += 3;
          }
        }

        // Boost architecture / decision entries when asking "why" or "how"
        if (request.query.toLowerCase().contains('why') ||
            request.query.toLowerCase().contains('architecture')) {
          if (entry.type == KnowledgeEntryType.architecture ||
              entry.type == KnowledgeEntryType.decision) {
            score += 5;
          }
        }

        if (score > 0 || queryKeywords.isEmpty) {
          scored.add((entry: entry, score: score));
        }
      }

      scored.sort((a, b) => b.score.compareTo(a.score));
      final topEntries =
          scored.take(request.limit).map((s) => s.entry).toList();

      // Check for conflicts within top matching entries
      final detectedConflicts = <ConflictReport>[];
      for (int i = 0; i < topEntries.length; i++) {
        final conflicts =
            detectConflicts(topEntries[i], topEntries.sublist(i + 1));
        detectedConflicts.addAll(conflicts);
      }

      // Formulate synthesis
      final synthesis = _synthesizeAnswer(
        query: request.query,
        entries: topEntries,
        conflicts: detectedConflicts,
      );

      stopwatch.stop();

      return MemoryQueryResult(
        query: request.query,
        entries: topEntries,
        synthesis: synthesis,
        conflictsDetected: detectedConflicts,
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    } catch (e, st) {
      stopwatch.stop();
      _logger.error('Error during memory query: $e', e, st);
      return MemoryQueryResult.failure(
        query: request.query,
        errorMessage:
            'Memory query failed: ${SecretRedactor.redact(e.toString())}',
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: now,
      );
    }
  }

  /// Removes all expired entries across all sessions.
  Future<int> purgeExpired({DateTime? now}) async {
    final t = now ?? DateTime.now();
    final all = await loadAllSessions();
    int purgedCount = 0;

    final updatedSessions = <MemorySession>[];
    for (final s in all) {
      final initialCount = s.entries.length;
      final purged = s.purgeExpired(now: t);
      purgedCount += (initialCount - purged.entries.length);
      updatedSessions.add(purged);
    }

    if (purgedCount > 0) {
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString =
          encoder.convert(updatedSessions.map((s) => s.toJson()).toList());
      final redacted = SecretRedactor.redact(jsonString);
      await File(_storagePath).writeAsString(redacted);
      _logger.info('Purged $purgedCount expired knowledge entries.');
    }

    return purgedCount;
  }

  /// Synthesizes a structured markdown answer based on retrieved entries and evidence.
  String _synthesizeAnswer({
    required String query,
    required List<KnowledgeEntry> entries,
    required List<ConflictReport> conflicts,
  }) {
    if (entries.isEmpty) {
      return 'No documented engineering decisions, architecture records, or implementation reports found matching "$query".';
    }

    final buf = StringBuffer();
    buf.writeln(
        'Based on project engineering memory and documented decisions:');
    buf.writeln();

    for (final e in entries) {
      buf.writeln('### ${e.type.label}: ${e.title} (v${e.version})');
      buf.writeln(e.content);
      if (e.evidenceRefs.isNotEmpty) {
        buf.writeln();
        buf.writeln('**Evidence References:**');
        for (final ref in e.evidenceRefs) {
          final loc = ref.location != null ? ' (${ref.location})' : '';
          buf.writeln('- `${ref.path}`$loc: ${ref.description}');
        }
      }
      buf.writeln();
    }

    if (conflicts.isNotEmpty) {
      buf.writeln('⚠️ **Attention: Architectural Conflicts Detected**');
      for (final c in conflicts) {
        buf.writeln('- [${c.severity.toUpperCase()}] ${c.reason}');
      }
      buf.writeln();
    }

    return SecretRedactor.redact(buf.toString().trim());
  }

  static const _commonStopWords = {
    'the',
    'is',
    'at',
    'which',
    'on',
    'a',
    'an',
    'and',
    'or',
    'in',
    'for',
    'of',
    'to',
    'with',
    'by',
    'as',
    'what',
    'why',
    'how',
    'when',
    'who',
    'we',
    'did',
    'do'
  };
}
