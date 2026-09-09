/// Checksum digest model for release artifact verification.
class ArtifactChecksum {
  final String algorithm;
  final String value;

  const ArtifactChecksum({
    required this.algorithm,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'algorithm': algorithm,
        'value': value,
      };
}

/// Provenance metadata tracking subsystem origin.
class ArtifactProvenance {
  final String generator;
  final String sourcePhase;

  const ArtifactProvenance({
    required this.generator,
    required this.sourcePhase,
  });

  Map<String, dynamic> toJson() => {
        'generator': generator,
        'sourcePhase': sourcePhase,
      };
}

/// An entry describing a release artifact in the manifest.
class ReleaseArtifactEntry {
  final String id;
  final String name;
  final String type;
  final String relativePath;
  final int sizeBytes;
  final ArtifactChecksum checksum;
  final ArtifactProvenance provenance;

  const ReleaseArtifactEntry({
    required this.id,
    required this.name,
    required this.type,
    required this.relativePath,
    required this.sizeBytes,
    required this.checksum,
    required this.provenance,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'relativePath': relativePath,
        'sizeBytes': sizeBytes,
        'checksum': checksum.toJson(),
        'provenance': provenance.toJson(),
      };
}

/// Options configuring release artifact manifest generation.
class ManifestOptions {
  final String packageName;
  final String version;
  final String artifactDir;
  final String outputDir;

  const ManifestOptions({
    required this.packageName,
    this.version = '1.0.0',
    this.artifactDir = 'build/artifacts',
    this.outputDir = 'doc/release',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'artifactDir': artifactDir,
        'outputDir': outputDir,
      };
}

/// Preview plan of release artifact manifest entries.
class ReleaseArtifactManifestPlan {
  final String packageName;
  final String version;
  final String schemaVersion;
  final List<ReleaseArtifactEntry> entries;

  const ReleaseArtifactManifestPlan({
    required this.packageName,
    required this.version,
    this.schemaVersion = '1.0.0',
    required this.entries,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'schemaVersion': schemaVersion,
        'entryCount': entries.length,
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}

/// Result of release artifact manifest generation and checksum compiling.
class ReleaseArtifactManifestResult {
  final String packageName;
  final String version;
  final String schemaVersion;
  final bool isVerified;
  final List<ReleaseArtifactEntry> entries;

  const ReleaseArtifactManifestResult({
    required this.packageName,
    required this.version,
    required this.schemaVersion,
    required this.isVerified,
    required this.entries,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Release Artifact Manifest Report: $packageName');
    buf.writeln();
    buf.writeln('**Package Version**: $version');
    buf.writeln('**Schema Version**: $schemaVersion');
    buf.writeln(
        '**Integrity Status**: ${isVerified ? "VERIFIED ✓" : "UNVERIFIED ✗"}');
    buf.writeln();
    buf.writeln(
        '| Artifact ID | Name | Type | Relative Path | Size (Bytes) | SHA-256 Checksum |');
    buf.writeln('|---|---|---|---|---|---|');
    for (final e in entries) {
      buf.writeln(
          '| ${e.id} | ${e.name} | ${e.type} | ${e.relativePath} | ${e.sizeBytes} | ${e.checksum.value} |');
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'schemaVersion': schemaVersion,
        'isVerified': isVerified,
        'entryCount': entries.length,
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}
