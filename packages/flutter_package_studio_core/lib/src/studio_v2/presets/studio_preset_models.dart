/// Domain models and storage contracts for Phase 10.11: Configuration Preset System.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_models.dart';

/// Complete studio configuration preset encapsulating all parameters across all subsystems.
class StudioConfigurationPreset {
  final String presetId;
  final String name;
  final String description;
  final String targetLoaderId;
  final String selectedThemeId;
  final StudioConfigurationDescriptor configuration;
  final Map<String, dynamic> metadata;
  final bool isBuiltIn;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudioConfigurationPreset({
    required this.presetId,
    required this.name,
    this.description = '',
    required this.targetLoaderId,
    required this.selectedThemeId,
    required this.configuration,
    this.metadata = const {},
    this.isBuiltIn = false,
    required this.createdAt,
    required this.updatedAt,
  });

  StudioConfigurationPreset copyWith({
    String? presetId,
    String? name,
    String? description,
    String? targetLoaderId,
    String? selectedThemeId,
    StudioConfigurationDescriptor? configuration,
    Map<String, dynamic>? metadata,
    bool? isBuiltIn,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudioConfigurationPreset(
      presetId: presetId ?? this.presetId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetLoaderId: targetLoaderId ?? this.targetLoaderId,
      selectedThemeId: selectedThemeId ?? this.selectedThemeId,
      configuration: configuration ?? this.configuration,
      metadata: metadata ?? this.metadata,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'preset_id': presetId,
        'name': name,
        'description': description,
        'target_loader_id': targetLoaderId,
        'selected_theme_id': selectedThemeId,
        'configuration': configuration.toJson(),
        'metadata': metadata,
        'is_built_in': isBuiltIn,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory StudioConfigurationPreset.fromJson(Map<String, dynamic> json) {
    return StudioConfigurationPreset(
      presetId: json['preset_id'] as String? ?? 'preset_default',
      name: json['name'] as String? ?? 'Default Preset',
      description: json['description'] as String? ?? '',
      targetLoaderId: json['target_loader_id'] as String? ?? 'infinite_universe',
      selectedThemeId: json['selected_theme_id'] as String? ?? 'deep_space',
      configuration: json['configuration'] != null
          ? StudioConfigurationDescriptor.fromJson(json['configuration'] as Map<String, dynamic>)
          : const StudioConfigurationDescriptor(),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
      isBuiltIn: json['is_built_in'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Abstract storage driver contract for preset persistence.
abstract class PresetStorageDriver {
  Future<List<StudioConfigurationPreset>> loadAllPresets();
  Future<StudioConfigurationPreset?> getPreset(String presetId);
  Future<void> savePreset(StudioConfigurationPreset preset);
  Future<bool> deletePreset(String presetId);
}

/// In-memory implementation of [PresetStorageDriver].
class InMemoryPresetStorageDriver implements PresetStorageDriver {
  final Map<String, StudioConfigurationPreset> _storage = {};

  InMemoryPresetStorageDriver([List<StudioConfigurationPreset>? initial]) {
    if (initial != null) {
      for (final p in initial) {
        _storage[p.presetId] = p;
      }
    }
  }

  @override
  Future<List<StudioConfigurationPreset>> loadAllPresets() async => _storage.values.toList();

  @override
  Future<StudioConfigurationPreset?> getPreset(String presetId) async => _storage[presetId];

  @override
  Future<void> savePreset(StudioConfigurationPreset preset) async {
    _storage[preset.presetId] = preset;
  }

  @override
  Future<bool> deletePreset(String presetId) async {
    return _storage.remove(presetId) != null;
  }
}
