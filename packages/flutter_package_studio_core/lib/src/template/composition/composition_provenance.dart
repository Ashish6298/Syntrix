import 'package:flutter_package_studio_core/src/template/template_composition.dart';

/// Detailed provenance record for an individual asset path in a composite template.
class FileProvenanceRecord {
  /// Relative target file path.
  final String path;

  /// Originating template ID that contributed the winning/selected asset.
  final String sourceTemplateId;

  /// Version of the originating template.
  final String sourceVersion;

  /// Layer index of the originating template in the composition stack.
  final int layerIndex;

  /// Action taken for this asset path (created, overridden, skipped).
  final String action;

  /// Optional original template ID if this asset replaced an earlier layer asset.
  final String? overriddenTemplateId;

  const FileProvenanceRecord({
    required this.path,
    required this.sourceTemplateId,
    required this.sourceVersion,
    required this.layerIndex,
    required this.action,
    this.overriddenTemplateId,
  });

  @override
  String toString() =>
      'FileProvenanceRecord($path <- $sourceTemplateId@$sourceVersion [L$layerIndex, $action])';
}

/// Representation of a file collision during composition.
class CompositionConflict {
  /// Colliding relative file path.
  final String path;

  /// Template ID and layer of existing asset.
  final String existingSourceId;
  final int existingLayerIndex;

  /// Template ID and layer of incoming asset.
  final String incomingSourceId;
  final int incomingLayerIndex;

  /// Resolution decision applied (fail, override, skip).
  final OverrideStrategy resolutionPolicy;

  const CompositionConflict({
    required this.path,
    required this.existingSourceId,
    required this.existingLayerIndex,
    required this.incomingSourceId,
    required this.incomingLayerIndex,
    required this.resolutionPolicy,
  });

  @override
  String toString() =>
      'CompositionConflict($path: $incomingSourceId[L$incomingLayerIndex] vs $existingSourceId[L$existingLayerIndex] -> ${resolutionPolicy.name})';
}
