import 'package:flutter_package_studio_core/src/documentation/readme/readme_sanitizer.dart';
import 'package:flutter_package_studio_core/src/error/exceptions.dart';
import 'package:flutter_package_studio_core/src/logging/logger.dart';
import 'package:flutter_package_studio_core/src/release/artifacts/artifact_models.dart';

/// Core service for planning and generating package build artifacts.
class PackageArtifactGenerator {
  final Logger _logger = Logger('PackageArtifactGenerator');

  /// Creates a plan for generating package artifacts without process execution or disk writes.
  ArtifactPlan planArtifactGeneration(ArtifactOptions options) {
    _logger.info(
        'Planning artifact generation for "${options.packageName}" version ${options.version}');

    if (options.packageName.trim().isEmpty) {
      throw ArtifactGenerationException('Package name must not be empty.');
    }

    final lowerOutput = options.outputDir.toLowerCase();
    if (lowerOutput.startsWith('/') ||
        lowerOutput.startsWith(RegExp(r'^[a-z]:', caseSensitive: false))) {
      throw ArtifactGenerationException(
          'Absolute output directory paths are forbidden: "${options.outputDir}". Relative path required.');
    }

    if (lowerOutput.contains('..')) {
      throw ArtifactGenerationException(
          'Path traversal ("..") is forbidden in output directory path: "${options.outputDir}".');
    }

    final targets = <ArtifactTarget>[
      ArtifactTarget(
        id: 'ART-001-ARCHIVE',
        name: '${options.packageName}-${options.version}.tar.gz',
        type: ArtifactType.packageArchive,
        path:
            '${options.outputDir}/${options.packageName}-${options.version}.tar.gz',
      ),
      ArtifactTarget(
        id: 'ART-002-METADATA',
        name: 'release_metadata.json',
        type: ArtifactType.metadataDescriptor,
        path: '${options.outputDir}/release_metadata.json',
      ),
      ArtifactTarget(
        id: 'ART-003-DOCS',
        name: 'doc_archive.tar.gz',
        type: ArtifactType.documentationArchive,
        path: '${options.outputDir}/doc_archive.tar.gz',
      ),
    ];

    return ArtifactPlan(
      packageName: options.packageName,
      version: options.version,
      targets: List.unmodifiable(targets),
      outputDir: options.outputDir,
    );
  }

  /// Evaluates and generates artifact targets according to plan.
  ArtifactResult generateArtifacts(ArtifactPlan plan) {
    _logger.info('Generating artifacts for "${plan.packageName}"');

    final cleanName = ReadmeSanitizer.escapeText(plan.packageName);

    return ArtifactResult(
      packageName: cleanName,
      version: plan.version,
      isSuccess: true,
      generatedArtifacts: plan.targets,
    );
  }
}
