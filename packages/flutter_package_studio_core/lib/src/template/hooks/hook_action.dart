/// Declarative actions proposed by template hooks.
library;

import 'package:flutter_package_studio_core/src/template/generation_plan.dart';

/// Type of declarative action requested by a hook.
enum HookActionType {
  /// Proposes creating or adding a file to the generation target.
  addFile,

  /// Proposes setting or modifying a template variable.
  modifyVariable,

  /// Proposes adding a validation rule or requirement.
  addValidationRequirement,

  /// Proposes adding a custom generation action.
  addGenerationAction;
}

/// Represents an immutable declarative modification proposed by a hook.
class TemplateHookAction {
  /// The type of action.
  final HookActionType type;

  /// Target relative file path (if applicable).
  final String? relativePath;

  /// Text content for file modification/addition.
  final String? textContent;

  /// Binary content for file modification/addition.
  final List<int>? binaryContent;

  /// Variable key (if applicable).
  final String? variableKey;

  /// Variable value (if applicable).
  final Object? variableValue;

  /// Description or justification for this proposed action.
  final String description;

  /// Associated [GenerationAction] payload if applicable.
  final GenerationAction? generationAction;

  /// Creates a [TemplateHookAction].
  const TemplateHookAction({
    required this.type,
    required this.description,
    this.relativePath,
    this.textContent,
    this.binaryContent,
    this.variableKey,
    this.variableValue,
    this.generationAction,
  });

  /// Factory constructor for adding a file.
  factory TemplateHookAction.addFile({
    required String relativePath,
    required String content,
    String description = 'Hook proposed file addition',
  }) {
    return TemplateHookAction(
      type: HookActionType.addFile,
      relativePath: relativePath,
      textContent: content,
      description: description,
    );
  }

  /// Factory constructor for modifying a variable.
  factory TemplateHookAction.modifyVariable({
    required String key,
    required Object value,
    String description = 'Hook proposed variable modification',
  }) {
    return TemplateHookAction(
      type: HookActionType.modifyVariable,
      variableKey: key,
      variableValue: value,
      description: description,
    );
  }

  /// Factory constructor for adding a validation requirement.
  factory TemplateHookAction.addValidationRequirement({
    required String requirement,
    String description = 'Hook proposed validation requirement',
  }) {
    return TemplateHookAction(
      type: HookActionType.addValidationRequirement,
      variableKey: 'requirement',
      variableValue: requirement,
      description: description,
    );
  }

  /// Factory constructor for adding a generation action.
  factory TemplateHookAction.addGenerationAction({
    required GenerationAction action,
    String description = 'Hook proposed generation action',
  }) {
    return TemplateHookAction(
      type: HookActionType.addGenerationAction,
      generationAction: action,
      description: description,
    );
  }

  /// Serializes action to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'description': description,
      if (relativePath != null) 'relativePath': relativePath,
      if (textContent != null) 'textContent': textContent,
      if (variableKey != null) 'variableKey': variableKey,
      if (variableValue != null) 'variableValue': variableValue.toString(),
      if (generationAction != null)
        'generationAction': {
          'type': generationAction!.type.name,
          'relativePath': generationAction!.relativePath,
        },
    };
  }
}
