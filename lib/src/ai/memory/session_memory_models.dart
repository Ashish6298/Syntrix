/// Domain models for AI Engineering Session & Knowledge Memory (Phase 8.12).
library;

import 'package:syntrix/src/ai/security/secret_redactor.dart';

/// Supported types of project-level engineering knowledge entries.
enum KnowledgeEntryType {
  /// Formal architectural and system design decisions.
  decision,

  /// Documented system limitations, capacity bounds, and constraints.
  limitation,

  /// Major architectural styles, subsystem boundaries, and structural rules.
  architecture,

  /// Known, tracked, or resolved software defects.
  bug,

  /// Historical release notes, version transitions, and changelog records.
  releaseHistory,

  /// Test run records, regression history, benchmarks, and coverage records.
  testHistory,

  /// Completed milestone or phase implementation reports and artifacts.
  implementationReport,

  /// Recurring pitfalls, flaky dependencies, or repeated engineering issues.
  repeatedIssue;

  /// Human-readable label for rendering.
  String get label {
    switch (this) {
      case KnowledgeEntryType.decision:
        return 'Engineering Decision';
      case KnowledgeEntryType.limitation:
        return 'Known Limitation';
      case KnowledgeEntryType.architecture:
        return 'Architecture Decision';
      case KnowledgeEntryType.bug:
        return 'Resolved Bug / Defect';
      case KnowledgeEntryType.releaseHistory:
        return 'Release History';
      case KnowledgeEntryType.testHistory:
        return 'Test History';
      case KnowledgeEntryType.implementationReport:
        return 'Implementation Report';
      case KnowledgeEntryType.repeatedIssue:
        return 'Repeated Issue';
    }
  }

  /// Parses a string into a [KnowledgeEntryType], defaulting to [decision] or null if invalid.
  static KnowledgeEntryType? tryParse(String? raw) {
    if (raw == null) return null;
    final clean = raw.trim().toLowerCase().replaceAll(RegExp(r'[-_\s]'), '');
    for (final val in KnowledgeEntryType.values) {
      if (val.name.toLowerCase() == clean) return val;
      if (val.label.toLowerCase().replaceAll(RegExp(r'[-_\s]'), '') == clean) {
        return val;
      }
    }
    // Handle common aliases
    if (clean == 'architecturedecision' || clean == 'arch') {
      return KnowledgeEntryType.architecture;
    }
    if (clean == 'knownlimitation' || clean == 'limitations') {
      return KnowledgeEntryType.limitation;
    }
    if (clean == 'resolvedbug' || clean == 'defect') {
      return KnowledgeEntryType.bug;
    }
    if (clean == 'release' || clean == 'releasehistory') {
      return KnowledgeEntryType.releaseHistory;
    }
    if (clean == 'test' || clean == 'testhistory') {
      return KnowledgeEntryType.testHistory;
    }
    if (clean == 'report' || clean == 'implementation') {
      return KnowledgeEntryType.implementationReport;
    }
    if (clean == 'repeated' || clean == 'repeatedissue') {
      return KnowledgeEntryType.repeatedIssue;
    }
    return null;
  }
}

/// An individual verifiable reference anchoring a knowledge entry to code, docs, or files.
class EvidenceReference {
  /// Target file path relative to workspace root (or URI).
  final String path;

  /// Specific symbol, line range, commit SHA, or section identifier.
  final String? location;

  /// Brief description of the evidence context.
  final String description;

  EvidenceReference({
    required String path,
    this.location,
    required String description,
  })  : path = SecretRedactor.redact(path.replaceAll('\\', '/')),
        description = SecretRedactor.redact(description);

  factory EvidenceReference.fromJson(Map<String, dynamic> json) =>
      EvidenceReference(
        path: json['path'] as String? ?? '',
        location: json['location'] as String?,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'path': SecretRedactor.redact(path),
        if (location != null) 'location': SecretRedactor.redact(location!),
        'description': SecretRedactor.redact(description),
      };
}

/// Single persistent project-level knowledge entry.
class KnowledgeEntry {
  /// Unique identifier (e.g. `ke_1719200000_abc`).
  final String id;

  /// Associated engineering session ID.
  final String sessionId;

  /// Category / type of knowledge.
  final KnowledgeEntryType type;

  /// Topic title / summary header.
  final String title;

  /// Full markdown or plain-text content.
  final String content;

  /// Concrete evidence references in the codebase or documentation.
  final List<EvidenceReference> evidenceRefs;

  /// Categorical tags for indexing (e.g. `['packaging', 'debian', 'cli']`).
  final List<String> tags;

  /// Target component or package scope in a monorepo.
  final String scope;

  /// SemVer or integer version of this knowledge record.
  final int version;

  /// Timestamp of creation.
  final DateTime createdAt;

