import 'package:yaml/yaml.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/utils/file_utils.dart';
import 'package:flutter_package_studio_core/src/utils/platform_utils.dart';

/// Strongly typed configuration model for Flutter Package Studio.
class FpsConfig {
  /// The target output directory for package creation.
  final String outputDirectory;

  /// Default author name for generated packages.
  final String defaultAuthor;

  /// Default license type (e.g. MIT, BSD-3).
  final String defaultLicense;

  /// Whether verbose logging is enabled.
  final bool verbose;

  /// Additional custom parameters, providing dynamic extensibility for later phases.
  final Map<String, dynamic> custom;

  /// Creates a new [FpsConfig] instance.
  const FpsConfig({
    required this.outputDirectory,
    required this.defaultAuthor,
    required this.defaultLicense,
    required this.verbose,
    this.custom = const {},
  });

  /// Default configuration settings.
  factory FpsConfig.defaults() => const FpsConfig(
        outputDirectory: '.',
        defaultAuthor: 'Flutter Package Studio Developer',
        defaultLicense: 'MIT',
        verbose: false,
      );

  /// Creates an [FpsConfig] by merging values from a map.
  factory FpsConfig.fromMap(Map<String, dynamic> map) {
    final defaults = FpsConfig.defaults();
    return FpsConfig(
      outputDirectory: (map['output_directory'] ??
              map['outputDirectory'] ??
              defaults.outputDirectory)
          .toString(),
      defaultAuthor: (map['default_author'] ??
              map['defaultAuthor'] ??
              defaults.defaultAuthor)
          .toString(),
      defaultLicense: (map['default_license'] ??
              map['defaultLicense'] ??
              defaults.defaultLicense)
          .toString(),
      verbose: map['verbose'] == true || map['verbose'] == 'true',
      custom: Map<String, dynamic>.from(map['custom'] ?? {}),
    );
  }

  /// Exports the configuration properties to a standard map.
  Map<String, dynamic> toMap() {
    return {
      'output_directory': outputDirectory,
      'default_author': defaultAuthor,
      'default_license': defaultLicense,
      'verbose': verbose,
      'custom': custom,
    };
  }

  @override
  String toString() => 'FpsConfig(${toMap()})';
}

/// Service to load and merge configuration across sources.
class ConfigLoader {
  final FileUtils _fileUtils;
  final PlatformUtils _platformUtils;

  /// Creates a [ConfigLoader] with required [FileUtils] and [PlatformUtils] dependencies.
  ConfigLoader(this._fileUtils, this._platformUtils);

  /// Loads configuration by resolving defaults, global config, local project config,
  /// and environment variables.
  FpsConfig load({
    String? localConfigPath,
    String? globalConfigPath,
  }) {
    final Map<String, dynamic> merged = FpsConfig.defaults().toMap();

    // 1. Load Global Config if it exists
    final globalPath = globalConfigPath ?? _getGlobalConfigPath();
    if (globalPath != null && _fileUtils.exists(globalPath)) {
      final content = _fileUtils.readAsString(globalPath);
      final parsed = _parseYaml(content, globalPath);
      merged.addAll(parsed);
    }

    // 2. Load Local Config if it exists
    final localPath = localConfigPath ?? 'fps.yaml';
    if (_fileUtils.exists(localPath)) {
      final content = _fileUtils.readAsString(localPath);
      final parsed = _parseYaml(content, localPath);
      merged.addAll(parsed);
    }

    // 3. Load Environment Variables
    final envOutputDir = _platformUtils.getEnv('FPS_OUTPUT_DIR');
    if (envOutputDir != null) {
      merged['output_directory'] = envOutputDir;
    }
    final envAuthor = _platformUtils.getEnv('FPS_DEFAULT_AUTHOR');
    if (envAuthor != null) {
      merged['default_author'] = envAuthor;
    }
    final envLicense = _platformUtils.getEnv('FPS_DEFAULT_LICENSE');
    if (envLicense != null) {
      merged['default_license'] = envLicense;
    }
    final envVerbose = _platformUtils.getEnv('FPS_VERBOSE');
    if (envVerbose != null) {
      merged['verbose'] = envVerbose == 'true';
    }

    return FpsConfig.fromMap(merged);
  }

  String? _getGlobalConfigPath() {
    final home =
        _platformUtils.getEnv('USERPROFILE') ?? _platformUtils.getEnv('HOME');
    if (home == null) return null;
    return '$home${_platformUtils.pathSeparator}.fps${_platformUtils.pathSeparator}config.yaml';
  }

  Map<String, dynamic> _parseYaml(String content, String sourcePath) {
    if (content.trim().isEmpty) return {};
    try {
      final doc = loadYaml(content);
      if (doc == null) return {};
      if (doc is! YamlMap) {
        throw ConfigurationException(
            'Invalid YAML structure in "$sourcePath". Must be a map.');
      }
      return _yamlMapToMap(doc);
    } catch (e, st) {
      if (e is PackageStudioException) rethrow;
      throw ConfigurationException(
          'Failed to parse YAML file at "$sourcePath"', e, st);
    }
  }

  Map<String, dynamic> _yamlMapToMap(YamlMap yamlMap) {
    final Map<String, dynamic> result = {};
    for (final entry in yamlMap.entries) {
      final key = entry.key.toString();
      final val = entry.value;
      if (val is YamlMap) {
        result[key] = _yamlMapToMap(val);
      } else if (val is YamlList) {
        result[key] = val.toList();
      } else {
        result[key] = val;
      }
    }
    return result;
  }
}
