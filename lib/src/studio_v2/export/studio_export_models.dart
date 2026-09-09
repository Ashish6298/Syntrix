/// Domain models and format descriptors for Phase 10.13: Export & Import System.
library;

/// Supported export targets.
enum ExportTargetEntity {
  configuration,
  preset,
  scene,
  generatedCode,
  diagnostics,
  performanceReport;

  String get id => name;

  String get label {
    switch (this) {
      case ExportTargetEntity.configuration:
        return 'Configuration';
      case ExportTargetEntity.preset:
        return 'Preset';
      case ExportTargetEntity.scene:
        return 'Scene';
      case ExportTargetEntity.generatedCode:
        return 'Generated Code';
      case ExportTargetEntity.diagnostics:
        return 'Diagnostics';
      case ExportTargetEntity.performanceReport:
        return 'Performance Report';
    }
  }
}

/// Output serialization format.
enum ExportFormat {
  json,
  dart,
  markdown,
  plainText;

  String get id => name;

  String get fileExtension {
    switch (this) {
      case ExportFormat.json:
        return 'json';
      case ExportFormat.dart:
        return 'dart';
      case ExportFormat.markdown:
        return 'md';
      case ExportFormat.plainText:
        return 'txt';
    }
  }
}

/// A serialized export bundle produced by the export engine.
class StudioExportBundle {
  final String bundleId;
  final ExportTargetEntity targetEntity;
  final ExportFormat format;
  final String content;
  final String suggestedFilename;
  final DateTime exportedAt;

  const StudioExportBundle({
    required this.bundleId,
    required this.targetEntity,
    required this.format,
    required this.content,
    required this.suggestedFilename,
    required this.exportedAt,
  });

  Map<String, dynamic> toJson() => {
        'bundle_id': bundleId,
        'target_entity': targetEntity.id,
        'format': format.id,
        'content': content,
        'suggested_filename': suggestedFilename,
        'exported_at': exportedAt.toIso8601String(),
      };

  factory StudioExportBundle.fromJson(Map<String, dynamic> json) {
    return StudioExportBundle(
      bundleId: json['bundle_id'] as String? ?? 'bundle_default',
      targetEntity: ExportTargetEntity.values.firstWhere(
        (e) => e.id == json['target_entity'] || e.name == json['target_entity'],
        orElse: () => ExportTargetEntity.configuration,
      ),
      format: ExportFormat.values.firstWhere(
        (f) => f.id == json['format'] || f.name == json['format'],
        orElse: () => ExportFormat.json,
      ),
      content: json['content'] as String? ?? '',
      suggestedFilename: json['suggested_filename'] as String? ?? 'export.txt',
      exportedAt: DateTime.parse(json['exported_at'] as String),
    );
  }
}
