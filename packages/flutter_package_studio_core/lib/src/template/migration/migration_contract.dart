import 'package:flutter_package_studio_core/src/template/migration/migration_models.dart';

/// Contract representing an explicit, versioned template migration step.
abstract class TemplateMigration {
  /// Unique identifier for this migration (e.g. `v1_0_0_to_v1_1_0`).
  String get id;

  /// Source template ID this migration applies to.
  String get templateId;

  /// Starting version constraint or exact version.
  String get sourceVersion;

  /// Target version constraint or exact version.
  String get targetVersion;

  /// Human-readable description of what this migration updates.
  String get description;

  /// Returns the list of actions performed by this migration step.
  List<TemplateMigrationAction> buildActions();
}

/// Concrete inline [TemplateMigration] implementation for simple declaration.
class SimpleTemplateMigration extends TemplateMigration {
  @override
  final String id;

  @override
  final String templateId;

  @override
  final String sourceVersion;

  @override
  final String targetVersion;

  @override
  final String description;

  final List<TemplateMigrationAction> _actions;

  SimpleTemplateMigration({
    required this.id,
    required this.templateId,
    required this.sourceVersion,
    required this.targetVersion,
    required this.description,
    List<TemplateMigrationAction> actions = const [],
  }) : _actions = List.unmodifiable(actions);

  @override
  List<TemplateMigrationAction> buildActions() => _actions;
}