  /// Optional expiration timestamp (null = never expires).
  final DateTime? expiresAt;

  KnowledgeEntry({
    required this.id,
    required this.sessionId,
    required this.type,
    required String title,
    required String content,
    this.evidenceRefs = const [],
    this.tags = const [],
    this.scope = 'workspace',
    this.version = 1,
    required this.createdAt,
    this.expiresAt,
  })  : title = SecretRedactor.redact(title),
        content = SecretRedactor.redact(content);

  /// Whether this entry has exceeded its expiration date relative to [now].
  bool isExpired([DateTime? now]) {
    if (expiresAt == null) return false;
    final current = now ?? DateTime.now();
    return current.isAfter(expiresAt!);
  }

  /// Creates a new copy with bumped version and updated content.
  KnowledgeEntry createUpdatedVersion({
    String? newTitle,
    String? newContent,
    List<EvidenceReference>? newEvidenceRefs,
    List<String>? newTags,
    String? newScope,
    DateTime? newExpiresAt,
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    return KnowledgeEntry(
      id: id,
      sessionId: sessionId,
      type: type,
      title: newTitle ?? title,
      content: newContent ?? content,
      evidenceRefs: newEvidenceRefs ?? evidenceRefs,
      tags: newTags ?? tags,
      scope: newScope ?? scope,
      version: version + 1,
      createdAt: t,
      expiresAt: newExpiresAt ?? expiresAt,
    );
  }

  factory KnowledgeEntry.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String?;
    final entryType =
        KnowledgeEntryType.tryParse(rawType) ?? KnowledgeEntryType.decision;

    final rawRefs = json['evidenceRefs'] as List<dynamic>? ?? const [];
    final refs = rawRefs
        .whereType<Map<String, dynamic>>()
        .map(EvidenceReference.fromJson)
        .toList();

    final rawTags = json['tags'] as List<dynamic>? ?? const [];
    final tags = rawTags.map((e) => e.toString()).toList();

    return KnowledgeEntry(
      id: json['id'] as String? ?? 'ke_unknown',
      sessionId: json['sessionId'] as String? ?? 'default',
      type: entryType,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      evidenceRefs: refs,
      tags: tags,
      scope: json['scope'] as String? ?? 'workspace',
      version: json['version'] as int? ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'type': type.name,
        'title': SecretRedactor.redact(title),
        'content': SecretRedactor.redact(content),
        'evidenceRefs': evidenceRefs.map((r) => r.toJson()).toList(),
        'tags': tags,
        'scope': scope,
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      };
}

/// Representation of a detected conflict between two knowledge entries.
class ConflictReport {
  /// The existing or conflicting knowledge entry ID.
  final String existingEntryId;

  /// The new or competing knowledge entry ID.
  final String competingEntryId;

  /// The topic or title where conflict occurs.
  final String topic;

  /// Detailed human-readable explanation of why these entries conflict.
  final String reason;

  /// Severity level: 'warning' or 'critical'.
  final String severity;

  ConflictReport({
    required this.existingEntryId,
    required this.competingEntryId,
    required String topic,
    required String reason,
    this.severity = 'warning',
  })  : topic = SecretRedactor.redact(topic),
        reason = SecretRedactor.redact(reason);

  factory ConflictReport.fromJson(Map<String, dynamic> json) => ConflictReport(
        existingEntryId: json['existingEntryId'] as String? ?? '',
        competingEntryId: json['competingEntryId'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        severity: json['severity'] as String? ?? 'warning',
      );

  Map<String, dynamic> toJson() => {
        'existingEntryId': existingEntryId,
        'competingEntryId': competingEntryId,
        'topic': SecretRedactor.redact(topic),
        'reason': SecretRedactor.redact(reason),
        'severity': severity,
      };
}

/// Engineering Session holding project-level engineering memory and context summaries.
class MemorySession {
  /// Unique session identifier (e.g. `session_2026_09_04_arch`).
  final String sessionId;

  /// Project root directory.
  final String projectRoot;

  /// High-level context summary of this session's engineering scope.
  final String summary;

  /// Documented knowledge entries associated with this session.
  final List<KnowledgeEntry> entries;

  /// Session creation timestamp.
  final DateTime createdAt;

  /// Last accessed or updated timestamp.
  final DateTime lastAccessedAt;

  MemorySession({
    required this.sessionId,
    required this.projectRoot,
    required String summary,
    this.entries = const [],
    required this.createdAt,
    required this.lastAccessedAt,
  }) : summary = SecretRedactor.redact(summary);

