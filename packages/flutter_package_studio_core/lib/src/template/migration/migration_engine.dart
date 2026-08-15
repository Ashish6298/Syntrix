import 'dart:convert';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/template/migration/migration_contract.dart';
import 'package:flutter_package_studio_core/src/template/migration/migration_filesystem.dart';
import 'package:flutter_package_studio_core/src/template/migration/migration_models.dart';
import 'package:flutter_package_studio_core/src/template/migration/migration_registry.dart';

/// Core engine for planning and executing project template migrations.
class TemplateMigrationEngine {
  final TemplateMigrationRegistry registry;
  final TemplateMigrationFileSystem fileSystem;
  final Logger _logger = Logger('TemplateMigrationEngine');

  TemplateMigrationEngine({
    TemplateMigrationRegistry? registry,
    TemplateMigrationFileSystem? fileSystem,
  })  : registry = registry ?? TemplateMigrationRegistry(),
        fileSystem = fileSystem ?? MemoryMigrationFileSystem();

  /// Detects template ID and version from project metadata in [projectPath].
  Map<String, String>? detectProjectMetadata(String projectPath) {
    final metaPath = '$projectPath/.fps/template_metadata.json';
    if (fileSystem.exists(metaPath)) {
      try {
        final content = fileSystem.readAsString(metaPath);
        final json = jsonDecode(content) as Map<String, dynamic>;
        final id = json['templateId'] as String?;
        final ver = json['version'] as String?;
        if (id != null && ver != null) {
          return {'templateId': id, 'version': ver};
        }
      } catch (_) {}
    }
    return null;
  }

  /// Builds a deterministic [TemplateMigrationPlan] without mutating the filesystem (preview mode).
  TemplateMigrationPlan planMigration(TemplateMigrationRequest request) {
    _logger.info('Planning migration for ${request.targetTemplateId}');

    // 1. Path security check
    _validatePathSecurity(request.projectPath);

    // 2. Metadata detection
    var sourceId = request.sourceTemplateId;
    var sourceVer = request.sourceVersion;

    if (sourceId == null || sourceVer == null) {
      final detected = detectProjectMetadata(request.projectPath);
      if (detected != null) {
        sourceId ??= detected['templateId'];
        sourceVer ??= detected['version'];
      }
    }

    if (sourceId == null || sourceVer == null) {
      throw TemplateMigrationPlanningException(
          'Could not detect originating template metadata for project at "${request.projectPath}". Specify --from explicitly.');
    }

    final findings = <TemplateMigrationFinding>[];

    // 3. Resolve migration chain
    List<TemplateMigration> chain;
    try {
      chain = registry.resolveChain(
        templateId: sourceId,
        sourceVersion: sourceVer,
        targetVersion: request.targetVersion,
      );
    } on TemplateMigrationPlanningException catch (e) {
      findings.add(TemplateMigrationFinding(
        code: 'MISSING_CHAIN',
        severity: TemplateMigrationSeverity.error,
        message: e.message,
      ));
      chain = const [];
    }

    // 4. Build steps
    final steps = <TemplateMigrationStep>[];
    for (final mig in chain) {
      final actions = mig.buildActions();
      for (final a in actions) {
        _validatePathSecurity(a.path);
        if (a.targetPath != null) {
          _validatePathSecurity(a.targetPath!);
        }
      }
      steps.add(TemplateMigrationStep(
        migrationId: mig.id,
        sourceVersion: mig.sourceVersion,
        targetVersion: mig.targetVersion,
        description: mig.description,
        actions: actions,
      ));
    }

    // Release profile check: promote warnings to errors
    if (request.profile == TemplateMigrationProfile.release) {
      for (int i = 0; i < findings.length; i++) {
        if (findings[i].severity == TemplateMigrationSeverity.warning) {
          findings[i] = TemplateMigrationFinding(
            code: findings[i].code,
            severity: TemplateMigrationSeverity.error,
            message: '[Release profile] ${findings[i].message}',
            filePath: findings[i].filePath,
          );
        }
      }
    }

    return TemplateMigrationPlan(
      sourceTemplateId: sourceId,
      sourceVersion: sourceVer,
      targetTemplateId: request.targetTemplateId,
      targetVersion: request.targetVersion,
      profile: request.profile,
      conflictPolicy: request.conflictPolicy,
      steps: List.unmodifiable(steps),
      findings: List.unmodifiable(findings),
    );
  }

