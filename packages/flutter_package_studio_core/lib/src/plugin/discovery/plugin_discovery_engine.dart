import 'dart:convert';
import 'dart:io';

import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_models.dart';
import 'package:flutter_package_studio_core/src/plugin/contract/plugin_contract_validator.dart';
import 'package:flutter_package_studio_core/src/plugin/discovery/plugin_discovery_models.dart';

/// Plugin Discovery Engine performing filesystem scanning of untrusted roots with strict non-execution.
class PluginDiscoveryEngine {
  final Logger _logger = Logger('PluginDiscoveryEngine');
  final PluginContractValidator _validator;

  /// Maximum allowed manifest file size in bytes (512 KB defensive threshold).
  static const int maxManifestSizeBytes = 512 * 1024;

  PluginDiscoveryEngine({PluginContractValidator? validator})
      : _validator = validator ?? PluginContractValidator();

  /// Scans provided root directory paths and produces a deterministic, non-executing [DiscoveryResult].
  Future<DiscoveryResult> discoverPlugins(List<String> rootPaths) async {
    _logger
        .info('Starting plugin discovery across ${rootPaths.length} root(s)');
    final rawEntries = <DiscoveredPluginEntry>[];
    final scannedRoots = <String>[];

    for (final rootPath in rootPaths) {
      final rootDir = Directory(rootPath);
      scannedRoots.add(rootPath);

      if (!rootDir.existsSync()) {
        _logger.warning('Discovery root "$rootPath" does not exist.');
        continue;
      }

      try {
        final rootManifest = File('${rootDir.path}/plugin.json');
        if (rootManifest.existsSync()) {
          final entry = await _inspectPluginDirectory(rootDir);
          if (entry != null) {
            rawEntries.add(entry);
          }
        } else {
          final entities = rootDir.listSync(followLinks: false);
          for (final entity in entities) {
            final isDir = FileSystemEntity.isDirectorySync(entity.path);
            final isLink = FileSystemEntity.isLinkSync(entity.path);
            if (isDir && !isLink) {
              final entry =
                  await _inspectPluginDirectory(Directory(entity.path));
              if (entry != null) {
                rawEntries.add(entry);
              }
            } else if (isLink) {
              // Symlink policy: Do not follow symlinks, report invalid/unsupported
              rawEntries.add(DiscoveredPluginEntry(
                directoryPath: entity.path,
                manifestPath: '${entity.path}/plugin.json',
                status: DiscoveredPluginStatus.invalid,
                details: ['Symlinks are not followed by security policy.'],
              ));
            }
          }
        }
      } catch (e) {
        _logger.error('Failed scanning root "$rootPath": $e');
        rawEntries.add(DiscoveredPluginEntry(
          directoryPath: rootPath,
          manifestPath: '$rootPath/plugin.json',
          status: DiscoveredPluginStatus.invalid,
          details: ['Permission denied or unreadable directory root: $e'],
        ));
      }
    }

    // Process duplicate detection & deterministic sorting
    final processedEntries = _processDuplicatesAndSort(rawEntries);

    return DiscoveryResult(
      scannedRoots: List.unmodifiable(scannedRoots),
      entries: List.unmodifiable(processedEntries),
    );
  }

  Future<DiscoveredPluginEntry?> _inspectPluginDirectory(Directory dir) async {
    final manifestFile = File('${dir.path}/plugin.json');
    if (!manifestFile.existsSync()) {
      // Directories with no plugin.json are silently excluded (not treated as error)
      return null;
    }

    // Defensive check 1: File size
    final stat = await manifestFile.stat();
    if (stat.size > maxManifestSizeBytes) {
      return DiscoveredPluginEntry(
        directoryPath: dir.path,
        manifestPath: manifestFile.path,
        status: DiscoveredPluginStatus.invalid,
        details: [
          'Oversized manifest (${stat.size} bytes > max $maxManifestSizeBytes bytes).'
        ],
      );
    }

    // Defensive check 2: Non-UTF8 / corruption reading text
    String content;
    try {
      content = await manifestFile.readAsString(encoding: utf8);
    } catch (e) {
      return DiscoveredPluginEntry(
        directoryPath: dir.path,
        manifestPath: manifestFile.path,
        status: DiscoveredPluginStatus.invalid,
        details: ['Corrupted or non-UTF-8 manifest content: $e'],
      );
    }

    // Defensive check 3: JSON parsing
    Map<String, dynamic> jsonMap;
    try {
      jsonMap = jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return DiscoveredPluginEntry(
        directoryPath: dir.path,
        manifestPath: manifestFile.path,
        status: DiscoveredPluginStatus.invalid,
        details: ['Malformed JSON content: $e'],
      );
    }

    // Contract validation using Phase 7.1 validator
    final valResult = _validator.validateRawJson(jsonMap);

    // Unsupported version check
    final apiVer = jsonMap['apiVersion'] as String?;
    if (apiVer != null &&
        !PluginContractValidator.supportedApiVersions.contains(apiVer.trim())) {
      return DiscoveredPluginEntry(
        directoryPath: dir.path,
        manifestPath: manifestFile.path,
        status: DiscoveredPluginStatus.unsupported,
        details: [
          'Unsupported plugin API version "$apiVer". Supported: ${PluginContractValidator.supportedApiVersions.join(", ")}'
        ],
      );
    }

    if (!valResult.isValid) {
      return DiscoveredPluginEntry(
        directoryPath: dir.path,
        manifestPath: manifestFile.path,
        status: DiscoveredPluginStatus.invalid,
        details: valResult.violations,
      );
    }

    // Valid Manifest parsed
    try {
      final manifest = PluginManifest.fromJson(jsonMap);
      return DiscoveredPluginEntry(
        directoryPath: dir.path,
        manifestPath: manifestFile.path,
        status: DiscoveredPluginStatus.valid,
        manifest: manifest,
        details: ['Manifest valid and compliant with Phase 7.1 contract.'],
      );
    } catch (e) {
      return DiscoveredPluginEntry(
        directoryPath: dir.path,
        manifestPath: manifestFile.path,
        status: DiscoveredPluginStatus.invalid,
        details: ['Failed constructing PluginManifest: $e'],
      );
    }
  }

  List<DiscoveredPluginEntry> _processDuplicatesAndSort(
      List<DiscoveredPluginEntry> rawEntries) {
    final idCounts = <String, int>{};
    for (final e in rawEntries) {
      if (e.manifest != null) {
        final id = e.manifest!.id.value;
        idCounts[id] = (idCounts[id] ?? 0) + 1;
      }
    }

    final result = <DiscoveredPluginEntry>[];
    for (final e in rawEntries) {
      if (e.manifest != null && (idCounts[e.manifest!.id.value] ?? 0) > 1) {
        result.add(DiscoveredPluginEntry(
          directoryPath: e.directoryPath,
          manifestPath: e.manifestPath,
          status: DiscoveredPluginStatus.duplicate,
          manifest: e.manifest,
          details: [
            'Duplicate Plugin ID "${e.manifest!.id.value}" declared across multiple discovered directories.'
          ],
        ));
      } else {
        result.add(e);
      }
    }

    // Deterministic sorting: sort by manifest ID if present, otherwise by directoryPath
    result.sort((a, b) {
      final idA = a.manifest != null ? a.manifest!.id.value : a.directoryPath;
      final idB = b.manifest != null ? b.manifest!.id.value : b.directoryPath;
      return idA.compareTo(idB);
    });

    return result;
  }
}
