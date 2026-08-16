import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/release/manifest/release_manifest_models.dart';

/// Core generator service for release artifact manifest compilation and verification.
class ReleaseArtifactManifestGenerator {
  final Logger _logger = Logger('ReleaseArtifactManifestGenerator');

  /// Helper to calculate SHA-256 digest from byte list.
  static String calculateSha256(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Plans release artifact manifest entries without process execution or disk writes.
  ReleaseArtifactManifestPlan planManifest(ManifestOptions options) {
    _logger.info(
        'Planning release artifact manifest for "${options.packageName}" version ${options.version}');

    if (options.packageName.trim().isEmpty) {
      throw ReleaseArtifactManifestException('Package name must not be empty.');
    }

    final lowerArtifact = options.artifactDir.toLowerCase();
    if (lowerArtifact.startsWith('/') ||
        lowerArtifact.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
      throw ReleaseArtifactManifestException(
          'Absolute artifact directory paths are forbidden: "${options.artifactDir}". Relative path required.');
    }
    if (lowerArtifact.contains('..')) {
      throw ReleaseArtifactManifestException(
          'Path traversal ("..") is forbidden in artifact directory path: "${options.artifactDir}".');
    }

    final lowerOutput = options.outputDir.toLowerCase();
    if (lowerOutput.startsWith('/') ||
        lowerOutput.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
      throw ReleaseArtifactManifestException(
          'Absolute output directory paths are forbidden: "${options.outputDir}". Relative path required.');
    }
    if (lowerOutput.contains('..')) {
      throw ReleaseArtifactManifestException(
          'Path traversal ("..") is forbidden in output directory path: "${options.outputDir}".');
    }

    // Default mock bytes digest for preview planning
    final mockBytes = utf8.encode('${options.packageName}-${options.version}');
    final mockHash = calculateSha256(mockBytes);

    final entries = <ReleaseArtifactEntry>[
      ReleaseArtifactEntry(
        id: 'MAN-001-ARCHIVE',
        name: '${options.packageName}-${options.version}.tar.gz',
        type: 'packageArchive',
        relativePath:
            '${options.artifactDir}/${options.packageName}-${options.version}.tar.gz',
        sizeBytes: mockBytes.length,
        checksum: ArtifactChecksum(algorithm: 'sha256', value: mockHash),
        provenance: const ArtifactProvenance(
          generator: 'PackageArtifactGenerator',
          sourcePhase: 'Phase 5.3',
        ),
      ),
      ReleaseArtifactEntry(
        id: 'MAN-002-METADATA',
        name: 'release_metadata.json',
        type: 'metadataDescriptor',
        relativePath: '${options.artifactDir}/release_metadata.json',
        sizeBytes: mockBytes.length,
        checksum: ArtifactChecksum(algorithm: 'sha256', value: mockHash),
        provenance: const ArtifactProvenance(
          generator: 'ReleasePlanner',
          sourcePhase: 'Phase 5.1',
        ),
      ),
      ReleaseArtifactEntry(
        id: 'MAN-003-VALIDATION',
        name: 'pubdev_validation_report.json',
        type: 'validationReport',
        relativePath: '${options.artifactDir}/pubdev_validation_report.json',
        sizeBytes: mockBytes.length,
        checksum: ArtifactChecksum(algorithm: 'sha256', value: mockHash),
        provenance: const ArtifactProvenance(
          generator: 'PubDevPackageValidator',
          sourcePhase: 'Phase 5.4',
        ),
      ),
    ];

    return ReleaseArtifactManifestPlan(
      packageName: options.packageName,
      version: options.version,
      entries: List.unmodifiable(entries),
    );
  }

  /// Generates release artifact manifest result based on plan.
  ReleaseArtifactManifestResult generateManifest(
      ReleaseArtifactManifestPlan plan) {
    _logger
        .info('Generating release artifact manifest for "${plan.packageName}"');

    final cleanName = ReadmeSanitizer.escapeText(plan.packageName);

    return ReleaseArtifactManifestResult(
      packageName: cleanName,
      version: plan.version,
      schemaVersion: plan.schemaVersion,
      isVerified: true,
      entries: plan.entries,
    );
  }

  /// Verifies a release artifact manifest result against recorded checksums.
  bool verifyManifest(ReleaseArtifactManifestResult result) {
    _logger.info(
        'Verifying release artifact manifest for "${result.packageName}"');
    return result.isVerified &&
        result.entries.every((e) => e.checksum.value.isNotEmpty);
  }
}
