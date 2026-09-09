/// Domain models and extension point abstractions for Phase 10.18: Studio Extension Architecture.
library;

import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_controller.dart';
import 'package:flutter_package_studio_core/src/studio_v2/export/studio_export_models.dart';
import 'package:flutter_package_studio_core/src/studio_v2/validation/studio_validation_models.dart';

/// Extension lifecycle status.
enum ExtensionStatus {
  registered,
  active,
  disabled,
  error;

  String get id => name;

  String get label => name.toUpperCase();
}

/// Category classifying a studio tool or extension component.
enum StudioToolCategory {
  shader,
  ai,
  animation,
  scene,
  profiling,
  custom;

  String get id => name;

  String get label {
    switch (this) {
      case StudioToolCategory.shader:
        return 'Shader Studio';
      case StudioToolCategory.ai:
        return 'AI Assistant';
      case StudioToolCategory.animation:
        return 'Animation Timeline';
      case StudioToolCategory.scene:
        return 'Scene Timeline';
      case StudioToolCategory.profiling:
        return 'Advanced Profiler';
      case StudioToolCategory.custom:
        return 'Custom Tool';
    }
  }
}

/// Abstract custom tool contribution.
abstract class StudioTool {
  String get toolId;
  String get title;
  StudioToolCategory get category;
  String get description;

  Future<void> execute(StudioV2Controller controller);

  Map<String, dynamic> toJson() => {
        'tool_id': toolId,
        'title': title,
        'category': category.id,
        'description': description,
      };
}

/// Abstract custom action executable from Studio commands or menus.
abstract class StudioAction {
  String get actionId;
  String get label;
  String get shortcut;

  Future<void> trigger(StudioV2Controller controller);

  Map<String, dynamic> toJson() => {
        'action_id': actionId,
        'label': label,
        'shortcut': shortcut,
      };
}

/// Abstract custom inspector panel or property contributor.
abstract class StudioInspectorExtension {
  String get inspectorId;
  String get targetSection;

  Map<String, dynamic> inspect(StudioV2Controller controller);

  Map<String, dynamic> toJson() => {
        'inspector_id': inspectorId,
        'target_section': targetSection,
      };
}

/// Abstract custom exporter contributor.
abstract class StudioExporterExtension {
  String get exporterId;
  ExportFormat get targetFormat;

  StudioExportBundle export(StudioV2Controller controller);

  Map<String, dynamic> toJson() => {
        'exporter_id': exporterId,
        'target_format': targetFormat.id,
      };
}

/// Abstract custom validator contributor.
abstract class StudioValidatorExtension {
  String get validatorId;
  StudioValidationCategory get category;

  ValidationCheckItem validate(StudioV2Controller controller);

  Map<String, dynamic> toJson() => {
        'validator_id': validatorId,
        'category': category.id,
      };
}

/// Abstract base class for Studio extensions.
abstract class StudioExtension {
  String get extensionId;
  String get name;
  String get version;
  String get author;
  String get description;

  List<StudioTool> get tools => const [];
  List<StudioAction> get actions => const [];
  List<StudioInspectorExtension> get inspectors => const [];
  List<StudioExporterExtension> get exporters => const [];
  List<StudioValidatorExtension> get validators => const [];

  Future<void> onInitialize(StudioV2Controller controller) async {}
  Future<void> onDispose(StudioV2Controller controller) async {}

  Map<String, dynamic> toJson() => {
        'extension_id': extensionId,
        'name': name,
        'version': version,
        'author': author,
        'description': description,
        'tools_count': tools.length,
        'actions_count': actions.length,
        'inspectors_count': inspectors.length,
        'exporters_count': exporters.length,
        'validators_count': validators.length,
      };
}
