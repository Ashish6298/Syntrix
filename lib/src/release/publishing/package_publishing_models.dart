/// Target registry destination for package publication.
class PublishingTarget {
  final String id;
  final String name;
  final String url;

  const PublishingTarget({
    required this.id,
    required this.name,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
      };
}

/// Evaluation status of package publication.
enum PublishingStatus {
  planned,
  passed,
  failed,
  blocked,
  published,
  dryRunSuccess,
}

/// Options configuring package publishing.
class PublishingOptions {
  final String packageName;
  final String version;
  final String profile;
  final bool publish; // Explicit execution flag
  final String outputDir;

  const PublishingOptions({
    required this.packageName,
    this.version = '1.0.0',
    this.profile = 'standard',
    this.publish = false,
    this.outputDir = 'doc/release',
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'profile': profile,
        'publish': publish,
        'outputDir': outputDir,
      };
}

/// Preview plan of package publication steps.
class PackagePublishingPlan {
  final String packageName;
  final String version;
  final PublishingTarget target;
  final PublishingStatus status;

  const PackagePublishingPlan({
    required this.packageName,
    required this.version,
    required this.target,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'target': target.toJson(),
        'status': status.name,
      };
}

/// Result of package publishing execution.
class PackagePublishingResult {
  final String packageName;
  final String version;
  final bool isSuccess;
  final PublishingStatus status;
  final String details;

  const PackagePublishingResult({
    required this.packageName,
    required this.version,
    required this.isSuccess,
    required this.status,
    required this.details,
  });

  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Package Publishing Report: $packageName');
    buf.writeln();
    buf.writeln('**Package Version**: $version');
    buf.writeln('**Publishing Status**: ${status.name.toUpperCase()}');
    buf.writeln(
        '**Result**: ${isSuccess ? "PUBLISHING SUCCESS ✓" : "PUBLISHING BLOCKED / FAILED ✗"}');
    buf.writeln();
    buf.writeln('### Details');
    buf.writeln(details);
    return buf.toString();
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'isSuccess': isSuccess,
        'status': status.name,
        'details': details,
      };
}
