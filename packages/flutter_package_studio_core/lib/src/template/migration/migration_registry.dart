import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/template/migration/migration_contract.dart';

/// Registry for managing and resolving declared template migrations.
class TemplateMigrationRegistry {
  final Map<String, TemplateMigration> _migrations = {};

  /// Registers a [TemplateMigration]. Rejects duplicate migration IDs.
  void register(TemplateMigration migration) {
    if (_migrations.containsKey(migration.id)) {
      throw TemplateMigrationConfigurationException(
          'Duplicate migration registration ID: "${migration.id}".');
    }
    _migrations[migration.id] = migration;
  }

  /// Finds all migrations registered for [templateId].
  List<TemplateMigration> forTemplate(String templateId) {
    return _migrations.values.where((m) => m.templateId == templateId).toList();
  }

  /// Resolves an ordered migration chain from [sourceVersion] to [targetVersion] for [templateId].
  List<TemplateMigration> resolveChain({
    required String templateId,
    required String sourceVersion,
    required String targetVersion,
  }) {
    if (sourceVersion == targetVersion) return const [];

    final available = forTemplate(templateId);
    final chain = <TemplateMigration>[];
    var currentVer = sourceVersion;
    final visited = <String>{};

    while (currentVer != targetVersion) {
      if (visited.contains(currentVer)) {
        throw TemplateMigrationPlanningException(
            'Circular migration path detected at version "$currentVer".');
      }
      visited.add(currentVer);

      final nextCandidates =
          available.where((m) => m.sourceVersion == currentVer).toList();
      if (nextCandidates.isEmpty) {
        throw TemplateMigrationPlanningException(
            'No migration path found from version "$currentVer" to "$targetVersion".');
      }

      final next = nextCandidates.first;
      chain.add(next);
      currentVer = next.targetVersion;
    }

    return List.unmodifiable(chain);
  }

  List<TemplateMigration> get allMigrations =>
      List.unmodifiable(_migrations.values);
}
