/// Central Configuration Preset Engine for Phase 10.11.
library;

import 'dart:convert';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_controller.dart';
import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_models.dart';
import 'package:flutter_package_studio_core/src/studio_v2/presets/studio_preset_models.dart';

/// Central Configuration Preset Engine managing preset lifecycle, mutations, and storage abstraction.
class StudioPresetEngine {
  final Logger _logger = Logger('StudioPresetEngine');
  final StudioV2Controller controller;
  final PresetStorageDriver storageDriver;

  StudioPresetEngine({
    required this.controller,
    PresetStorageDriver? storageDriver,
  }) : storageDriver = storageDriver ?? InMemoryPresetStorageDriver() {
    _registerBuiltInPresets();
  }

  void _registerBuiltInPresets() {
    final now = DateTime.now();
    savePreset(StudioConfigurationPreset(
      presetId: 'preset_cosmic_vortex_ultra',
      name: 'Cosmic Vortex Ultra',
      description: 'Ultra high-speed particle vortex with maximum gravity and shaders enabled.',
      targetLoaderId: 'infinite_universe',
      selectedThemeId: 'deep_space',
      configuration: const StudioConfigurationDescriptor(
        targetLoaderId: 'infinite_universe',
        selectedThemeId: 'deep_space',
        animationSpeed: 2.0,
        intensity: 1.8,
        scale: 1.2,
        particleCount: 500,
        particleSize: 2.5,
        particleOpacity: 0.9,
        gravity: 15.0,
        velocity: 2.0,
        shadersEnabled: true,
        isInteractive: true,
      ),
      isBuiltIn: true,
      createdAt: now,
      updatedAt: now,
    ));

    savePreset(StudioConfigurationPreset(
      presetId: 'preset_minimal_zen_pulse',
      name: 'Minimal Zen Pulse',
      description: 'Slow-pulsing minimalist ring with lightweight rendering overhead.',
      targetLoaderId: 'pulsar_wave',
      selectedThemeId: 'milky_way',
      configuration: const StudioConfigurationDescriptor(
        targetLoaderId: 'pulsar_wave',
        selectedThemeId: 'milky_way',
        animationSpeed: 0.5,
        intensity: 0.7,
        scale: 1.0,
        particleCount: 0,
        particleSize: 1.0,
        particleOpacity: 0.0,
        gravity: 0.0,
        velocity: 0.5,
        shadersEnabled: false,
        isInteractive: false,
      ),
      isBuiltIn: true,
      createdAt: now,
      updatedAt: now,
    ));

    savePreset(StudioConfigurationPreset(
      presetId: 'preset_cyber_matrix_rain',
      name: 'Cyber Matrix Rain',
      description: 'Fast-paced cyber synthwave rain with high particle count and scanline shaders.',
      targetLoaderId: 'cyber_matrix',
      selectedThemeId: 'cyber_galaxy',
      configuration: const StudioConfigurationDescriptor(
        targetLoaderId: 'cyber_matrix',
        selectedThemeId: 'cyber_galaxy',
        animationSpeed: 1.8,
        intensity: 1.5,
        scale: 1.0,
        particleCount: 400,
        particleSize: 1.5,
        particleOpacity: 0.95,
        gravity: 9.8,
        velocity: 3.0,
        shadersEnabled: true,
        isInteractive: true,
      ),
      isBuiltIn: true,
      createdAt: now,
      updatedAt: now,
    ));
  }

  /// List all available presets.
  Future<List<StudioConfigurationPreset>> listPresets() async {
    return storageDriver.loadAllPresets();
  }

  /// Look up a single preset by ID.
  Future<StudioConfigurationPreset?> getPreset(String presetId) async {
    return storageDriver.getPreset(presetId);
  }

  /// Create a preset from current workspace configuration.
  Future<StudioConfigurationPreset> createPresetFromCurrentState({
    required String presetId,
    required String name,
    String description = '',
  }) async {
    final cfg = controller.state.activeConfiguration;
    final now = DateTime.now();

    final preset = StudioConfigurationPreset(
      presetId: presetId,
      name: name,
      description: description,
      targetLoaderId: cfg.targetLoaderId,
      selectedThemeId: cfg.selectedThemeId,
      configuration: cfg,
      isBuiltIn: false,
      createdAt: now,
      updatedAt: now,
    );

    await savePreset(preset);
    _logger.info('Created preset "$name" ($presetId) from current state.');
    return preset;
  }

  /// Save or update a preset.
  Future<void> savePreset(StudioConfigurationPreset preset) async {
    await storageDriver.savePreset(preset);
  }

  /// Load a preset and apply its full configuration into the active Studio workspace.
  Future<bool> loadPreset(String presetId) async {
    final preset = await storageDriver.getPreset(presetId);
    if (preset != null) {
      controller.updateConfiguration((_) => preset.configuration);
      _logger.info('Loaded and applied preset "${preset.name}" ($presetId) to workspace.');
      return true;
    }
    return false;
  }

  /// Duplicate an existing preset to a new custom ID and name.
  Future<StudioConfigurationPreset> duplicatePreset(
    String sourcePresetId, {
    required String newPresetId,
    required String newName,
  }) async {
    final source = await storageDriver.getPreset(sourcePresetId);
    if (source == null) {
      throw ArgumentError('Preset "$sourcePresetId" not found to duplicate.');
    }

    final now = DateTime.now();
    final duplicate = source.copyWith(
      presetId: newPresetId,
      name: newName,
      isBuiltIn: false,
      createdAt: now,
      updatedAt: now,
    );

    await savePreset(duplicate);
    _logger.info('Duplicated preset "$sourcePresetId" -> "$newPresetId"');
    return duplicate;
  }

  /// Rename an existing preset.
  Future<bool> renamePreset(String presetId, String newName) async {
    final preset = await storageDriver.getPreset(presetId);
    if (preset != null) {
      final updated = preset.copyWith(name: newName, updatedAt: DateTime.now());
      await savePreset(updated);
      _logger.info('Renamed preset "$presetId" to "$newName"');
      return true;
    }
    return false;
  }

  /// Delete a preset by ID.
  Future<bool> deletePreset(String presetId) async {
    final deleted = await storageDriver.deletePreset(presetId);
    if (deleted) {
      _logger.info('Deleted preset "$presetId"');
    }
    return deleted;
  }

  /// Export a preset to a serialized JSON string.
  Future<String> exportPresetToJson(String presetId, {bool pretty = true}) async {
    final preset = await storageDriver.getPreset(presetId);
    if (preset == null) {
      throw ArgumentError('Preset "$presetId" not found for export.');
    }

    final encoder = pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(preset.toJson());
  }

  /// Import a preset from a JSON string.
  Future<StudioConfigurationPreset> importPresetFromJson(String jsonString) async {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    final preset = StudioConfigurationPreset.fromJson(map);
    await savePreset(preset);
    _logger.info('Imported preset "${preset.name}" (${preset.presetId})');
    return preset;
  }
}
