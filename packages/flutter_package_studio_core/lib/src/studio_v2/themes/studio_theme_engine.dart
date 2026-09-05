/// Central Theme Studio Engine for Phase 10.6.
library;

import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/studio_v2/studio_v2_controller.dart';
import 'package:flutter_package_studio_core/src/studio_v2/themes/studio_theme_models.dart';

/// Central Theme Studio Engine providing theme browsing, customization, duplication, and code generation.
class StudioThemeEngine {
  final Logger _logger = Logger('StudioThemeEngine');
  final StudioV2Controller controller;
  final Map<String, StudioThemeDescriptor> _themeCatalog = {};

  List<StudioThemeDescriptor> get allThemes => _themeCatalog.values.toList();

  StudioThemeEngine({
    required this.controller,
    List<StudioThemeDescriptor>? customThemes,
  }) {
    if (customThemes != null && customThemes.isNotEmpty) {
      for (final t in customThemes) {
        registerTheme(t);
      }
    } else {
      _registerDefaultPackageThemes();
    }
  }

  void _registerDefaultPackageThemes() {
    registerTheme(const StudioThemeDescriptor(
      id: 'deep_space',
      name: 'Deep Space',
      description: 'Abyssal cosmic midnight dark palette with indigo and violet nebula particles.',
      palette: [
        ThemeColorDefinition(role: 'background', hex: '#0B0D1B'),
        ThemeColorDefinition(role: 'primary', hex: '#6366F1'),
        ThemeColorDefinition(role: 'accent', hex: '#8B5CF6'),
        ThemeColorDefinition(role: 'glow', hex: '#4F46E5'),
        ThemeColorDefinition(role: 'particle', hex: '#C7D2FE'),
      ],
      backgroundColor: '#0B0D1B',
      particleGlowColor: '#4F46E5',
    ));

    registerTheme(const StudioThemeDescriptor(
      id: 'milky_way',
      name: 'Milky Way',
      description: 'Stellar spiral galaxy blend with opalescent starlight whites and soft cyan trails.',
      palette: [
        ThemeColorDefinition(role: 'background', hex: '#050814'),
        ThemeColorDefinition(role: 'primary', hex: '#38BDF8'),
        ThemeColorDefinition(role: 'accent', hex: '#818CF8'),
        ThemeColorDefinition(role: 'glow', hex: '#0284C7'),
        ThemeColorDefinition(role: 'particle', hex: '#F0F9FF'),
      ],
      backgroundColor: '#050814',
      particleGlowColor: '#0284C7',
    ));

    registerTheme(const StudioThemeDescriptor(
      id: 'nebula_storm',
      name: 'Nebula Storm',
      description: 'Vibrant interstellar storm with electric magenta, purple dust, and cyan ionization.',
      palette: [
        ThemeColorDefinition(role: 'background', hex: '#110C24'),
        ThemeColorDefinition(role: 'primary', hex: '#D946EF'),
        ThemeColorDefinition(role: 'accent', hex: '#06B6D4'),
        ThemeColorDefinition(role: 'glow', hex: '#A21CAF'),
        ThemeColorDefinition(role: 'particle', hex: '#FDF4FF'),
      ],
      backgroundColor: '#110C24',
      particleGlowColor: '#A21CAF',
    ));

    registerTheme(const StudioThemeDescriptor(
      id: 'quantum_void',
      name: 'Quantum Void',
      description: 'Deep pitch black void accented by high-contrast fluorescent neon emerald highlights.',
      palette: [
        ThemeColorDefinition(role: 'background', hex: '#020617'),
        ThemeColorDefinition(role: 'primary', hex: '#10B981'),
        ThemeColorDefinition(role: 'accent', hex: '#34D399'),
        ThemeColorDefinition(role: 'glow', hex: '#059669'),
        ThemeColorDefinition(role: 'particle', hex: '#ECFDF5'),
      ],
      backgroundColor: '#020617',
      particleGlowColor: '#059669',
    ));

    registerTheme(const StudioThemeDescriptor(
      id: 'solar_flare',
      name: 'Solar Flare',
      description: 'Blazing coronal plasma energy with fiery amber, crimson corona, and gold particles.',
      palette: [
        ThemeColorDefinition(role: 'background', hex: '#180B05'),
        ThemeColorDefinition(role: 'primary', hex: '#F59E0B'),
        ThemeColorDefinition(role: 'accent', hex: '#EF4444'),
        ThemeColorDefinition(role: 'glow', hex: '#D97706'),
        ThemeColorDefinition(role: 'particle', hex: '#FEF3C7'),
      ],
      backgroundColor: '#180B05',
      particleGlowColor: '#D97706',
    ));

    registerTheme(const StudioThemeDescriptor(
      id: 'cyber_galaxy',
      name: 'Cyber Galaxy',
      description: 'Retro futuristic synthwave grid with neon cyan, hot pink, and dark obsidian backdrop.',
      palette: [
        ThemeColorDefinition(role: 'background', hex: '#090A1A'),
        ThemeColorDefinition(role: 'primary', hex: '#00F0FF'),
        ThemeColorDefinition(role: 'accent', hex: '#FF007F'),
        ThemeColorDefinition(role: 'glow', hex: '#0077FF'),
        ThemeColorDefinition(role: 'particle', hex: '#FFFFFF'),
      ],
      backgroundColor: '#090A1A',
      particleGlowColor: '#0077FF',
    ));

    registerTheme(const StudioThemeDescriptor(
      id: 'aurora_cosmos',
      name: 'Aurora Cosmos',
      description: 'Polar geomagnetic aurora shimmering across cosmic sky with teal and lavender ribbons.',
      palette: [
        ThemeColorDefinition(role: 'background', hex: '#04131A'),
        ThemeColorDefinition(role: 'primary', hex: '#2DD4BF'),
        ThemeColorDefinition(role: 'accent', hex: '#A78BFA'),
        ThemeColorDefinition(role: 'glow', hex: '#0D9488'),
        ThemeColorDefinition(role: 'particle', hex: '#CCFBF1'),
      ],
      backgroundColor: '#04131A',
      particleGlowColor: '#0D9488',
    ));
  }

