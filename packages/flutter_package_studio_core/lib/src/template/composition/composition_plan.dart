import 'package:flutter_package_studio_core/src/compatibility/compatibility_result.dart';
import 'package:flutter_package_studio_core/src/template/composition/composition_layer.dart';
import 'package:flutter_package_studio_core/src/template/composition/composition_provenance.dart';
import 'package:flutter_package_studio_core/src/template/resolved_template.dart';
import 'package:flutter_package_studio_core/src/template/template_composition.dart';
import 'package:flutter_package_studio_core/src/template/template_manifest.dart';

/// Representation of a planned or previewed composition prior to project generation.
class CompositionPlan {
  /// Base template ID.
  final String baseTemplateId;

  /// Ordered composition layers included in the plan.
  final List<CompositionLayer> layers;

  /// Resolved composite template (contains file map and provenance).
  final ResolvedTemplate resolvedTemplate;

  /// All file provenance records explaining asset origin and override decisions.
  final List<FileProvenanceRecord> provenanceRecords;

  /// All collisions detected and resolution actions taken.
  final List<CompositionConflict> conflicts;

  /// Aggregated compatibility results across all layers.
  final List<CompatibilityResult> compatibilityResults;

  /// Conflict policy applied.
  final OverrideStrategy conflictPolicy;

  const CompositionPlan({
    required this.baseTemplateId,
    required this.layers,
    required this.resolvedTemplate,
    required this.provenanceRecords,
    required this.conflicts,
    required this.compatibilityResults,
    required this.conflictPolicy,
  });

  /// Total files in final composite.
  int get fileCount => resolvedTemplate.files.length;

  /// Total files overridden.
  int get overrideCount =>
      provenanceRecords.where((p) => p.action == 'overridden').length;

  /// Total files skipped.
  int get skipCount =>
      provenanceRecords.where((p) => p.action == 'skipped').length;

  /// Effective manifest generated for composition.
  TemplateManifest get manifest => resolvedTemplate.effectiveManifest;

  /// Formats plan as serializable JSON map.
  Map<String, dynamic> toJson() => {
        'baseTemplateId': baseTemplateId,
        'conflictPolicy': conflictPolicy.name,
        'fileCount': fileCount,
        'overrideCount': overrideCount,
        'skipCount': skipCount,
        'layers': layers
            .map((l) => {
                  'index': l.layerIndex,
                  'id': l.templateId,
                  'version': l.version,
                  'type': l.layerType.name,
                })
            .toList(),
        'conflicts': conflicts
            .map((c) => {
                  'path': c.path,
                  'existingSource': c.existingSourceId,
                  'incomingSource': c.incomingSourceId,
                  'resolution': c.resolutionPolicy.name,
                })
            .toList(),
        'provenance': provenanceRecords
            .map((p) => {
                  'path': p.path,
                  'source': p.sourceTemplateId,
                  'version': p.sourceVersion,
                  'layerIndex': p.layerIndex,
                  'action': p.action,
                })
            .toList(),
      };
}
