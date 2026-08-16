/// Types of build artifacts supported by Flutter Package Studio.
enum ArtifactType {
  packageArchive,
  webBundle,
  documentationArchive,
  metadataDescriptor,
}

/// Target representation for artifact generation.
class ArtifactTarget {
  final String id;
  final String name;
  final ArtifactType type;
  final String path;

  const ArtifactTarget({
    required this.id,
    required this.name,
    required this.type,
    required this.path,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'path': path,
      };
}

/// Options configuring artifact generation.
class ArtifactOptions {
  final String packageName;
  final String version;
  final String outputDir;
  final bool execute;

  const ArtifactOptions({
    required this.packageName,
    this.version = '1.0.0',
    this.outputDir = 'build/artifacts',
    this.execute = false,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'outputDir': outputDir,
        'execute': execute,
      };
}

/// Preview plan of build artifact targets.
class ArtifactPlan {
  final String packageName;
  final String version;
  final List<ArtifactTarget> targets;
  final String outputDir;

  const ArtifactPlan({
    required this.packageName,
    required this.version,
    required this.targets,
    required this.outputDir,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'targetCount': targets.length,
        'targets': targets.map((t) => t.toJson()).toList(),
        'outputDir': outputDir,
      };
}

/// Result of package build and artifact generation.
class ArtifactResult {
  final String packageName;
  final String version;
  final bool isSuccess;
  final List<ArtifactTarget> generatedArtifacts;

  const ArtifactResult({
    required this.packageName,
    required this.version,
    required this.isSuccess,
    required this.generatedArtifacts,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Package Build & Artifact Report: $packageName');
    buf.writeln();
    buf.writeln('**Package Version**: $version');
    buf.writeln('**Build Status**: ${isSuccess ? "SUCCESS ✓" : "FAILED ✗"}');
    buf.writeln();
    buf.writeln('| Artifact ID | Name | Type | Expected Path |');
    buf.writeln('|---|---|---|---|');
    for (final a in generatedArtifacts) {
      buf.writeln(
          '| ${a.id} | ${a.name} | ${a.type.name.toUpperCase()} | ${a.path} |');
    }
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'isSuccess': isSuccess,
        'artifactCount': generatedArtifacts.length,
        'generatedArtifacts':
            generatedArtifacts.map((a) => a.toJson()).toList(),
      };
}