  /// Executes [plan] against the filesystem with atomic backup and rollback support.
  TemplateMigrationResult executeMigration(
    TemplateMigrationPlan plan, {
    required String projectPath,
  }) {
    _logger.info('Executing migration plan for ${plan.targetTemplateId}');
    _validatePathSecurity(projectPath);

    if (plan.hasErrors) {
      throw TemplateMigrationExecutionException(
          'Cannot execute migration plan with errors: ${plan.findings.first.message}');
    }

    final backups = <String, String>{}; // original -> backup
    int actionsExecuted = 0;
    bool failed = false;

    try {
      for (final step in plan.steps) {
        for (final action in step.actions) {
          final fullPath = '$projectPath/${action.path}';
          _validatePathSecurity(fullPath);

          if (fileSystem.exists(fullPath)) {
            final bak = fileSystem.backupFile(fullPath);
            backups[fullPath] = bak;
          }

          switch (action.type) {
            case TemplateMigrationActionType.createFile:
            case TemplateMigrationActionType.updateFile:
              if (action.content != null) {
                fileSystem.writeString(fullPath, action.content!);
              }
              break;
            case TemplateMigrationActionType.renameFile:
              if (action.targetPath != null) {
                final newPath = '$projectPath/${action.targetPath!}';
                _validatePathSecurity(newPath);
                final oldContent = fileSystem.readAsString(fullPath);
                fileSystem.writeString(newPath, oldContent);
                fileSystem.delete(fullPath);
              }
              break;
            case TemplateMigrationActionType.deleteFile:
              if (plan.conflictPolicy == TemplateMigrationConflictPolicy.fail) {
                throw TemplateMigrationConflictException(
                    'Destructive delete operation rejected under fail conflict policy: ${action.path}');
              }
              fileSystem.delete(fullPath);
              break;
            case TemplateMigrationActionType.updateMetadata:
            case TemplateMigrationActionType.updateDependency:
              break;
          }
          actionsExecuted++;
        }
      }

      // Record new template metadata
      final metaDir = '$projectPath/.fps';
      fileSystem.createDirectory(metaDir);
      fileSystem.writeString(
        '$metaDir/template_metadata.json',
        jsonEncode({
          'templateId': plan.targetTemplateId,
          'version': plan.targetVersion,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );

      // Clean backups
      backups.values.forEach(fileSystem.removeBackup);

      return TemplateMigrationResult(
        isSuccess: true,
        sourceVersion: plan.sourceVersion,
        targetVersion: plan.targetVersion,
        actionsExecuted: actionsExecuted,
        findings: const [],
      );
    } catch (e) {
      failed = true;
      _logger.error('Migration failed. Executing rollback...', e);

      // Rollback
      backups.forEach((orig, bak) {
        try {
          fileSystem.restoreFile(orig, bak);
          fileSystem.removeBackup(bak);
        } catch (_) {}
      });

      return TemplateMigrationResult(
        isSuccess: false,
        sourceVersion: plan.sourceVersion,
        targetVersion: plan.targetVersion,
        actionsExecuted: actionsExecuted,
        findings: [
          TemplateMigrationFinding(
            code: 'EXECUTION_FAILED',
            severity: TemplateMigrationSeverity.error,
            message: 'Migration failed: $e',
          ),
        ],
        rollbackPerformed: failed,
      );
    }
  }

  void _validatePathSecurity(String pathStr) {
    final trimmed = pathStr.trim();
    if (trimmed.isEmpty) return;

    if (trimmed.contains('../') ||
        trimmed.contains('..\\') ||
        trimmed == '..' ||
        trimmed.endsWith('/..') ||
        trimmed.endsWith('\\..')) {
      throw TemplateMigrationSecurityException(
          'Security violation: Path traversal ".." in "$trimmed" is forbidden.');
    }
  }
}
