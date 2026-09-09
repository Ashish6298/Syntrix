/// Central Enterprise Audit Logging Engine and tamper-evident append log.
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:syntrix/src/logging/logger.dart';
import 'package:syntrix/src/enterprise/identity/enterprise_identity_models.dart';
import 'package:syntrix/src/enterprise/audit/enterprise_audit_models.dart';

/// Central Enterprise Audit Logging Engine.
///
/// Features:
/// 1. Tamper-evident hash chain linking all recorded events.
/// 2. Guaranteed zero secret/credential recording via SecretRedactor sanitization.
/// 3. Append-only persistent storage in `.fps/audit/audit_log.jsonl`.
/// 4. Querying and verification of audit trail integrity.
class EnterpriseAuditEngine {
  final Logger _logger = Logger('EnterpriseAuditEngine');
  final String _projectRoot;
  final List<EnterpriseAuditRecord> _inMemoryRecords = [];
  String? _latestRecordHash;

  String get projectRoot => _projectRoot;
  List<EnterpriseAuditRecord> get inMemoryRecords =>
      List.unmodifiable(_inMemoryRecords);

  EnterpriseAuditEngine({
    required String projectRoot,
  }) : _projectRoot = p.normalize(projectRoot) {
    _loadExistingAuditTrail();
  }

  File get _auditLogFile =>
      File(p.join(_projectRoot, '.fps', 'audit', 'audit_log.jsonl'));

  /// Records an enterprise operation event into the tamper-evident audit log.
  Future<EnterpriseAuditRecord> recordEvent({
    required AuditEventType eventType,
    required EnterpriseIdentity actorIdentity,
    required String operation,
    required String packageOrProject,
    String? command,
    required AuditEventOutcome outcome,
    String? correlationId,
    String? relevantVersion,
    AuditSecurityClassification securityClassification =
        AuditSecurityClassification.internal,
    String? failureInformation,
    String? policyDecision,
    Map<String, dynamic> metadata = const {},
    DateTime? timestamp,
  }) async {
    final actor = AuditActor(
      id: actorIdentity.id,
      displayName: actorIdentity.displayName,
      type: actorIdentity.type.id,
      role: actorIdentity.roles.isNotEmpty
          ? actorIdentity.roles.first.id
          : 'readOnly',
      organizationId: actorIdentity.organizationId,
    );

    final cid = correlationId ??
        'cor_${DateTime.now().millisecondsSinceEpoch}_${_inMemoryRecords.length + 1}';

    final record = EnterpriseAuditRecord.create(
      correlationId: cid,
      eventType: eventType,
      actor: actor,
      operation: operation,
      packageOrProject: packageOrProject,
      command: command,
      outcome: outcome,
      relevantVersion: relevantVersion,
      securityClassification: securityClassification,
      failureInformation: failureInformation,
      policyDecision: policyDecision,
      metadata: metadata,
      previousRecordHash: _latestRecordHash,
      timestamp: timestamp,
    );

    _inMemoryRecords.add(record);
    _latestRecordHash = record.recordHash;

    _appendRecordToFile(record);
    _logger.info(
        'Recorded audit event: [${record.eventType.displayName}] $operation ($packageOrProject) by ${actor.displayName} -> ${outcome.label}');

    return record;
  }

  /// Verifies the cryptographic integrity of the entire audit trail.
  Future<bool> verifyAuditTrailIntegrity() async {
    final records = await readAllRecords();
    if (records.isEmpty) return true;

    String? expectedPreviousHash;
    for (final record in records) {
      // 1. Verify single record integrity
      if (!record.verifyIntegrity()) {
        _logger.error(
            'Audit record integrity corrupted: eventId=${record.eventId}');
        return false;
      }

      // 2. Verify hash chain linking
      if (record.previousRecordHash != expectedPreviousHash) {
        _logger.error(
            'Audit chain broken: eventId=${record.eventId}, expectedPrev=$expectedPreviousHash, actualPrev=${record.previousRecordHash}');
        return false;
      }

      expectedPreviousHash = record.recordHash;
    }

    return true;
  }

  /// Reads all audit records from disk.
  Future<List<EnterpriseAuditRecord>> readAllRecords() async {
    final file = _auditLogFile;
    if (!file.existsSync()) return List.from(_inMemoryRecords);

    final records = <EnterpriseAuditRecord>[];
    try {
      final lines = await file.readAsLines();
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final jsonMap = jsonDecode(line) as Map<String, dynamic>;
        records.add(EnterpriseAuditRecord.fromJson(jsonMap));
      }
    } catch (e) {
      _logger.error('Failed to read audit log lines: $e');
    }
    return records;
  }

  /// Queries audit records by filters.
  Future<List<EnterpriseAuditRecord>> queryRecords({
    AuditEventType? eventType,
    String? actorId,
    String? packageOrProject,
    AuditEventOutcome? outcome,
    String? correlationId,
    int? limit,
  }) async {
    final all = await readAllRecords();
    var filtered = all.where((r) {
      if (eventType != null && r.eventType != eventType) return false;
      if (actorId != null && r.actor.id != actorId) return false;
      if (packageOrProject != null &&
          !r.packageOrProject
              .toLowerCase()
              .contains(packageOrProject.toLowerCase())) return false;
      if (outcome != null && r.outcome != outcome) return false;
      if (correlationId != null && r.correlationId != correlationId)
        return false;
      return true;
    }).toList();

    if (limit != null && limit > 0 && filtered.length > limit) {
      filtered = filtered.sublist(filtered.length - limit);
    }

    return filtered;
  }

  void _loadExistingAuditTrail() {
    final file = _auditLogFile;
    if (file.existsSync()) {
      try {
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final jsonMap = jsonDecode(line) as Map<String, dynamic>;
          final record = EnterpriseAuditRecord.fromJson(jsonMap);
          _inMemoryRecords.add(record);
          _latestRecordHash = record.recordHash;
        }
      } catch (_) {}
    }
  }

  void _appendRecordToFile(EnterpriseAuditRecord record) {
    try {
      final file = _auditLogFile;
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      file.writeAsStringSync('${jsonEncode(record.toJson())}\n',
          mode: FileMode.append, flush: true);
    } catch (e) {
      _logger.warning('Failed to persist audit log entry: $e');
    }
  }
}
