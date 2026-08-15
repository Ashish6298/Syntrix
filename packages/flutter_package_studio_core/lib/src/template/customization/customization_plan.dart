import 'package:flutter_package_studio_core/src/template/composition/composition_plan.dart';
import 'package:flutter_package_studio_core/src/template/customization/customization_context.dart';
import 'package:flutter_package_studio_core/src/template/customization/customization_schema.dart';

/// Representation of a planned or previewed customization prior to generation plan building.
class CustomizationPlan {
  /// Base template ID.
  final String templateId;

  /// Active preset name applied (if any).
  final String? activePreset;

  /// Underlying composition plan (if composition was performed).
  final CompositionPlan? compositionPlan;

  /// Resolved customization schema.
  final CustomizationSchema schema;

  /// Resolved customization variables context.
  final CustomizationContext context;

  /// List of files included after evaluating customization condition rules.
  final List<String> includedFiles;

  /// List of files excluded after evaluating customization condition rules.
  final List<String> excludedFiles;

  /// Map of original asset path -> target path override.
  final Map<String, String> activePathOverrides;

  const CustomizationPlan({
    required this.templateId,
    this.activePreset,
    this.compositionPlan,
    required this.schema,
    required this.context,
    required this.includedFiles,
    required this.excludedFiles,
    required this.activePathOverrides,
  });

  /// Total files included in final output.
  int get fileCount => includedFiles.length;

  /// Total files excluded.
  int get excludedCount => excludedFiles.length;

  /// Formats customization plan as a JSON dictionary.
  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'activePreset': activePreset,
        'fileCount': fileCount,
        'excludedCount': excludedCount,
        'variables': context.toMap(),
        'includedFiles': includedFiles,
        'excludedFiles': excludedFiles,
        'pathOverrides': activePathOverrides,
        if (compositionPlan != null) 'composition': compositionPlan!.toJson(),
      };
}
