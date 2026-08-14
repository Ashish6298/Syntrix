import 'package:flutter_package_studio_core/src/template/template_manifest.dart';

/// Represents a loaded template bundle ready for variable resolution and rendering.
class Template {
  /// Associated machine-readable manifest.
  final TemplateManifest manifest;

  /// Map of relative file paths to raw template string contents.
  final Map<String, String> fileTemplates;

  /// Map of relative binary file paths to raw byte arrays.
  final Map<String, List<int>> binaryTemplates;

  /// Creates a [Template] instance.
  const Template({
    required this.manifest,
    this.fileTemplates = const {},
    this.binaryTemplates = const {},
  });

  /// Template unique identifier.
  String get id => manifest.id;

  /// Display name.
  String get displayName => manifest.displayName;

  /// Project archetype (`flutter_package`, `dart_package`, etc.).
  String get projectType => manifest.projectType;

  /// Semantic version string.
  String get version => manifest.version;
}