  factory MemorySession.create({
    required String projectRoot,
    String? sessionId,
    String summary = 'Active engineering session',
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final id = sessionId ?? 'session_${t.millisecondsSinceEpoch}';
    return MemorySession(
      sessionId: id,
      projectRoot: projectRoot,
      summary: summary,
      entries: const [],
      createdAt: t,
      lastAccessedAt: t,
    );
  }

  /// Adds a new knowledge entry and returns an updated session.
  MemorySession withEntry(KnowledgeEntry entry, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final updatedList = List<KnowledgeEntry>.from(entries);
    // Replace if same ID, otherwise append
    final idx = updatedList.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      updatedList[idx] = entry;
    } else {
      updatedList.add(entry);
    }
    return MemorySession(
      sessionId: sessionId,
      projectRoot: projectRoot,
      summary: summary,
      entries: updatedList,
      createdAt: createdAt,
      lastAccessedAt: t,
    );
  }

  /// Removes expired entries.
  MemorySession purgeExpired({DateTime? now}) {
    final t = now ?? DateTime.now();
    final validEntries = entries.where((e) => !e.isExpired(t)).toList();
    return MemorySession(
      sessionId: sessionId,
      projectRoot: projectRoot,
      summary: summary,
      entries: validEntries,
      createdAt: createdAt,
      lastAccessedAt: t,
    );
  }

  factory MemorySession.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? const [];
    final entries = rawEntries
        .whereType<Map<String, dynamic>>()
        .map(KnowledgeEntry.fromJson)
        .toList();

    return MemorySession(
      sessionId: json['sessionId'] as String? ?? 'default',
      projectRoot: json['projectRoot'] as String? ?? '.',
      summary: json['summary'] as String? ?? '',
      entries: entries,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'projectRoot': projectRoot,
        'summary': SecretRedactor.redact(summary),
        'entries': entries.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'lastAccessedAt': lastAccessedAt.toIso8601String(),
      };
}

/// Request parameters for querying project engineering memory.
class MemoryQueryRequest {
  /// Natural language question or query (e.g. "Why did we choose this architecture?").
  final String query;

  /// Optional filter by knowledge type.
  final KnowledgeEntryType? type;

  /// Optional filter by session ID.
  final String? sessionId;

  /// Optional filter by tags.
  final List<String> tags;

  /// Optional filter by component scope.
  final String? scope;

  /// Whether to include expired entries (defaults to false).
  final bool includeExpired;

  /// Max entries to return.
  final int limit;

  const MemoryQueryRequest({
    required this.query,
    this.type,
    this.sessionId,
    this.tags = const [],
    this.scope,
    this.includeExpired = false,
    this.limit = 10,
  });

  Map<String, dynamic> toJson() => {
        'query': SecretRedactor.redact(query),
        if (type != null) 'type': type!.name,
        if (sessionId != null) 'sessionId': sessionId,
        'tags': tags,
        if (scope != null) 'scope': scope,
        'includeExpired': includeExpired,
        'limit': limit,
      };
}

/// Result returned from a memory query.
class MemoryQueryResult {
  /// Original query.
  final String query;

  /// Filtered and ranked matching knowledge entries.
  final List<KnowledgeEntry> entries;

  /// Context synthesis / direct answer formulated from documented decisions.
  final String synthesis;

  /// Conflicts detected during query or store operations.
  final List<ConflictReport> conflictsDetected;

  /// Query execution duration in milliseconds.
  final int durationMs;

  /// Execution timestamp.
  final DateTime timestamp;

  /// Whether operation succeeded.
  final bool isSuccess;

  /// Error message on failure.
  final String? errorMessage;

  MemoryQueryResult({
    required String query,
    required this.entries,
    required String synthesis,
    this.conflictsDetected = const [],
    required this.durationMs,
    required this.timestamp,
    this.isSuccess = true,
    this.errorMessage,
  })  : query = SecretRedactor.redact(query),
        synthesis = SecretRedactor.redact(synthesis);

  factory MemoryQueryResult.failure({
    required String query,
    required String errorMessage,
    int durationMs = 0,
    DateTime? timestamp,
  }) =>
      MemoryQueryResult(
        query: query,
        entries: const [],
        synthesis: 'Failed to retrieve project memory.',
        conflictsDetected: const [],
        durationMs: durationMs,
        timestamp: timestamp ?? DateTime.now(),
        isSuccess: false,
        errorMessage: SecretRedactor.redact(errorMessage),
      );

  Map<String, dynamic> toJson() => {
        'query': SecretRedactor.redact(query),
        'entries': entries.map((e) => e.toJson()).toList(),
        'synthesis': SecretRedactor.redact(synthesis),
        'conflictsDetected': conflictsDetected.map((c) => c.toJson()).toList(),
        'durationMs': durationMs,
        'timestamp': timestamp.toIso8601String(),
        'isSuccess': isSuccess,
        if (errorMessage != null)
          'errorMessage': SecretRedactor.redact(errorMessage!),
      };
}
