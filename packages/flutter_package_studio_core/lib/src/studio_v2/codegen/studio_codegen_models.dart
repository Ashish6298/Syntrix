/// Domain models, code templates, and generation options for Phase 10.8: Code Generation Studio.
library;

import 'dart:convert';

/// Target style/structure for the generated Flutter code.
enum CodeGenStyle {
  standaloneWidget,
  statelessWidgetClass,
  statefulInteractiveWidget,
  configurationSnippet,
  sceneStackWidget;

  String get id => name;

  String get label {
    switch (this) {
      case CodeGenStyle.standaloneWidget:
        return 'Standalone Widget Function';
      case CodeGenStyle.statelessWidgetClass:
        return 'StatelessWidget Class';
      case CodeGenStyle.statefulInteractiveWidget:
        return 'StatefulWidget (Interactive Controls)';
      case CodeGenStyle.configurationSnippet:
        return 'Raw Configuration Snippet';
      case CodeGenStyle.sceneStackWidget:
        return 'Composite Scene Stack Widget';
    }
  }
}

/// Generation options configuring the output source code.
class CodeGenOptions {
  final CodeGenStyle style;
  final bool includeImports;
  final bool includeComments;
  final bool includeExplicitTypes;
  final bool wrapWithSafeArea;
  final bool wrapWithCenter;
  final String customClassName;

  const CodeGenOptions({
    this.style = CodeGenStyle.standaloneWidget,
    this.includeImports = true,
    this.includeComments = true,
    this.includeExplicitTypes = true,
    this.wrapWithSafeArea = false,
    this.wrapWithCenter = true,
    this.customClassName = 'MyCosmicLoader',
  });

  Map<String, dynamic> toJson() => {
        'style': style.id,
        'include_imports': includeImports,
        'include_comments': includeComments,
        'include_explicit_types': includeExplicitTypes,
        'wrap_with_safe_area': wrapWithSafeArea,
        'wrap_with_center': wrapWithCenter,
        'custom_class_name': customClassName,
      };

  factory CodeGenOptions.fromJson(Map<String, dynamic> json) {
    return CodeGenOptions(
      style: CodeGenStyle.values.firstWhere(
        (s) => s.id == json['style'] || s.name == json['style'],
        orElse: () => CodeGenStyle.standaloneWidget,
      ),
      includeImports: json['include_imports'] as bool? ?? true,
      includeComments: json['include_comments'] as bool? ?? true,
      includeExplicitTypes: json['include_explicit_types'] as bool? ?? true,
      wrapWithSafeArea: json['wrap_with_safe_area'] as bool? ?? false,
      wrapWithCenter: json['wrap_with_center'] as bool? ?? true,
      customClassName: json['custom_class_name'] as String? ?? 'MyCosmicLoader',
    );
  }
}

/// Result of a code generation run, including generated code and validation status.
class CodeGenResult {
  final String sourceCode;
  final CodeGenOptions options;
  final bool isValidPublicApi;
  final List<String> requiredImports;
  final List<String> warnings;
  final DateTime generatedAt;

  const CodeGenResult({
    required this.sourceCode,
    required this.options,
    required this.isValidPublicApi,
    required this.requiredImports,
    this.warnings = const [],
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'source_code': sourceCode,
        'options': options.toJson(),
        'is_valid_public_api': isValidPublicApi,
        'required_imports': requiredImports,
        'warnings': warnings,
        'generated_at': generatedAt.toIso8601String(),
      };

  factory CodeGenResult.fromJson(Map<String, dynamic> json) {
    return CodeGenResult(
      sourceCode: json['source_code'] as String? ?? '',
      options: json['options'] != null
          ? CodeGenOptions.fromJson(json['options'] as Map<String, dynamic>)
          : const CodeGenOptions(),
      isValidPublicApi: json['is_valid_public_api'] as bool? ?? true,
      requiredImports: (json['required_imports'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }
}