  /// Register a theme into the catalog.
  void registerTheme(StudioThemeDescriptor theme) {
    _themeCatalog[theme.id] = theme;
    _logger.info('Registered theme: ${theme.id} (${theme.name})');
  }

  /// Look up theme by ID.
  StudioThemeDescriptor? getTheme(String themeId) => _themeCatalog[themeId];

  /// Apply a theme to the active Studio workspace.
  void applyTheme(String themeId) {
    final theme = _themeCatalog[themeId];
    if (theme != null) {
      controller.updateConfiguration((cfg) => cfg.copyWith(selectedThemeId: theme.id));
      _logger.info('Applied theme "${theme.name}" to workspace.');
    }
  }

  /// Duplicate an existing theme to create a custom variation.
  StudioThemeDescriptor duplicateTheme(String sourceThemeId, {required String newId, required String newName}) {
    final source = _themeCatalog[sourceThemeId];
    if (source == null) {
      throw ArgumentError('Source theme "$sourceThemeId" not found in catalog.');
    }

    final duplicate = source.copyWith(
      id: newId,
      name: newName,
      isCustom: true,
    );

    registerTheme(duplicate);
    return duplicate;
  }

  /// Compare two themes side-by-side.
  Map<String, dynamic> compareThemes(String themeIdA, String themeIdB) {
    final a = _themeCatalog[themeIdA];
    final b = _themeCatalog[themeIdB];

    if (a == null || b == null) {
      return {'error': 'One or both themes not found'};
    }

    return {
      'theme_a': a.toJson(),
      'theme_b': b.toJson(),
    };
  }

  /// Generate production-ready Dart Theme configuration code.
  String generateThemeCode(String themeId) {
    final theme = _themeCatalog[themeId];
    if (theme == null) return '// Theme "$themeId" not found.';

    final buffer = StringBuffer();
    buffer.writeln('// Production-ready UniverseTheme configuration generated by Syntrix Studio v2');
    buffer.writeln('import \'package:flutter/material.dart\';');
    buffer.writeln();
    buffer.writeln('class ${theme.name.replaceAll(" ", "")}Theme {');
    buffer.writeln('  static const String themeId = \'${theme.id}\';');
    buffer.writeln('  static const Color backgroundColor = Color(${theme.backgroundColor.replaceAll("#", "0xFF")});');
    buffer.writeln('  static const Color particleGlowColor = Color(${theme.particleGlowColor.replaceAll("#", "0xFF")});');
    buffer.writeln();
    buffer.writeln('  static const List<Color> palette = [');
    for (final c in theme.palette) {
      buffer.writeln('    Color(${c.hex.replaceAll("#", "0xFF")}), // ${c.role}');
    }
    buffer.writeln('  ];');
    buffer.writeln('}');

    return buffer.toString();
  }
}
