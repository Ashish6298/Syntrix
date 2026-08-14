import 'package:flutter_package_studio_core/src/template/template_manifest.dart';
import 'package:flutter_package_studio_core/src/template/template_model.dart';

/// Immutable representation of a fully resolved, composed template ready for generation planning.
class ResolvedTemplate {
  /// Base primary template.
  final Template baseTemplate;

  /// Ordered list of feature extensions/modules.
  final List<Template> extensions;

  /// Combined template manifest.
  final TemplateManifest effectiveManifest;

  /// Map of relative file path to source template ID for provenance auditing.
  final Map<String, String> fileProvenance;

  /// Composed file template contents.
  final Map<String, String> files;

  const ResolvedTemplate({
    required this.baseTemplate,
    required this.extensions,
    required this.effectiveManifest,
    required this.fileProvenance,
    required this.files,
  });

  String get id => baseTemplate.id;
  String get version => baseTemplate.version;
}
